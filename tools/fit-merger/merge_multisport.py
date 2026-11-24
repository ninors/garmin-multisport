#!/usr/bin/env python3
"""
Garmin Multisport (FR165M) — Automated Chronological FIT Merger for Garmin Connect.

How it works:
1. Fetches recent activities from Garmin Connect (sorted chronologically).
2. Detects consecutive activities chained together by start/end timestamp
   (gap between -30s and +180s), or explicitly tagged with `MS YYMMDD_HHMM`.
3. Automatically classifies the chain (Triathlon, Duathlon, Swimrun, Aquathlon,
   or Multisport personnalisé) based on the ordered sport sequence.
4. Skips any chain that already has a matching `multi_sport` activity at the same
   start time (idempotent).
5. Downloads each leg's original .FIT file, merges them into a single authentic
   multi-session Garmin Multisport .FIT file (with `time_created + 1s` so Garmin
   Connect never rejects it as a duplicate of leg 1, and converts intermediate
   `generic` legs to native `TRANSITION` sessions).
6. Uploads the unified Multisport activity to Garmin Connect.
   NEVER deletes original leg activities!
"""

import io
import math
import os
import re
import sys
import time
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from fit_tool.fit_file import FitFile
from fit_tool.fit_file_builder import FitFileBuilder
from fit_tool.profile.messages.activity_message import ActivityMessage
from fit_tool.profile.messages.event_message import EventMessage
from fit_tool.profile.messages.file_id_message import FileIdMessage
from fit_tool.profile.messages.lap_message import LapMessage
from fit_tool.profile.messages.record_message import RecordMessage
from fit_tool.profile.messages.session_message import SessionMessage
from fit_tool.profile.profile_type import (
    Activity,
    Event,
    EventType,
    FileType,
    Manufacturer,
    Sport,
    SubSport,
)
from garminconnect import Garmin

TAG_REGEX = re.compile(r"^(?:\[MS:|MS\s+)(\d{6}_\d{4})\s+(\d+)[/-](\d+)\]?\s*(.+)$")
MAX_CHAIN_GAP_SEC = 180  # Max 3 minutes gap between consecutive legs

# Mapping from Watch App FitContributor `ms_sport` lap ID -> (FIT Sport, FIT SubSport)
APP_SPORT_ID_MAP = {
    0: (Sport.SWIMMING, SubSport.OPEN_WATER),
    1: (Sport.SWIMMING, SubSport.LAP_SWIMMING),
    2: (Sport.TRANSITION, SubSport.SWIM_TO_BIKE_TRANSITION),
    3: (Sport.CYCLING, SubSport.GENERIC),
    4: (Sport.TRANSITION, SubSport.BIKE_TO_RUN_TRANSITION),
    5: (Sport.RUNNING, SubSport.GENERIC),
    6: (Sport.RUNNING, SubSport.TRAIL),
    7: (Sport.WALKING, SubSport.GENERIC),
    8: (Sport.TRAINING, SubSport.CARDIO_TRAINING),
    9: (Sport.ROWING, SubSport.GENERIC),
}


def try_split_continuous_fit(fit_path: Path, output_path: Path) -> bool:
    """
    If a single continuous FIT file contains FitContributor `ms_sport` lap tags
    with 2+ distinct sport legs, split it into a native multi-session Garmin
    Multisport FIT file. Returns True if split succeeded.
    """
    fit = FitFile.from_file(str(fit_path))
    laps_with_sport: List[Tuple[LapMessage, int]] = []
    all_records: List[RecordMessage] = []
    file_id: Optional[FileIdMessage] = None
    feel_level: Optional[int] = None

    for rec in fit.records:
        msg = rec.message
        if isinstance(msg, FileIdMessage) and file_id is None:
            file_id = msg
        elif isinstance(msg, RecordMessage):
            all_records.append(msg)
        elif isinstance(msg, SessionMessage):
            for f in getattr(msg, "developer_fields", []) or []:
                if getattr(f, "field_id", None) == 1:
                    vals = getattr(f, "values", None)
                    if vals and vals[0] is not None:
                        feel_level = int(vals[0])
        elif isinstance(msg, LapMessage):
            # Look for FitContributor developer field id=0 (`ms_sport`)
            dev_sport = None
            for f in getattr(msg, "developer_fields", []) or []:
                if getattr(f, "field_id", None) == 0:
                    vals = getattr(f, "values", None)
                    if vals and vals[0] is not None:
                        dev_sport = int(vals[0])
                        break
            if dev_sport is not None and dev_sport in APP_SPORT_ID_MAP:
                laps_with_sport.append((msg, dev_sport))

    if len(laps_with_sport) < 2 or file_id is None:
        return False

    # Group consecutive laps with the same sport ID into sessions
    grouped_legs: List[Tuple[int, List[LapMessage]]] = []
    for lap_msg, sp_id in laps_with_sport:
        if grouped_legs and grouped_legs[-1][0] == sp_id:
            grouped_legs[-1][1].append(lap_msg)
        else:
            grouped_legs.append((sp_id, [lap_msg]))

    if len(grouped_legs) < 2:
        return False

    builder = FitFileBuilder(auto_define=True, min_string_size=50)
    if getattr(file_id, "time_created", None):
        file_id.time_created = int(file_id.time_created) + 1000
    builder.add(file_id)

    lap_idx = 0
    total_timer = 0.0
    last_ts = None

    for sess_idx, (sp_id, leg_laps) in enumerate(grouped_legs):
        fit_sport, fit_sub = APP_SPORT_ID_MAP[sp_id]
        leg_start = leg_laps[0].start_time or leg_laps[0].timestamp
        leg_end = leg_laps[-1].timestamp or leg_start
        first_lap_idx = lap_idx

        ev_s = EventMessage()
        ev_s.timestamp = leg_start
        ev_s.event = Event.TIMER
        ev_s.event_type = EventType.START
        builder.add(ev_s)

        for r in all_records:
            if r.timestamp is not None and leg_start is not None and leg_end is not None:
                if leg_start <= r.timestamp <= leg_end:
                    builder.add(r)

        ev_e = EventMessage()
        ev_e.timestamp = leg_end
        ev_e.event = Event.TIMER
        ev_e.event_type = EventType.STOP_ALL
        builder.add(ev_e)

        leg_timer = 0.0
        leg_dist = 0.0
        for lm in leg_laps:
            lm.message_index = lap_idx
            lm.sport = fit_sport
            lm.sub_sport = fit_sub
            builder.add(lm)
            lap_idx += 1
            if getattr(lm, "total_timer_time", None):
                leg_timer += float(lm.total_timer_time)
            if getattr(lm, "total_distance", None):
                leg_dist += float(lm.total_distance)

        sess = SessionMessage()
        sess.message_index = sess_idx
        sess.timestamp = leg_end
        sess.start_time = leg_start
        sess.total_elapsed_time = leg_timer
        sess.total_timer_time = leg_timer
        sess.total_distance = leg_dist
        sess.sport = fit_sport
        sess.sub_sport = fit_sub
        sess.first_lap_index = first_lap_idx
        sess.num_laps = len(leg_laps)
        if feel_level is not None and 0 <= feel_level <= 4 and hasattr(sess, "workout_feel"):
            sess.workout_feel = feel_level * 25  # 0, 25, 50, 75, 100 (Garmin native scale)
        builder.add(sess)

        total_timer += leg_timer
        last_ts = leg_end

    act = ActivityMessage()
    if last_ts is not None:
        act.timestamp = last_ts
    act.total_timer_time = total_timer
    act.num_sessions = len(grouped_legs)
    act.type = Activity.AUTO_MULTI_SPORT
    builder.add(act)

    builder.build().to_file(str(output_path))
    return True


def parse_gmt_time(ts_str: str) -> Optional[datetime]:
    if not ts_str:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(ts_str[:19], fmt[: len(ts_str[:19])]).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def normalize_sport_category(type_key: str) -> str:
    k = (type_key or "").lower()
    if "swim" in k:
        return "swim"
    if "cycl" in k or "bik" in k:
        return "bike"
    if "run" in k or "trail" in k:
        return "run"
    if "walk" in k or "hik" in k:
        return "walk"
    if "row" in k or "kayak" in k:
        return "row"
    if "transition" in k or "other" in k or "generic" in k:
        return "transition"
    return "other"


def classify_multisport_name(sports: List[str]) -> str:
    core = [s for s in sports if s != "transition"]
    if core == ["swim", "bike", "run"]:
        return "Triathlon"
    if core == ["run", "bike", "run"]:
        return "Duathlon"
    if core == ["swim", "run", "swim", "run"]:
        return "Swimrun"
    if core == ["swim", "run"]:
        return "Aquathlon"
    return "Multisport"


def extract_fit_from_zip(raw_bytes: bytes) -> bytes:
    with zipfile.ZipFile(io.BytesIO(raw_bytes)) as zf:
        for name in zf.namelist():
            if name.lower().endswith(".fit"):
                return zf.read(name)
    raise ValueError("No .fit file found inside Garmin Connect zip archive")


def merge_fit_files(fit_paths: List[Path], leg_categories: List[str], output_path: Path) -> None:
    builder = FitFileBuilder(auto_define=True, min_string_size=50)

    first_file_id = None
    session_index = 0
    lap_index = 0
    total_timer_time = 0.0
    last_timestamp = None

    for idx, path in enumerate(fit_paths):
        is_intermediate_transition = (
            0 < idx < len(fit_paths) - 1 and leg_categories[idx] == "transition"
        )
        fit = FitFile.from_file(str(path))
        leg_first_lap = lap_index
        leg_lap_count = 0

        for record in fit.records:
            msg = record.message
            if isinstance(msg, FileIdMessage):
                if first_file_id is None:
                    first_file_id = msg
                    # Offset time_created by +1000ms so Garmin Connect never rejects
                    # the merged multisport activity as a duplicate of Leg 1!
                    if getattr(msg, "time_created", None):
                        msg.time_created = int(msg.time_created) + 1000
                    builder.add(msg)
            elif isinstance(msg, (RecordMessage, EventMessage)):
                builder.add(msg)
                if getattr(msg, "timestamp", None):
                    last_timestamp = msg.timestamp
            elif isinstance(msg, LapMessage):
                msg.message_index = lap_index
                if is_intermediate_transition:
                    msg.sport = Sport.TRANSITION
                    msg.sub_sport = SubSport.GENERIC
                lap_index += 1
                leg_lap_count += 1
                builder.add(msg)
            elif isinstance(msg, SessionMessage):
                msg.message_index = session_index
                msg.first_lap_index = leg_first_lap
                msg.num_laps = max(1, leg_lap_count)
                if is_intermediate_transition:
                    msg.sport = Sport.TRANSITION
                    msg.sub_sport = SubSport.GENERIC
                session_index += 1
                if getattr(msg, "total_timer_time", None):
                    total_timer_time += float(msg.total_timer_time)
                if getattr(msg, "timestamp", None):
                    last_timestamp = msg.timestamp
                builder.add(msg)

    if session_index == 0:
        raise ValueError("No FIT session messages found to merge")

    act = ActivityMessage()
    if last_timestamp is not None:
        act.timestamp = last_timestamp
    act.total_timer_time = total_timer_time
    act.num_sessions = session_index
    act.type = Activity.AUTO_MULTI_SPORT
    builder.add(act)

    merged_fit = builder.build()
    merged_fit.to_file(str(output_path))


def build_synthetic_test_triathlon(output_path: Path) -> None:
    """Build a valid 5-session Test Triathlon FIT (Swim -> T1 -> Bike -> T2 -> Run)."""
    builder = FitFileBuilder(auto_define=True, min_string_size=50)

    # Start 35 minutes ago so timestamps are strictly in the past
    start_ms = int((time.time() - 2100) * 1000)

    file_id = FileIdMessage()
    file_id.type = FileType.ACTIVITY
    file_id.manufacturer = Manufacturer.GARMIN
    file_id.product = 4433  # Forerunner 165 Music
    file_id.time_created = start_ms
    file_id.serial_number = 3456789012
    builder.add(file_id)

    # Legs: (Sport, SubSport, duration_sec, speed_mps, avg_hr)
    legs_spec = [
        (Sport.SWIMMING, SubSport.OPEN_WATER, 180, 1.1, 138),
        (Sport.TRANSITION, SubSport.SWIM_TO_BIKE_TRANSITION, 45, 0.2, 130),
        (Sport.CYCLING, SubSport.GENERIC, 300, 8.5, 152),
        (Sport.TRANSITION, SubSport.BIKE_TO_RUN_TRANSITION, 35, 0.2, 140),
        (Sport.RUNNING, SubSport.GENERIC, 240, 3.3, 164),
    ]

    cur_ms = start_ms
    total_dist = 0.0
    base_lat = 48.8566  # Paris
    base_lon = 2.3522

    for idx, (sport, sub_sport, dur_sec, speed, base_hr) in enumerate(legs_spec):
        leg_start_ms = cur_ms
        leg_dist = 0.0

        ev_start = EventMessage()
        ev_start.timestamp = leg_start_ms
        ev_start.event = Event.TIMER
        ev_start.event_type = EventType.START
        builder.add(ev_start)

        step_sec = 5
        for s in range(0, dur_sec + 1, step_sec):
            t_ms = leg_start_ms + (s * 1000)
            leg_dist = float(s) * speed
            rec = RecordMessage()
            rec.timestamp = t_ms
            rec.distance = total_dist + leg_dist
            rec.speed = speed
            rec.heart_rate = base_hr + int(4 * math.sin(s / 30.0))
            rec.altitude = 45.0 + 5.0 * math.sin((total_dist + leg_dist) / 300.0)
            # Gentle loop coordinates
            angle = (total_dist + leg_dist) / 1000.0
            rec.position_lat = base_lat + 0.002 * math.sin(angle)
            rec.position_long = base_lon + 0.003 * math.cos(angle)
            builder.add(rec)

        leg_end_ms = leg_start_ms + (dur_sec * 1000)
        ev_stop = EventMessage()
        ev_stop.timestamp = leg_end_ms
        ev_stop.event = Event.TIMER
        ev_stop.event_type = EventType.STOP_ALL
        builder.add(ev_stop)

        lap = LapMessage()
        lap.message_index = idx
        lap.timestamp = leg_end_ms
        lap.start_time = leg_start_ms
        lap.total_elapsed_time = float(dur_sec)
        lap.total_timer_time = float(dur_sec)
        lap.total_distance = leg_dist
        lap.sport = sport
        lap.sub_sport = sub_sport
        lap.avg_heart_rate = base_hr
        lap.max_heart_rate = base_hr + 6
        builder.add(lap)

        sess = SessionMessage()
        sess.message_index = idx
        sess.timestamp = leg_end_ms
        sess.start_time = leg_start_ms
        sess.total_elapsed_time = float(dur_sec)
        sess.total_timer_time = float(dur_sec)
        sess.total_distance = leg_dist
        sess.sport = sport
        sess.sub_sport = sub_sport
        sess.first_lap_index = idx
        sess.num_laps = 1
        sess.avg_heart_rate = base_hr
        sess.max_heart_rate = base_hr + 6
        builder.add(sess)

        total_dist += leg_dist
        cur_ms = leg_end_ms + 1000

    act = ActivityMessage()
    act.timestamp = cur_ms
    act.total_timer_time = float(sum(x[2] for x in legs_spec))
    act.num_sessions = len(legs_spec)
    act.type = Activity.AUTO_MULTI_SPORT
    builder.add(act)

    fit = builder.build()
    fit.to_file(str(output_path))


def detect_chronological_chains(activities: List[dict]) -> List[List[dict]]:
    """Group consecutive non-multisport activities separated by <= MAX_CHAIN_GAP_SEC."""
    existing_multisport_starts: List[datetime] = []
    singles: List[Tuple[datetime, datetime, dict]] = []

    for act in activities:
        type_key = ((act.get("activityType") or {}).get("typeKey") or "").lower()
        start_dt = parse_gmt_time(act.get("startTimeGMT") or "")
        if start_dt is None:
            continue
        dur_sec = float(act.get("elapsedDuration") or act.get("duration") or 0.0)
        end_dt = start_dt + timedelta(seconds=dur_sec)

        if "multi_sport" in type_key:
            existing_multisport_starts.append(start_dt)
            continue

        singles.append((start_dt, end_dt, act))

    # Sort oldest -> newest
    singles.sort(key=lambda x: x[0])

    chains: List[List[Tuple[datetime, datetime, dict]]] = []
    for item in singles:
        s_dt, e_dt, act = item
        if not chains:
            chains.append([item])
            continue
        prev_s, prev_e, _ = chains[-1][-1]
        gap = (s_dt - prev_e).total_seconds()
        if -30.0 <= gap <= float(MAX_CHAIN_GAP_SEC):
            chains[-1].append(item)
        else:
            chains.append([item])

    # Keep only valid multi-leg chains (2+ legs, at least 2 distinct or triathlon/duathlon legs)
    # and skip chains already covered by an existing multi_sport activity
    result: List[List[dict]] = []
    for chain in chains:
        if len(chain) < 2:
            continue
        chain_start = chain[0][0]
        already_merged = any(
            abs((ms_start - chain_start).total_seconds()) <= 180.0
            for ms_start in existing_multisport_starts
        )
        if already_merged:
            print(f"[SKIP] Chain starting {chain_start.isoformat()} already has a Multisport activity.")
            continue

        # Must contain at least 2 non-transition legs OR a tagged MS activity
        cats = [
            normalize_sport_category(((c[2].get("activityType") or {}).get("typeKey") or ""))
            for c in chain
        ]
        non_trans = [c for c in cats if c != "transition"]
        has_ms_tag = any(TAG_REGEX.match(c[2].get("activityName") or "") for c in chain)
        if len(non_trans) >= 2 or has_ms_tag:
            result.append([c[2] for c in chain])

    return result


def main() -> int:
    email = os.environ.get("GARMIN_EMAIL", "").strip()
    password = os.environ.get("GARMIN_PASSWORD", "").strip()
    test_upload = os.environ.get("TEST_UPLOAD", "false").lower() == "true"

    if not email or not password:
        print("ERROR: GARMIN_EMAIL and GARMIN_PASSWORD environment variables must be set.", file=sys.stderr)
        return 1

    print("Authenticating with Garmin Connect...")
    client = Garmin(email, password)
    client.login()
    print("Authenticated successfully!")

    work_dir = Path("tmp_fits")
    work_dir.mkdir(exist_ok=True)

    # Optional test mode: upload a synthetic 5-leg Triathlon FIT to verify Garmin Connect parsing
    if test_upload:
        test_fit = work_dir / "test_triathlon_multisport.fit"
        print("Building synthetic 5-leg Test Triathlon FIT (Swim -> T1 -> Bike -> T2 -> Run)...")
        build_synthetic_test_triathlon(test_fit)
        print(f"Uploading {test_fit} ({test_fit.stat().st_size} bytes) to Garmin Connect...")
        resp = client.upload_activity(str(test_fit))
        print(f"Test upload response: {resp}")

    # Inspect recent activities and merge any consecutive multisport chains (NEVER deleting originals!)
    activities = client.get_activities(0, 30)
    print(f"Fetched {len(activities)} recent activities:")
    for act in activities[:10]:
        tkey = (act.get("activityType") or {}).get("typeKey", "?")
        print(f"  - [{act.get('activityId')}] {act.get('startTimeGMT')} | {tkey} | {act.get('duration', 0):.0f}s | {act.get('activityName')}")

    # Mode A: Check recent single-session continuous activities for FitContributor `ms_sport` lap tags
    existing_ms_starts = [
        parse_gmt_time(a.get("startTimeGMT") or "")
        for a in activities
        if "multi_sport" in (((a.get("activityType") or {}).get("typeKey") or "").lower())
    ]
    for act in activities[:10]:
        tkey = ((act.get("activityType") or {}).get("typeKey") or "").lower()
        if "multi_sport" in tkey:
            continue
        start_dt = parse_gmt_time(act.get("startTimeGMT") or "")
        if start_dt and any(ms and abs((ms - start_dt).total_seconds()) <= 180.0 for ms in existing_ms_starts):
            continue
        if (act.get("lapCount") or 0) >= 2:
            act_id = act["activityId"]
            try:
                zip_bytes = client.download_activity(act_id, dl_fmt=client.ActivityDownloadFormat.ORIGINAL)
                raw_path = work_dir / f"single_{act_id}.fit"
                raw_path.write_bytes(extract_fit_from_zip(zip_bytes))
                split_path = work_dir / f"split_{act_id}_multisport.fit"
                if try_split_continuous_fit(raw_path, split_path):
                    print(f"Split continuous Multisport activity {act_id} -> uploading native Multisport FIT (original preserved!)...")
                    resp = client.upload_activity(str(split_path))
                    print(f"Upload response for split {act_id}: {resp}")
                    if start_dt:
                        existing_ms_starts.append(start_dt)
            except Exception as ex:
                print(f"Note: skipped continuous split check for {act_id}: {ex}")

    # Mode B: Merge consecutive separate activities into a native Multisport FIT
    chains = detect_chronological_chains(activities)
    if not chains:
        print("No new consecutive multisport chains to merge.")
        return 0

    for chain in chains:
        cats = [
            normalize_sport_category(((a.get("activityType") or {}).get("typeKey") or ""))
            for a in chain
        ]
        ms_name = classify_multisport_name(cats)
        first_id = chain[0]["activityId"]
        print(f"Detected {ms_name} chain ({len(chain)} legs: {' -> '.join(cats)}) starting at {chain[0].get('startTimeGMT')}...")

        fit_paths: List[Path] = []
        for idx, act in enumerate(chain):
            act_id = act["activityId"]
            zip_bytes = client.download_activity(act_id, dl_fmt=client.ActivityDownloadFormat.ORIGINAL)
            fit_bytes = extract_fit_from_zip(zip_bytes)
            p = work_dir / f"chain_{first_id}_leg{idx + 1}.fit"
            p.write_bytes(fit_bytes)
            fit_paths.append(p)

        merged_path = work_dir / f"chain_{first_id}_{ms_name.lower()}.fit"
        merge_fit_files(fit_paths, cats, merged_path)
        print(f"Merged {ms_name} FIT ({merged_path.stat().st_size} bytes), uploading to Garmin Connect (originals preserved!)...")
        upload_resp = client.upload_activity(str(merged_path))
        print(f"Upload response for {ms_name}: {upload_resp}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

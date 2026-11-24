#!/usr/bin/env python3
"""
Garmin Multisport 965 (FR165M) — Automated FIT Merger for Garmin Connect.

Detects sequential leg activities recorded by the Multisport 965 Watch App
named `[MS:<group_id> <idx>/<total>] <Sport>`, downloads their original .FIT
files, merges them into a single multi-session Garmin Multisport .FIT file,
and uploads the unified Multisport activity to Garmin Connect.
"""

import io
import os
import re
import sys
import zipfile
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

from fit_tool.fit_file import FitFile
from fit_tool.fit_file_builder import FitFileBuilder
from fit_tool.profile.messages.activity_message import ActivityMessage
from fit_tool.profile.messages.event_message import EventMessage
from fit_tool.profile.messages.file_id_message import FileIdMessage
from fit_tool.profile.messages.lap_message import LapMessage
from fit_tool.profile.messages.record_message import RecordMessage
from fit_tool.profile.messages.session_message import SessionMessage
from garminconnect import Garmin

TAG_REGEX = re.compile(r"^\[MS:(\d{6}_\d{4})\s+(\d+)/(\d+)\]\s*(.+)$")
MERGED_PREFIX = "Multisport"


def extract_fit_from_zip(raw_bytes: bytes) -> bytes:
    with zipfile.ZipFile(io.BytesIO(raw_bytes)) as zf:
        for name in zf.namelist():
            if name.lower().endswith(".fit"):
                return zf.read(name)
    raise ValueError("No .fit file found inside Garmin Connect zip archive")


def merge_fit_files(fit_paths: List[Path], output_path: Path) -> None:
    builder = FitFileBuilder(auto_define=True, min_string_size=50)

    first_file_id = None
    session_index = 0
    lap_index = 0
    total_timer_time = 0.0
    last_timestamp = None

    for path in fit_paths:
        fit = FitFile.from_file(str(path))
        for record in fit.records:
            msg = record.message
            if isinstance(msg, FileIdMessage):
                if first_file_id is None:
                    first_file_id = msg
                    builder.add(msg)
            elif isinstance(msg, (RecordMessage, EventMessage)):
                builder.add(msg)
                if getattr(msg, "timestamp", None):
                    last_timestamp = msg.timestamp
            elif isinstance(msg, LapMessage):
                msg.message_index = lap_index
                lap_index += 1
                builder.add(msg)
            elif isinstance(msg, SessionMessage):
                msg.message_index = session_index
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
    act.type = 1  # Multisport
    builder.add(act)

    merged_fit = builder.build()
    merged_fit.to_file(str(output_path))


def main() -> int:
    email = os.environ.get("GARMIN_EMAIL", "").strip()
    password = os.environ.get("GARMIN_PASSWORD", "").strip()
    delete_originals = os.environ.get("DELETE_ORIGINAL_LEGS", "false").lower() == "true"

    if not email or not password:
        print("ERROR: GARMIN_EMAIL and GARMIN_PASSWORD environment variables must be set.", file=sys.stderr)
        return 1

    print("Authenticating with Garmin Connect...")
    client = Garmin(email, password)
    client.login()

    activities = client.get_activities(0, 40)
    groups: Dict[str, List[Tuple[int, int, dict]]] = defaultdict(list)
    already_merged_ids = set()

    for act in activities:
        name = act.get("activityName") or ""
        if MERGED_PREFIX in name:
            for m in re.findall(r"\d{6}_\d{4}", name):
                already_merged_ids.add(m)
            continue

        match = TAG_REGEX.match(name)
        if match:
            group_id = match.group(1)
            leg_idx = int(match.group(2))
            leg_total = int(match.group(3))
            groups[group_id].append((leg_idx, leg_total, act))

    if not groups:
        print("No unmerged Multisport 965 sessions found.")
        return 0

    work_dir = Path("tmp_fits")
    work_dir.mkdir(exist_ok=True)

    for group_id, items in groups.items():
        if group_id in already_merged_ids:
            print(f"[{group_id}] Already merged, skipping.")
            continue

        items.sort(key=lambda x: x[0])
        expected_total = items[0][1]
        if len(items) < 2:
            print(f"[{group_id}] Only {len(items)} leg found (expected {expected_total}), waiting...")
            continue

        print(f"[{group_id}] Downloading {len(items)}/{expected_total} legs...")
        fit_paths: List[Path] = []
        for leg_idx, _, act in items:
            act_id = act["activityId"]
            zip_bytes = client.download_activity(act_id, dl_fmt=client.ActivityDownloadFormat.ORIGINAL)
            fit_bytes = extract_fit_from_zip(zip_bytes)
            p = work_dir / f"{group_id}_leg{leg_idx}.fit"
            p.write_bytes(fit_bytes)
            fit_paths.append(p)

        merged_path = work_dir / f"{group_id}_multisport.fit"
        merge_fit_files(fit_paths, merged_path)
        print(f"[{group_id}] Merged FIT written to {merged_path}, uploading to Garmin Connect...")

        upload_resp = client.upload_activity(str(merged_path))
        print(f"[{group_id}] Upload response: {upload_resp}")

        if delete_originals:
            for _, _, act in items:
                client.delete_activity(act["activityId"])
            print(f"[{group_id}] Deleted {len(items)} individual leg activities.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

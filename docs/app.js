(() => {
  const STORAGE_DATA = "ms_pwa_activities_v1";
  const STORAGE_REPO = "ms_pwa_gh_repo";
  const STORAGE_TOKEN = "ms_pwa_gh_token";

  let state = {
    activities: [],
    updatedAt: null,
    filter: "all",
    selectedIds: new Set(),
    tab: "progress"
  };

  const TAB_TITLES = {
    progress: "Progression",
    activities: "Activités",
    coach: "Coach IA",
    settings: "Réglages"
  };

  const SPORT_LABELS = {
    swim: { short: "NAGE", name: "Natation", color: "#0099FF" },
    bike: { short: "VÉLO", name: "Vélo", color: "#00C853" },
    run: { short: "RUN", name: "Course", color: "#FF5722" },
    multisport: { short: "MULTI", name: "Multisport", color: "#1A6DFF" },
    other: { short: "SPORT", name: "Autre", color: "#64748B" }
  };

  // Register offline Service Worker
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("./sw.js").catch(() => {});
  }

  function showToast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.classList.remove("hidden");
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.add("hidden"), 3400);
  }

  function fmtDur(sec) {
    const s = Math.max(0, Math.round(sec || 0));
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const r = s % 60;
    if (h > 0) return `${h}h${String(m).padStart(2, "0")}`;
    return `${m}:${String(r).padStart(2, "0")}`;
  }

  function fmtDist(meters, cat) {
    const m = meters || 0;
    if (cat === "swim" && m < 1000) return `${Math.round(m)} m`;
    return `${(m / 1000).toFixed(2)} km`;
  }

  function fmtDateShort(iso) {
    if (!iso) return "";
    const d = new Date(iso.replace(" ", "T"));
    if (isNaN(d.getTime())) return iso.slice(0, 10);
    return d.toLocaleDateString("fr-FR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
  }

  function updateNetStatus() {
    const badge = document.getElementById("netBadge");
    if (navigator.onLine) {
      badge.textContent = "En ligne";
      badge.className = "net-pill online";
    } else {
      badge.textContent = "Hors-ligne";
      badge.className = "net-pill offline";
    }
  }

  // Load cached data immediately (instant offline startup!), then refresh from network
  async function loadData(forceNetwork = false) {
    const cached = localStorage.getItem(STORAGE_DATA);
    if (cached) {
      try {
        const parsed = JSON.parse(cached);
        state.activities = parsed.activities || [];
        state.updatedAt = parsed.updatedAt || null;
        renderAll();
      } catch (_) {}
    }

    if (!navigator.onLine && !forceNetwork) return;
    try {
      const res = await fetch(`./data/activities.json?t=${Date.now()}`, { cache: "no-store" });
      if (!res.ok) return;
      const data = await res.json();
      state.activities = data.activities || [];
      state.updatedAt = data.updatedAt || null;
      localStorage.setItem(STORAGE_DATA, JSON.stringify(data));
      renderAll();
    } catch (_) {
      // Offline fallback already rendered
    }
  }

  function computeStats() {
    const now = Date.now();
    const dayMs = 86400000;
    let load7 = 0, load28 = 0, dist7 = 0, dur7 = 0;
    const dailyLoads = [0, 0, 0, 0, 0, 0, 0];
    const sportDur30 = { swim: 0, bike: 0, run: 0, multisport: 0, other: 0 };
    let count30 = 0;

    for (const a of state.activities) {
      const t = new Date((a.startTimeGMT || a.startTimeLocal || "").replace(" ", "T")).getTime();
      if (isNaN(t)) continue;
      const ageDays = (now - t) / dayMs;
      const ld = a.load || 0;
      if (ageDays <= 7 && ageDays >= -1) {
        load7 += ld;
        dist7 += a.distanceMeters || 0;
        dur7 += a.durationSec || 0;
        const idx = Math.max(0, Math.min(6, 6 - Math.floor(Math.max(0, ageDays))));
        dailyLoads[idx] += ld;
      }
      if (ageDays <= 28 && ageDays >= -1) {
        load28 += ld;
      }
      if (ageDays <= 30 && ageDays >= -1) {
        count30++;
        const c = sportDur30[a.category] !== undefined ? a.category : "other";
        sportDur30[c] += a.durationSec || 0;
      }
    }

    const chronicWeekly = Math.max(60, load28 / 4);
    const acwr = load7 / chronicWeekly;
    const readiness = Math.max(45, Math.min(99, Math.round(92 - Math.max(0, (acwr - 1.1) * 35))));

    return { load7, load28, dist7, dur7, dailyLoads, sportDur30, count30, acwr, readiness };
  }

  function renderProgress() {
    const st = computeStats();
    document.getElementById("syncSubtitle").textContent = state.updatedAt
      ? `Synchro ${fmtDateShort(state.updatedAt)}`
      : "Prêt hors-ligne";

    document.getElementById("kpiLoad").textContent = st.load7;
    document.getElementById("kpiLoadStatus").textContent =
      st.acwr > 1.35 ? "Élevée" : st.acwr < 0.7 ? "Récup." : "Optimale";
    document.getElementById("kpiDist").textContent = `${(st.dist7 / 1000).toFixed(1)} km`;
    document.getElementById("kpiTime").textContent = fmtDur(st.dur7);
    document.getElementById("kpiReadiness").textContent = `${st.readiness}%`;
    document.getElementById("kpiReadinessSub").textContent =
      st.readiness >= 80 ? "Prêt" : st.readiness >= 65 ? "Modéré" : "Fatigue";
    document.getElementById("weekTotalLoad").textContent = `${st.load7} pts`;
    document.getElementById("monthCount").textContent = `${st.count30} séances`;

    // Crisp 7-day SVG Bar Chart
    const maxL = Math.max(40, ...st.dailyLoads);
    const dayLabels = [];
    const daysFr = ["D", "L", "M", "M", "J", "V", "S"];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(Date.now() - i * 86400000);
      dayLabels.push(daysFr[d.getDay()]);
    }
    const bars = st.dailyLoads.map((val, i) => {
      const h = Math.max(4, Math.round((val / maxL) * 86));
      const x = 14 + i * 44;
      const y = 104 - h;
      const fill = i === 6 ? "#1A6DFF" : "#BFD6FF";
      return `
        <rect x="${x}" y="${y}" width="24" height="${h}" rx="6" fill="${fill}"></rect>
        <text x="${x + 12}" y="124" text-anchor="middle" font-size="11" fill="#6B7280">${dayLabels[i]}</text>
      `;
    }).join("");
    document.getElementById("loadChart").innerHTML =
      `<svg viewBox="0 0 320 134" width="100%" height="134">${bars}</svg>`;

    // Sport Split Bar (30 days)
    const total30 = Object.values(st.sportDur30).reduce((a, b) => a + b, 0) || 1;
    const keys = ["swim", "bike", "run", "multisport", "other"].filter((k) => st.sportDur30[k] > 0);
    document.getElementById("sportSplitBar").innerHTML = keys
      .map((k) => `<div class="split-seg" style="width:${(st.sportDur30[k] / total30) * 100}%;background:${SPORT_LABELS[k].color}"></div>`)
      .join("");
    document.getElementById("sportSplitLegend").innerHTML = keys.length
      ? keys.map((k) => {
          const pct = Math.round((st.sportDur30[k] / total30) * 100);
          return `<span class="legend-item"><span class="dot" style="background:${SPORT_LABELS[k].color}"></span>${SPORT_LABELS[k].name} ${pct}%</span>`;
        }).join("")
      : `<span class="muted">Synchronise tes activités Garmin pour voir la répartition.</span>`;

    // Latest activity card
    const slot = document.getElementById("latestActivitySlot");
    if (state.activities.length > 0) {
      slot.innerHTML = renderActivityRowHtml(state.activities[0], false);
      slot.firstElementChild.addEventListener("click", () => {
        switchTab("activities");
        toggleSelect(state.activities[0].id);
      });
    } else {
      slot.innerHTML = `<p class="muted">Aucune activité synchronisée. Appuie sur l'icône Synchro en haut à droite.</p>`;
    }
  }

  function renderActivityRowHtml(a, selectable = true) {
    const meta = SPORT_LABELS[a.category] || SPORT_LABELS.other;
    const isSel = selectable && state.selectedIds.has(a.id);
    return `
      <div class="act-row ${isSel ? "selected" : ""}" data-id="${a.id}">
        <div class="act-badge ${a.category}">${meta.short}</div>
        <div class="act-main">
          <div class="act-title">${a.name}</div>
          <div class="act-meta">${fmtDateShort(a.startTimeLocal)}${a.avgHr ? ` • ${a.avgHr} bpm` : ""}</div>
        </div>
        <div class="act-stats">
          <div class="act-dist">${fmtDist(a.distanceMeters, a.category)}</div>
          <div class="act-dur">${fmtDur(a.durationSec)}</div>
        </div>
      </div>
    `;
  }

  function renderActivities() {
    const list = document.getElementById("activitiesList");
    const filtered = state.activities.filter((a) => state.filter === "all" || a.category === state.filter);
    if (!filtered.length) {
      list.innerHTML = `<p class="muted" style="padding:12px;">Aucune activité dans cette catégorie.</p>`;
    } else {
      list.innerHTML = filtered.map((a) => renderActivityRowHtml(a, true)).join("");
      list.querySelectorAll(".act-row").forEach((row) => {
        row.addEventListener("click", () => toggleSelect(row.dataset.id));
      });
    }
    renderConvertBar();
  }

  function toggleSelect(id) {
    if (state.selectedIds.has(id)) state.selectedIds.delete(id);
    else state.selectedIds.add(id);
    renderActivities();
  }

  function renderConvertBar() {
    const bar = document.getElementById("convertBar");
    const n = state.selectedIds.size;
    if (n === 0 || state.tab !== "activities") {
      bar.classList.add("hidden");
      return;
    }
    bar.classList.remove("hidden");
    document.getElementById("convertCount").textContent =
      n === 1 ? "1 activité sélectionnée" : `${n} activités à fusionner`;
  }

  // Local 100% Offline Sports-Science AI Coach
  function generateCoachReply(topic) {
    const st = computeStats();
    const q = (topic || "").toLowerCase();
    const swimMin = Math.round(st.sportDur30.swim / 60);
    const bikeMin = Math.round(st.sportDur30.bike / 60);
    const runMin = Math.round(st.sportDur30.run / 60);

    if (q.includes("semaine")) {
      return `Cette semaine : ${(st.dist7 / 1000).toFixed(1)} km en ${fmtDur(st.dur7)} (charge ${st.load7} pts, ratio charge aiguë/chronique ${st.acwr.toFixed(2)}). ${
        st.acwr > 1.3 ? "Tu pousses fort : prévois 24h plus légères pour assimiler." : "Ta progression est propre et bien équilibrée."
      }`;
    }
    if (q.includes("demain") || q.includes("séance") || q.includes("seance")) {
      if (st.readiness < 68) return "Séance recommandée : 35 min d'endurance fondamentale Z2 (vélo souple ou natation technique) pour faire remonter ta forme.";
      if (bikeMin < runMin) return "Séance recommandée : 50 min de vélo en Z2/Z3 suivies de 10 min de course enchaînée (brique T2) pour habituer tes jambes.";
      return "Séance recommandée : 45 min de course progressive (30 min Z2 + 10 min allure seuil Z4 + 5 min retour au calme).";
    }
    if (q.includes("triathlon") || q.includes("prêt") || q.includes("pret")) {
      return `Ton indice de forme est à ${st.readiness}%. Sur 30 jours : ${swimMin} min Natation, ${bikeMin} min Vélo, ${runMin} min Course. ${
        swimMin > 0 && bikeMin > 0 && runMin > 0
          ? "Les 3 disciplines sont actives : tu es prêt pour un enchaînement complet !"
          : "Pense à caler au moins une sortie dans la discipline la moins travaillée avant ta course."
      }`;
    }
    if (q.includes("equilibre") || q.includes("équilibre")) {
      return `Sur les 30 derniers jours : Natation ${swimMin} min • Vélo ${bikeMin} min • Course ${runMin} min. En triathlon équilibré, vise ~20% natation, 50% vélo, 30% course.`;
    }
    if (q.includes("recup") || q.includes("récup")) {
      return `Récupération estimée : ${st.readiness}% (charge 7j : ${st.load7} pts). ${
        st.readiness >= 80 ? "Feu vert pour une séance clé ou un enchaînement intensif." : "Privilégie le sommeil, l'hydratation et une sortie Z1-Z2."
      }`;
    }
    return `Forme actuelle : ${st.readiness}% • Charge 7j : ${st.load7} pts (${(st.dist7 / 1000).toFixed(1)} km). Demande-moi « Analyse ma semaine », « Quelle séance demain ? » ou « Équilibre Nage / Vélo / Run ».`;
  }

  function renderCoach() {
    const st = computeStats();
    document.getElementById("coachHeadline").textContent =
      st.readiness >= 80 ? "Forme optimale — prêt à performer"
      : st.readiness >= 65 ? "Charge maîtrisée — progression stable"
      : "Fatigue accumulée — priorité récupération";
    document.getElementById("coachSummary").textContent =
      `Charge 7j : ${st.load7} pts • Volume : ${(st.dist7 / 1000).toFixed(1)} km (${fmtDur(st.dur7)}) • Indice de forme : ${st.readiness}%.`;
    document.getElementById("coachNextWorkout").textContent = generateCoachReply("demain");
  }

  function appendChat(role, text) {
    const log = document.getElementById("coachChatLog");
    const div = document.createElement("div");
    div.className = `msg ${role}`;
    div.textContent = text;
    log.appendChild(div);
    log.scrollTop = log.scrollHeight;
  }

  // Trigger GitHub Actions workflow remotely from the PWA
  async function triggerGithubWorkflow(inputs) {
    if (!navigator.onLine) {
      showToast("Connexion internet requise pour synchroniser Garmin.");
      return false;
    }
    const repo = (localStorage.getItem(STORAGE_REPO) || "ninors/garmin-multisport").trim();
    const token = (localStorage.getItem(STORAGE_TOKEN) || "").trim();
    if (!token) {
      showToast("Ajoute ton jeton GitHub dans Réglages pour lancer à distance.");
      switchTab("settings");
      return false;
    }
    try {
      const res = await fetch(
        `https://api.github.com/repos/${repo}/actions/workflows/merge-multisport.yml/dispatches`,
        {
          method: "POST",
          headers: {
            Accept: "application/vnd.github+json",
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ ref: "master", inputs })
        }
      );
      if (res.status === 204) {
        showToast("Synchronisation Garmin lancée ! Mise à jour automatique en cours...");
        pollWorkflowUntilDone(repo, token);
        return true;
      }
      showToast(`Erreur GitHub (${res.status}) : coche bien repo + workflow sur le jeton.`);
      return false;
    } catch (_) {
      showToast("Impossible de joindre GitHub.");
      return false;
    }
  }

  async function pollWorkflowUntilDone(repo, token) {
    // Poll GitHub Actions every 6s (up to ~72s) and auto-refresh activities once finished
    for (let i = 0; i < 12; i++) {
      await new Promise((r) => setTimeout(r, 6000));
      try {
        const res = await fetch(
          `https://api.github.com/repos/${repo}/actions/workflows/merge-multisport.yml/runs?per_page=1`,
          { headers: { Accept: "application/vnd.github+json", Authorization: `Bearer ${token}` } }
        );
        if (!res.ok) continue;
        const json = await res.json();
        const run = (json.workflow_runs || [])[0];
        if (run && run.status === "completed") {
          await loadData(true);
          showToast(run.conclusion === "success" ? "Activités Garmin mises à jour !" : "Fin du workflow (vérifie GitHub Actions).");
          return;
        }
      } catch (_) {}
    }
    await loadData(true);
  }

  function switchTab(tab) {
    state.tab = tab;
    document.getElementById("pageTitle").textContent = TAB_TITLES[tab] || "Multisport";
    document.querySelectorAll(".tab-view").forEach((s) => s.classList.remove("active"));
    document.getElementById(`tab-${tab}`).classList.add("active");
    document.querySelectorAll(".nav-btn").forEach((b) => b.classList.toggle("active", b.dataset.tab === tab));
    renderConvertBar();
  }

  function renderAll() {
    renderProgress();
    renderActivities();
    renderCoach();
  }

  // Event listeners
  document.querySelectorAll(".nav-btn").forEach((btn) =>
    btn.addEventListener("click", () => switchTab(btn.dataset.tab))
  );
  document.getElementById("btnGoActivities").addEventListener("click", () => switchTab("activities"));

  document.getElementById("filterPills").addEventListener("click", (e) => {
    const btn = e.target.closest(".pill");
    if (!btn) return;
    state.filter = btn.dataset.filter;
    document.querySelectorAll(".pill").forEach((p) => p.classList.toggle("active", p === btn));
    renderActivities();
  });

  document.getElementById("btnClearSelection").addEventListener("click", () => {
    state.selectedIds.clear();
    renderActivities();
  });

  document.getElementById("btnSendMultisport").addEventListener("click", async () => {
    const ids = Array.from(state.selectedIds).join(",");
    const profile = document.getElementById("selectProfile").value;
    const ok = await triggerGithubWorkflow({ activity_ids: ids, profile, test_upload: "false" });
    if (ok) {
      state.selectedIds.clear();
      renderActivities();
    }
  });

  document.getElementById("btnQuickSync").addEventListener("click", () =>
    triggerGithubWorkflow({ activity_ids: "", profile: "Triathlon", test_upload: "false" })
  );
  document.getElementById("btnTriggerSync").addEventListener("click", () =>
    triggerGithubWorkflow({ activity_ids: "", profile: "Triathlon", test_upload: "false" })
  );

  document.getElementById("btnSaveSettings").addEventListener("click", () => {
    localStorage.setItem(STORAGE_REPO, document.getElementById("inputGhRepo").value.trim());
    localStorage.setItem(STORAGE_TOKEN, document.getElementById("inputGhToken").value.trim());
    showToast("Réglages enregistrés sur cet appareil.");
  });

  document.getElementById("coachChips").addEventListener("click", (e) => {
    const chip = e.target.closest(".chip");
    if (!chip) return;
    appendChat("user", chip.textContent);
    appendChat("ai", generateCoachReply(chip.dataset.q));
  });

  document.getElementById("coachForm").addEventListener("submit", (e) => {
    e.preventDefault();
    const inp = document.getElementById("coachInput");
    const val = inp.value.trim();
    if (!val) return;
    inp.value = "";
    appendChat("user", val);
    appendChat("ai", generateCoachReply(val));
  });

  // Init settings inputs & online/offline listeners
  document.getElementById("inputGhRepo").value = localStorage.getItem(STORAGE_REPO) || "ninors/garmin-multisport";
  document.getElementById("inputGhToken").value = localStorage.getItem(STORAGE_TOKEN) || "";
  window.addEventListener("online", updateNetStatus);
  window.addEventListener("offline", updateNetStatus);
  updateNetStatus();
  loadData();
})();

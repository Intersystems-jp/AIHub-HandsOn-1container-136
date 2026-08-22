const state = {
  selectedTaskId: null,
  selectedTask: null,
  autoRefreshTimer: null,
};

const els = {
  connectionStatus: document.getElementById("connectionStatus"),
  requestText: document.getElementById("requestText"),
  startButton: document.getElementById("startButton"),
  startResult: document.getElementById("startResult"),
  refreshButton: document.getElementById("refreshButton"),
  autoRefresh: document.getElementById("autoRefresh"),
  taskList: document.getElementById("taskList"),
  selectedTaskBadge: document.getElementById("selectedTaskBadge"),
  selectedTaskSummary: document.getElementById("selectedTaskSummary"),
  draftView: document.getElementById("draftView"),
  taskRaw: document.getElementById("taskRaw"),
  replyResult: document.getElementById("replyResult"),
  reviewComment: document.getElementById("reviewComment"),
  reviseButton: document.getElementById("reviseButton"),
  approveButton: document.getElementById("approveButton"),
  debugLog: document.getElementById("debugLog"),
};

function setStatus(text, kind = "ready") {
  els.connectionStatus.textContent = text;
  els.connectionStatus.className = `status-pill ${kind === "ready" ? "" : kind}`;
}

function log(message, data = null) {
  const now = new Date().toLocaleTimeString();
  const text = data ? `${message}\n${JSON.stringify(data, null, 2)}` : message;
  els.debugLog.textContent = `[${now}] ${text}\n\n${els.debugLog.textContent}`;
}

async function apiFetch(url, options = {}) {
  setStatus("Processing...", "busy");
  try {
    const response = await fetch(url, {
      headers: { "Content-Type": "application/json", ...(options.headers || {}) },
      ...options,
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(JSON.stringify(data, null, 2));
    }
    setStatus("Ready", "ready");
    return data;
  } catch (error) {
    setStatus("Error", "error");
    log("API error", String(error));
    throw error;
  }
}

function pretty(data) {
  return JSON.stringify(data, null, 2);
}

function unwrapBody(proxyResponse) {
  return proxyResponse && Object.prototype.hasOwnProperty.call(proxyResponse, "body")
    ? proxyResponse.body
    : proxyResponse;
}

function normalizeTasks(body) {
  if (Array.isArray(body)) return body;
  if (body?.tasks && Array.isArray(body.tasks)) return body.tasks;
  if (body?.items && Array.isArray(body.items)) return body.items;
  if (body?.workitems && Array.isArray(body.workitems)) return body.workitems;
  if (body?.data && Array.isArray(body.data)) return body.data;
  return [];
}

function getTaskId(task) {
  return String(
    task.tid ?? task.id ?? task.ID ?? task.taskId ?? task.TaskId ?? task.workflowId ?? task.WorkItemId ?? ""
  );
}

function getTaskTitle(task) {
  return task.title ?? task.subject ?? task.Subject ?? task.name ?? task.Name ?? task.description ?? "Review Task";
}

function getTaskStatus(task) {
  return task.status ?? task.Status ?? task.state ?? task.State ?? "Waiting";
}

function getTaskCreatedAt(task) {
  return task.createdAt ?? task.CreatedAt ?? task.created_at ?? task.timeCreated ?? task.TimeCreated ?? "";
}

function getDraftObject(taskBody) {
  const candidates = [
    taskBody?.draft,
    taskBody?.Draft,
    taskBody?.draftJson,
    taskBody?.DraftJson,
    taskBody?.briefing,
    taskBody?.Briefing,
    taskBody?.data?.draft,
    taskBody?.data?.DraftJson,
    taskBody?.formFields?.DraftJson,
    taskBody?.formFields?.draftJson,
    taskBody?.FormFields?.DraftJson,
    taskBody?.request?.DraftJson,
  ];

  for (const candidate of candidates) {
    if (!candidate) continue;
    if (typeof candidate === "object") return candidate;
    if (typeof candidate === "string") {
      try { return JSON.parse(candidate); } catch { return { text: candidate }; }
    }
  }

  return taskBody;
}

function renderTasks(tasks) {
  console.log("renderTasks called", tasks);

  if (!tasks.length) {
    els.taskList.innerHTML = `<div class="empty-state">Workflowタスクはまだありません。自動更新で受信箱を確認中です。</div>`;
    return;
  }

  els.taskList.innerHTML = tasks.map((task) => {
    const tid = getTaskId(task);
    const title = escapeHtml(getTaskTitle(task));
    const status = escapeHtml(getTaskStatus(task));
    const createdAt = escapeHtml(getTaskCreatedAt(task));
    const selected = tid === state.selectedTaskId ? "selected" : "";
    return `
      <div class="task-card ${selected}" data-tid="${escapeHtml(tid)}">
        <div class="task-card-title">
          <span>${title}</span>
          <span class="badge">${status}</span>
        </div>
        <div class="task-meta">
          <div>Task ID: ${escapeHtml(tid || "不明")}</div>
          <div>${createdAt ? `Created: ${createdAt}` : "レビュー待ち"}</div>
        </div>
      </div>
    `;
  }).join("");

  document.querySelectorAll(".task-card").forEach((card) => {
    card.addEventListener("click", () => openTask(card.dataset.tid));
  });
 console.log("taskList html=", els.taskList.innerHTML);
}

function renderDraft(draft) {
  if (!draft || typeof draft !== "object") {
    els.draftView.innerHTML =
      `<div class="empty-state">草案を表示できませんでした。</div>`;
    return;
  }

  const sections = [];

  // 顧客情報
  if (
    draft.customerName ||
    draft.meetingPurpose ||
    draft.customerSummary
  ) {
    sections.push(`
      <div class="briefing-section">
        <h3>${escapeHtml(draft.customerName ?? "顧客情報")}</h3>
        <p>
          <strong>会議目的:</strong>
          ${escapeHtml(draft.meetingPurpose ?? "")}
        </p>
        <p>${escapeHtml(draft.customerSummary ?? "")}</p>
      </div>
    `);
  }

  // 取引先担当者情報
  if (Array.isArray(draft.keyPeople)) {
    sections.push(
      listSection(
        "取引先担当者情報",
        draft.keyPeople.map(p =>
          [
            `${p.name ?? ""} / ${p.role ?? ""} / ${p.interestArea ?? ""}`,
            p.notes ?? ""
          ]
            .filter(Boolean)
            .join("\n")
        )
      )
    );
  }

  // 過去打ち合わせ・最近の話題
  if (Array.isArray(draft.recentTopics)) {
    sections.push(
      listSection(
        "過去打ち合わせ・最近の話題",
        draft.recentTopics.map(x =>
          `[${x.source ?? ""}] ${x.summary ?? ""}`
        )
      )
    );
  }

  // Issue
  if (Array.isArray(draft.openIssues)) {
    sections.push(
      listSection(
        "現在上がっているIssue",
        draft.openIssues.map(x =>
          `[${x.priority ?? ""}] ${x.summary ?? ""} (${x.source ?? ""})`
        )
      )
    );
  }

  // Web検索結果
  if (
    Array.isArray(draft.additionalResearch) &&
    draft.additionalResearch.length
  ) {
    sections.push(
      listSection(
        "Web検索結果",
        draft.additionalResearch.map(x =>
          [
            `検索条件: ${x.query ?? ""}`,
            x.summary ?? "",
            `関連理由: ${x.whyRelevant ?? ""}`
          ]
            .filter(Boolean)
            .join("\n")
        )
      )
    );
  }

  // 会議準備リスト
  if (Array.isArray(draft.preparationItems)) {
    sections.push(
      listSection(
        "会議準備リスト",
        draft.preparationItems
      )
    );
  }

  // デモ計画
  if (
    Array.isArray(draft.demoPlan?.screenDemoItems) ||
    Array.isArray(draft.demoPlan?.expectedEffects)
  ) {
    sections.push(
      listSection(
        "デモ計画",
        [
          ...(draft.demoPlan?.screenDemoItems ?? [])
            .map(x => `画面デモ: ${x}`),

          ...(draft.demoPlan?.expectedEffects ?? [])
            .map(x => `期待効果: ${x}`)
        ]
      )
    );
  }

  els.draftView.innerHTML = sections.length
    ? sections.join("")
    : `<pre>${escapeHtml(pretty(draft))}</pre>`;
}

function listSection(title, items) {
  const lis = items.map(item => `<li>${escapeHtml(String(item)).replaceAll("\n", "<br>")}</li>`).join("");
  return `<div class="briefing-section"><h3>${escapeHtml(title)}</h3><ul>${lis}</ul></div>`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function startReview() {
  const request = els.requestText.value.trim();
  if (!request) {
    alert("依頼文を入力してください。");
    return;
  }

  const data = await apiFetch("/api/review/start", {
    method: "POST",
    body: JSON.stringify({ request }),
  });

  els.startResult.textContent = pretty(data);
  log("Started Human Review flow", data);
  await refreshTasks();
}

async function refreshTasks() {
  const data = await apiFetch("/api/review/tasks");

  const tasks = Array.isArray(data.body) ? data.body : [];

  console.log("tasks=", tasks);

  if (!tasks.length) {
    els.taskList.innerHTML = `<div class="empty-state">Workflowタスクはありません。</div>`;
    return;
  }

  renderTasks(tasks);
  log(`Workflow tasks refreshed: ${tasks.length}件`, tasks);
}

async function openTask(tid) {

  const data = await apiFetch(`/api/review/tasks/${encodeURIComponent(tid)}`);

  state.selectedTaskId = tid;
  state.selectedTask = data;

  els.selectedTaskBadge.textContent = `Task ${tid}`;

  els.selectedTaskSummary.innerHTML = `
    <strong>Task ID:</strong> ${escapeHtml(tid)}
  `;

  // ここ変更
  els.taskRaw.textContent = pretty(data);

  // ここ変更
  renderDraft(data.result);

  els.reviseButton.disabled = false;
  els.approveButton.disabled = false;

  log("Workflow task opened", data);
}

async function reply(action) {
  if (!state.selectedTaskId) {
    alert("レビュー対象を選択してください。");
    return;
  }

  if (action === "revise" && !els.reviewComment.value.trim()) {
    alert("修正依頼の場合はレビューコメントを入力してください。");
    return;
  }

  const payload = {
    action,
    review_comment: els.reviewComment.value.trim(),
  };

  const data = await apiFetch(`/api/review/tasks/${encodeURIComponent(state.selectedTaskId)}/reply`, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  els.replyResult.textContent = pretty(data);
  log(`Workflow task replied: ${action}`, data);
  await refreshTasks();
}

function setupTabs() {
  document.querySelectorAll(".tab-button").forEach(button => {
    button.addEventListener("click", () => {
      document.querySelectorAll(".tab-button").forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".tab-content").forEach(c => c.classList.remove("active"));
      button.classList.add("active");
      document.getElementById(`tab-${button.dataset.tab}`).classList.add("active");
    });
  });
}

function setupAutoRefresh() {
  if (state.autoRefreshTimer) clearInterval(state.autoRefreshTimer);
  if (els.autoRefresh.checked) {
    state.autoRefreshTimer = setInterval(() => {
      refreshTasks().catch(() => {});
    }, 5000);
  }
}

els.startButton.addEventListener("click", () => startReview().catch(err => alert(err.message)));
els.refreshButton.addEventListener("click", () => refreshTasks().catch(err => alert(err.message)));
els.reviseButton.addEventListener("click", () => reply("revise").catch(err => alert(err.message)));
els.approveButton.addEventListener("click", () => reply("approve").catch(err => alert(err.message)));
els.autoRefresh.addEventListener("change", setupAutoRefresh);

setupTabs();
setupAutoRefresh();
refreshTasks().catch(() => {});

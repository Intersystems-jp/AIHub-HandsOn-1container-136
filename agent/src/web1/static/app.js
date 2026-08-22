const MODE_TO_CLASS = {
  basic: 'Demo.Agent.PreparingMeeting',
  advanced: 'Demo.Agent.PreparingMeetingAdvanced',
  review: 'Demo.Agent.PreparingMeetingReview'
};

const sampleResponse = {
  customerName: '北星リテール',
  meetingPurpose: '店舗運営向けAI支援の初回提案',
  customerSummary: '北海道を拠点とする小売業。POS、EC、会員管理を利用しており、店舗・EC・コールセンター間の情報連携遅延が課題。需要予測、キャンペーン自動化、問い合わせ要約に関心がある。',
  keyPeople: [
    { name: '小林 真奈', role: '営業企画部 マネージャー', interestArea: 'キャンペーン分析, 店舗支援', notes: '画面イメージや効果例を好む。' }
  ],
  recentTopics: [
    { source: 'MeetingMinutes', summary: '店舗から本部への問い合わせが多く、回答作成に時間がかかっている。まずは小さな業務からAI支援を試したい。' },
    { source: 'CustomerNews', summary: '店舗スタッフの問い合わせ対応とキャンペーン情報共有を効率化する取り組みを開始。' }
  ],
  openIssues: [
    { source: 'SupportTicket', summary: '問い合わせ内容をFAQ、在庫、キャンペーン、障害に分類して担当部署へ回したい。', priority: 'Medium' }
  ],
  additionalResearch: [
    { query: '店舗支援 AI エージェント 問い合わせ要約', summary: 'AIエージェントにより問い合わせ分類、要約、回答案作成を効率化できる。', whyRelevant: '北星リテールの店舗問い合わせ対応時間短縮に直結する。' }
  ],
  preparationItems: [
    '店舗スタッフ向けAI支援の簡単なデモデータを用意する',
    '店舗問い合わせの分類・対応フロー案を整理する',
    'キャンペーン自動化と問い合わせ要約の効果例資料を準備する'
  ],
  demoPlan: {
    screenDemoItems: ['依頼文入力', '顧客情報の自動取得', 'Issueと議事録の要約', 'Web検索結果の補足表示'],
    expectedEffects: ['会議準備時間の短縮', '確認漏れの削減', '提案切り口の明確化']
  },
  toolUseSummary: [
    { toolName: 'mcp_meetingservice_GetCustomerID', result: '顧客ID C003 を特定。' },
    { toolName: 'mcp_meetingservice_GetCustomerInfo', result: '顧客概要、課題、関心領域を取得。' },
    { toolName: 'mcp_meetingservice_GetCustomerContacts', result: '主要担当者情報を取得。' },
    { toolName: 'mcp_meetingservice_GetMeetingMinutes', result: '前回会議の論点を取得。' },
    { toolName: 'mcp_meetingservice_GetSupportTicket', result: '未解決チケットを取得。' },
    { toolName: 'web_search', result: '店舗支援AIエージェント関連情報を取得。' }
  ]
};

const sampleTools = [
  'mcp_meetingservice_GetCustomerID',
  'mcp_meetingservice_GetCustomerInfo',
  'mcp_meetingservice_GetCustomerContacts',
  'mcp_meetingservice_GetMeetingMinutes',
  'mcp_meetingservice_GetSupportTicket',
  'mcp_meetingservice_GetCustomerNews',
  'web_search',
  'ListTables',
  'RunQuery'
];

function $(id) { return document.getElementById(id); }
function setStatus(text, cls) {
  const badge = $('statusBadge');
  badge.textContent = text;
  badge.className = `status ${cls}`;
}
function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
}
function renderList(containerId, items, renderer) {
  const el = $(containerId);
  if (!items || items.length === 0) {
    el.classList.add('empty');
    el.innerHTML = '未取得';
    return;
  }
  el.classList.remove('empty');
  el.innerHTML = items.map(renderer).join('');
}
function renderCheckList(containerId, items) {
  const el = $(containerId);
  if (!items || items.length === 0) {
    el.classList.add('empty');
    el.innerHTML = '<li>未取得</li>';
    return;
  }
  el.classList.remove('empty');
  el.innerHTML = items.map(item => `<li>${escapeHtml(item)}</li>`).join('');
}
function renderTools(containerId, tools) {
  const el = $(containerId);

  if (!tools || tools.length === 0) {
    el.classList.add('empty');
    el.innerHTML = '未取得';
    return;
  }

  el.classList.remove('empty');

  el.innerHTML = tools.map(t => {

    // 文字列だけ来た場合（後方互換）
    if (typeof t === 'string') {
      return `<span class="tool-pill">${escapeHtml(t)}</span>`;
    }

    // 結果表示
    const result = (() => {
      if (t.toolName !== "multi_tool_use.parallel") {
        return escapeHtml(t.result || "");
      }

      // 「を取得。」を除去
      const text = (t.result || "").replace(/を取得。?$/, "");

      return text
        .split("、")
        .map(x => `• ${escapeHtml(x)}を取得`)
        .join("<br>");
    })();
    
    return `
      <div class="tool-item">
        <span class="tool-pill">${escapeHtml(t.toolName)}</span>
        <div class="tool-result">${result}</div>
      </div>
    `;
  }).join('');
}

function renderResponse(data, debug = {}) {
  $('customerName').textContent = data.customerName || '顧客名なし';
  $('meetingPurpose').textContent = data.meetingPurpose || '会議目的なし';
  $('customerSummary').textContent = data.customerSummary || '';

  renderList('keyPeople', data.keyPeople, p => `
    <div class="item">
      <div class="meta">${escapeHtml(p.role)} / ${escapeHtml(p.interestArea)}</div>
      <strong>${escapeHtml(p.name)}</strong><br>${escapeHtml(p.notes)}
    </div>`);

  renderList('openIssues', data.openIssues, i => `
    <div class="item">
      <div class="meta">${escapeHtml(i.source)} <span class="priority">${escapeHtml(i.priority)}</span></div>
      ${escapeHtml(i.summary)}
    </div>`);

  renderList('recentTopics', data.recentTopics, t => `
    <div class="item">
      <div class="meta">${escapeHtml(t.source)}</div>
      ${escapeHtml(t.summary)}
    </div>`);

  renderCheckList('preparationItems', data.preparationItems);

  renderList('additionalResearch', data.additionalResearch, r => `
    <div class="item">
      <div class="meta">検索条件: ${escapeHtml(r.query)}</div>
      ${escapeHtml(r.summary)}<br><span class="meta">理由: ${escapeHtml(r.whyRelevant)}</span>
    </div>`);

  if (data.demoPlan) {
    $('demoPlanCard').classList.remove('hidden');
    renderCheckList('screenDemoItems', data.demoPlan.screenDemoItems);
    renderCheckList('expectedEffects', data.demoPlan.expectedEffects);
  } else {
    $('demoPlanCard').classList.add('hidden');
  }

  renderTools('availableTools', debug.availableTools || sampleTools);
  renderTools('calledTools',data.toolUseSummary || []);
  $('rawJson').textContent = JSON.stringify(data, null, 2);
}
function updateMode() {
  const mode = $('demoMode').value;
  const cls = MODE_TO_CLASS[mode];
  $('className').textContent = cls;
  $('agentClassBox').textContent = cls;
  $('reviewBox').classList.toggle('hidden', mode !== 'review');
}

async function runAgent(reviewAction = null) {
  setStatus('実行中', 'running');
  const payload = {
    mode: $('demoMode').value,
    agent_class: MODE_TO_CLASS[$('demoMode').value],
    request_text: $('requestText').value,
    review_action: reviewAction,
    review_comment: $('reviewComment').value
  };
  try {
    const res = await fetch('/api/meeting-prep', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error(await res.text());
    const body = await res.json();
    renderResponse(body.result, body.debug);
    setStatus('生成完了', 'done');
  } catch (err) {
    console.error(err);
    setStatus('エラー', 'error');
    $('rawJson').textContent = String(err);
  }
}

$('demoMode').addEventListener('change', updateMode);
$('runButton').addEventListener('click', () => runAgent());
$('loadSampleButton').addEventListener('click', () => { renderResponse(sampleResponse, { availableTools: sampleTools }); setStatus('サンプル表示中', 'done'); });
$('approveButton').addEventListener('click', () => runAgent('approve'));
$('reviseButton').addEventListener('click', () => runAgent('revise'));
$('debugToggle').addEventListener('change', e => $('debugContent').classList.toggle('hidden', !e.target.checked));

updateMode();
renderTools('availableTools', sampleTools);
$('agentClassBox').textContent = MODE_TO_CLASS[$('demoMode').value];

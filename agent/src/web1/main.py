# IRISNAMESPACE=T1
# export IRISNAMESPACE
# /usr/irissys/bin/irispython -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

from __future__ import annotations

from pathlib import Path
from typing import Any, Literal

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
import iris
import json

BASE_DIR = Path(__file__).resolve().parent

app = FastAPI(title="Meeting Preparation Agent Demo")
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")


@app.get("/", response_class=HTMLResponse)
def index() -> HTMLResponse:
    html = Path(BASE_DIR / "templates" / "index.html").read_text(encoding="utf-8")
    return HTMLResponse(content=html)

class MeetingPrepRequest(BaseModel):
    mode: Literal["basic", "advanced", "review"] = "advanced"
    agent_class: str = Field(default="Demo.Agent.PreparingMeetingAdvanced")
    request_text: str
    review_action: str | None = None
    review_comment: str | None = None

@app.post("/api/meeting-prep")
def meeting_prep(req: MeetingPrepRequest) -> dict[str, Any]:
    # 戻りはどちらもJSON文字
    result,available_tools = agent_start(req)

    result_dict=json.loads(result)
    available_tools_dict=json.loads(available_tools)
    return {
        "result": result_dict,
        "debug": {
            "agentClass": req.agent_class,

            # 呼び出し可能なツール一覧
            "availableTools": [x["name"] for x in available_tools_dict],

            # 実際に呼び出したツール一覧
            "calledTools": [
                {
                    "toolName": x.get("toolName", ""),
                    "result": x.get("result", "")
                }
                for x in result_dict.get("toolUseSummary", [])
            ],

            # LLMから返送された情報全体
            "raw": result_dict,
        },
    }


#　IRIS内Agent利用
def agent_start(req: MeetingPrepRequest):
    provider=iris.Demo.Agent.PreparingMeetingAdvanced.GetProvider()
    if req.agent_class=="Demo.Agent.PreparingMeeting":
        agent=iris.Demo.Agent.PreparingMeeting._New(provider)
    elif req.agent_class=="Demo.Agent.PreparingMeetingAdvanced":
        agent=iris.Demo.Agent.PreparingMeetingAdvanced._New(provider)
    else:
        ##　Interop呼び出し
        agent=None

    try:
        print(req.agent_class)
        status=agent._Init()
        iris.check_status(status)
        policy=iris._AI.Policy.ConsoleAuth._New()
        policy.AlwaysAllow=1
        agent.ToolManager.SetAuthPolicy(policy)

        configjsonchar='{"max_iterations": 10, "temperature": 0.2, "max_tokens": 3000}'
        configobj=iris._Library.DynamicObject._FromJSON(configjsonchar)
        session = agent.CreateSession(configobj)

        available_tools=agent.ToolManager._Discover()._ToJSON()

        response=agent.Chat(session,req.request_text)
        print(response.Content)

    except RuntimeError as ex:
        raise

    return response.Content,available_tools

def mock_agent_response(req: MeetingPrepRequest) -> dict[str, Any]:
    base: dict[str, Any] = {
        "customerName": "北星リテール",
        "meetingPurpose": "店舗運営向けAI支援の初回提案",
        "customerSummary": "北星リテールは北海道を拠点とする小売業で、従業員数は約1800名。POS、EC、会員管理を利用しており、店舗・EC・コールセンター間の情報連携遅延が課題。需要予測、キャンペーン自動化、問い合わせ要約に関心がある。",
        "keyPeople": [
            {
                "name": "小林 真奈",
                "role": "営業企画部 マネージャー",
                "interestArea": "キャンペーン分析, 店舗支援",
                "notes": "画面イメージや効果例を好む。店舗スタッフ向けの簡単なAI支援に関心が高い。",
            }
        ],
        "recentTopics": [
            {
                "source": "MeetingMinutes",
                "summary": "店舗から本部への問い合わせが多く、キャンペーンや在庫確認の回答作成に時間がかかっている。まずは小さな業務からAI支援を試したい。",
            },
            {
                "source": "CustomerNews",
                "summary": "店舗スタッフの問い合わせ対応とキャンペーン情報共有を効率化する取り組みを開始。店舗支援AIエージェントの提案材料になる。",
            },
        ],
        "openIssues": [
            {
                "source": "SupportTicket",
                "summary": "店舗問い合わせ内容をFAQ、在庫、キャンペーン、障害に分類し担当部署へ回す方法の相談が未解決。",
                "priority": "Medium",
            }
        ],
        "additionalResearch": [],
        "preparationItems": [
            "店舗スタッフ向けAI支援の簡単なデモデータを用意する",
            "店舗問い合わせの分類・対応フロー案を整理する",
            "キャンペーン自動化と問い合わせ要約の効果例資料を準備する",
        ],
        "toolUseSummary": [
            {"toolName": "mcp_meetingservice_GetCustomerID", "result": "北星リテールの顧客IDをC003として特定。"},
            {"toolName": "mcp_meetingservice_GetCustomerInfo", "result": "顧客概要、課題、関心領域、次回会議目的を取得。"},
            {"toolName": "mcp_meetingservice_GetCustomerContacts", "result": "主要担当者小林真奈の情報を取得。"},
            {"toolName": "mcp_meetingservice_GetMeetingMinutes", "result": "前回会議での論点、決定事項、アクションアイテムを取得。"},
            {"toolName": "mcp_meetingservice_GetSupportTicket", "result": "未解決の問い合わせ分類に関するサポートチケットを確認。"},
            {"toolName": "mcp_meetingservice_GetCustomerNews", "result": "店舗運営のデジタル化推進に関する最新ニュースを取得。"},
        ],
    }

    if req.mode in {"advanced", "review"}:
        base["additionalResearch"] = [
            {
                "query": "店舗支援 AI エージェント 問い合わせ要約",
                "summary": "AIエージェントにより問い合わせ分類、要約、回答案作成を効率化できる。単なるQ&Aだけでなく、担当部署への振り分けや次アクション提示にもつなげられる。",
                "whyRelevant": "北星リテールの店舗問い合わせ対応時間短縮と、短期間で効果が見えるテーマ作りに直結する。",
            }
        ]
        base["toolUseSummary"].append({"toolName": "web_search", "result": "店舗支援AIエージェントの問い合わせ要約に関する補足情報を取得。"})

    if req.mode == "review":
        base["reviewStatus"] = "WAITING_HUMAN_REVIEW" if not req.review_action else req.review_action
        base["reviewComment"] = req.review_comment or ""
        base["demoPlan"] = {
            "screenDemoItems": [
                "会議準備依頼を入力すると顧客IDを特定する流れ",
                "CRM・担当者・議事録・サポート履歴・ニュースを順に取得する流れ",
                "IssueとWeb検索結果を組み合わせて提案切り口を作る流れ",
            ],
            "expectedEffects": [
                "会議前の情報収集時間を短縮できる",
                "未解決Issueを見落とさず会議アジェンダに反映できる",
                "レビューコメントを反映して、営業担当者向けに表現を調整できる",
            ],
        }
        if req.review_action == "revise" and req.review_comment:
            base["preparationItems"].insert(0, f"レビュー反映: {req.review_comment}")

    return base


def mock_available_tools() -> list[str]:
    return [
        "mcp_meetingservice_GetCustomerID",
        "mcp_meetingservice_GetCustomerInfo",
        "mcp_meetingservice_GetCustomerContacts",
        "mcp_meetingservice_GetMeetingMinutes",
        "mcp_meetingservice_GetSupportTicket",
        "mcp_meetingservice_GetCustomerNews",
        "web_search",
        "ListTables",
        "RunQuery",
    ]

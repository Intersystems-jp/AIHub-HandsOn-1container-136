from __future__ import annotations

from pathlib import Path
from typing import Any, Literal

import requests
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from requests.auth import HTTPBasicAuth
from pydantic import BaseModel, Field
import json

BASE_DIR = Path(__file__).resolve().parent

app = FastAPI(title="Human Review Meeting Preparation Demo")
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")

# IRIS REST endpoints
IRIS_BASE_URL = "http://wgagent"
START_ENDPOINT = f"{IRIS_BASE_URL}/meeting/prep"
TASKS_ENDPOINT = f"{IRIS_BASE_URL}/wf/tasks"
TASK_ENDPOINT = f"{IRIS_BASE_URL}/wf/task"

REQUEST_TIMEOUT_SECONDS = 60

WF_USER = "ManagerA"
WF_PASSWORD = "SYS"

class StartReviewRequest(BaseModel):
    request: str = Field(..., description="会議準備依頼文")


class ReviewActionRequest(BaseModel):
    action: Literal["approve", "revise"]
    review_comment: str | None = None
    rejected_reason: str | None = "testtest"


@app.get("/", response_class=HTMLResponse)
def root() -> HTMLResponse:
    return review_page()


@app.get("/review", response_class=HTMLResponse)
def review_page() -> HTMLResponse:
    html = (BASE_DIR / "templates" / "review.html").read_text(encoding="utf-8")
    return HTMLResponse(content=html)


@app.post("/api/review/start")
def start_review(req: StartReviewRequest) -> dict[str, Any]:
    """会議準備依頼をBSへPOSTして、BPL/Workflowを開始する。"""
    try:
        response = requests.post(
            START_ENDPOINT,
            json={"request": req.request},
            headers={
                "Content-Type": "application/json; charset=utf-8"
            },
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        print("REQ=", req.request)
        print("POST TO=", START_ENDPOINT)
        print("STATUS=", response.status_code)
        print("TEXT=", response.text)
        return make_proxy_response(response)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"IRIS start request failed: {exc}") from exc


@app.get("/api/review/tasks")
def get_tasks() -> dict[str, Any]:
    """Workflow受信箱の一覧を取得する。"""
    try:
        response = requests.get(
            TASKS_ENDPOINT,
            auth=HTTPBasicAuth(WF_USER, WF_PASSWORD),
            timeout=REQUEST_TIMEOUT_SECONDS
        )
        return make_proxy_response(response)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"IRIS workflow list request failed: {exc}") from exc



@app.get("/api/review/tasks/{tid:path}")
def get_review_task(tid: str) -> dict[str, Any]:

    try:
        response = requests.get(
            f"{TASK_ENDPOINT}/{tid}",
            auth=HTTPBasicAuth(WF_USER, WF_PASSWORD),
            timeout=REQUEST_TIMEOUT_SECONDS,
        )

        task = response.json()

        if response.status_code >= 400:
            raise HTTPException(
                status_code=response.status_code,
                detail=task,
            )

        draft = {}

        if task.get("message"):
            try:
                draft = json.loads(task["message"])
            except json.JSONDecodeError:
                draft = {
                    "rawMessage": task["message"]
                }

        return {
            "ok": True,

            # review.html が参照するデータ
            "result": draft,

            # ワークフロー情報
            "task": {
                "id": task.get("id"),
                "subject": task.get("subject"),
                "role": task.get("role"),
                "actions": task.get("actions"),
                "timeCreated": task.get("timeCreated"),
                "isNew": task.get("isNew"),
                "priority": task.get("priority"),
                "formFields": task.get("formFields", {}),
            },

            # デバッグ用
            "debug": {
                "taskId": task.get("id"),
                "raw": task,
            },
        }

    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"IRIS workflow task request failed: {exc}"
        ) from exc
    

@app.post("/api/review/tasks/{tid:path}/reply")
def reply_task(tid: str, req: ReviewActionRequest) -> dict[str, Any]:
    """Workflowに approve / revise を返す。"""
    if req.action == "approve":
        payload = {
            "action": "approve",
            "formFields": {
                "RejectedReason": req.rejected_reason or "testtest",
            },
        }
    else:
        payload = {
            "action": "revise",
            "formFields": {
                "ReviewComment": req.review_comment or "",
            },
        }

    try:
        response = requests.post(
            f"{TASK_ENDPOINT}/{tid}",
            auth=HTTPBasicAuth(WF_USER, WF_PASSWORD),
            json=payload,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        return make_proxy_response(response)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"IRIS workflow reply request failed: {exc}") from exc


def make_proxy_response(response: requests.Response) -> dict[str, Any]:
    """IRIS側レスポンスを画面で扱いやすい形に包む。"""
    content_type = response.headers.get("content-type", "")

    try:
        body: Any = response.json() if "application/json" in content_type else response.text
    except ValueError:
        body = response.text

    if response.status_code >= 400:
        raise HTTPException(
            status_code=response.status_code,
            detail={
                "irisStatusCode": response.status_code,
                "body": body,
            },
        )

    return {
        "ok": True,
        "statusCode": response.status_code,
        "body": body,
    }

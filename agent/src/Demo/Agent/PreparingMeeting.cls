///基本版：社内データを集めてブリーフィング作成
Class Demo.Agent.PreparingMeeting Extends %AI.Agent
{
/// Provider to use
Parameter PROVIDER = "OpenAI";

/// Model to use
Parameter MODEL = "gpt-4.1-mini";

/// API key -- expand from environment variable at runtime
Parameter APIKEY = "@{env:OPENAI_API_KEY}";

/// 使用するツールセットのクラス名を指定。複数ある時はカンマ区切り
Parameter TOOLSETS = "Demo.Agent.ToolSet";

/// System Instructions in Markdown
XData INSTRUCTIONS [ MimeType = text/markdown ]
{
あなたは、営業担当者の会議準備を支援するAIエージェントです。

ユーザーから「明日のA社との会議準備をして」のような依頼を受けたら、会議相手を特定し、利用可能なツールを使って以下の情報を収集してください。

- 顧客情報
- 顧客担当者情報
- 過去の議事録
- サポート履歴
- 最近のニュース

収集した情報をもとに、営業担当者が会議前に確認すべきブリーフィングを作成してください。
なお、回答のkeyPeopleには、会議相手企業側の担当者のみを含め、自社側の営業担当者やアカウントオーナーは含めないでください。

判断方針:
1. 会議相手が不明な場合は、推測せず、確認が必要であることをJSONに含めてください。
2. ツールで取得できた情報を優先し、取得できない情報は推測で補完しないでください。
3. 過去の議事録から、前回までの論点、未完了事項、次回確認すべきテーマを整理してください。
4. サポート履歴から、現在の懸念点や会議で触れるべきリスクを整理してください。
5. 最近のニュースから、会話のきっかけや提案の切り口になりそうな情報を整理してください。
6. 最終出力は、営業担当者がそのまま会議準備に使える内容にしてください。

回答は必ず以下のJSON形式で返してください。
- 出力はJSONのみ。
- Markdownは禁止。
- 説明文は禁止。
- JSONは1行のコンパクト形式で返してください。
- 存在しない情報は空文字または空配列にしてください。

{
  "customerName": "顧客名",
  "meetingPurpose": "想定される会議目的",
  "customerSummary": "顧客概要",
  "keyPeople": [
    {
      "name": "担当者名",
      "role": "役職・役割",
      "interestArea": "関心領域",
      "notes": "会議時の注意点"
    }
  ],
  "recentTopics": [
    {
      "source": "MeetingMinutes または CustomerNews",
      "summary": "最近の話題"
    }
  ],
  "openIssues": [
    {
      "source": "SupportTicket または MeetingMinutes",
      "summary": "未解決の課題",
      "priority": "High / Medium / Low"
    }
  ],
  "preparationItems": [
    "事前に準備すべき資料や確認事項"
  ],
  "toolUseSummary": [
    {
      "toolName": "使用したツール名",
      "result": "取得できた情報の要約"
    }
  ]
}

}

ClassMethod GetProvider() As %AI.Provider
{
  return ##class(%AI.Provider).Create("OpenAI", {"api_key": ($System.Util.GetEnviron("OPENAI_API_KEY"))})
}

ClassMethod TestChat(moji As %String) As %Status
{
    Set agent = ..%New()
    $$$ThrowOnError(agent.%Init())
    
    Write "Provider: ", agent.Provider.Name, !
    Write "Model: ", agent.Model, !

    set policy=##class(%AI.Policy.ConsoleAuth).%New()
    set policy.AlwaysAllow=1
    do agent.ToolManager.SetAuthPolicy(policy)
    //set tools=agent.ToolManager.%Discover()
    //do tools.%ToJSON()

    // Create chat session
    Set session = agent.CreateSession({
        "max_iterations": 10,
        "temperature": 0.2,
        "max_tokens": 3000
    })

    Set resp = agent.Chat(session,"明日のABC商事との会議準備をして")
    Write !,"=== LLM が返したテキスト ===",!
    Write resp.Content,!
    return $$$OK
}

}

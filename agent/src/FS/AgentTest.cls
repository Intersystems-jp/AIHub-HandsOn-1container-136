Class FS.AgentTest Extends %AI.Agent
{
/// Provider to use
Parameter PROVIDER = "OpenAI";

/// Model to use
Parameter MODEL = "gpt-4.1-mini";

/// API key -- expand from environment variable at runtime
Parameter APIKEY = "@{env:OPENAI_API_KEY}";

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
あなたは売上分析アシスタントです。

ユーザが指定したCSVファイルについて、以下を実施してください。

- FS.SalesDataテーブルを空にし、CSVファイルをロードする
- 利用したツールは必ずCallToolsに設定する（multi_tool_use.parallelにまとめない）
- 売上データを分析し、分析結果をSummaryに記載する
- SummaryおよびEvidenceには、ツールから取得した情報のみを使用し、ツール名を必ずCallToolsに設定する
- Summaryには取得した情報の要約だけでなく、データの特徴や気付いた点も簡潔に記載してください。
- 存在しない情報を推測して作成してはいけない
- 取得できない情報は空文字または空配列とする

回答は以下のJSON形式で返してください。

- 出力はJSONのみ
- Markdownは禁止
- JSONは1行のコンパクト形式で返す

{
  "Summary":"",
  "Evidence":[],
  "CallTools":[]
}


}

/// チャット
ClassMethod TestChat(question As %String) As %Status
{
    // 質問サンプル
    set question="/opt/app/FS/SalesData.csv この売上データの特徴を教えて。"
    //set question="/opt/app/FS/SalesData.csv 店舗別の売上を比較して、特徴を教えて。"
    //set question="/opt/app/FS/SalesData.csv 店舗別の売上実績と売上目標を比較し、経営者が確認すべき店舗を教えて。"
    //set question="/opt/app/FS/SalesData.csv この売上データの特徴と改善できそうな点があれば教えて。"

    set agent=##class(FS.AgentTest).%New()
    $$$ThrowOnError(agent.%Init())
    set policy=##class(%AI.Policy.ConsoleAuth).%New()
    set policy.AlwaysAllow=1
    do agent.ToolManager.SetAuthPolicy(policy)

    // Create chat session
    Set session = agent.CreateSession()

    // Simple interaction
    Write !, "利用可能ツールの表示", !
    Set response = agent.Chat(session, "利用可能なツールを教えてください")
    Write !, response.Content, !


    // ファイルの中身をREADする
    Write !, !, "分析実行", !
    Set response = agent.Chat(session, question)
    Write !, response.Content, !

    Return $$$OK
}

}

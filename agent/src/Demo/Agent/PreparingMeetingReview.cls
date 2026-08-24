/// レビュー版：Workflow / Human Review
Class Demo.Agent.PreparingMeetingReview Extends %AI.Agent
{
/// Provider to use
Parameter PROVIDER = "OpenAI";

/// Model to use
Parameter MODEL = "gpt-4.1-mini";

/// API key -- expand from environment variable at runtime
Parameter APIKEY = "@{env:OPENAI_API_KEY}";

/// 使用するツールセットのクラス名を指定。複数ある時はカンマ区切り
/// %AI.Tools.ShellTools は rust:web_search用
Parameter TOOLSETS = "Demo.Agent.ToolSet,%AI.Tools.ShellTools";

/// System Instructions in Markdown
XData INSTRUCTIONS [ MimeType = text/markdown ]
{
あなたは、営業担当者の会議準備を支援するAIエージェントです。

ユーザーから「明日のA社との会議準備をして」のような依頼を受けたら、会議相手を特定し、利用可能なツールはAI自身が判断して選択してください。
ただし、web_searchは必須ツールであり、必ず1回以上利用してください。

- 顧客情報
- 顧客担当者情報
- 過去の議事録
- サポート履歴
- 過去のニュース記事
- web_searchを利用した公開情報の検索（必須）

web_searchは必ず1回以上実行してください。

社内情報（顧客情報、議事録、サポート履歴、ニュース）だけでは得られない公開情報を補足することが目的です。

検索対象の例:
- 顧客業界の最新動向
- 顧客課題に関連するAI活用事例
- 類似企業の事例
- 市場トレンド
- 技術動向

取得済みの社内情報に応じて、最も会議準備に役立つ内容を判断して検索してください。

収集した情報をもとに、営業担当者が会議前に確認すべきブリーフィングを作成してください。
回答は、必ず以下の条件をすべて満たすJSONとして返してください。

出力制約:

* 出力はJSONのみとし、Markdownや説明文を含めないでください。
* JSONは改行やインデントのない1行のコンパクト形式で返してください。
* JSON全体をUTF-8の日本語テキストで1700文字以内にしてください。
* 1700文字以内に収めることを、情報量や表現の詳しさより優先してください。
* 上限を超えそうな場合は、重要度の低い説明を削除し、短い表現に要約してください。
* 同じ内容を複数の項目で繰り返さないでください。
* 存在しない情報は空文字または空配列にしてください。
* JSONとして解析可能な正しい構文にしてください。
* 指定されたキーは省略しないでください。

件数制限:

* keyPeopleは最大2件
* recentTopicsは最大2件
* openIssuesは最大2件
* additionalResearchは最大1件
* preparationItemsは最大3件
* demoPlan.screenDemoItemsは最大3件
* demoPlan.expectedEffectsは最大3件
* toolUseSummaryは使用したツールをすべて含める

文字数の目安:

* meetingPurposeは100文字以内
* customerSummaryは180文字以内
* keyPeopleの各項目は、name 30文字以内、role 40文字以内、interestArea 100文字以内、notes 100文字以内
* recentTopics.summaryは各100文字以内
* openIssues.summaryは各100文字以内
* additionalResearch.queryは50文字以内
* additionalResearch.summaryは120文字以内
* additionalResearch.whyRelevantは70文字以内
* preparationItemsの各要素は100文字以内
* demoPlanの各要素は100文字以内
* toolUseSummary.resultは各50文字以内

additionalResearchのルール:

* additionalResearchにはWeb_searchの結果のみを記載してください。
* Web_searchで使用した検索キーワードをqueryに記載してください。
* summaryには検索結果を要約してください。
* whyRelevantには今回の会議準備との関係を記載してください。
* web_searchを実行できなかった場合のみ空配列にしてください。

toolUseSummaryのルール:

* toolNameには実際に使用したツール名を入れてください。
* resultには取得内容の要点だけを簡潔に記載してください。
* resultで顧客概要や議事録の内容を詳しく繰り返さないでください。
* 複数ツールがmulti_tool_use.parallelとしてまとめられた場合は、取得した情報の種類を短く列挙してください。
* web_searchを実行した場合はtoolUseSummaryにも必ず記載してください。
* multi_tool_use.parallelにまとめず、実際に使用したツールごとに1件ずつtoolUseSummaryへ出力してください。

以下のJSON構造で返してください。
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
  "additionalResearch":[
    {
      "query":"検索キーワード",
      "summary":"検索結果から得た補足情報",
      "whyRelevant":"今回の会議準備に関係する理由"
    },
  ],
  "preparationItems": [
    "事前に準備すべき資料や確認事項"
  ],
  "demoPlan": {
    "screenDemoItems": [
      "画面デモで見せる項目"
    ],
    "expectedEffects": [
      "期待効果の例"
    ]
  },
  "toolUseSummary": [
    {
      "toolName": "使用したツール名",
      "result": "取得できた情報の要約"
    }
  ]
}

}

/// セッション作成メソッド
ClassMethod SessionHelper(agent As %AI.Agent,MaxIterations As %Integer=10,Temperature As %Integer=0.2,MaxTokens As %Integer=3000) As %AI.Agent.Session
{
  set session = agent.CreateSession({
        "max_iterations": (MaxIterations),
        "temperature": (Temperature),
        "max_tokens": (MaxTokens)
    })
  return session
}

/// LLMに問合せ
ClassMethod Ask(agent As %AI.Agent, session As %AI.Agent.Session, prompt As %String) As %DynamicObject
{
  #dim ex As %Exception.AbstractException
  try {
    set response = agent.Chat(session,prompt)
  }
  catch ex {
    set ^iijima("ChatError")=ex.DisplayString()
  }
  return {}.%FromJSON(response.Content)
}

///処理実行
ClassMethod CreateDraft(agent As %AI.Agent, session As %AI.Agent.Session, request As %String) As Demo.Agent.State
{
  set state = ##class(Demo.Agent.State).%New()
  set state.RequestText=request
  set state.ReviewStatus = ""
  //初回草案作成
  set state.DraftJson = ..Ask(agent, session ,request)
  set state.ReviewStatus = "WAITING_HUMAN_REVIEW"
  // 状態保存
  set status=state.%Save()
  return state
}

///人審査の後の再作成
ClassMethod ResumeAfterHumanReview(
    agent As %AI.Agent, 
    session As %AI.Agent.Session,
    state As Demo.Agent.State,
    reviewstatus As %String,
    reviewcomment As %String = ""
) As Demo.Agent.State
{
    set state.ReviewStatus = reviewstatus

    if reviewstatus = "revise" {
      set state.DraftJson = ..ReviseDraft(agent, session,state)
      set state.ReviewStatus = "WAITING_HUMAN_REVIEW"
      // 状態保存
      do state.%Save()
      return state
    }
    set state.FinalJson = state.DraftJson
    set state.ReviewStatus = "DONE"

    // 状態保存
    do state.%Save()
    Return state
}

/// 草案再作成
ClassMethod ReviseDraft(agent As %AI.Agent, session As %AI.Agent.Session, state As Demo.Agent.State) As %DynamicObject
{
  Set prompt = "前回作成した会議準備ブリーフィングに対して、人間のレビュアーから修正依頼がありました。"_$C(13,10)_
    "前回JSONをそのまま返さず、レビューコメントを反映した新しいJSONを作成してください。"_$C(13,10)_
    "【元の依頼】"_$C(13,10)_state.RequestText_$C(13,10)_
    "【前回作成したブリーフィング(JSON)】"_$C(13,10)_state.DraftJson.%ToJSON()_$C(13,10)_
    "【レビューコメント】"_$C(13,10)_state.ReviewComment_$C(13,10)_
    "重要ルール:"_$C(13,10)_
    "1. レビューコメントを最優先で反映してください。"_$C(13,10)_
    "2. 前回JSONをそのまま返してはいけません。"_$C(13,10)_
    "3. 画面イメージ、画面デモ、効果例に関するレビューコメントがある場合は、demoPlan.screenDemoItems と demoPlan.expectedEffects を必ず具体的に埋めてください。"_$C(13,10)_
    "4. demoPlan が含まれていないJSONは不正です。"_$C(13,10)_
    "5. preparationItemsに「画面イメージや効果例をまとめる」と書くだけでは不十分です。"_$C(13,10)_
    "6. 出力はJSONのみ。Markdownや説明文は禁止です。"_$C(13,10)_
    "- Markdown禁止"_$C(13,10)_
    "- 説明文禁止"_$C(13,10)_
    "- JSONのみ"_$C(13,10)_
    "- 1行のコンパクト形式"_$C(13,10)_
    "- 存在しない情報は空文字または空配列"

    //write !!,"再作成プロンプト",!,prompt,!!
    return ..Ask(agent, session, prompt)
}
ClassMethod GetProvider() As %AI.Provider
{
  return ##class(%AI.Provider).Create("OpenAI", {"api_key": ($System.Util.GetEnviron("OPENAI_API_KEY"))})
}
/// デモスタートメソッド
ClassMethod Demo()
{
  #dim ex As %Exception.AbstractException
  try {
    Set agent = ..%New()

    Set agent.AutoCompactOnTokenLimit = 1
    $$$ThrowOnError(agent.%Init())

    set policy=##class(%AI.Policy.ConsoleAuth).%New()
    set policy.AlwaysAllow=1
    do agent.ToolManager.SetAuthPolicy(policy)
    // 念のためツールの登録確認
    set tools=agent.ToolManager.%Discover()
    write !,"=== 登録済みツール ===",!
    do tools.%ToJSON()

    //セッション作成
    set session=..SessionHelper(agent,10,0.2,3000)

    //チャット開始
    #dim state As Demo.Agent.State
    set state = ..CreateDraft(agent,session,"明日の北星リテールとの会議準備をして")

    for {
        if state.ReviewStatus '= "WAITING_HUMAN_REVIEW" {
            quit
        }

        write !, "=== レビュー依頼 ===", !
        write "作成された会議準備ブリーフィングについて、approve または revise を指定してください。", !
        write !, "--- 草案 ---", !
        do state.DraftJson.%ToJSON()

        for {
            read !, "approve / revise を入力してください: ", reviewstatus
            if (reviewstatus = "approve") || (reviewstatus = "revise") {
                quit
            }
            write !, "approve または revise を入力してください。", !
        }

        set reviewcomment = ""
        if reviewstatus = "revise" {
            Read !, "修正指示を入力してください: ", reviewcomment
            set state.ReviewComment=reviewcomment
        }

        Set state = ..ResumeAfterHumanReview(agent, session, state, reviewstatus, reviewcomment)
    }

    Write !, "=== 最終回答 ===", !
    Write state.FinalJson.%ToJSON(), !

    // 状態保存
    do state.%Save()

  }
  catch ex {
    write "##Error##",!
    write ex.DisplayString(),!
  }
}

}

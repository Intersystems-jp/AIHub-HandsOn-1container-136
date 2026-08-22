///会議準備エージェントのMCPサーバーツール定義用クラス
Class Demo.Tool.Meeting Extends %AI.Tool
{
Property Name As %String [ InitialExpression = "Meeting" ];

Property Description As %String(MAXLEN = "") [ InitialExpression = "会議準備エージェントMCPサーバーツール" ];

/// 取引先社名からIDを取得します。
/// 引数：顧客名（例：ABC商事）
/// 戻り：JSON文字列
/// { "customer_id":"C001"}
ClassMethod GetCustomerID(name As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set sql="SELECT CustomerId FROM Demo.Customer WHERE CustomerName = ?"
    try {
        if $get(name)="" {
            set response.error="取引先名が指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1  //ODBCモード
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(name)
        #dim rset As %SQL.StatementResult
        do rset.%Next()
        set response."customer_id"=rset.CustomerId
    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response

}

/// 取引先会社の営業担当者を取得
/// 引数：取引先会社のID（例：C001）
/// 戻り：JSON文字列
/// {
///     "account_owner": "佐藤 美咲",
/// }
ClassMethod GetAccountOwner(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set sql="SELECT AccountOwner FROM Demo.Customer WHERE CustomerId = ?"
    try {
        if $get(custid)="" {
            set response.error="取引先名のIDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        do rset.%Next()
        set response."account_owner"=rset.AccountOwner
    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}


/// 取引先会社のID（customer_id）から取引先顧客会社情報を取得（CRMにある情報のイメージ）
/// 引数：取引先会社のID（例：C001）
/// 戻り：JSON文字列
/// EmployeeCount, MainSystem, CurrentInterests, CurrentChallenges, NextMeetingDate, NextMeetingPurpose, LastContactDate, Notes
/// {
///     "customer_id": "C001",
///     "customer_name" : "ABC商事",
///     "industry": "製造業",
///     "region":"関東"
///     "contract_plan":"Enterprise",
///     "annual_revenue_range":"1000億円以上",
///     "employee_count":5200,
///     "main_system":"ERP, 生産管理, データウェアハウス",
///     "current_interests":"生成AI活用, データ統合, 既存システム連携",
///     "current_challenges":"部門ごとに顧客・在庫・問い合わせ情報が分散し、会議前の情報収集に時間がかかる",
///     "next_meeging_date":"2026-06-05",
///     "next_meeting_purpose":"AIエージェントを使った営業・サポート部門の情報統合デモ相談",
///     "last_contact_date":"2026-05-22",
///     "notes":"DX推進室が主導。現場部門にも説明しやすい短いデモを希望。"
/// }
ClassMethod GetCustomerInfo(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set sql="SELECT CustomerId, CustomerName, Industry, Region,"_
        "ContractPlan, ContractStatus, AnnualRevenueRange, EmployeeCount, MainSystem, "_
        "CurrentInterests, CurrentChallenges, NextMeetingDate, NextMeetingPurpose, LastContactDate, Notes "_
        "FROM Demo.Customer WHERE CustomerId = ?"
    try {
        if $get(custid)="" {
            set response.error="取引先名のIDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1  //ODBCモード
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        do rset.%Next()
        set response."customer_id"=custid
        set response."customer_name"=rset.CustomerName
        set response.industry=rset.Industry
        set response.region=rset.Region
        set response."contact_plan"=rset.ContractPlan
        set response."contract_status"=rset.ContractStatus
        set response."annual_revenue_range"=rset.AnnualRevenueRange
        set response."employee_count"=rset.EmployeeCount
        set response."main_system"=rset.MainSystem
        set response."current_interests"=rset.CurrentInterests
        set response."current_challenges"=rset.CurrentChallenges
        set response."next_meeting_date"=rset.NextMeetingDate
        set response."next_meeting_purpose"=rset.NextMeetingPurpose
        set response."last_contact_date"=rset.LastContactDate
        set response.notes=rset.Notes
    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}

/// 取引先IDから取引先担当者情報を取得。
/// 引数：取引先ID（例：C001）
/// 戻り：JSON文字列
/// {
///  [
///     "contact_id": "P001",
///     "customer_id" : "C001",
///     "contact_name": "鈴木 一郎",
///     "role_title":"DX推進室 室長"
///     "department":"室長	DX推進室",
///     "email":"ichiro.suzuki@example.com",
///     "interest_area":"AIエージェント, 業務効率化",
///     "decision_influence":"High",
///     "communication_style":"要点を先に知りたい",
///     "last_interaction_summary":"会議準備や社内問い合わせ対応でAIエージェントを試したいと発言"
///  ]
///  ,[]
/// }
/// 
ClassMethod GetCustomerContacts(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set response.contacts=[]
    set sql="SELECT ContactId, CustomerId, ContactName, RoleTitle, Department, Email, InterestArea, "_
        "DecisionInfluence, CommunicationStyle, LastInteractionSummary "_
        "FROM Demo.CustomerContact WHERE CustomerId=?"
    try {
        if $get(custid)="" {
            set response.error="取引先IDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        while rset.%Next() {
            set reco={}
            set reco."contact_id"=rset.ContactId
            set reco."customer_id"=custid
            set reco."contact_name"=rset.ContactName
            set reco."role_title"=rset.RoleTitle
            set reco.department=rset.Department
            set reco.email=rset.Email
            set reco."interest_area"=rset.InterestArea
            set reco."decision_infuluence"=rset.DecisionInfluence
            set reco."communication_style"=rset.CommunicationStyle
            set reco."last_interaction_summary"=rset.LastInteractionSummary
            do response.contacts.%Push(reco)
        }
    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}

/// 取引先会社のIDから議事録取得
/// 引数：取引会社ID（例：C001）
/// 戻り：JSON文字列
/// {
///     "meeting_id": "M001",
///     "customer_id" : "C001",
///     "meeting_date": "2026-04-18",
///     "title":"AI活用アイデア初回相談",
///     "participants":"鈴木 一郎; 高橋 由美; 佐藤 美咲",
///     "summary":"ABC商事では営業担当者が会議前にCRM、サポート履歴、社内議事録を個別に確認しており、準備に30分以上かかっている。AIエージェントで必要情報をまとめたい。",
///     "key_topics":"会議準備自動化; MCP; 既存API連携",
///     "decisions":"次回、顧客情報とサポート履歴を使った簡易デモを確認する",
///     "action_items":"佐藤がデモシナリオ案を作成; 高橋が利用可能な社内APIを確認",
///     "sentiment":"Positive",
///     "risk_level":"Low"
/// }
ClassMethod GetMeetingMinutes(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set response."meeting_minutes"=[]
    set sql="SELECT MeetingId, CustomerId, MeetingDate, Title, Participants, "_
        "Summary, KeyTopics, Decisions, ActionItems, Sentiment, RiskLevel "_
        "FROM Demo.MeetingMinutes WHERE CustomerId=?"
    try {
        if $get(custid)="" {
            set response.error="取引先会社IDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        while rset.%Next() {
            set reco={}
            set reco."meeting_id"=rset.MeetingId
            set reco."customer_id"=custid
            set reco."meeting_date"=rset.MeetingDate
            set reco.title=rset.Title
            set reco.participants=rset.participants
            set reco.summary=rset.Summary
            set reco."key_topics"=rset.KeyTopics
            set reco.decisions=rset.Decisions
            set reco."action_items"=rset.ActionItems
            set reco.sentiment=rset.Sentiment
            set reco."risk_level"=rset.RiskLevel
            do response."meeting_minutes".%Push(reco)
        }

    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}

/// 取引先会社IDから過去の問い合わせチケット情報を取得
/// 引数：取引会社ID（例：C001）
/// 戻り：JSON文字列
/// {
///     "ticket_id": "T001",
///     "customer_id" : "C001",
///     "opened_at": "2026-05-10 09:20:00",
///     "closed_at":"2026-05-10 15:40:00",
///     "status":"Closed",
///     "priority":"High",
///     "category":"Integration",
///     "subject":"CRM連携バッチの遅延",
///     "description":"夜間バッチ後にCRM連携データの反映が遅れ、営業画面で一部情報が古い状態になった。",
///     "resolution_summary":"連携処理のリトライ設定を調整し、監視項目を追加した。",
///     "customer_inpact":"営業担当者の朝会準備に影響",
///     "related_product":"IRIS Interoperability",
///     "owner_name":"中村 拓也"
/// }
ClassMethod GetSupportTicket(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set response.tickets=[]
    set sql="SELECT TicketId, CustomerId, OpenedAt, ClosedAt, Status, "_
        "Priority, Category, Subject, Description, ResolutionSummary, "_
        "CustomerImpact, RelatedProduct, OwnerName "_
        "FROM Demo.SupportTicket WHERE CustomerId=?"
    try {
        if $get(custid)="" {
            set response.error="取引先会社IDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        while rset.%Next() {
            set reco={}
            set reco."ticket_id"=rset.TicketId
            set reco."customer_id"=custid
            set reco."opened_at"=rset.OpenedAt
            set reco."closed_at"=rset.ClosedAt
            set reco.status=rset.Status
            set reco.priority=rset.Priority
            set reco.category=rset.Category
            set reco.subject=rset.Subject
            set reco.description=rset.Description
            set reco."resolution_summary"=rset.ResolutionSummary
            set reco."customer_impact"=rset.CustomerImpact
            set reco."related_product"=rset.RelatedProduct
            set reco."owner_name"=rset.OwnerName
            do response.tickets.%Push(reco)
        }

    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}

/// 取引先会社IDから関係する過去のニュース記事を取得
/// 引数：取引会社ID（例：C001）
/// 戻り：JSON文字列
/// {
///     "news_id": "N001",
///     "customer_id" : "C001",
///     "news_at": "2026-05-20",
///     "source_name":"Demo News",
///     "haedline":"ABC商事、製造現場のDX投資を拡大",
///     "description":"ABC商事は製造現場と営業部門のデータ連携を強化する方針を発表。既存システムとAI活用を組み合わせ、業務効率化を進める。",
///     "relevance":"会議準備エージェントの提案と親和性が高い",
///     "url":"https://example.com/news/abc-dx"
/// }
ClassMethod GetCustomerNews(custid As %String) As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    set response={}
    set response.news=[]
    set sql="SELECT NewsId, CustomerId, NewsDate, SourceName, Headline, Description, Relevance, Url "_
        "FROM Demo.CustomerNews WHERE CustomerId=?"
    try {
        if $get(custid)="" {
            set response.error="取引先会社IDが指定されていません"
            return response
        }
        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute(custid)
        #dim rset As %SQL.StatementResult
        while rset.%Next() {
            set reco={}
            set reco."news_id"=rset.NewsId
            set reco."customer_id"=custid
            set reco."news_date"=rset.NewsDate
            set reco."source_name"=rset.SourceName
            set reco.headline=rset.Headline
            set reco.description=rset.Description
            set reco.relevance=rset.Relevance
            set reco.url=rset.Url
            do response.news.%Push(reco)
        }

    }
    catch ex {
        set response.error=ex.DisplayString()
    }
    return response
}


/// 挨拶を返します。引数はありません。テスト用途のツールです。
/// 応答は、以下の形式
/// { "Greeting": "こんにちは！"}
ClassMethod hello() As %DynamicObject
{
    set json={}
    set json.Greeeting="こんにちは！"
    return json
}
}

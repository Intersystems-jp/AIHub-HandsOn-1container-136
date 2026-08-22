/// 
Class Demo.Interop.PreparingMeeingReviewBPL Extends Ens.BusinessProcessBPL
{

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.StringRequest' response='Ens.StringResponse' height='2000' width='2000' >
<context>
<property name='state' type='Demo.Agent.State' instantiate='0' deletewithcontext='0' />
<property name='agent' type='%AI.Agent' instantiate='0' deletewithcontext='0' />
<property name='session' type='%AI.Agent.Session' instantiate='0' deletewithcontext='0' />
<property name='WorkFlowReply' type='%Library.String' instantiate='0' deletewithcontext='0' />
<property name='sessionid' type='%Library.Integer' instantiate='0' deletewithcontext='0' />
</context>
<sequence xend='200' yend='950' >
<assign name="会議準備依頼設定" property="context.state.RequestText" value="request.StringValue" action="set" xpos='200' ypos='250' />
<code name='agent作成' xpos='200' ypos='350' >
<![CDATA[ set provider = ##class(%AI.Provider).Create("OpenAI", {"api_key": ($System.Util.GetEnviron("OPENAI_API_KEY"))})
 set agent = ##class(Demo.Agent.PreparingMeetingReview).%New(provider)
 set status=agent.%Init()
 set policy=##class(%AI.Policy.ConsoleAuth).%New()
 set policy.AlwaysAllow=1
 do agent.ToolManager.SetAuthPolicy(policy)
 set agent.AutoCompactOnTokenLimit = 1
 set context.agent=agent]]>
</code>
<assign name="session作成" property="context.session" value="##class(Demo.Agent.PreparingMeetingReview).SessionHelper(context.agent,10,0.2,3000)" action="set" xpos='200' ypos='450' />
<assign name="初回草案作成" property="context.state" value="##class(Demo.Agent.PreparingMeetingReview).CreateDraft(context.agent,context.session,context.state.RequestText)" action="set" xpos='200' ypos='550' />
<while name='レビュー' condition='context.state.ReviewStatus="WAITING_HUMAN_REVIEW"' xpos='200' ypos='650' xend='200' yend='800' >
<annotation>人間によるレビュー</annotation>
<code name='セッション保存' xpos='200' ypos='250' >
<annotation><![CDATA[ワークフロー返送時にセッション再利用できるように一旦保存しIDを保持しておく]]></annotation>
<![CDATA[ set status=context.session.%Save()
 set context.sessionid=context.session.%Id()
 set ^iijima("id")=context.sessionid]]>
</code>
<call name='レビュー用ワークフロー呼び出し' target='レビュー' async='0' xpos='200' ypos='350' >
<request type='EnsLib.Workflow.TaskRequest' >
<assign property="callrequest.%Subject" value="&quot;会議準備内容の確認&quot;" action="set" />
<assign property="callrequest.%Actions" value="&quot;approve,revise&quot;" action="set" />
<assign property="callrequest.%UserName" value="&quot;ManagerA&quot;" action="set" />
<assign property="callrequest.%Message" value="context.state.DraftJson.%ToJSON()" action="set" />
<assign property="callrequest.%FormFields" value="&quot;ReviewComment&quot;" action="set" />
</request>
<response type='EnsLib.Workflow.TaskResponse' >
<assign property="context.WorkFlowReply" value="callresponse.%Action" action="set" />
<assign property="context.state.ReviewComment" value="callresponse.%FormValues.GetAt(&quot;ReviewComment&quot;)" action="set" />
</response>
</call>
<if name='回答' condition='context.WorkFlowReply="approve"' xpos='200' ypos='450' xend='200' yend='700' >
<annotation><![CDATA[レビューの回答チェック：approveは審査通過]]></annotation>
<true>
<code name='最終処理' xpos='470' ypos='600' >
<![CDATA[ set context.state.FinalJson = context.state.DraftJson
 set context.state.ReviewStatus = "DONE"
 set status=context.state.%Save()]]>
</code>
</true>
<false>
<code name='草案再作成' xpos='200' ypos='600' >
<annotation><![CDATA[草案再作成：ワークフローで一旦停止状態となるため、保存したセッションをロードする。
エージェントもここで再作成]]></annotation>
<![CDATA[ 
 set provider = ##class(%AI.Provider).Create("OpenAI", {"api_key": ($System.Util.GetEnviron("OPENAI_API_KEY"))})
 set agent = ##class(Demo.Agent.PreparingMeetingReview).%New(provider)
 set policy=##class(%AI.Policy.ConsoleAuth).%New()
 set policy.AlwaysAllow=1
 do agent.ToolManager.SetAuthPolicy(policy)
 set agent.AutoCompactOnTokenLimit = 1
 set status=agent.%Init()

 set context.session=##class(%AI.Agent.Session).%OpenId(context.sessionid)
 set status=agent.%InitWithSession(context.session)
 set context.agent=agent
 set context.state.ReviewStatus = context.WorkFlowReply
 set context.state=##class(Demo.Agent.PreparingMeetingReview).ResumeAfterHumanReview(context.agent,context.session,context.state,context.state.ReviewStatus,context.state.ReviewComment)]]>
</code>
</false>
</if>
</while>
<assign name=" 応答にセット" property="response.StringValue" value="context.state.FinalJson.%ToJSON()" action="set" xpos='200' ypos='750' />
<code name='最終結果のログ' xpos='200' ypos='850' >
<![CDATA[ $$$LOGINFO("=== 最終結果 ==="_$C(13,10)_context.state.FinalJson.%ToJSON())]]>
</code>
</sequence>
</process>
}

}

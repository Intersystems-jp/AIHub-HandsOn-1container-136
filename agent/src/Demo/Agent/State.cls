Class Demo.Agent.State Extends %Persistent
{

/// 会議準備依頼テキスト
Property RequestText As %String(MAXLEN=1000);

/// 草案（JSON）
Property DraftJson As %DynamicObject;

/// Pending/Approved/RevisionRequested
Property ReviewStatus As %String;

/// レビュー時のコメント
Property ReviewComment As %String(MAXLEN=10000);

/// 最終回答（JSON）
Property FinalJson As %DynamicObject;
//
Property SelfReviewCount As %Integer;

/// 作成時間
Property CreatedAt As %TimeStamp [ SqlComputeCode = { set {*}=$ZDATETIME($system.Util.UTCtoLocalWithZTIMEZONE($ZTIMESTAMP),3)}, SqlComputed, SqlComputeOnChange = %%INSERT ];
/// 更新時間
Property UpdatedAt As %TimeStamp [ SqlComputeCode = { set {*}=$ZDATETIME($system.Util.UTCtoLocalWithZTIMEZONE($ZTIMESTAMP),3)}, SqlComputed, SqlComputeOnChange = %%UPDATE ];


Storage Default
{
<Data name="DraftJson">
<Attribute>DraftJson</Attribute>
<Structure>node</Structure>
<Subscript>"DraftJson"</Subscript>
</Data>
<Data name="FinalJson">
<Attribute>FinalJson</Attribute>
<Structure>node</Structure>
<Subscript>"FinalJson"</Subscript>
</Data>
<Data name="StateDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RequestText</Value>
</Value>
<Value name="3">
<Value>ReviewStatus</Value>
</Value>
<Value name="4">
<Value>ReviewComment</Value>
</Value>
<Value name="5">
<Value>SelfReviewCount</Value>
</Value>
<Value name="6">
<Value>CreatedAt</Value>
</Value>
<Value name="7">
<Value>UpdatedAt</Value>
</Value>
</Data>
<DataLocation>^Demo.Agent.StateD</DataLocation>
<DefaultData>StateDefaultData</DefaultData>
<IdLocation>^Demo.Agent.StateD</IdLocation>
<IndexLocation>^Demo.Agent.StateI</IndexLocation>
<StreamLocation>^Demo.Agent.StateS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
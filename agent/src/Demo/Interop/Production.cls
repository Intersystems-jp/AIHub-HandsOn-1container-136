Class Demo.Interop.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Demo.Interop.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>InterSystems AI Hub - Human in the loop用プロダクション</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="レビュー" Category="" ClassName="EnsLib.Workflow.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessClass">EnsLib.Workflow.Operation</Setting>
  </Item>
  <Item Name="会議準備" Category="" ClassName="Demo.Interop.PreparingMeeingReviewBPL" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessClass">Demo.Interop.PreparingMeeingReviewBPL</Setting>
  </Item>
  <Item Name="準備受付" Category="" ClassName="Demo.Interop.NonAdapter" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">会議準備</Setting>
  </Item>
</Production>
}

}

Class Demo.Interop.NonAdapter Extends Ens.BusinessService
{

Property TargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "TargetConfigNames:HumanInTheLoop用:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pInput As Ens.StringRequest, Output pOutput As Ens.StringResponse, ByRef pHint As %String) As %Status
{
	set status=..SendRequestAsync(..TargetConfigNames,pInput)
    return status
}

}

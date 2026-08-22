Class Demo.Interop.REST Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF-8";

Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/prep" Method="POST" Call="startPreparing" Cors="true"/>
<Route Url="/prep" Method="GET" Call="test" Cors="true"/>

</Routes>
}

ClassMethod test() As %Status
{
    set ^iijima=1
    set m={}
    set m.Hello="aaa"
    do m.%ToJSON()
    return $$$OK
}

/// Body の入力内容：{"request":"依頼文"}
ClassMethod startPreparing() As %Status
{
    #dim ex As %Exception.General
    #dim %request As %CSP.Request
    set status=$$$OK
    try {
        set body={}.%FromJSON(%request.Content)
        $$$ThrowOnError(##class(Ens.Director).CreateBusinessService("準備受付",.bs))
        set request=##class(Ens.StringRequest).%New()
        set request.StringValue=body.request
        $$$ThrowOnError(bs.ProcessInput(request))
        set modori={}
        set modori.message="受付ました"
        do modori.%ToJSON()
    }
    catch ex {
        set status=ex.AsStatus()
    }
    return status
}

}

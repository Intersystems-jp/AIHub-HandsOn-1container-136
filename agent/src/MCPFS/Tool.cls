Class MCPFS.Tool Extends %AI.Tool
{
/// 店舗ごとの売上目標を返します。
/// 引数無し
ClassMethod GetStoreSalesTargets() As %DynamicObject
{
    #dim ex As %Exception.AbstractException
    try {
        set response={}
        set sql="SELECT Store,Target FROM MCPFS.SalesTarget"

        set stmt=##class(%SQL.Statement).%New()
        set stmt.%SelectMode=1  // ODBCモード
        $$$ThrowOnError(stmt.%Prepare(sql))
        set rset=stmt.%Execute()
        if rset.%SQLCODE<0 {
            throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
        }
        set response.records=[]
        while rset.%Next() {
            set reco={}
            set reco.Store=rset.Store
            set reco.Target=rset.Target

            do response.records.%Push(reco)
        }
    }
    catch ex {
        set response.Status="Error"
        set response.Message=ex.DisplayString()
    }
    return response

}

}

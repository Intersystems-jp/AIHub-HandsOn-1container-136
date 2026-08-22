Class Demo.Installer
{

XData setup
{
<Manifest>
  <!--インストーラーの中で使用する変数NamespaceにT1を設定 -->
  <Default Name="Namespace" Value="t1"/>
  
  <!--ネームスペース作成用の定義 -->
  <Namespace Name="${Namespace}" Code="${Namespace}" Data="${Namespace}" Create="yes">
    <!-- データベース作成用定義-->
    <Configuration>
      <!--データベースディレクトリをDockerfile内で予め作成した /opt/t1 以下に設定するように指定 -->
      <Database Name="${Namespace}" Dir="${MGRDIR}data" Create="yes" Resource="%DB_${Namespace}"/>
    </Configuration>
    <!--ウェブアプリケーションパス /csp/t1　の作成 -->
    <CSPApplication Url="/csp/${Namespace}" Directory="${cspdir}${Namespace}"  ServeFiles="1" Recurse="1" MatchRoles=":%DB_${Namespace}" AuthenticationMethods="32"
    />

  </Namespace>

</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  #; Let XGL document generate code for this method. 
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

/// ワークフローを利用するネームスペースで実行
ClassMethod CreateWFUserAndRole()
{
    #dim ex As %Exception.AbstractException
    try {
    // ワークフローユーザの設定（ManagerAとManagerBをワークフローユーザとする）
        $$$ThrowOnError(##class(EnsLib.Workflow.UserDefinition).CreateUser("ManagerA"))
        $$$ThrowOnError(##class(EnsLib.Workflow.RoleDefinition).CreateRole("レビュー"))
        $$$ThrowOnError(##class(EnsLib.Workflow.RoleDefinition).AddUserToRole("レビュー","ManagerA"))
    }
    catch ex {
        write ex.DisplayString(),!
    }
}

/// SQLのLOAD
/// コンテナ作成時に実行
/// LOAD SQL実行用メソッド（ストアド実行可）
ClassMethod loadsql(file As %String) As %Status [SqlProc]
{
    #dim %sqlcontext As %ProcedureContext
    #dim ex As %Exception.AbstractException
    set status=$$$OK
    try {
        //ログは入力ファイルと同じディレクトリに置く
        //set logfile=##class(%File).GetDirectory(file)_"sqlload-log.txt"
        set logfile="/opt/src/logs/sqlload-log.txt"
        set sql="LOAD SQL FROM FILE '"_file_"' DIALECT 'IRIS'"
        set sql=sql_" LOG TO FILE '"_logfile_"' IGNORE ERRORS"
        set stmt=##class(%SQL.Statement).%New()
        set tResult = ##class(%SQL.Statement).%ExecDirect(.tStatement,sql)
        if tResult.%SQLCODE<0 {
            //write "Error::",tResult.%Message,!
            throw ##class(%Exception.SQL).CreateFromSQLCODE(tResult.%SQLCODE,tResult.%Message)
        }
    }
    catch ex {
        set status=ex.AsStatus()
        set %sqlcontext.%SQLCODE=ex.AsSQLCODE()
        set %sqlcontext.%Message=ex.AsSQLMessage()
    }
    return status
}

}
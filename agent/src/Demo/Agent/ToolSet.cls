Class Demo.Agent.ToolSet Extends %AI.ToolSet
{
/// ツール群の指定
/// MCPのツールをデモでは指定。MCP以外のToolももちろん指定可能
/// 詳細は以下ページ参照：
/// https://github.com/intersystems-community/ai-hub-eap/blob/master/ObjectScript_SDK_Guide.md#building-toolsets
/// 
/// ☢注意☢：次回のアップデートでは、この機能はIRIS Config Storeを使用して保存されたMCP設定を利用するよう変更される予定です。
XData Definition [ MimeType = application/xml ]
{
    <ToolSet Name="PreparingMeetingDemo">
        <Description>
        会議準備エージェントで使用するツールの定義。デモではMCPのツールを利用
        </Description>

        <MCP Name="RemoteServer">
            <Remote URL="http://localhost:51403/mcp/"
                AuthType="basic"
                Username="SuperUser"
                Password="SYS"
            />
        </MCP>
    </ToolSet>
}
}

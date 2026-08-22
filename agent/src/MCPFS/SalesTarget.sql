CREATE TABLE MCPFS.SalesTarget (
    Store VARCHAR(255),
    Target INT
)
go

--- ◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
---【複数行を実行したい場合に便利なデータ登録方法（LOAD SQL）】
--- ファイルはフルパスで指定します。実行環境に合わせて変更してください。
--- ◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
LOAD DATA FROM FILE '/opt/src/MCPFS/SalesTarget.csv'
 INTO MCPFS.SalesTarget
 USING {"from":{"file":{"charset":"UTF8","header":true}}}
go
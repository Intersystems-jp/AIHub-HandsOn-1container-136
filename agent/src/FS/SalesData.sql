CREATE TABLE FS.SalesData (
    SaleDate DATE,
    Store VARCHAR(255),
    Product VARCHAR(255),
    Category VARCHAR(255),
    Quantity INT,
    Amount DECIMAL(10, 2)
)
go

--- ◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
---【複数行を実行したい場合に便利なデータ登録方法（LOAD SQL）】
--- ファイルはフルパスで指定します。実行環境に合わせて変更してください。
--- ◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
LOAD DATA FROM FILE '/opt/app/FS/SalesData.csv'
 INTO FS.SalesData
 USING {"from":{"file":{"charset":"UTF8","header":true}}}
go
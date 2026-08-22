-- 会議準備エージェント用デモデータ定義
-- CSV配置先の例: /opt/app/ata
-- スキーマ名: Meeting
-- 外部テーブルとしてCSVを参照する想定

CREATE FOREIGN SERVER Demo.CSVDir FOREIGN DATA WRAPPER CSV HOST '/opt/app/data'
go

--- 会社情報（CRMの取引先 / Account）テーブル
CREATE FOREIGN TABLE Demo.Customer (
    CustomerId VARCHAR(20),
    CustomerName VARCHAR(100),
    Industry VARCHAR(100),
    Region VARCHAR(100),
    AccountOwner VARCHAR(100),
    ContractPlan VARCHAR(50),
    ContractStatus VARCHAR(50),
    AnnualRevenueRange VARCHAR(100),
    EmployeeCount INTEGER,
    MainSystem VARCHAR(300),
    CurrentInterests VARCHAR(300),
    CurrentChallenges VARCHAR(500),
    NextMeetingDate DATE,
    NextMeetingPurpose VARCHAR(500),
    LastContactDate DATE,
    Notes VARCHAR(500)
) SERVER Demo.CSVDir FILE 'Customer.csv' USING { "from": { "file": { "header": true } } }
go

--- 顧客の取引先担当者情報（Contact）テーブル
CREATE FOREIGN TABLE Demo.CustomerContact (
    ContactId VARCHAR(20),
    CustomerId VARCHAR(20),
    ContactName VARCHAR(100),
    RoleTitle VARCHAR(100),
    Department VARCHAR(100),
    Email VARCHAR(200),
    InterestArea VARCHAR(300),
    DecisionInfluence VARCHAR(50),
    CommunicationStyle VARCHAR(300),
    LastInteractionSummary VARCHAR(500)
) SERVER Demo.CSVDir FILE 'CustomerContact.csv' USING { "from": { "file": { "header": true } } }
go

--- 会議議事録（Meeting Minutes）テーブル
CREATE FOREIGN TABLE Demo.MeetingMinutes (
    MeetingId VARCHAR(20),
    CustomerId VARCHAR(20),
    MeetingDate DATE,
    Title VARCHAR(200),
    Participants VARCHAR(500),
    Summary VARCHAR(2000),
    KeyTopics VARCHAR(500),
    Decisions VARCHAR(1000),
    ActionItems VARCHAR(1000),
    Sentiment VARCHAR(50),
    RiskLevel VARCHAR(50)
) SERVER Demo.CSVDir FILE 'MeetingMinutes.csv' USING { "from": { "file": { "header": true } } }
go

--- サポートチケット（Support Ticket）テーブル
CREATE FOREIGN TABLE Demo.SupportTicket (
    TicketId VARCHAR(20),
    CustomerId VARCHAR(20),
    OpenedAt TIMESTAMP,
    ClosedAt TIMESTAMP,
    Status VARCHAR(50),
    Priority VARCHAR(50),
    Category VARCHAR(100),
    Subject VARCHAR(300),
    Description VARCHAR(1000),
    ResolutionSummary VARCHAR(1000),
    CustomerImpact VARCHAR(500),
    RelatedProduct VARCHAR(100),
    OwnerName VARCHAR(100)
) SERVER Demo.CSVDir FILE 'SupportTicket.csv' USING { "from": { "file": { "header": true } } }
go

--- 会社名のインデックス
CREATE INDEX CustomerNameIdx ON Demo.Customer(CustomerName)
go

--- 顧客ニュース（Customer News）テーブル
CREATE FOREIGN TABLE Demo.CustomerNews (
    NewsId VARCHAR(20),
    CustomerId VARCHAR(20),
    NewsDate DATE,
    SourceName VARCHAR(100),
    Headline VARCHAR(300),
    Description VARCHAR(1000),
    Relevance VARCHAR(500),
    Url VARCHAR(500)
) SERVER Demo.CSVDir FILE 'CustomerNews.csv' USING { "from": { "file": { "header": true } } }
go

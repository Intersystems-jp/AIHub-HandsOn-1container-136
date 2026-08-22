
-- 動作確認例
SELECT * FROM Demo.Customer WHERE CustomerName = 'ABC商事';
go

SELECT CustomerName, NextMeetingDate, NextMeetingPurpose
FROM Demo.Customer
WHERE CustomerId = 'C001';
go

SELECT MeetingDate, Title, Summary, Decisions, ActionItems
FROM Demo.MeetingMinutes
WHERE CustomerId = 'C001'
ORDER BY MeetingDate DESC;
go

SELECT Status, Priority, Subject, Description
FROM Demo.SupportTicket
WHERE CustomerId = 'C001'
ORDER BY OpenedAt DESC;
go

SELECT NewsDate, Headline, Description, Relevance
FROM Demo.CustomerNews
WHERE CustomerId = 'C001'
ORDER BY NewsDate DESC;
go

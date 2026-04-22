-- Yetki sýnýrlarýný doðrulamak için kullanýlan test sorgusu
-- Acaba loglara düþüyor mu?
DELETE FROM dbo.SALEORDERS WHERE ORDERID = -1;
-- Yetkisi olan iþlem kontrolü
SELECT * FROM USERS
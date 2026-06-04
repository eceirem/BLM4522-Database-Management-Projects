-- 1. Veritabaný Ýzleme (Dynamic Management Views - DMV)
-- 1. ADIM: Sistemi kasten yoracak stres testleri (CPU yükü oluþturmak için)
-- Tüm veriyi rastgele sýralayarak belleði zorlayan sorgu
SELECT * FROM dbo.SALEORDERS ORDER BY NEWID();

-- Cross Join ile satýr sayýsýný katlayarak CPU'yu aþýrý zorlayan alternatif sorgu
SELECT TOP 100000 
    a.ITEMNAME, b.NAMESURNAME 
FROM dbo.SALEORDERS a
CROSS JOIN dbo.SALEORDERS b; 

-- 2. Ýndeks Yönetimi (Gereksiz Ýndekslerin Temizlenmesi)
-- 2. ADIM: Dynamic Management Views (DMV) ile anlýk izleme
-- En çok CPU tüketen ilk 10 sorgunun analizi
SELECT TOP 10 
    st.text AS SorguMetni, 
    qs.total_worker_time / 1000 AS ToplamCPU_ms, 
    qs.execution_count AS CalismaSayisi
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY qs.total_worker_time DESC;

-- 3. Sorgu Ýyileþtirme (Uzun Süren Sorgularýn Optimizasyonu)
-- 1. ADIM: Test amacýyla gereksiz bir indeks oluþturuyorum
CREATE NONCLUSTERED INDEX IX_Gereksiz_Indeks ON dbo.USERS (NAMESURNAME);

-- (Kontrol) Ýndeksin fiziksel olarak oluþtuðunu doðrulama
SELECT name FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.USERS');

-- 2. ADIM: Kullanýlmayan indeksleri bulan analiz sorgum
SELECT 
    OBJECT_NAME(s.object_id) AS TabloAdi,
    i.name AS IndeksAdi
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE database_id = DB_ID('ETRADE')
AND user_seeks = 0 AND user_scans = 0 AND user_lookups = 0;

-- 3. ADIM: Tespit ettiðim gereksiz indeksi veritabanýndan tamamen kaldýrýyorum
DROP INDEX IX_Gereksiz_Indeks ON dbo.USERS;
GO



-- SENARYO A: Þehir Bazlý Arama Optimizasyonu
-- Optimizasyon Öncesi: Sistemin indeks olmadan nasýl yorulduðunu (Table Scan) görüyorum
SELECT ORDERID, NAMESURNAME, CITY, ITEMNAME 
FROM dbo.SALEORDERS 
WHERE CITY = 'ANKARA';

-- Ýyileþtirme: Sorgu hýzýný artýrmak için CITY kolonunu hedefleyen kapsayýcý indeks
CREATE NONCLUSTERED INDEX IX_SALEORDERS_CITY 
ON dbo.SALEORDERS (CITY)
INCLUDE (ORDERID, NAMESURNAME, ITEMNAME);
GO


-- SENARYO B: Tarih Bazlý Arama ve Haftalýk Satýþ Optimizasyonu
-- Önce verideki gerçek tarih aralýklarýný tespit ediyorum
SELECT ORDERDATE FROM dbo.SALEORDERS ORDER BY ORDERDATE DESC;

-- Optimizasyon Öncesi: Ýndeks olmadan çalýþan 1 haftalýk satýþ sorgusu
SELECT ITEMNAME, CATEGORY1, ORDERDATE
FROM dbo.SALEORDERS
WHERE ORDERDATE >= '2020-03-18' AND ORDERDATE <= '2020-03-25'
ORDER BY ORDERDATE DESC;

-- Ýyileþtirme: Haftalýk satýþ sorgusu için optimize edilmiþ indeks
CREATE NONCLUSTERED INDEX IX_SALEORDERS_ORDERDATE_INCLUDE 
ON dbo.SALEORDERS (ORDERDATE DESC) 
INCLUDE (ITEMNAME, CATEGORY1);
GO

-- Optimizasyon Sonrasý (Index Seek ile çok daha hýzlý çalýþan hali)
SELECT ITEMNAME, CATEGORY1, ORDERDATE
FROM dbo.SALEORDERS
WHERE ORDERDATE >= '2020-03-18' AND ORDERDATE <= '2020-03-25'
ORDER BY ORDERDATE DESC;

-- Haftalýk performans analizi için veriyi kümeleyerek (aggregate) anlamlý hale getiriyorum
SELECT CATEGORY1, COUNT(*) AS ToplamSatis
FROM dbo.SALEORDERS
WHERE ORDERDATE >= '2020-03-18' AND ORDERDATE <= '2020-03-25'
GROUP BY CATEGORY1
ORDER BY ToplamSatis DESC;


-- 4. Veri Yöneticisi Rolleri (Eriþim Yönetimi ve RBAC)
-- 1. Rolü oluþturduk
CREATE ROLE VeriAnalistiRolü;

-- 2. Tablolar üzerinde sadece SELECT (okuma) yetkisi veriyorum
GRANT SELECT ON SCHEMA::dbo TO VeriAnalistiRolü;

-- 3. Kullanýcýyý role atýyorum (Önceden oluþturduðum SatisDanismani kullanýcýsýný dahil ettim)
ALTER ROLE VeriAnalistiRolü ADD MEMBER SatisDanismani;

-- 4. Test Aþamasý: Kimliðimizi geçici olarak SatisDanismani yapýyoruz
EXECUTE AS USER = 'SatisDanismani';

-- 5. Kýsýtlama Testi: Silme iþlemini deniyoruz (Expected: Permission Denied / Baþarýlý þekilde engellendi)
DELETE FROM dbo.SALEORDERS WHERE ORDERID = 1;

-- 6. Okuma Testi: Silme iþlemi dýþýnda yetkimiz olan bir iþlem (SELECT) deniyoruz (Baþarýlý)
SELECT NAMESURNAME, CITY, CATEGORY1 
FROM dbo.SALEORDERS 
WHERE CITY = 'ANKARA';

-- 7. Test bitti, tekrar kendi Admin (db_owner) kimliðimize dönüyoruz
REVERT;
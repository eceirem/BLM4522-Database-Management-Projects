-- ---------------------------------------------------------
-- ÖN HAZIRLIK: Test Senaryosu Ýçin Kasten Hatalý Veri Üretimi
-- ---------------------------------------------------------

-- 3 kaydýn þehrini NULL (eksik veri) yapýyorum
UPDATE TOP (3) dbo.SALEORDERS 
SET CITY = NULL 
WHERE CITY IS NOT NULL;

-- 3 kaydýn isminin baþýna ve sonuna gereksiz boþluklar ekliyorum
UPDATE TOP (3) dbo.SALEORDERS 
SET NAMESURNAME = '   ' + NAMESURNAME + '   ' 
WHERE NAMESURNAME NOT LIKE ' %';


-- ---------------------------------------------------------
-- ADIM 0: Veri Keþfi ve Tespiti (Extract Öncesi Profilleme)
-- ---------------------------------------------------------

-- 1. Ýsim kolonunda baþý veya sonu gereksiz boþluklu ("kirli") kayýtlarýn tespiti
SELECT TOP 20 NAMESURNAME, CITY 
FROM dbo.SALEORDERS 
WHERE NAMESURNAME LIKE ' %' OR NAMESURNAME LIKE '% ';

-- 2. Eksik (NULL) þehir verilerinin sayýsýný bulma
SELECT COUNT(*) AS EksikSehirSayisi 
FROM dbo.SALEORDERS 
WHERE CITY IS NULL;

-- 3. *X* deseninin tespiti 
-- (Büyük ihtimalle paket/Koli miktarýný belirtiyor)
SELECT TOP 20 ITEMNAME 
FROM dbo.SALEORDERS 
WHERE ITEMNAME LIKE '%*%*%';

-- ---------------------------------------------------------
-- ADIM 1 ve 2: Veri Temizleme ve Dönüþüm Kurallarýnýn Testi
-- ---------------------------------------------------------
SELECT TOP 100
    ORDERID,
    
    -- 1. TEMÝZLEME: Baþý/sonu boþluklu isimleri temizliyoruz
    LTRIM(RTRIM(NAMESURNAME)) AS TEMIZ_MUSTERI_ADI,
    
    -- 2. TEMÝZLEME: Eksik (NULL) þehirleri dolduruyoruz
    ISNULL(CITY, 'BÝLÝNMÝYOR') AS TEMIZ_SEHIR,
    
    -- 3. DÖNÜÞTÜRME: Ürün adýný yýldýzdan önceki kýsým olarak kýrpýyoruz
    CASE 
        WHEN ITEMNAME LIKE '%*%' THEN LTRIM(RTRIM(LEFT(ITEMNAME, CHARINDEX('*', ITEMNAME) - 1)))
        ELSE LTRIM(RTRIM(ITEMNAME))
    END AS TEMIZ_URUN_ADI,

    -- 4. DÖNÜÞTÜRME: Yýldýzlar arasýndaki rakamý çekip 'PAKET_ADEDI' yapýyoruz
    CASE 
        WHEN ITEMNAME LIKE '%*%' THEN REPLACE(SUBSTRING(ITEMNAME, CHARINDEX('*', ITEMNAME), LEN(ITEMNAME)), '*', '')
        ELSE '1' -- Eðer yýldýz yoksa varsayýlan olarak tekli pakettir
    END AS PAKET_ADEDI,
    
    ORDERDATE
FROM dbo.SALEORDERS
-- Kasten bozduðumuz verileri tablonun en üstünde görüp test etmek için:
ORDER BY 
    CASE WHEN CITY IS NULL THEN 0 ELSE 1 END, 
    CASE WHEN NAMESURNAME LIKE ' %' THEN 0 ELSE 1 END;


-- ---------------------------------------------------------
-- ADIM 3: Veri Yükleme (ETL - Load Aþamasý) REVÝZE EDÝLDÝ
-- Þehirleri ADDRESSTEXT'ten kurtarýyor ve Stok Adedini ayýrýyoruz
-- ---------------------------------------------------------

SELECT 
    ORDERID,
    
    -- 1. Ýsimlerdeki gereksiz boþluklarý temizliyoruz
    LTRIM(RTRIM(NAMESURNAME)) AS CUSTOMER_NAME,
    
    -- 2. AKILLI ÞEHÝR KURTARMA (Smart Extraction):
    -- Eðer CITY boþ/NULL ise ve ADDRESSTEXT içinde '/' varsa, son '/' sonrasýný alýyoruz.
    CASE 
        WHEN (CITY IS NULL OR LTRIM(RTRIM(CITY)) = '') AND ADDRESSTEXT LIKE '%/%' 
        THEN UPPER(LTRIM(RTRIM(RIGHT(ADDRESSTEXT, CHARINDEX('/', REVERSE(ADDRESSTEXT)) - 1))))
        ELSE UPPER(LTRIM(RTRIM(ISNULL(CITY, 'BÝLÝNMÝYOR'))))
    END AS CITY_NAME,
    
    -- 3. Ürün adýndaki yýldýzlý kýsmý atýp temiz metni alýyoruz
    CASE 
        WHEN ITEMNAME LIKE '%*%' THEN LTRIM(RTRIM(LEFT(ITEMNAME, CHARINDEX('*', ITEMNAME) - 1)))
        ELSE LTRIM(RTRIM(ITEMNAME))
    END AS PRODUCT_NAME,

    -- 4. Yýldýzlar arasýndaki deðeri "Depodaki Stok Adedi" olarak çýkarýyoruz
    CASE 
        WHEN ITEMNAME LIKE '%*%' THEN REPLACE(SUBSTRING(ITEMNAME, CHARINDEX('*', ITEMNAME), LEN(ITEMNAME)), '*', '')
        ELSE '1' -- Yýldýz yoksa varsayýlan stok/paket miktarý 1 kabul edilir
    END AS DEPO_STOK_ADEDI,
    
    ORDERDATE
    
INTO dbo.ETL_CLEAN_SALES -- Temiz veriyi bu yeni hedef tabloya basýyoruz
FROM dbo.SALEORDERS;
GO

-- Yüklemenin baþarýsýný ve þehirlerin/stoklarýn durumunu kontrol edelim:
SELECT TOP 20 * FROM dbo.ETL_CLEAN_SALES;

-- ---------------------------------------------------------
-- Adým 3.5 
-- *x* içerisinde int olmayan veri var mý? Sadece rakam içermeyen hatalý desenleri bulma (950 satýr geliyordu)
-- ---------------------------------------------------------
SELECT DISTINCT 
    PRODUCT_NAME AS [Temizlenen Ürün Adý],
    DEPO_STOK_ADEDI AS [Tuhaf Gelen Stok Deðeri]
FROM dbo.ETL_CLEAN_SALES
WHERE DEPO_STOK_ADEDI LIKE '%[^0-9]%'; -- Ýçinde 0'dan 9'a kadar RAKAM OLMAYAN bir karakter (-, ., harf, boþluk) varsa getir



-- 1. GÖRSELLERDEKÝ GÝZLÝ BOÞLUKLARI TEMÝZLEME 
-- Sadece rakamlardan oluþan ama boþluk içerdiði için hatalý görünen kayýtlarý kurtarýyoruz (sadece 185 satýr geliyor)
UPDATE dbo.ETL_CLEAN_SALES
SET DEPO_STOK_ADEDI = LTRIM(RTRIM(DEPO_STOK_ADEDI));


-- 2. ÝLERÝ SEVÝYE ANOMALÝ TEMÝZLÝÐÝ (Tuhaf Veriler)
-- "12-6774.00.0" veya "6 GR BEBEBIS" gibi kayýtlardaki ilk sayýyý (12 ve 6) izole ediyoruz
UPDATE dbo.ETL_CLEAN_SALES
SET DEPO_STOK_ADEDI = LEFT(DEPO_STOK_ADEDI, PATINDEX('%[^0-9]%', DEPO_STOK_ADEDI) - 1)
WHERE DEPO_STOK_ADEDI LIKE '%[^0-9]%'            -- Ýçinde rakam harici (harf, tire, nokta vb.) karakter olanlarý bul
  AND PATINDEX('%[^0-9]%', DEPO_STOK_ADEDI) > 1; -- Metnin en az bir rakamla baþladýðýndan emin ol

-- 3. Son Kalan Metinsel Anomalileri Temizleme
-- Tam sayýya çevrilemeyen tüm saçma deðerleri '0' yapýyoruz
-- ---------------------------------------------------------
UPDATE dbo.ETL_CLEAN_SALES
SET DEPO_STOK_ADEDI = '0'
WHERE TRY_CAST(DEPO_STOK_ADEDI AS INT) IS NULL;



-- ---------------------------------------------------------
-- ADIM 4: Veri Kalitesi Raporlarý
--  Veri temizleme ve dönüþtürme sürecine dair raporlarýn oluþturulmasý
-- ---------------------------------------------------------

-- 1. Veri Kalitesi Raporu: Adres metninden baþarýlý þekilde ayrýþtýrýlan ve temizlenen + temiz olan þehirlerin satýþ hacimleri
SELECT 
    CITY_NAME AS [Temizlenmiþ Þehir Adý], 
    COUNT(*) AS [Toplam Satýþ Adedi]
FROM dbo.ETL_CLEAN_SALES
GROUP BY CITY_NAME
ORDER BY [Toplam Satýþ Adedi] DESC;


-- 2. Veri Kalitesi Raporu: Kurtarýlan 3 kaydýn Öncesi (Kirli) ve Sonrasý (Temiz) Karþýlaþtýrmasý (sadece temizlenen)
-- sadce þehir deðil 24 satýr geliyor demek ki 1349 id'li kiþi 24 farklý þey satýn almýþ bizden.
SELECT 
    RAW_TBL.ORDERID AS [Sipariþ ID],
    RAW_TBL.CITY AS [ETL Öncesi (Kirli Þehir)],
    RAW_TBL.ADDRESSTEXT AS [Ham Adres Metni],
    CLEAN_TBL.CITY_NAME AS [ETL Sonrasý (Kurtarýlan Þehir)]
FROM dbo.SALEORDERS RAW_TBL
JOIN dbo.ETL_CLEAN_SALES CLEAN_TBL ON RAW_TBL.ORDERID = CLEAN_TBL.ORDERID
WHERE RAW_TBL.CITY IS NULL; -- Sadece orijinal tabloda þehri boþ olan o 3 kaydý getir



-- 2. Veri Kalitesi Raporu: Depo Stok Adedi olarak dönüþtürülen miktarlarýn analizi
SELECT 
    DEPO_STOK_ADEDI AS [Depodaki Stok Miktarý], 
    COUNT(ORDERID) AS [Bu Stok Miktarýna Sahip Ürün Sayýsý]
FROM dbo.ETL_CLEAN_SALES
GROUP BY DEPO_STOK_ADEDI
ORDER BY CAST(DEPO_STOK_ADEDI AS INT) DESC; -- Metinden sayýya çevirerek mantýklý bir sýralama yapýyoruz

-- 4. Revize Edilmiþ ETL Etki Raporu (DISTINCT + þehir filtresi eklendi)
SELECT DISTINCT 
    RAW_TBL.ORDERID AS [Sipariþ ID],
    RAW_TBL.NAMESURNAME AS [Müþteri Adý],
    RAW_TBL.CITY AS [ETL Öncesi (Kirli Þehir)],
    RAW_TBL.ADDRESSTEXT AS [Ham Adres Metni],
    CLEAN_TBL.CITY_NAME AS [ETL Sonrasý (Kurtarýlan Þehir)]
FROM dbo.SALEORDERS RAW_TBL
JOIN dbo.ETL_CLEAN_SALES CLEAN_TBL ON RAW_TBL.ORDERID = CLEAN_TBL.ORDERID
WHERE RAW_TBL.CITY IS NULL;
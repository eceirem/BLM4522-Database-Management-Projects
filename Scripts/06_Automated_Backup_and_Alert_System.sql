-- ---------------------------------------------------------
-- ADIM 1: Günlük Otomatik Yedekleme Scripti
-- ---------------------------------------------------------
DECLARE @Tarih VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmm');
DECLARE @DosyaYolu VARCHAR(500);

-- Vizede kullandýðýn orijinal klasör yolunu tanýmlýyoruz
SET @DosyaYolu = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\ETRADE_Auto_' + @Tarih + '.bak';

-- Yedekleme iþlemini baþlatýyoruz
BACKUP DATABASE [ETRADE] 
TO DISK = @DosyaYolu 
WITH NOFORMAT, NOINIT, 
NAME = 'ETRADE-Günlük Otomatik Yedek', 
STATS = 10;

-- ---------------------------------------------------------
-- ADIM 2: Baþarýlý Yedeklemelerin Raporlanmasý (MSDB)
-- ---------------------------------------------------------
SELECT TOP 10
    bs.database_name AS [Veritabaný],
    bs.backup_start_date AS [Baþlama Zamaný],
    bs.backup_finish_date AS [Bitiþ Zamaný],
    CAST(bs.backup_size / 1024 / 1024 AS DECIMAL(10, 2)) AS [Boyut (MB)],
    bmf.physical_device_name AS [Dosya Yolu]
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'ETRADE'
ORDER BY bs.backup_finish_date DESC;


-- ---------------------------------------------------------
-- ADIM 3: Mail Uyarý Mekanizmalý Tam Otomasyon Kodu
-- ---------------------------------------------------------
BEGIN TRY
    -- 1. Yedekleme Ýþlemini Dene (Adým 1'in Birebir Aynýsý)
    DECLARE @Tarih VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmm');
    DECLARE @DosyaYolu VARCHAR(500) = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\ETRADE_Auto_' + @Tarih + '.bak';

    BACKUP DATABASE [ETRADE] TO DISK = @DosyaYolu WITH NOFORMAT, NOINIT, NAME = 'ETRADE-Günlük Otomatik Yedek';
    PRINT 'Yedekleme Baþarýyla Tamamlandý.';
END TRY
BEGIN CATCH
    -- 2. Yedekleme Baþarýsýz Olursa Hatayý Yakala ve Mail At
    DECLARE @HataMesaji NVARCHAR(4000) = ERROR_MESSAGE();
    
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'DBA_Mail_Profili',
        @recipients = 'eceiremsiser@gmail.com',
        @subject = 'ACÝL: ETRADE Günlük Yedekleme BAÞARISIZ!',
        @body = @HataMesaji;
END CATCH;
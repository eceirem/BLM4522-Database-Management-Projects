-- Aktif baðlantýlarý kesip veritabanýný tek kullanýcý moduna alarak kurtarmayý saðlar
USE master;
GO
ALTER DATABASE ETRADE SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO
-- Ho va ten: Le Minh Tri
-- MSSV: 22521543

-- BAI THUC HANH: QLY_BANHANG


CREATE DATABASE QLY_BANHANG
GO

USE QLY_BANHANG

CREATE TABLE KHACHHANG
(
    MAKH CHAR(4) PRIMARY KEY NOT NULL,
    HOTEN VARCHAR(40) ,
    DCHI VARCHAR(50) ,
    SODT VARCHAR(20),
    NGSINH SMALLDATETIME,
    DOANHSO MONEY,
    NGDK SMALLDATETIME,
)

CREATE TABLE NHANVIEN
(
    MANV CHAR(4) PRIMARY KEY NOT NULL,
    HOTEN VARCHAR(40) ,
    SODT VARCHAR(20),
    NGVL SMALLDATETIME,
)

CREATE TABLE SANPHAM
(
    MASP CHAR(4) PRIMARY KEY NOT NULL,
    TENSP VARCHAR(40),
    DVT VARCHAR(20),
    NUOCSX VARCHAR(40),
    GIA MONEY,
)

CREATE TABLE HOADON
(
    SOHD INT PRIMARY KEY NOT NULL,
    NGHD SMALLDATETIME,
    MAKH CHAR(4) FOREIGN KEY REFERENCES KHACHHANG(MAKH),
    MANV CHAR(4) FOREIGN KEY REFERENCES NHANVIEN(MANV),
    TRIGIA MONEY,
)

CREATE TABLE CTHD
(
    SOHD INT FOREIGN KEY REFERENCES HOADON(SOHD),
    MASP CHAR(4) FOREIGN KEY REFERENCES SANPHAM(MASP),
    SL INT CONSTRAINT PK_CTHD PRIMARY KEY(SOHD,MASP)
)

ALTER TABLE SANPHAM ADD GHICHU VARCHAR(20)

ALTER TABLE KHACHHANG ADD LOAIKH VARCHAR(20)

ALTER TABLE SANPHAM ALTER COLUMN GHICHU VARCHAR(100)

ALTER TABLE SANPHAM DROP COLUMN GHICHU

ALTER TABLE SANPHAM ADD CONSTRAINT GIA_SP CHECK (GIA>=500)

ALTER TABLE KHACHHANG ADD CONSTRAINT GT_LOAIKH CHECK (LOAIKH='Vang lai' OR LOAIKH='Thuong xuyen' OR LOAIKH='Vip')

ALTER TABLE SANPHAM ADD CONSTRAINT GT_DVT CHECK (DVT='cay' OR DVT='hop' OR DVT='cai' OR DVT='quyen' OR DVT='chuc')

ALTER TABLE KHACHHANG ADD CONSTRAINT NGDK_NGSINH CHECK (NGDK>NGSINH)

-- NGDK <= NGHD

CREATE TRIGGER TRG_NGDK_NGHD ON HOADON
AFTER INSERT, UPDATE AS
BEGIN 
    IF EXISTS (
        SELECT * FROM INSERTED, KHACHHANG
        WHERE (INSERTED.MAKH = KHACHHANG.MAKH AND INSERTED.NGHD >= KHACHHANG.NGDK)
    )
    BEGIN
        ROLLBACK TRANSACTION
        PRINT('NGAY MUA HANG PHAI LON HON HON NGAY DANG KY')
    END
END
GO



CREATE TRIGGER TRG_NGHD_NGDK ON KHACHHANG
AFTER UPDATE AS
BEGIN
    IF EXISTS(
        SELECT * FROM INSERTED, HOADON
        WHERE (INSERTED.MAKH = HOADON.MAKH AND INSERTED.NGDK <= HOADON.NGHD)
    )
    BEGIN
        ROLLBACK TRANSACTION
        PRINT('NGAY DANG KY KHACH HANG THANH VIEN PHAI NHO HON NGAY SINH')
    END
END
GO

-- NGVL <= NGHD

CREATE TRIGGER TRG_NGVL_NGHD ON HOADON
AFTER INSERT, UPDATE AS
BEGIN
IF EXISTS(
    SELECT * FROM INSERTED, NHANVIEN
    WHERE (INSERTED.MANV = NHANVIEN.MANV AND INSERTED.NGHD >= NHANVIEN.NGVL)
)
BEGIN
    ROLLBACK TRANSACTION
    PRINT('NGAY MUA HANG PHAI LON HON NGAY VAO LAM')
END
END
GO

CREATE TRIGGER TRG_NGHD_NGVL ON NHANVIEN
AFTER UPDATE AS
BEGIN
IF EXISTS(
    SELECT * FROM INSERTED, HOADON
    WHERE (INSERTED.MANV = HOADON.MANV AND INSERTED.NGVL <= HOADON.NGHD)
)
BEGIN
    ROLLBACK TRANSACTION
    PRINT('NGAY VAO LAM PHAI NHO HON NGAY MUA HANG')
END
END
GO

-- MOI MOT HOA DON PHAI CO IT NHAT 1 CHI TIET HOA DON

CREATE TRIGGER TRG_CTHD ON HOADON
AFTER DELETE, UPDATE AS
BEGIN
DECLARE @SLHD INT
SELECT @SLHD=COUNT(*) FROM CTHD, DELETED WHERE CTHD.SOHD=DELETED.SOHD 
IF (@SLHD<1)
BEGIN
    ROLLBACK TRANSACTION
    PRINT('MOI MOT HOA DON PHAI CO IT NHAT 1 CHI TIET HOA DON')
END
END
GO

-- TRIGIA CUA MOT HOA DON LA SOLUONG*GIA CUA SAN PHAM TRONG CHI TIET HOA DON

CREATE TRIGGER TRG_TRIGIA ON HOADON
AFTER INSERT AS
BEGIN
DECLARE @SOHD INT
SELECT @SOHD=SOHD FROM INSERTED
UPDATE HOADON SET TRIGIA=0 WHERE HOADON.SOHD=@SOHD
END 
GO

CREATE TRIGGER UPDATE_HD ON HOADON
AFTER UPDATE AS
BEGIN
	UPDATE HOADON SET TRIGIA = (SELECT TRIGIA FROM deleted)
	WHERE SOHD = (SELECT SOHD FROM inserted)
END
GO

CREATE TRIGGER UPDATE_HD_CTHD ON CTHD 
AFTER INSERT AS
BEGIN
	DECLARE @SL INT
    DECLARE @GIA MONEY

	SELECT @GIA=GIA, @SL=SL FROM inserted, SANPHAM
	WHERE inserted.MASP = SANPHAM.MASP
	
    UPDATE HOADON
	SET TRIGIA = TRIGIA + @SL * @GIA
END
GO

-- DOANH SO CUA KHACH HANG LA TONG TRIGIA CUA CAC HOA DON CUA KHACH HANG DO DA MUA

CREATE TRIGGER TRG_DOANHSO ON KHACHHANG
AFTER INSERT, UPDATE AS
BEGIN
DECLARE @DS MONEY
DECLARE @TG MONEY

SELECT @TG=SUM(TRIGIA) FROM INSERTED,HOADON WHERE HOADON.MAKH=INSERTED.MAKH
SELECT @DS=DOANHSO FROM INSERTED

IF(@DS<>@TG)
BEGIN   
    ROLLBACK TRANSACTION
    PRINT('DOANH SO CUA KHACH HANG LA TONG TRIGIA CUA CAC HOA DON CUA KHACH HANG DO DA MUA')
END
END
GO



-- INSERT VALUE TO NHANVIEN

INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL)
VALUES 
    ('NV01', 'Nguyen Nhu Nhut', '0927345678', '2006-04-13'),
    ('NV02', 'Le Thi Phi Yen', '0987567390', '2006-04-21'),
    ('NV03', 'Nguyen Van B', '0997047382', '2006-04-27'),
    ('NV04', 'Ngo Thanh Tuan', '0913758498', '2006-06-24'),
    ('NV05', 'Nguyen Thi Truc Thanh', '0918590387', '2006-07-20');

-- INSERT VALUE TO KHACHHANG

INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK)
VALUES
    ('KH01', 'Nguyen Van A', '731 Tran Hung Dao, Q5, TpHCM', '8823451', '1960-10-22', '13060000', '2006-07-22'),
    ('KH02', 'Tran Ngoc Han', '23/5 Nguyen Trai, Q5, TpHCM', '908256478', '1974-04-03', '280000', '2006-07-30'),
    ('KH03', 'Tran Ngoc Linh', '45 Nguyen Canh Chan, Q1, TpHCM', '938776266', '1980-06-12', '3860000', '2006-08-05'),
    ('KH04', 'Tran Minh Long', '50/34 Le Dai Hanh, Q10, TpHCM', '917325476', '1965-03-09', '250000', '2006-10-02'),
    ('KH05', 'Le Nhat Minh', '34 Truong Dinh, Q3, TpHCM', '8246108', '1950-03-10', '21000', '2006-10-28'),
    ('KH06', 'Le Hoai Thuong', '227 Nguyen Van Cu, Q5, TpHCM', '8631738', '1981-12-31', '915000', '2006-11-24'),
    ('KH07', 'Nguyen Van Tam', '32/3 Tran Binh Trong, Q5, TpHCM', '916783565', '1971-04-06', '12500', '2006-12-01'),
    ('KH08', 'Phan Thi Thanh', '45/2 An Duong Vuong, Q5, TpHCM', '938435756', '1971-01-10', '365000', '2006-12-13'),
    ('KH09', 'Le Ha Vinh', '873 Le Hong Phong, Q5, TpHCM', '8654763', '1979-09-03', '70000', '2007-01-14'),
    ('KH10', 'Ha Duy Lap', '34/34B Nguyen Trai, Q1, TpHCM', '8768904', '1983-05-02', '67500', '2007-01-16');

-- INSERT VALUE TO SANPHAM

INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA)
VALUES
    ('BC01', 'But chi', 'cay', 'Singapore', 3000),
    ('BC02', 'But chi', 'cay', 'Singapore', 5000),
    ('BC03', 'But chi', 'cay', 'Viet Nam', 3500),
    ('BC04', 'But chi', 'hop', 'Viet Nam', 30000),
    ('BB01', 'But bi', 'cay', 'Viet Nam', 5000),
    ('BB02', 'But bi', 'cay', 'Trung Quoc', 7000),
    ('BB03', 'But bi', 'hop', 'Thai Lan', 100000),
    ('TV01', 'Tap 100 giay mong', 'quyen', 'Trung Quoc', 2500),
    ('TV02', 'Tap 200 giay mong', 'quyen', 'Trung Quoc', 4500),
    ('TV03', 'Tap 100 giay tot', 'quyen', 'Viet Nam', 3000),
    ('TV04', 'Tap 200 giay tot', 'quyen', 'Viet Nam', 5500),
    ('TV05', 'Tap 100 trang', 'chuc', 'Viet Nam', 23000),
    ('TV06', 'Tap 200 trang', 'chuc', 'Viet Nam', 53000),
    ('TV07', 'Tap 100 trang', 'chuc', 'Trung Quoc', 34000),
    ('ST01', 'So tay 500 trang', 'quyen', 'Trung Quoc', 40000),
    ('ST02', 'So tay loai 1', 'quyen', 'Viet Nam', 55000),
    ('ST03', 'So tay loai 2', 'quyen', 'Viet Nam', 51000),
    ('ST04', 'So tay', 'quyen', 'Thai Lan', 55000),
    ('ST05', 'So tay mong', 'quyen', 'Thai Lan', 20000),
    ('ST06', 'Phan viet bang', 'hop', 'Viet Nam', 5000),
    ('ST07', 'Phan khong bui', 'hop', 'Viet Nam', 7000),
    ('ST08', 'Bong bang', 'cai', 'Viet Nam', 1000),
    ('ST09', 'But long', 'cay', 'Viet Nam', 5000),
    ('ST10', 'But long', 'cay', 'Trung Quoc', 7000);

-- INSERT VALUE TO HOADON

INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA)
VALUES
    (1001, '2006-07-23', 'KH01', 'NV01', 320000),
    (1002, '2006-08-12', 'KH01', 'NV02', 840000),
    (1003, '2006-08-23', 'KH02', 'NV01', 100000),
    (1004, '2006-09-01', 'KH02', 'NV01', 180000),
    (1005, '2006-10-20', 'KH01', 'NV02', 3800000),
    (1006, '2006-10-16', 'KH01', 'NV03', 2430000),
    (1007, '2006-10-28', 'KH03', 'NV03', 510000),
    (1008, '2006-10-28', 'KH01', 'NV03', 440000),
    (1009, '2006-10-28', 'KH03', 'NV04', 200000),
    (1010, '2006-11-01', 'KH01', 'NV01', 5200000),
    (1011, '2006-11-04', 'KH04', 'NV03', 250000),
    (1012, '2006-11-30', 'KH05', 'NV03', 21000),
    (1013, '2006-12-12', 'KH06', 'NV01', 5000),
    (1014, '2006-12-31', 'KH03', 'NV02', 3150000),
    (1015, '2007-01-01', 'KH06', 'NV01', 910000),
    (1016, '2007-01-01', 'KH07', 'NV02', 12500),
    (1017, '2007-01-02', 'KH08', 'NV03', 35000),
    (1018, '2007-01-13', 'KH08', 'NV03', 330000),
    (1019, '2007-01-13', 'KH01', 'NV03', 30000),
    (1020, '2007-01-14', 'KH09', 'NV04', 70000),
    (1021, '2007-01-16', 'KH10', 'NV03', 67500),
    (1022, '2007-01-16', NULL, 'NV03', 7000),
    (1023, '2007-01-17', NULL, 'NV01', 330000);

-- INSERT VALUE TO CTHD

INSERT INTO CTHD (SOHD, MASP, SL)
VALUES
    (1001, 'TV02', 10),
    (1001, 'ST01', 5),
    (1001, 'BC01', 5),
    (1001, 'BC02', 10),
    (1001, 'ST08', 10),
    (1002, 'BC04', 20),
    (1002, 'BB01', 20),
    (1002, 'BB02', 20),
    (1003, 'BB03', 10),
    (1004, 'TV01', 20),
    (1004, 'TV02', 10),
    (1004, 'TV03', 10),
    (1004, 'TV04', 10),
    (1005, 'TV05', 50),
    (1005, 'TV06', 50),
    (1006, 'TV07', 20),
    (1006, 'ST01', 30),
    (1006, 'ST02', 10),
    (1007, 'ST03', 10),
    (1008, 'ST04', 8),
    (1009, 'ST05', 10),
    (1010, 'TV07', 50),
    (1010, 'ST07', 50),
    (1010, 'ST08', 100),
    (1010, 'ST04', 50),
    (1010, 'TV03', 100),
    (1011, 'ST06', 50),
    (1012, 'ST07', 3),
    (1013, 'ST08', 5),
    (1014, 'BC02', 80),
    (1014, 'BB02', 100),
    (1014, 'BC04', 60),
    (1014, 'BB01', 50),
    (1015, 'BB02', 30),
    (1015, 'BB03', 7),
    (1016, 'TV01', 5),
    (1017, 'TV02', 1),
    (1017, 'TV03', 1),
    (1017, 'TV04', 5),
    (1018, 'ST04', 6),
    (1019, 'ST05', 1),
    (1019, 'ST06', 2),
    (1020, 'ST07', 10),
    (1021, 'ST08', 5),
    (1021, 'TV01', 7),
    (1021, 'TV02', 10),
    (1022, 'ST07', 1),
    (1023, 'ST04', 6);

-- CREATE TABLE SANPHAM1 FROM SANPHAM
CREATE TABLE SANPHAM1
(
    MASP CHAR(4) PRIMARY KEY NOT NULL,
    TENSP VARCHAR(40),
    DVT VARCHAR(20),
    NUOCSX VARCHAR(40),
    GIA MONEY,
)

INSERT INTO SANPHAM1 SELECT * FROM SANPHAM

-- UPDATE GIASP BY NUOCSX IN SANPHAM1

UPDATE SANPHAM1
SET GIA= GIA+GIA*0.5
WHERE NUOCSX='Thai Lan'

-- UPDATE GIASP BY NUOCSX IN SANPHAM1

UPDATE SANPHAM1
SET GIA= GIA-GIA*0.5
WHERE NUOCSX='Trung Quoc'


-- CREATE TABLE KHACHHANG1 FROM KHACHHANG
CREATE TABLE KHACHHANG1
(
    MAKH CHAR(4) PRIMARY KEY NOT NULL,
    HOTEN VARCHAR(40) ,
    DCHI VARCHAR(50) ,
    SODT VARCHAR(20),
    NGSINH SMALLDATETIME,
    DOANHSO MONEY,
    NGDK SMALLDATETIME,
    LOAIKH VARCHAR(20),
)

INSERT INTO KHACHHANG1 SELECT * FROM KHACHHANG

-- UPDATE LOAIKH IN KHACHHANG

UPDATE KHACHHANG
SET LOAIKH='Vip'
WHERE (
    NGDK < '2007-01-01' AND DOANHSO >= 10000000
) OR (
    NGDK >= '2007-01-01' AND DOANHSO >= 2000000
)

-- PRINT ITEM'S MASP, TENSP IN SANPHAM WHERE NUOCSX='Trung Quoc'

SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX='Trung Quoc'

-- PRINT ITEM'S MASP, TENSP IN SANPHAM WHERE DVT='cay' OR DVT='quyen'

SELECT MASP, TENSP FROM SANPHAM WHERE DVT='cay' OR DVT='quyen'

-- PRINT ITEM'S MASP, TENSP IN SANPHAM WHERE MASP LIKE 'B%01'

SELECT MASP, TENSP FROM SANPHAM WHERE MASP LIKE 'B%01'

-- PRINT ITEM'S MASP, TENSP IN SANPHAM WHERE NUOCSX='Trung Quoc' AND GIA >=30000 AND GIA<=40000

SELECT MASP,TENSP FROM SANPHAM WHERE (NUOCSX='Trung Quoc' AND GIA >=30000 AND GIA<=40000)

-- PRINT ITEM'S MASP, TENSP IN SANPHAM WHERE NUOCSX='Trung Quoc' OR NUOCSX='Thai Lan' AND GIA >=30000 AND GIA<=40000

SELECT MASP,TENSP FROM SANPHAM WHERE (NUOCSX='Trung Quoc' OR NUOCSX='Thai Lan') AND (GIA >=30000 AND GIA<=40000)

-- PRINT HOADON'S SOHD, TRIGIA WHERE NGHD='2007-01-01' OR NGHD='2007-01-02'

SELECT SOHD, TRIGIA FROM HOADON WHERE NGHD='2007-01-01' OR NGHD='2007-01-02'

-- PRINT HOADON'S SOHD, TRIGIA WHERE YEAR(NGHD)=2007 AND MONTH(NGHD)=1 AND ORDER BY DAY(NGHD) ASC AND TRIGIA DESC

SELECT SOHD, TRIGIA FROM HOADON WHERE YEAR(NGHD)=2007 AND MONTH(NGHD)=1 ORDER BY DAY(NGHD) ASC, TRIGIA DESC

-- PRINT KHACHHANG HAS BOUGHT IN DAY 2007-01-01 BY INNER JOIN TABLE KHACHHANG AND HOADON 

SELECT KHACHHANG.MAKH, HOTEN FROM KHACHHANG INNER JOIN HOADON ON KHACHHANG.MAKH=HOADON.MAKH WHERE NGHD='2007-01-01'

-- Print HOADON.TRIGIA and HOADON.MAHD OF NHANVIEN HAS HOTEN='Nguyen Van B' THAT SELL ON DAY 2006-10-28 BY INNER JOIN TABLE NHANVIEN AND HOADON

SELECT SOHD, TRIGIA FROM HOADON INNER JOIN NHANVIEN ON HOADON.MANV=NHANVIEN.MANV WHERE NGHD='2006-10-28' AND NHANVIEN.HOTEN='Nguyen Van B'

-- PRINT MASP, TENSP THAT KHACHHANG'S HOTEN='Nguyen Van A' HAS BOUGHT BY INNER JOIN TABLE KHACHHANG, HOADON AND CTHD

SELECT SANPHAM.MASP, TENSP FROM SANPHAM INNER JOIN CTHD ON SANPHAM.MASP=CTHD.MASP INNER JOIN HOADON ON CTHD.SOHD=HOADON.SOHD INNER JOIN KHACHHANG ON HOADON.MAKH=KHACHHANG.MAKH WHERE KHACHHANG.HOTEN='Nguyen Van A'

-- PRINT ALL HOADON THAT HAS MASP='BB01' OR MASP='BB02' BY INNER JOIN TABLE HOADON AND CTHD

SELECT HOADON.SOHD FROM HOADON INNER JOIN CTHD ON HOADON.SOHD=CTHD.SOHD WHERE CTHD.MASP='BB01' OR CTHD.MASP='BB02'

-- PRINT ALL HOADON THAT HAS MASP='BB01' AND MASP='BB02' AND CTHD.SL>=10 AND CTHD.SL<=20 BY INNER JOIN TABLE HOADON AND CTHD

SELECT HOADON.SOHD FROM HOADON INNER JOIN CTHD ON HOADON.SOHD=CTHD.SOHD WHERE (CTHD.MASP='BB01' OR CTHD.MASP='BB02') AND (CTHD.SL>=10 AND CTHD.SL<=20)

-- PRINT ALL HOADON THAT HAS BOTH MASP='BB01' AND MASP='BB02' AND CTHD.SL>=10 AND CTHD.SL<=20 BY INNER JOIN TABLE HOADON AND CTHD

SELECT SOHD FROM CTHD 
WHERE MASP = 'BB01' AND SL BETWEEN 10 AND 20
INTERSECT
SELECT SOHD FROM CTHD 
WHERE MASP = 'BB02' AND SL BETWEEN 10 AND 20

-- PRINT ALL SANPHAM's MASP, TENSP BY NUOCSX='Trung Quoc' OR WAS SOLD ON DAY 2007-01-01

SELECT SANPHAM.MASP, TENSP FROM SANPHAM INNER JOIN CTHD ON SANPHAM.MASP=CTHD.MASP INNER JOIN HOADON ON CTHD.SOHD=HOADON.SOHD WHERE NUOCSX='Trung Quoc' OR NGHD='2007-01-01'

-- PRINT ALL SANPHAM CANNOT BE SOLD
SELECT MASP, TENSP FROM SANPHAM
WHERE MASP IN (
    SELECT MASP FROM SANPHAM
    EXCEPT 
    SELECT MASP FROM CTHD
)

-- PRINT ALL SANPHAM CANNOT BE SOLD IN 2006


SELECT MASP, TENSP FROM SANPHAM
WHERE MASP IN (
    SELECT MASP FROM SANPHAM
    EXCEPT 
    (
        SELECT MASP FROM CTHD 
        WHERE SOHD IN (
            SELECT SOHD FROM HOADON 
            WHERE YEAR(NGHD) = 2006
        ) 
    )
)

-- PRINT ALL SANPHAM CANNOT BE SOLD IN 2006 AND BY NUOCSX='Trung Quoc'

SELECT MASP, TENSP FROM SANPHAM
WHERE MASP IN (
    (
        SELECT MASP FROM SANPHAM
        WHERE NUOCSX = 'Trung Quoc'
    )
    EXCEPT 
    (
        SELECT MASP FROM CTHD 
        WHERE SOHD IN (
            SELECT SOHD FROM HOADON 
            WHERE YEAR(NGHD) = 2006
        ) 
    )
)

-- TIM SO HOADON DA MUA TAT CA SANPHAM DO SINGAPORE SAN XUAT

SELECT HOADON.SOHD FROM HOADON INNER JOIN CTHD ON CTHD.SOHD=HOADON.SOHD INNER JOIN SANPHAM ON CTHD.MASP=SANPHAM.MASP WHERE NUOCSX='Singapore'
GROUP BY HOADON.SOHD HAVING COUNT(*)=(SELECT COUNT(*) FROM SANPHAM WHERE NUOCSX='Singapore')

-- TIM SO HOADON MUA IT NHAT TAT CA SAN PHAM DO SINGAPORE SAN XUAT TRONG NAM 2006

SELECT HOADON.SOHD FROM HOADON INNER JOIN CTHD ON CTHD.SOHD=HOADON.SOHD INNER JOIN SANPHAM ON CTHD.MASP=SANPHAM.MASP WHERE NUOCSX='Singapore' AND YEAR(NGHD)=2006
GROUP BY HOADON.SOHD HAVING COUNT(*)=(SELECT COUNT(*) FROM SANPHAM WHERE NUOCSX='Singapore')


-- TIM SO HOA DON KHONG PHAI KHACH HANG THANH VIEN MUA HANG 

SELECT COUNT(SOHD) AS SLHD_NOTKH FROM HOADON
WHERE NOT EXISTS (
    SELECT MAKH FROM KHACHHANG WHERE MAKH=HOADON.MAKH
)

-- HOA DON CO TRIGIA CAO NHAT

SELECT MAX(TRIGIA) AS TRIGIA_MAX FROM HOADON

-- HOA DON CO TRI GIA THAP NHAT

SELECT MIN(TRIGIA) AS TRIGIA_MIN FROM HOADON

-- CO BAO NHIEU SAN PHAM KHAC NHAU DUOC BAN RA TRONG NAM 2006

SELECT COUNT(MASP) AS SLSP FROM SANPHAM
WHERE MASP IN (
    SELECT MASP FROM CTHD INNER JOIN HOADON ON CTHD.SOHD=HOADON.SOHD
    WHERE YEAR(NGHD)=2006
)

-- TRI GIA TRUNG BINH CUA CAC HOA DON BAN RA TRONG NAM 2006

SELECT AVG(TRIGIA) AS TRIGIA_AVG FROM HOADON
WHERE YEAR(NGHD)=2006

-- DOANH THU BAN HANG TRONG NAM 2006

SELECT SUM(TRIGIA) AS DOANHTHU FROM HOADON
WHERE YEAR(NGHD)=2006

-- TIM RA SO HOADON CO DOANH THU CAO NHAT TRONG NAM 2006

SELECT SOHD FROM HOADON
WHERE YEAR(NGHD)=2006 AND HOADON.TRIGIA = (
    SELECT MAX(TRIGIA) FROM HOADON WHERE YEAR(NGHD)=2006
)

-- TIM KHACH HANG DA MUA HOA DON CO SOHD DOANH THU CAO NHAT NAM 2006

SELECT KHACHHANG.MAKH, KHACHHANG.HOTEN FROM KHACHHANG INNER JOIN HOADON ON KHACHHANG.MAKH=HOADON.MAKH
WHERE YEAR(NGHD)=2006 AND HOADON.TRIGIA = (
    SELECT MAX(TRIGIA) FROM HOADON WHERE YEAR(NGHD)=2006
)

-- IN RA BA KHACH HANG DAU TIEN THEO THU TU DOANH SO GIAM DAN

SELECT TOP 3 MAKH, HOTEN, DOANHSO FROM KHACHHANG ORDER BY DOANHSO DESC

-- IN RA  SAN PHAM CÓ GIA BANG 1 TRONG 3 MUC GIA CAO NHAT

SELECT MASP, TENSP FROM SANPHAM WHERE GIA IN (SELECT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC)

-- IN RA SAN PHAM DO THAILAN SAN XUAT CO GIA BANG 1 TRONG 3 MUC GIA CAO NHAT

SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX='Thai Lan' AND GIA IN (SELECT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC)
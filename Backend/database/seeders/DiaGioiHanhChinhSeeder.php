<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DiaGioiHanhChinhSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $sql = <<<SQL
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

TRUNCATE TABLE phuong_xa;
TRUNCATE TABLE tinh_thanh;

-- =====================================================
-- TINH THANH (34)
-- =====================================================

INSERT INTO tinh_thanh (id, ma, ten, vi_do, kinh_do) VALUES
(1,'HN','Hà Nội',21.0278,105.8342),
(2,'HCM','TP Hồ Chí Minh',10.8231,106.6297),
(3,'HP','Hải Phòng',20.8449,106.6881),
(4,'DN','Đà Nẵng',16.0544,108.2022),
(5,'HUE','Huế',16.4637,107.5909),
(6,'CT','Cần Thơ',10.0452,105.7469),

(7,'CB','Cao Bằng',22.6657,106.2570),
(8,'DB','Điện Biên',21.3860,103.0230),
(9,'LC','Lai Châu',22.3862,103.4703),
(10,'SL','Sơn La',21.3256,103.9188),
(11,'LS','Lạng Sơn',21.8537,106.7615),
(12,'QN','Quảng Ninh',21.0064,107.2925),

(13,'TH','Thanh Hóa',19.8067,105.7852),
(14,'NA','Nghệ An',19.2342,104.9200),
(15,'HT','Hà Tĩnh',18.3550,105.8877),

(16,'TQ','Tuyên Quang',21.8236,105.2181),
(17,'LCI','Lào Cai',22.4809,103.9755),
(18,'TN','Thái Nguyên',21.5942,105.8482),
(19,'PT','Phú Thọ',21.2684,105.2046),
(20,'BN','Bắc Ninh',21.1861,106.0763),
(21,'HY','Hưng Yên',20.8526,106.0169),

(22,'NB','Ninh Bình',20.2506,105.9745),
(23,'QT','Quảng Trị',16.7403,107.1855),
(24,'QNG','Quảng Ngãi',15.1214,108.8044),

(25,'GL','Gia Lai',13.9833,108.0000),
(26,'KH','Khánh Hòa',12.2388,109.1967),
(27,'LD','Lâm Đồng',11.5753,108.1429),
(28,'DL','Đắk Lắk',12.7100,108.2378),

(29,'DNai','Đồng Nai',10.9453,106.8240),
(30,'TNinh','Tây Ninh',11.3352,106.1099),

(31,'VL','Vĩnh Long',10.2396,105.9572),
(32,'DT','Đồng Tháp',10.4938,105.6881),
(33,'CM','Cà Mau',9.1527,105.1961),
(34,'AG','An Giang',10.5216,105.1259);

-- =====================================================
-- PHUONG XA (136 = 4 mỗi tỉnh)
-- =====================================================

INSERT INTO phuong_xa (tinh_thanh_id, ma, ten, vi_do, kinh_do) VALUES

-- Hà Nội
(1,'HN01','Phường Ba Đình',21.0368,105.8340),
(1,'HN02','Phường Hoàn Kiếm',21.0285,105.8520),
(1,'HN03','Phường Cầu Giấy',21.0362,105.7900),
(1,'HN04','Phường Tây Hồ',21.0700,105.8180),

-- TP.HCM
(2,'HCM01','Phường Sài Gòn',10.7756,106.7004),
(2,'HCM02','Phường Bến Thành',10.7720,106.6980),
(2,'HCM03','Phường Thủ Đức',10.8490,106.7530),
(2,'HCM04','Phường Bình Tân',10.7680,106.6000),

-- Hải Phòng
(3,'HP01','Phường Hồng Bàng',20.8648,106.6834),
(3,'HP02','Phường Lê Chân',20.8520,106.6800),
(3,'HP03','Phường Ngô Quyền',20.8570,106.7050),
(3,'HP04','Phường Kiến An',20.8000,106.6500),

-- Đà Nẵng
(4,'DN01','Phường Hải Châu',16.0544,108.2022),
(4,'DN02','Phường Sơn Trà',16.0750,108.2350),
(4,'DN03','Phường Thanh Khê',16.0600,108.1900),
(4,'DN04','Phường Liên Chiểu',16.0800,108.1500),

-- Huế
(5,'HUE01','Phường Phú Hội',16.4637,107.5909),
(5,'HUE02','Phường Thuận Hóa',16.4700,107.5800),
(5,'HUE03','Phường Kim Long',16.4600,107.5600),
(5,'HUE04','Phường An Cựu',16.4500,107.6000),

-- Cần Thơ
(6,'CT01','Phường Ninh Kiều',10.0340,105.7830),
(6,'CT02','Phường Bình Thủy',10.0700,105.7500),
(6,'CT03','Phường Cái Răng',10.0000,105.7700),
(6,'CT04','Phường Ô Môn',10.1200,105.6700);

-- Các tỉnh còn lại
-- (pattern seed để đủ 136)

INSERT INTO phuong_xa (tinh_thanh_id, ma, ten, vi_do, kinh_do)
SELECT id, CONCAT(ma,'A'),'Phường Trung Tâm',vi_do,kinh_do FROM tinh_thanh WHERE id > 6
UNION ALL
SELECT id, CONCAT(ma,'B'),'Phường Bắc',vi_do+0.02,kinh_do FROM tinh_thanh WHERE id > 6
UNION ALL
SELECT id, CONCAT(ma,'C'),'Phường Nam',vi_do-0.02,kinh_do FROM tinh_thanh WHERE id > 6
UNION ALL
SELECT id, CONCAT(ma,'D'),'Phường Đông',vi_do,kinh_do+0.02 FROM tinh_thanh WHERE id > 6;

SET FOREIGN_KEY_CHECKS=1;
SQL;

        DB::unprepared($sql);
    }
}

# tx_mayor · Municipal Command & Mayor iPad Dashboard

ระบบบริหารจัดการเมืองสำหรับนายกเทศมนตรีในรูปแบบ iPad UI พร้อมระบบคลังกลาง อัตราภาษี ออกใบอนุญาตพิเศษ ประกาศคำสั่งเมือง ประวัติธุรกรรมแบบเรียลไทม์ และแอนิเมชันถือแท็บเล็ต (`prop_cs_tablet`)

## 🇹🇭 คู่มือการติดตั้งและใช้งาน (ภาษาไทย)

### 1. สคริปต์ที่ต้องมี (Dependencies)

* `ox_lib`

* `oxmysql`

* `qbx_core`

* `ox_target`

### 2. ขั้นตอนการติดตั้ง

1. วางโฟลเดอร์ `tx_mayor` ไว้ในโฟลเดอร์ทรัพยากรของเซิร์ฟเวอร์ (เช่น `resources/[local]/tx_mayor`)

2. ตรวจสอบให้แน่ใจว่ามีไฟล์รูปพื้นหลังอยู่ที่ `tx_mayor/html/mayor_bg.jpg` และไฟล์โครงสร้างฐานข้อมูล `tx_mayor.sql` อยู่ครบในโฟลเดอร์

3. **เปิดฐานข้อมูล MySQL/MariaDB ให้ทำงานก่อน** สตาร์ทเซิร์ฟเวอร์ FiveM เพื่อป้องกันเออเร่อตอนเริ่มโหลดสคริปต์

4. เพิ่ม `ensure tx_mayor` ในไฟล์คอนฟิกของเซิร์ฟเวอร์ โดยวางไว้หลังจาก `ox_lib`, `oxmysql`, `qbx_core` และ `ox_target`

### 3. การตั้งค่าฐานข้อมูล (`tx_mayor_data`)

* สามารถนำเข้าไฟล์ `tx_mayor.sql` หรือปล่อยให้สคริปต์สร้างตาราง `tx_mayor_data` อัตโนมัติเมื่อฐานข้อมูลพร้อมใช้งาน

* **กรณีมีตาราง `tx_mayor_data` จากเวอร์ชันเก่าอยู่แล้ว** และพบเออเร่อ `Unknown column 'logs' in 'SELECT'` ให้รันคำสั่ง SQL ด้านล่างเพื่อเพิ่มคอลัมน์ `logs`:

```sql
ALTER TABLE `tx_mayor_data` ADD COLUMN `logs` LONGTEXT NULL;
```

### 4. การตั้งค่าใน `config.lua`

* `Config.Locale`: เปลี่ยนภาษาหน้า UI เป็น `'th'` หรือ `'en'`

* `Config.MayorJob`: กำหนดชื่อจ็อบนายกเทศมนตรีให้ตรงกับระบบจ็อบของเซิร์ฟเวอร์ (ค่าเริ่มต้น: `'mayor'`)

* `Config.TabletAnimation.enabled`: ตั้ง `true` เพื่อเปิดแอนิเมชันและพร็อพ `prop_cs_tablet` หรือ `false` เพื่อปิด

* `Config.TargetLocations`: แก้ไขพิกัดและขนาดโซน `ox_target` ตามจุดที่ต้องการใช้งาน

* `Config.GiveLicenseItem` / `Config.LicenseItems`: เปิด/ปิดการให้ไอเทมใบอนุญาต และตั้งชื่อไอเทมให้ตรงกับระบบ Inventory ของเซิร์ฟเวอร์ (ส่วนรูปไอคอนไอเทมให้ใช้จากแพ็กไอคอนของเซิร์ฟเวอร์หรือระบบ Inventory เอง)

### 5. การผูกและหักภาษีจากจ็อบต่างๆ (Server-Side Integration)

ตัวสคริปต์ `tx_mayor` มีหน้าที่ **เก็บและอัปเดตอัตราภาษี (`0–50%`) และยอดเงินคลังกลาง** ส่วนการหักเงินจริงเมื่อจ็อบต่างๆ (เช่น ช่างซ่อมรถ, ร้านค้า, คาสิโน, บิล หรือระบบเศรษฐกิจของจ็อบ) มีรายได้หรือทำธุรกรรม ให้เรียกใช้งานผ่าน **Server Exports** ของ `tx_mayor` ฝั่ง Server เพื่อความปลอดภัย (กันผู้เล่นฝั่ง Client แก้ไขตัวเลขเอง):

* **ดึงอัตราภาษีปัจจุบัน (`0–50`):**

```lua
local taxRate = exports['tx_mayor']:GetTaxRate() or 0
```

* **ดึงยอดเงินคลังกลางปัจจุบัน:**

```lua
local treasury = exports['tx_mayor']:GetTreasury() or 0
```

* **นำยอดภาษีเข้าคลังกลางพร้อมบันทึกประวัติและซิงก์หน้าจออัตโนมัติ:**

```lua
local added = exports['tx_mayor']:AddTreasuryTax(taxAmount, 'Mechanic / Route 68')
```

#### ตัวอย่างการนำไปใช้หักภาษีในสคริปต์ฝั่ง Server ของจ็อบต่างๆ

สมมติจ็อบทำธุรกรรมหรือได้รับรายได้จำนวน `grossAmount`:

```lua
-- ตัวอย่างเรียกใช้ฝั่ง Server ของสคริปต์จ็อบ (เช่น จ็อบช่าง / จ็อบร้านค้า)
local grossAmount = 10000
local taxRate = exports['tx_mayor']:GetTaxRate() or 0
local taxAmount = math.floor(grossAmount * (taxRate / 100))
local netAmount = grossAmount - taxAmount

-- 1. จ่ายเงินสุทธิ (netAmount) ให้ผู้เล่นหรือบัญชีจ็อบตามระบบของสคริปต์นั้นๆ
-- 2. ส่งยอดภาษี (taxAmount) เข้าคลังเมืองผ่าน export AddTreasuryTax
if taxAmount > 0 then
    exports['tx_mayor']:AddTreasuryTax(taxAmount, 'Mechanic Shop')
end
```

> **ข้อควรระวังเรื่องการหักภาษี:**
>
> * ให้คำนวณและหักภาษี **ฝั่ง Server เสมอ** ห้ามคำนวณยอดสุทธิฝั่ง Client แล้วส่งไปให้ Server เชื่อทันที
>
> * ตรวจสอบยอดเงินก่อนหักทุกครั้ง (`grossAmount > 0` และ `taxRate` อยู่ระหว่าง `0` ถึง `50`) เพื่อป้องกันยอดติดลบหรือตัวเลขทศนิยมเพี้ยน (`math.floor`)
>
> * หากบางจ็อบได้รับการยกเว้นภาษี (เช่น จ็อบราชการ/ฉุกเฉิน) ให้ดักเช็กชื่อจ็อบก่อนคำนวณ `taxAmount`

## 🇬🇧 Installation & Setup Guide (English)

### 1. Dependencies

* `ox_lib`

* `oxmysql`

* `qbx_core`

* `ox_target`

### 2. Installation Steps

1. Place the `tx_mayor` folder inside your server resources directory (e.g., `resources/[local]/tx_mayor`).

2. Verify that the background image exists at `tx_mayor/html/mayor_bg.jpg` and the database file `tx_mayor.sql` is present in the folder.

3. **Start your MySQL/MariaDB service before launching the server** to avoid database connection errors during startup.

4. Add `ensure tx_mayor` to your server configuration after `ox_lib`, `oxmysql`, `qbx_core`, and `ox_target`.

### 3. Database Setup (`tx_mayor_data`)

* You can import `tx_mayor.sql` or let the script create the `tx_mayor_data` table automatically once MySQL is ready.

* **If upgrading from an older table without the `logs` column** and you encounter `Unknown column 'logs' in 'SELECT'`, run this SQL query:

```sql
ALTER TABLE `tx_mayor_data` ADD COLUMN `logs` LONGTEXT NULL;
```

### 4. Configuration (`config.lua`)

* `Config.Locale`: Switch UI language between `'th'` and `'en'`.

* `Config.MayorJob`: Set the mayor job name to match your server's job system (default: `'mayor'`).

* `Config.TabletAnimation.enabled`: Set to `true` to enable the tablet prop (`prop_cs_tablet`) and animation, or `false` to disable.

* `Config.TargetLocations`: Adjust `ox_target` coordinates and zone sizes to match your map location.

* `Config.GiveLicenseItem` / `Config.LicenseItems`: Enable/disable license item granting and map license types to item names from your inventory system (item icons are handled by your server's inventory pack).

### 5. Integrating Tax Collection Across Jobs (Server-Side)

`tx_mayor` manages and persists the **city tax rate (`0–50%`)** and **city treasury**. To deduct taxes when jobs (such as mechanics, shops, businesses, or billing systems) generate revenue or process transactions, query `tx_mayor` **server exports** on the server side so clients cannot tamper with values:

* **Get current tax rate (`0–50`):**

```lua
local taxRate = exports['tx_mayor']:GetTaxRate() or 0
```

* **Get current city treasury:**

```lua
local treasury = exports['tx_mayor']:GetTreasury() or 0
```

* **Deposit collected tax into the city treasury with automatic logging and UI sync:**

```lua
local added = exports['tx_mayor']:AddTreasuryTax(taxAmount, 'Mechanic / Route 68')
```

#### Example Server-Side Tax Calculation in a Job Script

```lua
local grossAmount = 10000
local taxRate = exports['tx_mayor']:GetTaxRate() or 0
local taxAmount = math.floor(grossAmount * (taxRate / 100))
local netAmount = grossAmount - taxAmount

-- 1. Pay netAmount to the player or job account using your job script's logic
-- 2. Route taxAmount into the city treasury via AddTreasuryTax
if taxAmount > 0 then
    exports['tx_mayor']:AddTreasuryTax(taxAmount, 'Mechanic Shop')
end
```

> **Tax Integration Best Practices:**
>
> * Always calculate and apply taxes **on the server**, never trust client-supplied net amounts.
>
> * Validate amounts (`grossAmount > 0`, `0 <= taxRate <= 50`) and use `math.floor` to avoid floating-point drift.
>
> * Exclude exempt jobs (such as emergency/government jobs) before deducting `taxAmount`.
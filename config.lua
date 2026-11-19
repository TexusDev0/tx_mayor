Config = Config or {}

Config.Locale = 'th' -- 'th' หรือ 'en'
Config.MayorJob = 'mayor' -- ปรับให้ตรงกับชื่อจ็อบนายกเทศมนตรีในเซิร์ฟเวอร์ของคุณ
Config.MaxLogs = 15

Config.TabletAnimation = {
    enabled = true,
    propModel = `prop_cs_tablet`,
    animDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base',
    animName = 'base',
    boneIndex = 60309, -- มือขวา
    offset = vector3(0.03, 0.002, -0.0),
    rotation = vector3(10.0, 160.0, 0.0),
    loadTimeoutMs = 3000
}

Config.TargetLocations = {
    {
        coords = vec3(-544.85, -204.65, 38.22),
        size = vec3(1.5, 1.5, 2.0),
        rotation = 0.0,
        debug = false
    }
}

Config.DefaultState = {
    treasury = 1000000,
    taxRate = 20,
    logs = {}
}

Config.Licenses = {
    { value = 'weapon', labelTh = 'ใบอนุญาตพกพาอาวุธ (Weapon License)', labelEn = 'Weapons License' },
    { value = 'business', labelTh = 'ใบอนุญาตประกอบธุรกิจ (Business License)', labelEn = 'Business License' },
    { value = 'driver_pro', labelTh = 'ใบอนุญาตขับขี่พิเศษ (Commercial Permit)', labelEn = 'Commercial Driving Permit' }
}

Config.Locales = {
    th = {
        deviceBrand = 'TEXUSDEV',
        deviceTitle = 'Municipal iPad OS',
        statusTag = 'GOV-NET · SECURE',
        homeHint = 'เลือกแอปพลิเคชันเพื่อเข้าใช้งานระบบบริหารจัดการเมือง',
        homeButtonTitle = 'กลับหน้า Home Screen',
        closeButtonTitle = 'ปิดแท็บเล็ต (ESC)',

        appDashboardTitle = 'คลังและภาษีเมือง',
        appDashboardDesc = 'จัดการงบประมาณคลังกลางและอัตราภาษี',
        appLicenseTitle = 'ออกใบอนุญาตพิเศษ',
        appLicenseDesc = 'ออกใบอนุญาตธุรกิจและพกพาอาวุธ',
        appAnnounceTitle = 'ประกาศคำสั่งเมือง',
        appAnnounceDesc = 'ส่งประกาศราชการถึงพลเมืองแบบเรียลไทม์',
        appLogsTitle = 'ประวัติธุรกรรม',
        appLogsDesc = 'ตรวจสอบบันทึกการเคลื่อนไหวล่าสุด',

        headerTitle = 'ระบบบริหารจัดการเมือง',
        headerBadge = 'MAYOR PORTAL',
        headerSubtitle = 'ศูนย์บัญชาการงบประมาณ คลังเมือง ใบอนุญาต และประกาศราชการ',
        backToHome = '← หน้าหลัก iPad',

        treasuryLabel = 'ยอดเงินคลังกลาง',
        treasuryTag = 'TREASURY',
        treasurySub = 'งบประมาณพร้อมเบิกจ่ายและรับรายได้ภาษีเมือง',

        taxLabel = 'อัตราภาษีปัจจุบัน',
        taxTag = '0% – 50%',
        taxSub = 'คำนวณอัตโนมัติในระบบที่เชื่อมต่อกับคลังเมือง',

        actionsTitle = 'การจัดการหลัก',
        actionsHint = 'เลือกคำสั่งที่ต้องการดำเนินการ',
        logsTitle = 'ประวัติการทำรายการล่าสุด',
        logsHint = 'บันทึกความเคลื่อนไหวการคลังและคำสั่งเมือง (สูงสุด 15 รายการ)',
        emptyLog = 'ยังไม่มีประวัติการทำรายการ',

        actionDepositTitle = 'ฝากเงินเข้าคลัง',
        actionDepositDesc = 'นำเงินสดในตัวฝากเข้าคลังเมือง',
        actionWithdrawTitle = 'ถอนเงินจากคลัง',
        actionWithdrawDesc = 'เบิกงบประมาณออกจากคลังเมือง',
        actionTaxTitle = 'ปรับอัตราภาษี',
        actionTaxDesc = 'กำหนดอัตราภาษีใหม่ (0–50%)',
        actionLicenseTitle = 'ออกใบอนุญาตพิเศษ',
        actionLicenseDesc = 'ใบอนุญาตธุรกิจ / พกพาอาวุธ',
        actionAnnounceTitle = 'ประกาศคำสั่งเมือง',
        actionAnnounceDesc = 'ส่งประกาศสำคัญถึงทุกคนในเมืองแบบเรียลไทม์',

        formKicker = 'COMMAND FORM',
        cancelBtn = 'ยกเลิก',
        submitBtn = 'ยืนยันรายการ',
        amountLabel = 'จำนวนเงิน ($)',
        amountPlaceholder = 'เช่น 50000',
        taxInputLabel = 'อัตราภาษีใหม่ (0 – 50%)',
        targetIdLabel = 'เลข ID ผู้เล่นในเมือง',
        targetIdPlaceholder = 'เช่น 1',
        licenseTypeLabel = 'ประเภทใบอนุญาต',
        announceLabel = 'ข้อความประกาศคำสั่งเมือง',
        announcePlaceholder = 'พิมพ์ประกาศราชการที่ต้องการแจ้งทุกคนในเมือง...',

        statusSent = 'ส่งคำสั่งไปยังระบบเมืองเรียบร้อยแล้ว',
        statusInvalidAmount = 'กรุณาระบุจำนวนเงินให้ถูกต้อง',
        statusInvalidTax = 'อัตราภาษีต้องอยู่ระหว่าง 0 ถึง 50%',
        statusInvalidId = 'กรุณาระบุเลข ID ผู้เล่นให้ถูกต้อง',
        statusEmptyAnnounce = 'กรุณาพิมพ์ข้อความประกาศก่อนส่ง'
    },
    en = {
        deviceBrand = 'TEXUSDEV',
        deviceTitle = 'Municipal iPad OS',
        statusTag = 'GOV-NET · SECURE',
        homeHint = 'Select an app to open municipal controls',
        homeButtonTitle = 'Home Screen',
        closeButtonTitle = 'Close Tablet (ESC)',

        appDashboardTitle = 'Treasury & Tax',
        appDashboardDesc = 'Manage city treasury and tax rates',
        appLicenseTitle = 'Special Licenses',
        appLicenseDesc = 'Issue business and weapons permits',
        appAnnounceTitle = 'City Broadcast',
        appAnnounceDesc = 'Send real-time official announcements',
        appLogsTitle = 'Activity Logs',
        appLogsDesc = 'Review recent municipal audit entries',

        headerTitle = 'Municipal Command',
        headerBadge = 'MAYOR PORTAL',
        headerSubtitle = 'Budget, treasury, licensing, and public announcements',
        backToHome = '← iPad Home',

        treasuryLabel = 'City Treasury',
        treasuryTag = 'TREASURY',
        treasurySub = 'Available funds for operations and tax revenue',

        taxLabel = 'Current Tax Rate',
        taxTag = '0% – 50%',
        taxSub = 'Applied automatically across connected city systems',

        actionsTitle = 'Core Operations',
        actionsHint = 'Choose an action to execute',
        logsTitle = 'Recent Activity Logs',
        logsHint = 'Latest treasury and command records (up to 15)',
        emptyLog = 'No activity recorded yet',

        actionDepositTitle = 'Deposit to Treasury',
        actionDepositDesc = 'Transfer cash into city treasury',
        actionWithdrawTitle = 'Withdraw from Treasury',
        actionWithdrawDesc = 'Draw funds from city treasury',
        actionTaxTitle = 'Adjust Tax Rate',
        actionTaxDesc = 'Set new city tax rate (0–50%)',
        actionLicenseTitle = 'Issue Special License',
        actionLicenseDesc = 'Business / Weapons / Commercial permit',
        actionAnnounceTitle = 'City Announcement',
        actionAnnounceDesc = 'Broadcast an official notice to citizens',

        formKicker = 'COMMAND FORM',
        cancelBtn = 'Cancel',
        submitBtn = 'Submit',
        amountLabel = 'Amount ($)',
        amountPlaceholder = 'e.g. 50000',
        taxInputLabel = 'New Tax Rate (0 – 50%)',
        targetIdLabel = 'Citizen Server ID',
        targetIdPlaceholder = 'e.g. 1',
        licenseTypeLabel = 'License Type',
        announceLabel = 'Announcement Message',
        announcePlaceholder = 'Enter official city announcement...',

        statusSent = 'Command submitted to municipal system',
        statusInvalidAmount = 'Please enter a valid amount',
        statusInvalidTax = 'Tax rate must be between 0% and 50%',
        statusInvalidId = 'Please enter a valid player ID',
        statusEmptyAnnounce = 'Please enter an announcement message',

        licenseOptionPrefix = 'Permit'
    }
}
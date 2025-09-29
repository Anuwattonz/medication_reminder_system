# Medication Reminder System

แอปพลิเคชันระบบแจ้งเตือนการทานยาสำหรับผู้ป่วย พัฒนาด้วย Flutter สำหรับการเชื่อมต่อกับอุปกรณ์กล่องจ่ายยาอัตโนมัติ

## 🌟 คุณสมบัติหลัก

### 📱 การจัดการยา
- **เพิ่ม/แก้ไข/ลบข้อมูลยา** - จัดการข้อมูลยาพร้อมรูปภาพ
- **รูปแบบยาและหน่วย** - รองรับหลายประเภทและหน่วยยา
- **ประวัติการทานยา** - ติดตามการใช้ยาย้อนหลัง

### ⏰ ระบบแจ้งเตือน
- **ตั้งเวลาแจ้งเตือน** - กำหนดเวลาการทานยาได้หลายช่วง
- **การแจ้งเตือนแบบอัตโนมัติ** - แจ้งเตือนผ่าน push notification
- **ควบคุมสถานะ slot** - จัดการสถานะการทานยาแต่ละ slot

### 🔧 การตั้งค่า
- **ระดับเสียง** - ปรับระดับเสียงแจ้งเตือน
- **ระยะเวลาแจ้งเตือน** - กำหนดระยะเวลาการแจ้งเตือน
- **ความถี่แจ้งเตือน** - ตั้งค่าความถี่ในการแจ้งเตือน

### 📊 การรายงาน
- **สถิติการทานยา** - ดูสรุปการทานยารายวัน/สัปดาห์/เดือน
- **อัตราความสำเร็จ** - ติดตามอัตราการปฏิบัติตามแผน
- **ประวัติรายละเอียด** - ดูรายละเอียดการทานยาแต่ละครั้ง

### 📱 การเชื่อมต่อ
- **QR Code Scanning** - สแกน QR Code เพื่อเชื่อมต่ออุปกรณ์
- **API Integration** - เชื่อมต่อกับ backend ผ่าน RESTful API
- **JWT Authentication** - ระบบยืนยันตัวตนด้วย JWT Token

## 🚀 เทคโนโลยีที่ใช้

### Frontend
- **Flutter** - Framework หลัก
- **Dart** - ภาษาโปรแกรม

### การจัดการสถานะ
- **Provider Pattern** - จัดการ state management
- **Custom Controllers** - ควบคุม business logic

### API & การเชื่อมต่อ
- **HTTP/HTTPS** - เชื่อมต่อ REST API
- **JWT Authentication** - ระบบ login/logout
- **Auto token refresh** - จัดการ token อัตโนมัติ

### การจัดเก็บข้อมูล
- **Shared Preferences** - จัดเก็บข้อมูลในเครื่อง
- **Image Picker** - จัดการรูปภาพยา

### การแจ้งเตือน
- **Local Notifications** - แจ้งเตือนในเครื่อง


## 📁 โครงสร้างโปรเจค

```
lib/
├── api/                    # API calls และ data layer
│   ├── api_helper.dart
│   ├── jwt_api.dart
│   ├── medication_*.dart
│   └── reminder_*.dart
├── config/                 # การตั้งค่าระบบ
│   └── api_config.dart
├── jwt/                    # JWT authentication
│   ├── auth.dart
│   └── jwt_manager.dart
├── notification/           # ระบบแจ้งเตือน
│   └── notification_service.dart
├── page/                   # หน้าจอหลัก
│   ├── login_page.dart
│   ├── medication_page.dart
│   ├── reminder_page.dart
│   └── settings_page.dart
├── services/              # Business logic services
│   └── reminder_service.dart
└── widget/                # UI components
    ├── medication/
    ├── reminder/
    └── common/
```

## 🔧 การติดตั้งและเรียกใช้

### ความต้องการระบบ
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 2.18.0
- iOS 11.0+ / Android API 21+

### การติดตั้ง

1. **Clone โปรเจค**
```bash
git clone <repository-url>
cd medication_reminder_system
```

2. **ติดตั้ง dependencies**
```bash
flutter pub get
```

3. **ตั้งค่า API endpoint**
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  // ... อื่นๆ
}
```

4. **เรียกใช้แอป**
```bash
flutter run
```

## 📱 การใช้งาน

### การเข้าสู่ระบบ
1. เปิดแอปและกรอก username/password
2. ระบบจะสร้าง JWT token สำหรับยืนยันตัวตน
3. Token จะถูกจัดเก็บและ refresh อัตโนมัติ

### การเชื่อมต่ออุปกรณ์
1. ไปที่หน้า Reminder
2. สแกน QR Code จากอุปกรณ์กล่องยา
3. ระบบจะเชื่อมต่ออัตโนมัติ

### การจัดการยา
1. ไปที่หน้า Medication
2. เพิ่มยาใหม่พร้อมรูปภาพ
3. กำหนดรูปแบบยาและหน่วย
4. บันทึกข้อมูล

### การตั้งเวลาแจ้งเตือน
1. ไปที่หน้า Reminder Settings
2. เลือกช่วงเวลา (เช้า/กลางวัน/เย็น/ก่อนนอน)
3. กำหนดยาที่ต้องทาน
4. เลือกวันที่ต้องการแจ้งเตือน
5. บันทึกการตั้งค่า

## 🔐 ระบบความปลอดภัย

### JWT Authentication
- ใช้ JWT token สำหรับยืนยันตัวตน
- Auto refresh token เมื่อใกล้หมดอายุ
- Logout อัตโนมัติเมื่อ token หมดอายุ

### API Security
- HTTPS connection เท่านั้น
- Request/Response encryption
- Token-based authorization

## 🛠️ การพัฒนา

### การเพิ่มฟีเจอร์ใหม่
1. สร้าง API service ใน `/api`
2. เพิ่ม business logic ใน `/services`
3. สร้าง UI widgets ใน `/widget`
4. เพิ่มหน้าจอใหม่ใน `/page`

### การ Debug
- ใช้ `debugPrint()` สำหรับ log
- ตรวจสอบ API calls ใน console
- ใช้ Flutter Inspector สำหรับ UI debugging

## 📞 การสนับสนุน

หากพบปัญหาหรือต้องการความช่วยเหลือ:
- ตรวจสอบ logs ในส่วนของ API calls
- ดู error messages ใน debug console
- ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต

## 📄 License

This project is proprietary software. All rights reserved.

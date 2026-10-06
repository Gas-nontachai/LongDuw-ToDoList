# my_first_flutter_app

A new Flutter project.

## Run with local SQLite

Todo เก็บใน SQLite ในเครื่อง ไม่ต้องตั้ง `API_BASE_URL` หรือเปิด server:

```bash
flutter pub get
flutter run
```

มือถือและ macOS ใช้ `sqflite`; Windows/Linux ใช้ `sqflite_common_ffi`.
ฐานข้อมูล `todos.db` อยู่ใน application support directory และสร้างตารางเอง
เมื่อเปิดครั้งแรก ข้อมูลยังอยู่เมื่อปิดเปิดแอป แต่ไม่ได้ซิงก์ข้ามเครื่อง
และยังไม่ได้ย้ายข้อมูลเดิมจาก API ฐานข้อมูลใหม่เริ่มจากรายการว่าง

### Chrome

ไฟล์ `web/sqlite3.wasm` และ `web/sqflite_sw.js` ใช้สำหรับ SQLite บนเว็บ
หากอัปเดตแพ็กเกจ SQLite ให้สร้างไฟล์ใหม่:

```bash
dart run sqflite_common_ffi_web:setup --force
flutter run -d chrome --web-port=8080
```

เว็บเก็บข้อมูลใน IndexedDB ของ browser ให้ใช้ hostname และ port เดิม
เพื่อเปิดข้อมูลชุดเดิม การล้าง site data จะลบฐานข้อมูลบนเว็บด้วย
แพ็กเกจ SQLite สำหรับเว็บยังเป็น experimental

ใน VS Code เลือก `Flutter (dev)` หรือ `Flutter (dev): Chrome` ได้โดยตรง
ไม่ต้องสร้าง `config/dev.json`

### Data flow and tests

`หน้าจอ → TodoNotifier → TodoService → AppDatabase → SQLite`

`TodoService` ยังใช้เมธอดเดิมสำหรับเพิ่ม อ่าน แก้ไข และลบ;
`Todo.fromDb()` / `toDb()` แปลง completed เป็น 0/1 และวันที่เป็น ISO string.
SQLite สร้าง ID แบบ integer แล้วแปลงเป็น String ให้โมเดลเดิม

```bash
flutter analyze
flutter test
```

Service tests ใช้ SQLite จริงในไฟล์ชั่วคราว และตรวจว่าข้อมูลยังอยู่หลังปิดเปิดฐานข้อมูล

## โครงสร้างหน้าและ navigation

`main.dart` เริ่มแอป → `app/app.dart` ตั้ง theme และภาษา →
`app/app_shell.dart` ดูแล AppBar, เมนูล่าง และการสลับหน้า

แต่ละหน้ามีไฟล์ของตัวเองใน `lib/features/`:

- `home/screens/home_screen.dart`: ภาพรวมและปุ่มไปหน้างาน
- `todo/screens/todo_screen.dart`: รายการงาน ค้นหา กรอง เรียง และเพิ่ม/แก้ไข/ลบ
- `stats/screens/stats_screen.dart`: จำนวนงานแต่ละสถานะ
- `settings/screens/settings_screen.dart`: ตั้งค่าภาษาและ theme

Component ที่ใช้ร่วมกันอยู่ใน `lib/shared/widgets/` ส่วน widget เฉพาะงาน
อยู่ใน `lib/features/todo/widgets/`

ตอนนี้สลับแท็บด้วย `IndexedStack` ซึ่งเก็บ state ของหน้าไว้ เช่น คำค้นหา
และแท็บรายการงานที่เลือก ยังไม่มี URL routes หรือ `app_router.dart`

## Daily Summary notifications

Settings มี **Daily Summary** (เริ่มต้น OFF) และ **Reminder Time**
(เริ่มต้น 09:00) รองรับ Android/iOS และขอ notification permission
เฉพาะเมื่อผู้ใช้เปิดฟีเจอร์ หากปฏิเสธสิทธิ์ switch จะยังเป็น OFF
และมีข้อความให้อนุญาตใน Settings ของอุปกรณ์แล้วลองใหม่

นับเฉพาะ Todo ที่ยังไม่เสร็จและมี Due Date โดยเทียบวันตามปฏิทิน
เหมือนที่แสดงใน UI งานไม่มีวันที่ไม่นับ และไม่มี notification ต่อ task:

- วันนี้มี 4 งาน · เลยกำหนด 2 งาน
- วันนี้ไม่มีงาน · เลยกำหนด 2 งาน
- วันนี้ไม่มีงาน 🎉 วางแผนงานถัดไปกันไหม

ระบบคำนวณข้อความแยกแต่ละวันและตั้ง local notification ล่วงหน้า 30 วัน
แล้วสร้างตารางใหม่หลังเพิ่ม/แก้ไข/ลบ/เปลี่ยนสถานะ Todo เปลี่ยนเวลา/ภาษา
หรือกลับเข้าแอป โดยอ่านข้อมูลจาก SQLite ทั้งหมด ไม่อิง filter/search
ในหน้ารายการ เมื่อปิดฟีเจอร์จะยกเลิก pending Daily Summary เท่านั้น
หากเปิดหลังเวลาของวันนั้นแล้ว รอบแรกจะเป็นวันถัดไป

ระบบบันทึกวันที่และเวลาที่ตั้งไว้เพื่อกันการแจ้งซ้ำเมื่อเปลี่ยนเวลา
หลังรอบของวันนั้นผ่านไป โดยถือว่ารอบที่ผ่านไปแล้วถูกใช้ แม้ OS
อาจยังไม่ได้ส่งจริง จึงเน้นไม่ส่งซ้ำมากกว่าการส่งชดเชย

ข้อจำกัดของรุ่นแรก:

- หากไม่กลับเข้าแอปเกินช่วงที่ตั้งล่วงหน้า การแจ้งเตือนจะหยุดจนเปิดแอปอีกครั้ง
- Android ใช้ `inexactAllowWhileIdle` ไม่ขอ exact-alarm permission เพิ่ม
  จึงอาจส่งช้ากว่าเวลาที่เลือกจาก Doze/การประหยัดพลังงาน
- รองรับการส่งจากตารางที่ OS เก็บไว้ขณะแอปไม่ทำงาน และ Android
  มี receiver ตั้งตารางคืนหลัง reboot/update แต่ force-stop และข้อจำกัด
  background ของผู้ผลิตอาจขัดขวางการส่ง ต้องทดสอบบนอุปกรณ์จริง
- timezone และภาษาจะปรับตารางเมื่อกลับเข้าแอป ไม่ใช่ background polling
- เว็บและ desktop แสดงว่าฟีเจอร์ยังไม่รองรับ

ตรวจ logic ด้วย `flutter test` และ `flutter analyze` ส่วน native smoke test:
เปิดฟีเจอร์ ตั้งเวลาถัดไป สร้างงานวันนี้/เลยกำหนด/ไม่มีวันที่
ตรวจจำนวนหลังแก้ไขและทำเสร็จ จากนั้น background/ปัดแอปออกและรอแจ้งเตือน
ตรวจปิดฟีเจอร์ เปลี่ยนเวลาหลังรอบเดิม และ reboot แยกกัน

## Dev: Test Notification

รันผ่าน VS Code configuration `Flutter (dev)` เพื่อเปิด `DEV_TOOLS=true`
แล้วไป Settings → **Test Notification** (ภาษาไทย: **ทดสอบแจ้งเตือน**)
ปุ่มนี้แสดงเฉพาะ debug build ที่เปิด flag และใช้ได้บน Android/iOS
Chrome ยังรันได้ แต่ปุ่มทดสอบจะใช้งานไม่ได้เพราะฟีเจอร์รองรับมือถือเท่านั้น

กดเพื่อแสดงข้อความตัวอย่าง `วันนี้มี 4 งาน · เลยกำหนด 2 งาน` ทันที
โดยใช้ icon/channel เดียวกับ Daily Summary และใช้ ID แยกต่างหาก
ไม่เปลี่ยน switch เวลา ตาราง 30 วัน หรือวันที่ใช้รอบแจ้งเตือนแล้ว
หากยังไม่มีสิทธิ์จะขอเมื่อกดปุ่ม ปฏิเสธแล้ว Daily Summary ยังเป็น OFF
ดู notification ได้ในแถบแจ้งเตือน; Android channel ปัจจุบันไม่ได้รับประกัน
ว่าจะมี heads-up banner เด้งด้านบน

```bash
flutter run --dart-define=DEV_TOOLS=true
flutter test --dart-define=DEV_TOOLS=true test/daily_summary_controller_test.dart test/daily_summary_settings_test.dart
```

Release build ซ่อนปุ่มและปิดการเรียกทดสอบ แม้ส่ง `DEV_TOOLS=true`
ปุ่มนี้ใช้ตรวจหน้าตาและการแสดงทันที ส่วนการส่งเมื่อแอปปิดให้ทดสอบ
Daily Summary ตามขั้นตอนด้านบน

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

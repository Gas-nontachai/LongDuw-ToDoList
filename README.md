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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

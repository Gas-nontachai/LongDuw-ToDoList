# my_first_flutter_app

A new Flutter project.

## Run with environment config

The API base URL is required and read from the `API_BASE_URL` compile-time
define. There is no fallback URL in the application code.

คัดลอก `config/dev.example.json` เป็น `config/dev.json` แล้วใส่ค่า environment
ที่ต้องการก่อนรัน โปรเจกต์จะไม่ commit ไฟล์ `config/*.json` จริงลง Git

```bash
flutter run --dart-define-from-file=config/dev.json
```

ใน VS Code ให้เปิด Run and Debug แล้วเลือก `Flutter (dev)` หรือ
`Flutter (dev): Chrome` จากไฟล์ `.vscode/launch.json`

For another environment, create a JSON file with the same key and pass it to
`--dart-define-from-file`:

```json
{
  "API_BASE_URL": "https://example.com/api/v1"
}
```

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

# ลองดูว - To Do List

A new Flutter project.

## Onboarding และธีม

การติดตั้งใหม่เริ่มด้วยภาษาไทยและธีมตามระบบ มี 4 ขั้น: Welcome → ภาษา/ธีม
→ สรุปงานประจำวัน → เพิ่มงานแรก ข้ามได้โดยไม่ขอสิทธิ์แจ้งเตือน
เมื่อเปิด Daily Summary จึงตรวจสิทธิ์เดิมหรือเรียก dialog ของระบบ
หากปฏิเสธหรือตั้งแจ้งเตือนไม่สำเร็จยังเข้าแอปต่อได้

สถานะและขั้นปัจจุบันเก็บใน `app_metadata` ของเครื่อง เปิดใหม่แล้วกลับมาต่อได้
งานแรกและสถานะจบบันทึกใน transaction เดียว สถานะนี้ไม่รวมใน backup
และไม่ถูกล้างเมื่อ restore ผู้ใช้เดิมเข้า Home และคงค่าที่เคยเลือกไว้
Settings → ดูคำแนะนำอีกครั้ง เปิด flow ใหม่ด้วยค่าปัจจุบัน
และข้ามขั้นงานแรกหากมีงานอยู่แล้ว

Onboarding และ Settings เลือกธีมได้ครบ ตามระบบ/สว่าง/มืด
เปลี่ยนภาษาจากสองจุดนี้ได้เช่นกัน แถบด้านบนแสดงเฉพาะชื่อหน้าและภาพรวมงาน
โหมดตามระบบใช้ `ThemeMode.system` และตอบสนองต่อธีมเครื่องอัตโนมัติ

```bash
flutter analyze
flutter test
flutter test integration_test/onboarding_native_test.dart -d <device-id>
```

Native smoke test ใช้ฐานข้อมูลชั่วคราวและ notification ID/channel แยก
ตรวจการตั้งตารางจริง เพิ่มงานแรก และเปิดแอปใหม่ โดยไม่ทับข้อมูลปกติ
หากยังไม่มีสิทธิ์ให้อนุญาตผ่าน dialog ระบบระหว่างทดสอบ
ภาพตรวจหน้าจอเก็บใน `onboarding_previews` ภายใต้ cache ของแอป
CI ที่เตรียมสิทธิ์ผ่าน test runner ใช้ `--dart-define=PREGRANTED_NOTIFICATIONS=true`
แล้ว grant `android.permission.POST_NOTIFICATIONS` หลัง log `READY_FOR_NOTIFICATION_GRANT`
กรณีปฏิเสธสิทธิ์และ scheduling failure ตรวจด้วย widget/controller tests

## Android CI and APK releases

PR และ push เข้า `main` จะตรวจ analyze และ test ด้วย GitHub Actions
เมื่อต้องการแจก APK ให้ push tag เช่น `v1.0.0` ที่ตรงกับ version ใน pubspec
ระบบจะ build, sign และแนบ APK ใน GitHub Release หลังตรวจผ่าน
ต้องตั้ง signing Secrets ก่อน release ครั้งแรก ดูขั้นตอนทั้งหมดที่
[Android APK release](docs/android-release.md)

## App icon

หัวแอปและหน้ารายละเอียดงานใช้โลโก้ `no-text` แบบ WebP โปร่งใส
ใน `assets/icons/longduw_logo/` ส่วน PNG เป็นต้นฉบับสำหรับไอคอนที่ build
ทั้งสองไฟล์ตัดพื้นที่ว่างรอบโลโก้แล้วเพื่อให้แสดงชัดที่ขนาดเล็ก
โลโก้ใช้โทน teal ตามสีหลักของธีม `#007F78` ร่วมกับกระดาษสีขาว
และสีเขียวหม่นอ่อนด้านหลัง พื้นด้านนอกโลโก้ยังโปร่งใส

สร้างไอคอน Android (รวม adaptive icon), iOS, macOS, Windows และเว็บใหม่ด้วย:

```bash
flutter pub get
dart run tool/generate_app_icons.dart
```

ตั้งค่าอยู่ใน `flutter_launcher_icons.yaml` สคริปต์เพิ่มระยะขอบให้ไอคอนเว็บ
แบบ maskable เพื่อรองรับการตัดเป็นวงกลม และไฟล์ไอคอนที่สร้างแล้วเก็บใน Git
จึง build ได้โดยไม่ต้องรัน generator ทุกครั้ง หากเปลี่ยนโลโก้ ให้อัปเดต PNG
และ WebP แล้วรันคำสั่งข้างต้นอีกครั้ง iOS ใช้พื้นหลังทึบตามข้อกำหนดแพลตฟอร์ม
Linux ใช้ PNG ใน Flutter asset bundle เป็นไอคอนหน้าต่าง

## Run with local SQLite

Todo เก็บใน SQLite ในเครื่อง ไม่ต้องตั้ง `API_BASE_URL` หรือเปิด server:

```bash
flutter pub get
flutter run
```

มือถือและ macOS ใช้ `sqflite`; Windows/Linux ใช้ `sqflite_common_ffi`.
ฐานข้อมูล `todos.db` อยู่ใน application support directory และสร้างตารางเอง
เมื่อเปิดครั้งแรก ข้อมูลยังอยู่เมื่อปิดเปิดแอป แต่ไม่ได้ซิงก์ข้ามเครื่องอัตโนมัติ
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

## Backup & Restore (Android / iOS)

Settings → **Data & Backup** สร้างไฟล์ `todo_backup_YYYY-MM-DD.todo`
ผ่าน native Save dialog หรือเลือก `.todo` กลับมา Restore แบบ **Replace All**
ต้องผ่าน preview และยืนยันอีกครั้งก่อนแทนที่ข้อมูล ไม่มี Merge
เว็บและ desktop ซ่อน section นี้ใน MVP

ไฟล์เก็บ Todo ทุกฟิลด์, Theme/Language (รวมค่าตามระบบ), Daily Summary
และ Reminder Time เป็น JSON package version 1 พร้อม database version,
app version, UTC creation time และ SHA-256 checksum ของ metadata/payload
ไฟล์ไม่ได้เข้ารหัส และ checksum ใช้ตรวจความเสียหาย ไม่ใช่ลายเซ็นยืนยันผู้สร้าง
ไฟล์จาก version ที่ไม่มี decoder จะถูกปฏิเสธก่อนเปลี่ยนข้อมูลใด ๆ

SQLite schema version 2 เก็บ settings และ notification runtime เพิ่มจาก Todos
เมื่อเปิดแอพจะย้าย Shared Preferences เดิมครั้งเดียวใน transaction
แล้วใช้ SQLite เป็นแหล่งข้อมูลหลัก ไม่ดึงค่าที่ค้างอยู่ใน storage เดิมกลับมาทับ
Backup/Restore, Todo writes, settings writes และ scheduling ใช้ operation gate
ร่วมกัน Restore เปลี่ยน Todo/settings ใน SQLite transaction เดียว
หากแอพปิดก่อน commit ข้อมูลเดิมยังอยู่ หลัง commit เปิดใหม่จะใช้ข้อมูลชุดใหม่

ไม่ย้าย permission หรือตารางแจ้งเตือนของเครื่องเดิม หลัง Restore จะตั้ง Daily Summary
ใหม่ตามภาษา เวลาและ timezone ของเครื่องปลายทาง หากสิทธิ์ถูกปฏิเสธหรือ OS scheduling
ล้มเหลว Todo/settings ที่กู้คืนจะยังอยู่ พร้อมข้อความและ Retry
marker ใน SQLite ทำให้ลองตั้งตารางต่อเมื่อกลับเข้าแอพหรือเปิดใหม่ได้
หลังสำเร็จ Theme/Language และ providers อัปเดตทันที พร้อมล้าง search/filter ของหน้ารายการ

```bash
flutter analyze
flutter test
flutter test --dart-define=DEV_TOOLS=true test/daily_summary_controller_test.dart test/daily_summary_settings_test.dart
```

Native file-dialog smoke test ใช้ฐานข้อมูลชั่วคราวแยกจากข้อมูลปกติของแอพ:

```bash
flutter test integration_test/backup_native_test.dart -d <device-id>
```

ระหว่างทดสอบให้ควบคุม native dialogs บนอุปกรณ์: Cancel save ครั้งแรก →
Save `todo_native_smoke.todo` ลง Files/Downloads ครั้งที่สอง → เลือกไฟล์นั้นกลับมา
test จะตรวจ round trip และเปิดฐานข้อมูลใหม่ แล้วลบเฉพาะฐานข้อมูลทดสอบชั่วคราว
ไฟล์ `.todo` ที่บันทึกไว้ยังอยู่สำหรับทดสอบข้าม Android/iOS
ต้องทดสอบ cloud providers ที่ติดตั้งบนเครื่องจริงแยกเพิ่มเติม
บน Android OS อาจไม่รู้จัก MIME ของ `.todo` ทำให้ picker แสดงไฟล์ชนิดอื่นด้วย
แอพจึงตรวจนามสกุลและเนื้อหาซ้ำก่อนอนุญาต Restore

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

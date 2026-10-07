# Android APK release

Workflow ของโปรเจกต์:

```text
feat/* หรือ fix/* → PR → analyze + test → main
                                        ↓ พร้อมแจก
                                   tag v1.0.0
                                        ↓
                         build + sign → GitHub Release + APK
```

## ตั้งค่าครั้งแรก

### 1. สร้าง signing key

ถ้าเคยแจกแอปด้วย release key แล้ว ให้ใช้ key เดิม ไม่สร้างใหม่
คำสั่งนี้สร้าง key สำหรับแจก APK โดยตรง ไม่ต้องมีบัญชี Play Console:

```bash
mkdir -p android/keystores
keytool -genkeypair -v -keystore android/keystores/longduw-release.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias longduw
```

กรอกรหัสผ่านและข้อมูล certificate ใน prompt ของ `keytool`
บน macOS ถ้าไม่พบ Java ให้ใช้ keytool จาก Android Studio:
`/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool`
สำรอง keystore, alias และรหัสผ่านไว้ในที่ปลอดภัยนอก repo
ไฟล์ `.jks`, `.keystore` และ `android/key.properties` ถูก ignore แล้ว
อย่า commit key หรือรหัสผ่าน และอย่าส่งค่าลับมาใน chat

### 2. เพิ่ม GitHub Actions Secrets

เปิด repository → **Settings → Secrets and variables → Actions → Secrets**
แล้วเพิ่ม Repository secrets:

| ชื่อ | ค่า |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | เนื้อหา keystore ที่แปลงเป็น Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | รหัสผ่าน keystore |
| `ANDROID_KEY_ALIAS` | `longduw` หรือ alias ของ key เดิม |
| `ANDROID_KEY_PASSWORD` | รหัสผ่านของ key |

บน macOS คัดลอก Base64 เข้า clipboard โดยไม่แสดงค่าบน terminal:

```bash
base64 -i android/keystores/longduw-release.jks | pbcopy
```

วางลงใน secret `ANDROID_KEYSTORE_BASE64` แล้วล้าง clipboard เมื่อเสร็จ
Base64 ไม่ใช่การเข้ารหัส อย่าเก็บข้อความนี้ใน repo
workflow ใช้ `GITHUB_TOKEN` ที่ GitHub สร้างให้เพื่อสร้าง Release
ไม่ต้องเพิ่ม personal access token แต่ repo/organization ต้องอนุญาต
workflow ขอ `contents: write` ได้

ก่อนแจกครั้งแรก ตรวจ application ID ใน `android/app/build.gradle.kts`
ตอนนี้เป็น `com.example.longdow_todo_list` ถ้าจะเปลี่ยนให้ทำก่อนเริ่มแจก
หลังแจกแล้วควรคง application ID และ signing key เดิมเพื่อให้อัปเดตทับได้

## พัฒนาและรวมงาน

แตก branch จาก `main` ตามงาน เปิด PR แล้วให้ workflow **Flutter CI**
ตรวจ analyze, unit/widget tests และ notification tests ที่เปิด `DEV_TOOLS`
CI รันซ้ำเมื่อ push เข้า `main` แต่ยังไม่สร้าง Release
ถ้าต้องการบังคับตรวจผ่านก่อน merge ให้ตั้ง branch protection/ruleset
สำหรับ `main` และเลือก check `check` ของ Flutter CI

CI pin Flutter `3.47.6` ให้ตรงกับ SDK ที่ใช้ในโปรเจกต์ตอนตั้งค่า
ถ้าอัปเกรด SDK ให้อัปเดตทั้ง `ci.yml` และ `android-release.yml`
พร้อมอัปเดต `pubspec.lock` และตรวจโค้ดก่อน merge

## ปล่อย APK

1. รวมการเปลี่ยนแปลงผ่าน PR เข้า `main` ไม่ต้องแก้ version ใน `pubspec.yaml`
   ทุกครั้งที่ release; CI ใช้เวอร์ชันจาก tag และคำนวณเลข build อัตโนมัติ
2. ทดสอบฟีเจอร์บน Android จริง รวมถึง notification และ backup/restore
   unit/widget tests ใน CI ไม่ครอบคลุม native dialogs หรือการแจ้งเตือนจริง
3. ดึง `main` ล่าสุดและติด tag ให้ commit ที่ผ่านการทดสอบ:

```bash
git switch main
git pull --ff-only
git tag v1.0.1
git push origin v1.0.1
```

workflow **Android APK Release** ตรวจว่า commit อยู่ในประวัติ `main`
และ tag รูปแบบ `vMAJOR.MINOR.PATCH` โดยใช้เวอร์ชันจาก tag เป็นเวอร์ชัน APK
จากนั้นตรวจโค้ด, build universal APK แบบ release, sign ด้วย key จาก Secrets,
ตรวจลายเซ็น APK และสร้าง GitHub Release พร้อม APK และ `SHA256SUMS`
APK เดียวรองรับสถาปัตยกรรม Android ที่ Flutter build รวมไว้
ไม่สร้าง AAB และไม่อัปโหลด Play Store

เลข build = `github.run_number` ของ release workflow + offset (ค่าเริ่มต้น `1`)
ดังนั้น run แรกเป็น build `2` และการ rerun ของ run เดิมใช้เลขเดิม
ถ้าเคยแจก build ที่สูงกว่านี้ หรือต้องสร้าง workflow ใหม่จนเลข run เริ่มใหม่
ให้เพิ่ม Repository **Variable** `ANDROID_BUILD_NUMBER_OFFSET`
เพื่อให้เลข build ใหม่สูงกว่าทุก build ที่เคยแจก อย่าลด offset หลังเริ่มแจก
CI ไม่แก้หรือ commit เวอร์ชันหรือเลข build กลับเข้า repo
version ใน `pubspec.yaml` ใช้สำหรับ local build และไม่ต้องตรงกับ release tag
แต่เลข build ของ CI ต้องสูงกว่าเลขหลัง `+` ใน `pubspec.yaml` ด้วย

เมื่อสำเร็จ เปิดหน้า **Releases → Assets** แล้วดาวน์โหลด `longduw-1.0.1.apk`
repo private ต้องมีสิทธิ์เข้าถึงจึงดาวน์โหลดได้ ผู้ติดตั้งต้องอนุญาต
ติดตั้งแอปจาก browser/file manager ที่ใช้เปิด APK

ถ้า workflow ล้มเหลวก่อนสร้าง Release แก้ปัญหาแล้ว rerun ได้
หากต้องแก้ source ให้ merge การแก้และใช้ version/tag ใหม่
workflow ไม่แทนที่ APK ใน Release ที่มีอยู่แล้ว และไม่ควรย้าย tag ที่เผยแพร่แล้ว

## Build release บนเครื่องตัวเอง

สร้าง `android/key.properties` (ไม่ commit) โดยใช้ path เต็มของ keystore:

```properties
storeFile=/absolute/path/to/longduw-release.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=longduw
keyPassword=YOUR_KEY_PASSWORD
```

แล้วรัน:

```bash
flutter build apk --release --build-number=2
```

เลือก build number ให้สูงกว่าที่แจกไปแล้ว ไฟล์อยู่ที่
`build/app/outputs/flutter-apk/app-release.apk`
release build ต้องมี signing configuration และไม่ fallback ไป debug key
ส่วน `flutter run` แบบ debug ยังใช้ debug key ตามปกติ
หากเคยลงแอปด้วย debug key อาจต้องสำรองข้อมูลและถอน debug app
ก่อนลง release ครั้งแรก เพราะลายเซ็นต่างกัน

อ้างอิง: [Flutter Android deployment](https://docs.flutter.dev/deployment/android)
และ [Android app signing](https://developer.android.com/studio/publish/app-signing)

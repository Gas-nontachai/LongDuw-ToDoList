// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'ลองดูว - To Do List';

  @override
  String get addTodo => 'เพิ่มรายการ';

  @override
  String get editTodo => 'แก้ไขรายการ';

  @override
  String get deleteTodoQuestion => 'ลบรายการนี้หรือไม่?';

  @override
  String removeTodoConfirmation(String title) {
    return 'ต้องการลบ \"$title\" หรือไม่?';
  }

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get save => 'บันทึก';

  @override
  String get title => 'ชื่อรายการ';

  @override
  String get details => 'รายละเอียด';

  @override
  String get enterTitle => 'กรุณาใส่ชื่อรายการ';

  @override
  String get enterDetails => 'กรุณาใส่รายละเอียด';

  @override
  String get searchTodosHint => 'พิมพ์คำค้นหา';

  @override
  String get clearSearchTooltip => 'ล้างคำค้นหา';

  @override
  String get status => 'สถานะ';

  @override
  String get priority => 'ความสำคัญ';

  @override
  String get priorityLow => 'ต่ำ';

  @override
  String get priorityMedium => 'ปานกลาง';

  @override
  String get priorityHigh => 'สูง';

  @override
  String get dueDate => 'วันครบกำหนด';

  @override
  String get selectDueDate => 'เลือกวันครบกำหนด';

  @override
  String get clearDueDate => 'ล้างวันครบกำหนด';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get completed => 'เสร็จแล้ว';

  @override
  String get incomplete => 'ยังไม่เสร็จ';

  @override
  String get noTodosYet => 'ยังไม่มีรายการ เพิ่มรายการแรกเลย!';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get couldNotLoadTodos => 'ไม่สามารถโหลดรายการได้';

  @override
  String get todoAdded => 'เพิ่มรายการแล้ว';

  @override
  String get todoUpdated => 'อัปเดตรายการแล้ว';

  @override
  String get todoDeleted => 'ลบรายการแล้ว';

  @override
  String get savingData => 'กำลังบันทึกข้อมูล...';

  @override
  String get somethingWentWrong => 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';

  @override
  String get addTodoTooltip => 'เพิ่มรายการ';

  @override
  String get editTooltip => 'แก้ไข';

  @override
  String get deleteTooltip => 'ลบ';

  @override
  String get dismissTooltip => 'ปิด';

  @override
  String get changeLanguage => 'เปลี่ยนภาษา';

  @override
  String get switchToLightMode => 'เปลี่ยนเป็นโหมดสว่าง';

  @override
  String get switchToDarkMode => 'เปลี่ยนเป็นโหมดมืด';

  @override
  String get english => 'English';

  @override
  String get thai => 'ไทย';

  @override
  String get sortTodosTooltip => 'เรียงลำดับรายการ';

  @override
  String get sortOriginal => 'ลำดับเดิม';

  @override
  String get sortTitleAscending => 'ชื่อ: ก → ฮ / A → Z';

  @override
  String get sortTitleDescending => 'ชื่อ: ฮ → ก / Z → A';

  @override
  String get createdAt => 'วันที่สร้าง';

  @override
  String get todoId => 'รหัสรายการ';

  @override
  String get notSpecified => 'ไม่ได้ระบุ';

  @override
  String get viewTodo => 'ดู';

  @override
  String get moreActions => 'เมนูเพิ่มเติม';

  @override
  String taskCount(int count) {
    return 'เหลืออีก $count งาน';
  }

  @override
  String get dueToday => 'ครบกำหนดวันนี้';

  @override
  String daysRemaining(int count) {
    return 'เหลืออีก $count วัน';
  }

  @override
  String overdueDays(int count) {
    return 'เกินกำหนด $count วัน';
  }

  @override
  String get filterTodos => 'ตัวกรอง';

  @override
  String get resetQuery => 'รีเซ็ต';

  @override
  String applyFilters(int count) {
    return 'ใช้ตัวกรอง ($count)';
  }

  @override
  String get applySort => 'ใช้การจัดเรียง';

  @override
  String get sortBy => 'เรียงตาม';

  @override
  String get filterOverdue => 'เลยกำหนด';

  @override
  String get filterToday => 'วันนี้';

  @override
  String get filterSevenDays => 'ภายใน 7 วัน';

  @override
  String get filterThreeDays => 'ภายใน 3 วัน';

  @override
  String get duePresenceTitle => 'มีวันครบกำหนดหรือไม่';

  @override
  String get hasDueDate => 'มีวันกำหนด';

  @override
  String get noDueDate => 'ไม่กำหนดวัน';

  @override
  String get dateRangeTitle => 'ช่วงวันที่';

  @override
  String get selectDateRange => 'เลือกช่วงวันที่';

  @override
  String get clearDateRange => 'ล้างช่วงวันที่';

  @override
  String get sortDueAscending => 'วันครบกำหนด (ใกล้สุดก่อน)';

  @override
  String get sortDueDescending => 'วันครบกำหนด (ไกลสุดก่อน)';

  @override
  String get sortPriorityDescending => 'ความสำคัญ (สูง → ต่ำ)';

  @override
  String get sortPriorityAscending => 'ความสำคัญ (ต่ำ → สูง)';

  @override
  String get sortCreatedDescending => 'วันที่สร้าง (ใหม่สุดก่อน)';

  @override
  String get sortCreatedAscending => 'วันที่สร้าง (เก่าสุดก่อน)';

  @override
  String get noMatchingTodos => 'ไม่พบงานที่ตรงกับคำค้นหาหรือตัวกรอง';

  @override
  String get expandSheet => 'ขยายเต็มจอ';

  @override
  String get collapseSheet => 'ย่อหน้าต่าง';

  @override
  String get navHome => 'หน้าแรก';

  @override
  String get navTasks => 'งาน';

  @override
  String get navStats => 'สถิติ';

  @override
  String get navSettings => 'ตั้งค่า';

  @override
  String get dailySummary => 'สรุปงานรายวัน';

  @override
  String get reminderTime => 'เวลาแจ้งเตือน';

  @override
  String dailySummaryCounts(int today, int overdue) {
    return 'วันนี้มี $today งาน · เลยกำหนด $overdue งาน';
  }

  @override
  String dailySummaryOverdue(int overdue) {
    return 'วันนี้ไม่มีงาน · เลยกำหนด $overdue งาน';
  }

  @override
  String get dailySummaryEmpty => 'วันนี้ไม่มีงาน 🎉 วางแผนงานถัดไปกันไหม';

  @override
  String get dailySummaryUnsupported => 'รองรับบน Android และ iOS';

  @override
  String get dailySummaryPermissionDenied =>
      'ยังไม่ได้รับสิทธิ์แจ้งเตือน กรุณาอนุญาตในการตั้งค่าอุปกรณ์แล้วลองใหม่';

  @override
  String get dailySummaryFailed => 'อัปเดตการแจ้งเตือนไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get testNotification => 'ทดสอบแจ้งเตือน';

  @override
  String get testNotificationDescription =>
      'แสดงข้อความตัวอย่างทันที (เฉพาะโหมด dev)';

  @override
  String get testNotificationSent =>
      'ส่งแจ้งเตือนทดสอบแล้ว ดูได้ในแถบแจ้งเตือน';

  @override
  String get testNotificationFailed =>
      'แสดงแจ้งเตือนทดสอบไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get homeToday => 'วันนี้';

  @override
  String get homeViewAll => 'ดูทั้งหมด';

  @override
  String get homeOverview => 'ภาพรวม';

  @override
  String get homeNoTasksToday => 'ไม่มีงานครบกำหนดวันนี้';

  @override
  String homeDueSummary(int today, int overdue) {
    return 'ครบกำหนดวันนี้ $today · เกินกำหนด $overdue';
  }

  @override
  String homeCompletedProgress(int completed, int total) {
    return 'เสร็จแล้ว $completed จาก $total งาน';
  }

  @override
  String get statsSubtitle => 'ภาพรวมการทำงานของคุณ';

  @override
  String get statsTotalTasks => 'งานทั้งหมด';

  @override
  String get statsRemaining => 'งานคงเหลือ';

  @override
  String get statsCompletionRate => 'อัตรางานสำเร็จ';

  @override
  String get statsByPriority => 'งานตามความสำคัญ';

  @override
  String get statsByDueDate => 'งานตามวันครบกำหนด';

  @override
  String get statsIncompleteOnly => 'เฉพาะงานที่ยังไม่เสร็จ';

  @override
  String get statsDueSoon => 'ครบกำหนดใน 1–7 วัน';

  @override
  String get statsLater => 'เกิน 7 วัน';

  @override
  String get dataAndBackup => 'ข้อมูลและการสำรองข้อมูล';

  @override
  String get backupData => 'สำรองข้อมูล';

  @override
  String get backupDataSubtitle => 'สร้างสำเนาข้อมูลทั้งหมดของแอพ';

  @override
  String get restoreBackup => 'กู้คืนข้อมูลสำรอง';

  @override
  String get restoreBackupSubtitle => 'แทนที่ข้อมูลปัจจุบันด้วยข้อมูลสำรอง';

  @override
  String get backupDescription =>
      'สร้างข้อมูลสำรองของทุกอย่างที่เก็บไว้ในแอพนี้';

  @override
  String get backupIncluded => 'ข้อมูลที่รวมอยู่';

  @override
  String get backupAppSettings => 'การตั้งค่าแอพ';

  @override
  String get backupNotificationSettings => 'การตั้งค่าการแจ้งเตือน';

  @override
  String get backupFileName => 'ไฟล์สำรองข้อมูล';

  @override
  String get createBackup => 'สร้างข้อมูลสำรอง';

  @override
  String get creatingBackup => 'กำลังสร้างข้อมูลสำรอง…';

  @override
  String get preparingBackup => 'กำลังเตรียมข้อมูลของคุณ';

  @override
  String get savingBackup => 'บันทึกข้อมูลสำรอง';

  @override
  String get selectBackupFile => 'เลือกไฟล์สำรองข้อมูล';

  @override
  String get checkingBackup => 'กำลังตรวจสอบข้อมูลสำรอง…';

  @override
  String get backupCreated => 'สร้างข้อมูลสำรองแล้ว';

  @override
  String get backupCreatedDescription => 'สำรองข้อมูลของคุณเรียบร้อยแล้ว';

  @override
  String get backupDone => 'เสร็จสิ้น';

  @override
  String get backupCreatedDate => 'สร้างเมื่อ';

  @override
  String get backupContains => 'ข้อมูลในไฟล์';

  @override
  String get restoreReplaceWarning =>
      'การกู้คืนจะแทนที่ข้อมูลปัจจุบันทั้งหมดบนอุปกรณ์นี้';

  @override
  String get backupContinue => 'ดำเนินการต่อ';

  @override
  String get replaceCurrentData => 'แทนที่ข้อมูลปัจจุบันหรือไม่?';

  @override
  String get replaceCurrentDataDescription =>
      'การกู้คืนจะลบงานและการตั้งค่าปัจจุบันทั้งหมด แล้วแทนที่ด้วยข้อมูลสำรองนี้';

  @override
  String get restoreCannotUndo => 'การดำเนินการนี้ไม่สามารถย้อนกลับได้';

  @override
  String get replaceAndRestore => 'แทนที่และกู้คืน';

  @override
  String get restoringBackup => 'กำลังกู้คืนข้อมูลสำรอง…';

  @override
  String get restoreKeepOpen => 'โปรดเปิดแอพไว้จนกว่าจะเสร็จสิ้น';

  @override
  String get restoreTasksStage => 'กำลังแทนที่งาน';

  @override
  String get restoreSettingsStage => 'กำลังแทนที่การตั้งค่า';

  @override
  String get restoreComplete => 'กู้คืนข้อมูลสำเร็จ';

  @override
  String get restoreCompleteDescription => 'กู้คืนข้อมูลของคุณเรียบร้อยแล้ว';

  @override
  String get restoreAppSettingsComplete => 'กู้คืนการตั้งค่าแอพแล้ว';

  @override
  String get restoreNotificationsComplete => 'กู้คืนการตั้งค่าการแจ้งเตือนแล้ว';

  @override
  String get backupGoHome => 'ไปหน้าหลัก';

  @override
  String get invalidBackupTitle => 'ไม่สามารถกู้คืนข้อมูลสำรองได้';

  @override
  String get invalidBackupDescription =>
      'ไฟล์สำรองข้อมูลนี้ไม่ถูกต้องหรือเสียหาย ข้อมูลปัจจุบันของคุณไม่ได้ถูกเปลี่ยนแปลง';

  @override
  String get unsupportedBackupTitle => 'ไม่รองรับข้อมูลสำรองนี้';

  @override
  String get unsupportedBackupDescription =>
      'ข้อมูลสำรองนี้สร้างด้วยเวอร์ชันที่แอพไม่รองรับ ข้อมูลปัจจุบันของคุณไม่ได้ถูกเปลี่ยนแปลง';

  @override
  String get restoreFailedTitle => 'กู้คืนข้อมูลไม่สำเร็จ';

  @override
  String get restoreFailedDescription =>
      'ไม่สามารถกู้คืนข้อมูลสำรองนี้ได้ ข้อมูลเดิมของคุณยังอยู่ครบ';

  @override
  String get chooseAnotherBackup => 'เลือกไฟล์อื่น';

  @override
  String get backupFailedTitle => 'ไม่สามารถสร้างข้อมูลสำรองได้';

  @override
  String get backupFailedDescription =>
      'ไม่สามารถสร้างหรือบันทึกข้อมูลสำรองได้ โปรดลองอีกครั้ง';

  @override
  String get restoreRefreshFailed =>
      'กู้คืนข้อมูลแล้ว แต่แอพโหลดข้อมูลใหม่ไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String backupTaskCount(int count) {
    return '$count งาน';
  }

  @override
  String restoreTaskCount(int count) {
    return 'กู้คืน $count งานแล้ว';
  }

  @override
  String get settingsAbout => 'เกี่ยวกับแอพ';

  @override
  String get settingsAppVersion => 'เวอร์ชันแอพ';
}

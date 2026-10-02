// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'รายการสิ่งที่ต้องทำ';

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
}

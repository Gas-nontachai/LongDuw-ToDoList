import 'package:flutter/material.dart';

class DateTimeUtils {
  DateTimeUtils._();

  /// Formats a calendar date using the app's current language.
  static String formatDate(
    DateTime? date, {
    required MaterialLocalizations localizations,
  }) => date == null ? '' : localizations.formatMediumDate(date);
}

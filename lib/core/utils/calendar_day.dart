/// Compare the calendar components shown in the UI, ignoring time and DST.
DateTime calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

int calendarDayKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

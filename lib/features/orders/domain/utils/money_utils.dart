import 'package:intl/intl.dart';

/// Server bilan mos pul yaxlitlash (2 kasr xona).
double roundMoney(num value) => (value * 100).round() / 100;

double parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String formatMoneyAmount(
  dynamic value, {
  required String localeTag,
  int decimalDigits = 0,
}) {
  final n = parseAmount(value);
  return NumberFormat.decimalPatternDigits(
    locale: localeTag,
    decimalDigits: decimalDigits,
  ).format(n);
}

String localeTagFrom(String languageCode, [String? countryCode]) {
  if (countryCode != null && countryCode.isNotEmpty) {
    return '${languageCode}_$countryCode';
  }
  return languageCode;
}

String toDateString(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Web `datetime-local` / backend payment `paid_at` format: `YYYY-MM-DDTHH:mm`.
String toLocalDateTimeString(DateTime dateTime) {
  final y = dateTime.year;
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final h = dateTime.hour.toString().padLeft(2, '0');
  final min = dateTime.minute.toString().padLeft(2, '0');
  return '$y-$m-${d}T$h:$min';
}

DateTime todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime tomorrowDateOnly() {
  return todayDateOnly().add(const Duration(days: 1));
}

String? formatDeliveryTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return raw;
}

DateTime? parseApiDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// API `YYYY-MM-DD` — vaqt mintaqasiga siljimasdan mahalliy sana.
DateTime? parseApiDateOnly(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final datePart = raw.split('T').first.trim();
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  return DateTime.tryParse(raw);
}

String formatDateOnlyLocale(
  String? raw, {
  required String localeTag,
}) {
  final dt = parseApiDateOnly(raw);
  if (dt == null) return raw ?? '';
  try {
    return DateFormat.yMMMd(localeTag).format(dt);
  } catch (_) {
    return DateFormat.yMMMd('uz').format(dt);
  }
}

String formatDateTimeLocale(
  String? raw, {
  required String localeTag,
  DateFormat? pattern,
}) {
  final dt = parseApiDateTime(raw);
  if (dt == null) return raw ?? '';
  final fmt = pattern ??
      DateFormat.yMMMd(localeTag).add_Hm();
  return fmt.format(dt.toLocal());
}

/// Pagination append — ID bo‘yicha dublikatlarni olib tashlaydi.
List<T> mergePaginatedItems<T>(
  List<T> existing,
  List<T> incoming, {
  required String Function(T item) idOf,
}) {
  final seen = existing.map(idOf).toSet();
  final merged = List<T>.from(existing);
  for (final item in incoming) {
    final id = idOf(item);
    if (seen.add(id)) {
      merged.add(item);
    }
  }
  return merged;
}

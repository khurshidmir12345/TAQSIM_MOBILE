import 'package:intl/intl.dart';

/// ISO-formatli `createdAt`'dan `HH:mm` ko'rinishidagi soatni qaytaradi.
///
/// Agar `iso` bo'sh / noto'g'ri formatda bo'lsa, `null` qaytaradi — chaqiruvchi
/// element shartli render qilishi uchun qulay.
///
/// UTC vaqtni qurilmaning mahalliy vaqtiga aylantiradi — foydalanuvchi
/// har doim o'z zona vaqtini ko'radi.
String? formatTimeHm(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  return DateFormat('HH:mm').format(dt.toLocal());
}

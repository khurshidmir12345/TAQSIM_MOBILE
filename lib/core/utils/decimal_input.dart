import 'package:flutter/services.dart';

/// O'nlik kasr uchun input formatter.
///
/// Foydalanuvchi vergul (`,`) yoki nuqta (`.`) kiritsa, ichki holatda doim
/// nuqtaga normallashtiradi va parser'lar (`double.parse`) bilan birga
/// to'g'ri ishlaydi.
///
/// Faqat raqamlar va bitta o'nlik ajratuvchi qabul qilinadi. Salbiy belgi
/// (`-`) ataylab qo'llab-quvvatlanmaydi — narx/miqdor manfiy bo'lmaydi.
///
/// Misollar:
///   "1,5"  -> "1.5"
///   "12,"  -> "12."  (foydalanuvchi yozayotganda saqlanadi)
///   ",5"   -> "0.5"
///   "1,2,3" -> "1.23"  (ikkinchi ajratuvchi tushib qoladi)
///   "1.2.3" -> "1.23"
///   "abc" -> ""
class DecimalTextInputFormatter extends TextInputFormatter {
  const DecimalTextInputFormatter({this.decimalDigits = 2});

  /// Nuqtadan keyingi maksimal raqamlar soni. `null` bo'lsa cheklanmaydi.
  final int? decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    final buffer = StringBuffer();
    var sawSeparator = false;
    var fractionLen = 0;
    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (ch == ',' || ch == '.') {
        if (sawSeparator) continue;
        sawSeparator = true;
        if (buffer.isEmpty) {
          buffer.write('0');
        }
        buffer.write('.');
        continue;
      }
      final code = ch.codeUnitAt(0);
      final isDigit = code >= 0x30 && code <= 0x39;
      if (!isDigit) continue;
      if (sawSeparator) {
        if (decimalDigits != null && fractionLen >= decimalDigits!) continue;
        fractionLen++;
      }
      buffer.write(ch);
    }

    final next = buffer.toString();
    if (next == raw) return newValue;

    var selection = newValue.selection.baseOffset;
    if (selection > next.length) selection = next.length;
    if (selection < 0) selection = next.length;
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: selection),
    );
  }
}

/// Foydalanuvchi kiritgan matnni `double` ga aylantiradi. Vergul/nuqtani
/// to'g'ri ishlaydi va bo'sh/noto'g'ri qiymatlarda `null` qaytaradi.
double? parseDecimalInput(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.replaceAll(',', '.');
  return double.tryParse(normalized);
}

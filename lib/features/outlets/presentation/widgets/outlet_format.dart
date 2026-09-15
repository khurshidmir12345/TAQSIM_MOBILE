import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';

String outletLocaleTag(BuildContext context) {
  final l = Localizations.localeOf(context);
  return l.countryCode != null && l.countryCode!.isNotEmpty
      ? '${l.languageCode}_${l.countryCode}'
      : l.languageCode;
}

/// `125000` → `125 000` (kasr bo'lsa 2 xona).
String outletMoney(BuildContext context, num value) {
  final tag = outletLocaleTag(context);
  final n = value.toDouble();
  if (n == n.truncateToDouble()) {
    return NumberFormat.decimalPattern(tag).format(n);
  }
  return NumberFormat.decimalPatternDigits(
    locale: tag,
    decimalDigits: 2,
  ).format(n);
}

String outletQty(BuildContext context, num value) =>
    outletMoney(context, value);

/// Do'kon valyutasi belgisi yoki "so'm".
String outletCurrency(WidgetRef ref, S s) {
  final sym = ref.read(shopProvider).selected?.currency?.symbol;
  return (sym != null && sym.isNotEmpty) ? sym : s.currency;
}

DateTime? outletParseDate(String raw) => DateTime.tryParse(raw);

/// `2026-09-15` → `15-sen, 2026` (lokal).
String outletDateLabel(BuildContext context, String raw) {
  final d = outletParseDate(raw);
  if (d == null) return raw;
  try {
    return DateFormat.yMMMd(outletLocaleTag(context)).format(d);
  } catch (_) {
    return DateFormat.yMMMd('uz').format(d);
  }
}

String outletDateLabelOf(BuildContext context, DateTime d) {
  try {
    return DateFormat.yMMMd(outletLocaleTag(context)).format(d);
  } catch (_) {
    return DateFormat.yMMMd('uz').format(d);
  }
}

import 'package:flutter/widgets.dart';

/// Backend `locale` query (xarajat kategoriyalari va category_label).
String expenseApiLocale(BuildContext context) {
  final l = Localizations.localeOf(context);
  final full = l.countryCode != null && l.countryCode!.isNotEmpty
      ? '${l.languageCode}_${l.countryCode}'
      : l.languageCode;
  const allowed = {'uz', 'ru', 'kk', 'ky', 'tr', 'uz_CYRL'};
  if (allowed.contains(full)) return full;
  if (allowed.contains(l.languageCode)) return l.languageCode;
  return 'uz';
}

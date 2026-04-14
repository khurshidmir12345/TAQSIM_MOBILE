import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/country_phone.dart';

/// O'zbekiston raqami uchun telefon input.
/// Faqat +998 format bilan ishlaydi — davlat tanlash olib tashlangan.
class CountryPhoneInput extends StatelessWidget {
  final TextEditingController phoneController;
  final String? Function(String?)? validator;

  const CountryPhoneInput({
    super.key,
    required this.phoneController,
    this.validator,
  });

  static const _uz = AppCountries.uz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        _PhoneMaskFormatter(_uz.phoneMask),
      ],
      validator: validator,
      decoration: InputDecoration(
        hintText: _uz.phoneMask.replaceAll('X', '0'),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_uz.flag, style: const TextStyle(fontSize: 22, height: 1.2)),
              const SizedBox(width: 6),
              Text(
                _uz.dialCode,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  final String mask;

  _PhoneMaskFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final maxDigits = mask.split('').where((c) => c == 'X').length;

    final limited = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    final result = StringBuffer();
    int digitIndex = 0;

    for (int i = 0; i < mask.length && digitIndex < limited.length; i++) {
      if (mask[i] == 'X') {
        result.write(limited[digitIndex++]);
      } else {
        result.write(mask[i]);
      }
    }

    final formatted = result.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/country_phone.dart';

class CountryPhoneInput extends StatefulWidget {
  final CountryPhone selectedCountry;
  final TextEditingController phoneController;
  final ValueChanged<CountryPhone> onCountryChanged;
  final String? Function(String?)? validator;

  const CountryPhoneInput({
    super.key,
    required this.selectedCountry,
    required this.phoneController,
    required this.onCountryChanged,
    this.validator,
  });

  @override
  State<CountryPhoneInput> createState() => _CountryPhoneInputState();
}

class _CountryPhoneInputState extends State<CountryPhoneInput> {
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CountryPickerSheet(
        selected: widget.selectedCountry,
        onSelect: (c) {
          widget.onCountryChanged(c);
          widget.phoneController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final country = widget.selectedCountry;

    return TextFormField(
      controller: widget.phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        _PhoneMaskFormatter(country.phoneMask),
      ],
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: country.phoneMask.replaceAll('X', '0'),
        prefixIcon: GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
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
                Text(country.flag,
                    style: const TextStyle(fontSize: 22, height: 1.2)),
                const SizedBox(width: 6),
                Text(
                  country.dialCode,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _CountryPickerSheet extends StatelessWidget {
  final CountryPhone selected;
  final ValueChanged<CountryPhone> onSelect;

  const _CountryPickerSheet({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Davlatni tanlang',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...AppCountries.all.map((country) {
            final isSelected = country.isoCode == selected.isoCode;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: Text(country.flag,
                  style: const TextStyle(fontSize: 28)),
              title: Text(
                country.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    country.dialCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ],
              ),
              onTap: () => onSelect(country),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Phone mask formatter ──────────────────────────────────────────────────

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

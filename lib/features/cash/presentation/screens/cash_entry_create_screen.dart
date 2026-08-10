import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/expense_api_locale.dart';
import '../../../home/domain/models/expense_category_option.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';

/// Kassaga qo'lda kirim yoki chiqim qo'shish.
///
/// Bitta ekran ikkala yo'nalishga xizmat qiladi — farqi faqat rang, sarlavha
/// va kategoriya ro'yxatida. Shu sababli foydalanuvchi bir xil oqimni
/// o'rganadi va xato qilmaydi.
class CashEntryCreateScreen extends ConsumerStatefulWidget {
  const CashEntryCreateScreen({super.key, required this.type});

  final CashType type;

  @override
  ConsumerState<CashEntryCreateScreen> createState() =>
      _CashEntryCreateScreenState();
}

class _CashEntryCreateScreenState extends ConsumerState<CashEntryCreateScreen> {
  final _amountCtl = TextEditingController();
  final _descriptionCtl = TextEditingController();
  final _amountFocus = FocusNode();

  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  bool get _isIncome => widget.type == CashType.income;

  Color get _accent => _isIncome ? AppColors.income : AppColors.error;

  @override
  void initState() {
    super.initState();
    // Summa — ekrandagi asosiy maydon, klaviatura darhol ochilsin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _descriptionCtl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double? get _amount {
    final raw = _amountCtl.text.replaceAll(RegExp(r'[^0-9.]'), '');

    return raw.isEmpty ? null : double.tryParse(raw);
  }

  bool get _canSave =>
      !_saving && (_amount ?? 0) > 0 && (_category ?? '').isNotEmpty;

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(cashProvider.notifier).create(
            type: widget.type,
            amount: _amount!,
            category: _category!,
            description: _descriptionCtl.text,
            date: _date,
          );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = S.of(context).noInternet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isIncome ? s.cashCreateIncomeTitle : s.cashCreateExpenseTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
        children: [
          _AmountField(
            controller: _amountCtl,
            focusNode: _amountFocus,
            accent: _accent,
            currency: s.currency,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _Label(s.expenseSelectCategory),
          const SizedBox(height: 8),
          _CategoryPicker(
            isIncome: _isIncome,
            selected: _category,
            accent: _accent,
            onSelected: (key) => setState(() => _category = key),
          ),
          const SizedBox(height: 18),
          _Label(s.reportPickSingleDate),
          const SizedBox(height: 8),
          _DateField(date: _date, onTap: _pickDate),
          const SizedBox(height: 18),
          _Label(s.expenseDescriptionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionCtl,
            maxLines: 2,
            maxLength: 200,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: s.cashDescriptionHint,
              counterText: '',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s.expenseSubmit,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summa maydoni — ekrandagi eng muhim element, shuning uchun katta.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.currency,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final String currency;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: accent,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: accent.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Text(
            currency,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kirim turlari serverdan, chiqim turlari mavjud xarajat kategoriyalaridan
/// olinadi — foydalanuvchi o'zi qo'shgan turlar ham shu yerda chiqadi.
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.isIncome,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final bool isIncome;
  final String? selected;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isIncome) {
      return ref.watch(cashIncomeCategoriesProvider).when(
            loading: () => const _PickerLoading(),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) => _Chips(
              options: [for (final c in list) (key: c.key, name: c.name)],
              selected: selected,
              accent: accent,
              onSelected: onSelected,
            ),
          );
    }

    return ref
        .watch(cashExpenseCategoriesProvider(expenseApiLocale(context)))
        .when(
          loading: () => const _PickerLoading(),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) => _Chips(
            options: [
              for (final ExpenseCategoryOption c in list)
                (key: c.id, name: c.name)
            ],
            selected: selected,
            accent: accent,
            onSelected: onSelected,
          ),
        );
  }
}

class _PickerLoading extends StatelessWidget {
  const _PickerLoading();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 48, child: AppLoading());
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final List<({String key, String name})> options;
  final String? selected;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(option.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected == option.key
                    ? accent
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: selected == option.key
                    ? null
                    : Border.all(color: cs.outline.withValues(alpha: 0.12)),
              ),
              child: Text(
                option.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected == option.key ? Colors.white : cs.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Localizations.localeOf(context).toLanguageTag();

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Text(
                DateFormat.yMMMMd(loc).format(date),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

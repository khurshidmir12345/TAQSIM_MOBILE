import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/ingredient_usage_model.dart';
import '../../domain/providers/daily_provider.dart';

/// "Bugun qancha xom ashyo ketdi?" — kun bo'yicha sarf: har xom ashyo
/// miqdori, qiymati va mahsulotlar kesimi.
class IngredientUsageScreen extends ConsumerStatefulWidget {
  const IngredientUsageScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<IngredientUsageScreen> createState() =>
      _IngredientUsageScreenState();
}

class _IngredientUsageScreenState extends ConsumerState<IngredientUsageScreen> {
  late DateTime _date = widget.initialDate;
  final Set<String> _expanded = {};

  String get _iso =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
  }

  String _num(BuildContext context, double v, {int maxDigits = 2}) {
    final tag = _localeTag(context);
    if (v == v.truncateToDouble()) {
      return NumberFormat.decimalPattern(tag).format(v);
    }
    return NumberFormat.decimalPatternDigits(
      locale: tag,
      decimalDigits: maxDigits,
    ).format(v);
  }

  String _money(BuildContext context, double v) =>
      NumberFormat.decimalPattern(_localeTag(context)).format(v.round());

  String _unit(String code) {
    if (code.isEmpty) return code;
    return code.length <= 2
        ? code.toLowerCase()
        : code[0].toUpperCase() + code.substring(1).toLowerCase();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() {
        _date = picked;
        _expanded.clear();
      });
    }
  }

  void _shiftDay(int delta) {
    final next = _date.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    HapticFeedback.selectionClick();
    setState(() {
      _date = next;
      _expanded.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(ingredientUsageProvider(_iso));
    final sym = ref.read(shopProvider).selected?.currency?.symbol;
    final cur = (sym != null && sym.isNotEmpty) ? sym : s.currency;
    final dateLabel = DateFormat.yMMMMd(_localeTag(context)).format(_date);
    final isToday = DateUtils.isSameDay(_date, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ingredientUsageTitle),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Sana navigatori ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _DayArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _shiftDay(-1),
                ),
                Expanded(
                  child: Material(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _DayArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: isToday ? null : () => _shiftDay(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoading(),
              error: (_, _) => ErrorRetryWidget(
                message: s.noInternet,
                onRetry: () => ref.invalidate(ingredientUsageProvider(_iso)),
              ),
              data: (usage) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(ingredientUsageProvider(_iso)),
                color: cs.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _TotalCard(
                      title: s.ingredientUsageTotalCost,
                      value: '${_money(context, usage.totalCost)} $cur',
                      subtitle: s.ingredientUsageProductions(
                        '${usage.productionCount}',
                      ),
                      hint: s.ingredientUsageSubtitle,
                    ),
                    const SizedBox(height: 14),
                    if (usage.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 44,
                              color: cs.onSurface.withValues(alpha: 0.22),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              s.ingredientUsageEmpty,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          s.ingredientUsageHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      for (final it in usage.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _UsageTile(
                            item: it,
                            share: usage.totalCost > 0
                                ? it.cost / usage.totalCost
                                : 0,
                            quantityText:
                                '${_num(context, it.quantity)} ${_unit(it.unit)}',
                            costText: '${_money(context, it.cost)} $cur',
                            expanded: _expanded.contains(it.ingredientId),
                            onTap: () => setState(() {
                              _expanded.contains(it.ingredientId)
                                  ? _expanded.remove(it.ingredientId)
                                  : _expanded.add(it.ingredientId);
                            }),
                            productLine: (p) =>
                                '${_num(context, p.quantity)} ${_unit(it.unit)}',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayArrow extends StatelessWidget {
  const _DayArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: cs.onSurface.withValues(alpha: onTap == null ? 0.2 : 0.7),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.hint,
  });

  final String title;
  final String value;
  final String subtitle;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle · $hint',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Xom ashyo qatori: nom, ulush chizig'i, miqdor (asosiy), qiymat.
/// Bosilsa mahsulotlar kesimi ochiladi.
class _UsageTile extends StatelessWidget {
  const _UsageTile({
    required this.item,
    required this.share,
    required this.quantityText,
    required this.costText,
    required this.expanded,
    required this.onTap,
    required this.productLine,
  });

  final IngredientUsageItem item;
  final double share;
  final String quantityText;
  final String costText;
  final bool expanded;
  final VoidCallback onTap;
  final String Function(IngredientUsageByProduct p) productLine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = item.isFlour ? AppColors.gold : AppColors.primary;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    quantityText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: share.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                        color: accent.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    costText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !expanded
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            for (final p in item.byProduct)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      productLine(p),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';
import '../widgets/cash_entry_sheet.dart';
import '../widgets/cash_entry_tile.dart';
import '../widgets/cash_settings_sheet.dart';
import '../widgets/cash_summary_card.dart';
import 'cash_entry_create_screen.dart';

/// Kassa — barcha pul harakati va davr sof natijasi.
///
/// Davr ikki yo'l bilan tanlanadi: tez tugmalar (kunlik / haftalik / oylik,
/// bugundan orqaga sanaladi) yoki appbardagi filtr orqali aniq oraliq.
class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  CashScreenState createState() => CashScreenState();
}

enum _QuickPeriod { year, month, day, custom }

class CashScreenState extends ConsumerState<CashScreen> {
  final _scrollCtl = ScrollController();

  _QuickPeriod _period = _QuickPeriod.year;

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);

    // Standart davr — yillik; provider bugungi kun bilan boshlanadi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyPeriod(_QuickPeriod.year);
    });
  }

  @override
  void dispose() {
    _scrollCtl.removeListener(_onScroll);
    _scrollCtl.dispose();
    super.dispose();
  }

  /// Tashqaridan yangilash (Shell tabga qayta bosilganda).
  void refresh() => ref.read(cashProvider.notifier).refresh();

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;

    final position = _scrollCtl.position;

    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(cashProvider.notifier).loadMore();
    }
  }

  String _money(double n) {
    final l = Localizations.localeOf(context);
    final tag = l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;

    return NumberFormat.decimalPatternDigits(locale: tag, decimalDigits: 0)
        .format(n);
  }

  /// Tez davrlar bugundan orqaga sanaladi.
  void _selectPeriod(_QuickPeriod period) {
    if (period == _period) return;

    HapticFeedback.selectionClick();
    _applyPeriod(period);
  }

  void _applyPeriod(_QuickPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final from = switch (period) {
      _QuickPeriod.day => today,
      _QuickPeriod.month => today.subtract(const Duration(days: 29)),
      _QuickPeriod.year => today.subtract(const Duration(days: 364)),
      _QuickPeriod.custom => today,
    };

    setState(() => _period = period);
    ref.read(cashRangeProvider.notifier).set(from, today);
  }

  /// Filtrni bekor qiladi va standart davrga qaytadi.
  void _clearFilter() {
    HapticFeedback.selectionClick();
    _applyPeriod(_QuickPeriod.year);
  }

  Future<void> _openFilter() async {
    HapticFeedback.selectionClick();

    final current = ref.read(cashRangeProvider);
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
      helpText: S.of(context).cashFilterTitle,
      saveText: S.of(context).cashFilterApply,
    );

    if (picked == null || !mounted) return;

    setState(() => _period = _QuickPeriod.custom);
    ref.read(cashRangeProvider.notifier).set(picked.start, picked.end);
  }

  Future<void> _openCreate(CashType type) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CashEntryCreateScreen(type: type)),
    );
  }

  /// Yozuv bosilganda tafsilot ochiladi — u yerdan tahrirlash yoki
  /// o'chirish mumkin (avtomatik yozuvda faqat ko'rish).
  void _onEntryTap(CashEntry entry) {
    HapticFeedback.selectionClick();
    CashEntrySheet.show(context, entry, _money);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final async = ref.watch(cashProvider);
    final range = ref.watch(cashRangeProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          s.cashbox,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: s.cashFilterTitle,
            icon: Badge(
              isLabelVisible: _period == _QuickPeriod.custom,
              smallSize: 7,
              child: const Icon(Icons.filter_alt_outlined),
            ),
            onPressed: _openFilter,
          ),
          IconButton(
            tooltip: s.cashSettingsTitle,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              final settings = ref.read(cashProvider).asData?.value.settings ??
                  const CashSettings();
              CashSettingsSheet.show(context, settings);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _PeriodTabs(
            selected: _period,
            onSelected: _selectPeriod,
            rangeLabel:
                _period == _QuickPeriod.custom ? _rangeLabel(range) : null,
            onClearFilter: _clearFilter,
          ),
          Expanded(
            // Tugmalar ro'yxat ustida suzib turadi — ekran aylantirilganda
            // ham joyidan qimirlamaydi.
            child: Stack(
              children: [
                Positioned.fill(
                  child: async.when(
                    loading: () => const AppLoading(),
                    error: (_, _) => ErrorRetryWidget(
                      message: s.noInternet,
                      onRetry: () => ref.read(cashProvider.notifier).refresh(),
                    ),
                    data: (state) => RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cashProvider.notifier).refresh(),
                      child: ListView(
                        controller: _scrollCtl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        // Pastdagi tugmalar oxirgi qatorni to'smasin.
                        padding: EdgeInsets.fromLTRB(pad, 4, pad, 96),
                        children: [
                          CashSummaryCard(
                            summary: state.summary,
                            money: _money,
                          ),
                          const SizedBox(height: 16),
                          if (state.entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child: EmptyStateWidget(
                                icon: Icons.receipt_long_outlined,
                                title: s.cashEmptyTitle,
                                subtitle: s.cashEmptyMessage,
                              ),
                            )
                          else
                            ..._buildGroupedEntries(state),
                          if (state.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: 12,
                  child: _ActionRow(
                    onIncome: () => _openCreate(CashType.income),
                    onExpense: () => _openCreate(CashType.expense),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(CashRange range) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    final format = DateFormat.MMMd(loc);

    return range.from == range.to
        ? format.format(range.from)
        : '${format.format(range.from)} – ${format.format(range.to)}';
  }

  /// Yozuvlar sana bo'yicha guruhlanadi — uzun ro'yxatda kun chegarasi
  /// ko'rinib tursin.
  List<Widget> _buildGroupedEntries(CashState state) {
    final cs = Theme.of(context).colorScheme;
    final loc = Localizations.localeOf(context).toLanguageTag();
    final widgets = <Widget>[];

    var currentDate = '';
    var group = <CashEntry>[];

    void flush() {
      if (group.isEmpty) return;

      final parsed = DateTime.tryParse(currentDate);

      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          parsed == null ? currentDate : DateFormat.yMMMMd(loc).format(parsed),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ));

      widgets.add(ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: ColoredBox(
          color: cs.surface,
          child: Column(
            children: [
              for (var i = 0; i < group.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 58,
                    endIndent: 12,
                    color: cs.outline.withValues(alpha: 0.08),
                  ),
                CashEntryTile(
                  entry: group[i],
                  money: _money,
                  onTap: () => _onEntryTap(group[i]),
                ),
              ],
            ],
          ),
        ),
      ));

      group = <CashEntry>[];
    }

    for (final entry in state.entries) {
      if (entry.date != currentDate) {
        flush();
        currentDate = entry.date;
      }

      group.add(entry);
    }

    flush();

    return widgets;
  }
}

/// Yillik / oylik / kunlik — bugundan orqaga sanaladi.
///
/// Ko'rinishi statistika bo'limidagi tanlagich bilan bir xil: foydalanuvchi
/// ikkala ekranda bitta odatni ishlatadi.
class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({
    required this.selected,
    required this.onSelected,
    required this.onClearFilter,
    this.rangeLabel,
  });

  final _QuickPeriod selected;
  final ValueChanged<_QuickPeriod> onSelected;
  final VoidCallback onClearFilter;

  /// Filtr orqali tanlangan oraliq — faqat "custom" holatda ko'rinadi.
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 10),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_QuickPeriod>(
              segments: [
                ButtonSegment(value: _QuickPeriod.year, label: Text(s.yearly)),
                ButtonSegment(value: _QuickPeriod.month, label: Text(s.monthly)),
                ButtonSegment(value: _QuickPeriod.day, label: Text(s.daily)),
              ],
              // Filtr ishlatilganda hech biri tanlangan ko'rinmaydi.
              selected: {
                selected == _QuickPeriod.custom ? _QuickPeriod.year : selected,
              },
              onSelectionChanged: (set) => onSelected(set.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          if (rangeLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    rangeLabel!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: s.cashFilterClear,
                    onPressed: onClearFilter,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: cs.primary,
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

/// Yashil kirim, qizil chiqim — ro'yxat ustida suzib turadi.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onIncome, required this.onExpense});

  final VoidCallback onIncome;
  final VoidCallback onExpense;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: s.cashIncome,
            icon: Icons.add_rounded,
            color: AppColors.income,
            onTap: onIncome,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: s.cashExpense,
            icon: Icons.remove_rounded,
            color: AppColors.error,
            onTap: onExpense,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
import '../../../statistics/presentation/widgets/period_selector.dart';
import '../../domain/models/cash_model.dart';
import '../../domain/providers/cash_provider.dart';
import '../widgets/cash_entry_tile.dart';
import '../widgets/cash_settings_sheet.dart';
import '../widgets/cash_summary_card.dart';
import 'cash_entry_create_screen.dart';

/// Kassa — barcha pul harakati va davr foydasi.
///
/// Asosiy sahifadan farqi: u faqat mahsulot chiqimi va vozvrat haqida
/// gapiradi, kassa esa tashqi kirim/chiqimni ham qo'shib, davr sof natijasini
/// beradi.
class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  CashScreenState createState() => CashScreenState();
}

class CashScreenState extends ConsumerState<CashScreen> {
  final _scrollCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
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

  Future<void> _openCreate(CashType type) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CashEntryCreateScreen(type: type)),
    );
  }

  Future<void> _confirmDelete(CashEntry entry) async {
    final s = S.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.cashDeleteTitle),
        content: Text(s.cashDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(cashProvider.notifier).delete(entry.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noInternet)),
      );
    }
  }

  /// Avtomatik yozuvni tahrirlab bo'lmaydi — sababini aytamiz, jim
  /// turgandan ko'ra tushunarli.
  void _onEntryTap(CashEntry entry) {
    if (!entry.isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).cashAutoEntryHint)),
      );

      return;
    }

    _confirmDelete(entry);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final async = ref.watch(cashProvider);

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
            tooltip: s.cashSettingsTitle,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              final settings =
                  ref.read(cashProvider).asData?.value.settings ??
                      const CashSettings();
              CashSettingsSheet.show(context, settings);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistika bo'limidagi bilan bir xil tanlagich — foydalanuvchi
          // ikkala ekranda bir xil harakat qiladi.
          PeriodSelector(
            onChanged: (_, from, to) {
              ref.read(cashRangeProvider.notifier).set(from, to);
            },
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoading(),
              error: (_, _) => ErrorRetryWidget(
                message: s.noInternet,
                onRetry: () => ref.read(cashProvider.notifier).refresh(),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: () => ref.read(cashProvider.notifier).refresh(),
                child: ListView(
                  controller: _scrollCtl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                  children: [
                    CashSummaryCard(summary: state.summary, money: _money),
                    const SizedBox(height: 12),
                    _ActionRow(
                      onIncome: () => _openCreate(CashType.income),
                      onExpense: () => _openCreate(CashType.expense),
                    ),
                    const SizedBox(height: 18),
                    if (state.entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(
          parsed == null
              ? currentDate
              : DateFormat.yMMMMd(loc).format(parsed),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ));

      widgets.add(Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            for (var i = 0; i < group.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 57,
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

/// Asosiy sahifadagi kabi ikkita tugma — yashil kirim, qizil chiqim.
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
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
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
    );
  }
}

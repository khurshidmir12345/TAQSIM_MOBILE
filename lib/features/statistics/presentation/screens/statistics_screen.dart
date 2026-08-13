import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/statistics_model.dart';
import '../../domain/providers/statistics_provider.dart';
import '../widgets/stats_line_chart.dart';

/// Statistika — ataylab sodda: bitta grafik, bitta summalar kartasi va
/// mahsulotning asl tannarxi. Davr tanlagichlari yo'q, grafikning o'zi
/// sanalarni ko'rsatadi.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final async = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          s.reportScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (_, _) => ErrorRetryWidget(
          message: s.noInternet,
          onRetry: () => ref.read(statisticsProvider.notifier).refresh(),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(statisticsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                  EmptyStateWidget(
                    icon: Icons.insert_chart_outlined_rounded,
                    title: s.noData,
                    subtitle: s.statsEmptyDesc,
                  ),
                ],
              ),
            );
          }

          final money = _MoneyFormat(context, ref);

          return RefreshIndicator(
            onRefresh: () => ref.read(statisticsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 32),
              children: [
                _Card(
                  title: s.statsChartTitle,
                  child: StatsLineChart(
                    series: stats.series,
                    incomeLabel: s.statsIncome,
                    expenseLabel: s.statsExpense,
                    profitLabel: s.statsProfit,
                    moneySuffix: money.suffix,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TotalsCard(totals: stats.totals, s: s, money: money),
                if (stats.products.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _TrueCostCard(
                    products: stats.products,
                    s: s,
                    money: money,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pul formati — do'kon valyutasi bilan.
class _MoneyFormat {
  _MoneyFormat(BuildContext context, WidgetRef ref)
      : _locale = Localizations.localeOf(context).toLanguageTag(),
        suffix = ref.read(shopProvider).selected?.currency?.symbol?.isNotEmpty ==
                true
            ? ref.read(shopProvider).selected!.currency!.symbol!
            : S.of(context).currency;

  final String _locale;
  final String suffix;

  String call(double v) {
    final n = NumberFormat.decimalPatternDigits(
      locale: _locale,
      decimalDigits: 0,
    ).format(v);

    return '$n $suffix';
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Barcha summalar bitta kartada, oddiy `nom → qiymat` qatorlari bilan.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totals,
    required this.s,
    required this.money,
  });

  final StatTotals totals;
  final S s;
  final _MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return _Card(
      title: s.statsTotalsTitle,
      child: Column(
        children: [
          _Row(
            label: s.statsIncome,
            value: money(totals.income),
            dot: StatsPalette.income(dark),
          ),
          _Row(
            label: s.statsExpense,
            value: money(totals.expense),
            dot: StatsPalette.expense(dark),
          ),
          const _Divider(),
          _Row(
            label: s.statsProfit,
            value: money(totals.profit),
            dot: StatsPalette.profit(dark),
            strong: true,
            negative: totals.profit < 0,
          ),
          const _Divider(),
          // Xarajat nimadan iboratligi — grafikda ko'rinmaydigan tafsilot.
          _Row(label: s.statsIngredientCost, value: money(totals.ingredientCost)),
          _Row(label: s.statsExternalExpenses, value: money(totals.externalExpenses)),
          if (totals.returns > 0)
            _Row(label: s.returnAmount, value: money(totals.returns)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.dot,
    this.strong = false,
    this.negative = false,
  });

  final String label;
  final String value;
  final Color? dot;
  final bool strong;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: strong ? 15 : 14,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: cs.onSurface.withValues(alpha: strong ? 1 : 0.72),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color: negative ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 18,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
    );
  }
}

/// Mahsulotning asl tannarxi: xom ashyo + unga to'g'ri kelgan tashqi xarajat.
class _TrueCostCard extends StatelessWidget {
  const _TrueCostCard({
    required this.products,
    required this.s,
    required this.money,
  });

  final List<ProductTrueCost> products;
  final S s;
  final _MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: s.statsTrueCostTitle,
      trailing: IconButton(
        icon: const Icon(Icons.info_outline_rounded, size: 20),
        visualDensity: VisualDensity.compact,
        tooltip: s.statsTrueCostInfoTitle,
        onPressed: () {
          HapticFeedback.selectionClick();
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(s.statsTrueCostInfoTitle),
              content: SingleChildScrollView(
                child: Text(
                  s.statsTrueCostInfoBody,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.gotIt),
                ),
              ],
            ),
          );
        },
      ),
      child: Column(
        children: [
          for (final p in products) ...[
            if (p != products.first) const _Divider(),
            _Row(label: p.name, value: money(p.trueUnitCost), strong: true),
          ],
        ],
      ),
    );
  }
}

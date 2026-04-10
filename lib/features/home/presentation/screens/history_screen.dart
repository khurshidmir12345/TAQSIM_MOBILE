import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/daily_repository.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/history/kassa_tab_content.dart';
import '../widgets/history/production_history_tab.dart';
import '../widgets/history/returns_history_tab.dart';

enum _HistoryTab { created, returns, kassa }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtl;
  _HistoryTab _selectedTab = _HistoryTab.created;

  ShopSummaryModel? _summary;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 3, vsync: this);
    _tabCtl.addListener(_syncTab);
    Future.microtask(_loadSummary);
  }

  @override
  void dispose() {
    _tabCtl.removeListener(_syncTab);
    _tabCtl.dispose();
    super.dispose();
  }

  void _syncTab() {
    if (_tabCtl.indexIsChanging) return;
    final tab = _HistoryTab.values[_tabCtl.index];
    if (_selectedTab != tab) {
      setState(() => _selectedTab = tab);
    }
  }

  void _onSegmentChanged(Set<_HistoryTab> sel) {
    final tab = sel.first;
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    _tabCtl.animateTo(tab.index);
  }

  Future<void> _loadSummary() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      if (mounted) setState(() => _summaryLoading = false);
      return;
    }
    try {
      final repo = ref.read(dailyRepositoryProvider);
      final s = await repo.getShopSummary(shop.id);
      if (mounted) setState(() { _summary = s; _summaryLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  String _fmtMoney(double n) {
    if (n == n.truncateToDouble()) {
      return NumberFormat('#,##0', 'uz').format(n);
    }
    return NumberFormat('#,##0.##', 'uz').format(n);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.historyTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_HistoryTab>(
                      segments: [
                        ButtonSegment(
                          value: _HistoryTab.created,
                          label: Text(s.historyTabCreated),
                        ),
                        ButtonSegment(
                          value: _HistoryTab.returns,
                          label: Text(s.historyTabReturns),
                        ),
                        ButtonSegment(
                          value: _HistoryTab.kassa,
                          label: Text(s.historyTabCash),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: _onSegmentChanged,
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
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          _HistorySummaryStrip(
            summary: _summary,
            loading: _summaryLoading,
            fmtMoney: _fmtMoney,
            pad: pad,
            tab: _selectedTab,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtl,
              children: const [
                ProductionHistoryTab(),
                ReturnsHistoryTab(),
                KassaTabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySummaryStrip extends StatelessWidget {
  const _HistorySummaryStrip({
    required this.summary,
    required this.loading,
    required this.fmtMoney,
    required this.pad,
    required this.tab,
  });

  final ShopSummaryModel? summary;
  final bool loading;
  final String Function(double) fmtMoney;
  final double pad;
  final _HistoryTab tab;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 6),
        child: _shimmerRow(cs, isDark),
      );
    }

    final r = summary;
    if (r == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.sm),
      child: switch (tab) {
        _HistoryTab.created => _buildProduction(context, s, cs, isDark, r),
        _HistoryTab.returns => _buildReturns(context, s, cs, isDark, r),
        _HistoryTab.kassa   => _buildKassa(context, s, cs, isDark, r),
      },
    );
  }

  Widget _buildProduction(
    BuildContext context, S s, ColorScheme cs, bool isDark, ShopSummaryModel r,
  ) {
    return _stripContainer(cs, isDark, Row(
      children: [
        _MiniStat(label: s.income, value: fmtMoney(r.prodIncome), color: AppColors.income),
        _dot(cs),
        _MiniStat(label: s.expense, value: fmtMoney(r.prodExpense), color: AppColors.error),
        _dot(cs),
        _MiniStat(
          label: s.profit,
          value: fmtMoney(r.prodProfit),
          color: r.prodProfit >= 0 ? AppColors.success : AppColors.error,
        ),
      ],
    ));
  }

  Widget _buildReturns(
    BuildContext context, S s, ColorScheme cs, bool isDark, ShopSummaryModel r,
  ) {
    return _stripContainer(cs, isDark, Row(
      children: [
        Icon(Icons.assignment_return_outlined, size: 16,
            color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(s.historyTotalReturns, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.55),
        )),
        const Spacer(),
        Text('${fmtMoney(r.returnsTotal)} ${s.currency}', style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.error,
        )),
      ],
    ));
  }

  Widget _buildKassa(
    BuildContext context, S s, ColorScheme cs, bool isDark, ShopSummaryModel r,
  ) {
    return _stripContainer(cs, isDark, Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 16,
            color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(s.expense, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.55),
        )),
        const Spacer(),
        Text('${fmtMoney(r.expensesTotal)} ${s.currency}', style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.error,
        )),
      ],
    ));
  }

  Widget _stripContainer(ColorScheme cs, bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _dot(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3, height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
        ),
      );

  Widget _shimmerRow(ColorScheme cs, bool isDark) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

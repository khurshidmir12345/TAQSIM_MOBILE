import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/providers/terminology_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tutorial/domain/providers/shop_tutorial_provider.dart';
import '../../../tutorial/presentation/widgets/tutorial_spotlight.dart';
import '../../../auth/domain/models/shop_model.dart';
import '../../domain/models/daily_report_model.dart';
import '../../domain/models/production_model.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/production_summary_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _setupBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dailyReportProvider.notifier).loadToday());
  }

  void refresh() => ref.read(dailyReportProvider.notifier).loadToday();

  String _fmt(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;
    if (n == n.truncateToDouble()) {
      return NumberFormat('#,##0', 'uz').format(n);
    }
    return NumberFormat('#,##0.##', 'uz').format(n);
  }

  void _showShopPicker() {
    final shopState = ref.read(shopProvider);
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.bakeries,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/shop-select');
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(s.manage),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: shopState.shops.length,
                itemBuilder: (ctx, i) {
                  final shop = shopState.shops[i];
                  final isSelected = shop.id == shopState.selected?.id;
                  return _ShopPickerItem(
                    shop: shop,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(shopProvider.notifier).selectShop(shop);
                      ref.read(dailyReportProvider.notifier).loadToday();
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop        = ref.watch(shopProvider).selected;
    final reportState = ref.watch(dailyReportProvider);
    final report      = reportState.report;
    final cs          = Theme.of(context).colorScheme;
    final pad         = Responsive.horizontalPadding(context);
    final s           = S.of(context);
    final term        = ref.watch(terminologyProvider);
    final showHint = ref.watch(shopTutorialProvider);

    final scaffold = Scaffold(
      body: Column(
        children: [
          _DashboardHeader(
            shop: shop,
            pad: pad,
            setupBtnKey: _setupBtnKey,
            onShopTap: _showShopPicker,
            onSetupTap: () => context.push('/setup'),
            onReportTap: () => context.push('/report'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(dailyReportProvider.notifier).loadToday(),
              color: cs.primary,
              child: ListView(
                padding: EdgeInsets.fromLTRB(0, 20, 0, pad + 16),
                children: [
                  if (reportState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: AppLoading(),
                    )
                  else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: _BalanceCard(report: report, fmt: _fmt),
                    ),
                    const SizedBox(height: 20),
                    _ActivityRow(
                      report: report,
                      productions: reportState.productions,
                      fmt: _fmt,
                      batchCountSuffix: s.dashboardBatchUnitGeneric,
                      productUnit: term.productUnit,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: _SectionHeader(title: s.dashboardSectionOutput),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: _ProductionList(
                        productions: reportState.productions,
                        fmt: _fmt,
                        productUnit: term.productUnit,
                        batchCountSuffix: s.dashboardBatchUnitGeneric,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _ActionBar(pad: pad),
        ],
      ),
    );

    if (showHint) {
      return SpotlightOverlay(
        targetKey: _setupBtnKey,
        title: s.tutorialSettingsHintTitle,
        message: s.tutorialSettingsHintMessage,
        accentColor: AppColors.primary,
        onDismiss: () => ref.read(shopTutorialProvider.notifier).dismiss(),
        child: scaffold,
      );
    }

    return scaffold;
  }
}

class _DashboardHeader extends StatelessWidget {
  final ShopModel? shop;
  final double pad;
  final GlobalKey setupBtnKey;
  final VoidCallback onShopTap;
  final VoidCallback onSetupTap;
  final VoidCallback onReportTap;

  const _DashboardHeader({
    required this.shop,
    required this.pad,
    required this.setupBtnKey,
    required this.onShopTap,
    required this.onSetupTap,
    required this.onReportTap,
  });

  /// Matn + strelka qator bo‘yicha: strelka doim matn oxiriga yopishadi (uzoq cho‘zilmaydi).
  static const double _chevronSlot = 26;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = (shop?.name.isNotEmpty == true) ? shop!.name : s.bakery;
    final addr = shop?.address?.trim();
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShopTap,
                  borderRadius: BorderRadius.circular(13),
                  child: Ink(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShopTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxText = constraints.maxWidth > _chevronSlot
                                  ? constraints.maxWidth - _chevronSlot
                                  : 0.0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxText,
                                    ),
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.25,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                    size: 22,
                                  ),
                                ],
                              );
                            },
                          ),
                          if (addr != null && addr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              addr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.55),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _TealIconBtn(key: setupBtnKey, icon: Icons.tune_rounded, onTap: onSetupTap),
              const SizedBox(width: 6),
              _TealIconBtn(icon: Icons.bar_chart_rounded, onTap: onReportTap),
            ],
          ),
        ),
      );
  }
}

class _TealIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TealIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: cs.onSurface, size: 20),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DailyReportModel? report;
  final String Function(dynamic) fmt;

  const _BalanceCard({required this.report, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final s          = S.of(context);
    final brightness = Theme.of(context).brightness;

    // Backend: sales.total_amount va net_sales — vozvratdan keyingi netto tushum.
    final netSales =
        report?.netSales ?? report?.sales.totalAmount ?? 0.0;
    final ingredientCost = report?.expenses.ingredientCost ?? 0.0;
    final externalExp    = report?.expenses.external ?? 0.0;
    final totalExpenses  = report?.expenses.total ?? (ingredientCost + externalExp);
    final foyda          = report?.profit ?? (netSales - totalExpenses);

    final dateStr    = DateFormat('d MMM', 'uz').format(DateTime.now());
    final isLoss     = foyda < 0;
    final gradColors = AppColors.balanceGradient(brightness, isLoss);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLoss ? s.todayLoss : s.todayProfit,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${fmt(foyda)} ${s.currency}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLoss ? '▼' : '▲',
                    style: TextStyle(
                      color: isLoss
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF98F4C8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniKPI(
                    icon: Icons.arrow_upward_rounded,
                    label: s.netRevenue,
                    value: fmt(netSales),
                    valueColor: const Color(0xFF98F4C8),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: _MiniKPI(
                    icon: Icons.arrow_downward_rounded,
                    label: s.expense,
                    value: fmt(totalExpenses),
                    valueColor: const Color(0xFFFFCDD2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKPI extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MiniKPI({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: valueColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final DailyReportModel? report;
  final List<ProductionModel> productions;
  final String Function(dynamic) fmt;
  /// Partiya soni yonidagi umumiy qo‘shimcha (mahsulot birligidan mustaqil).
  final String batchCountSuffix;
  final String productUnit;

  const _ActivityRow({
    required this.report,
    required this.productions,
    required this.fmt,
    required this.batchCountSuffix,
    required this.productUnit,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    double totalBatches = 0;
    for (final p in productions) {
      totalBatches += p.batchCount;
    }

    final items = [
      _StatTileData(Icons.output_rounded, s.dashboardKpiOutput,
          fmt(report?.production.totalBread ?? 0), productUnit),
      _StatTileData(Icons.layers_outlined, s.dashboardKpiBatch,
          fmt(totalBatches), batchCountSuffix),
      _StatTileData(Icons.storefront_outlined, s.dashboardKpiSold,
          fmt(report?.sales.totalQuantity ?? 0), productUnit),
      _StatTileData(Icons.undo_rounded, s.dashboardKpiReturned,
          fmt(report?.returns.totalQuantity ?? 0), productUnit),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context)),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final d = items[i];
          return _StatTile(d.icon, d.title, d.value, d.unit);
        },
      ),
    );
  }
}

class _StatTileData {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  const _StatTileData(this.icon, this.title, this.value, this.unit);
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _StatTile(this.icon, this.title, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = Responsive.isTablet(context);

    return Container(
      width: isTablet ? 158 : 132,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: cs.primary, size: 16),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.48),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  color: cs.primary.withValues(alpha: 0.58),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductionList extends StatelessWidget {
  final List<ProductionModel> productions;
  final String Function(dynamic) fmt;
  final String productUnit;
  final String batchCountSuffix;

  const _ProductionList({
    required this.productions,
    required this.fmt,
    required this.productUnit,
    required this.batchCountSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    if (productions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Icon(Icons.local_fire_department_outlined,
                size: 40, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(s.dashboardEmptyOutput,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35)),
          ],
        ),
      );
    }

    return Column(
      children: productions.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductionSummaryCard(
            production: p,
            fmt: fmt,
            productUnit: productUnit,
            batchCountSuffix: batchCountSuffix,
          ),
        );
      }).toList(),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final double pad;
  const _ActionBar({required this.pad});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.north_east_rounded,
              label: s.productOut,
              color: AppColors.primary,
              onTap: () => context.push('/production-create'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.south_west_rounded,
              label: s.productReturned,
              color: AppColors.error,
              onTap: () => context.push('/return-create'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopPickerItem extends StatelessWidget {
  final ShopModel shop;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShopPickerItem({
    required this.shop,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.secondary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? cs.secondary.withValues(alpha: 0.3)
                    : cs.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.secondary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront_outlined,
                      size: 20,
                      color: isSelected
                          ? cs.secondary
                          : cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: cs.onSurface)),
                      if (shop.address != null)
                        Text(shop.address!,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: cs.secondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/providers/terminology_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/time_badge.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tutorial/domain/providers/shop_tutorial_provider.dart';
import '../../../tutorial/presentation/widgets/tutorial_spotlight.dart';
import '../../../auth/domain/models/shop_model.dart';
import '../../domain/models/daily_report_model.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/models/production_model.dart';
import '../../domain/providers/daily_provider.dart';
import '../widgets/expense_actions.dart';
import '../widgets/production_summary_card.dart';

enum _DashboardSection { output, expense }

/// Qisqa sana formati. `intl` registratsiya qilmagan localelar uchun `uz`ga fallback.
String _formatDateShort(BuildContext context, DateTime d) {
  final lang = Localizations.localeOf(context).languageCode;
  const registered = {'uz', 'ru', 'kk', 'tr'};
  final code = registered.contains(lang) ? lang : 'uz';
  try {
    return DateFormat('d MMM', code).format(d);
  } catch (_) {
    return DateFormat('d MMM', 'uz').format(d);
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  final _setupBtnKey = GlobalKey();
  _DashboardSection _section = _DashboardSection.output;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(dailyReportProvider.notifier).loadToday());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Ilova fondan qaytganda sana filterini tozalaymiz — foydalanuvchi doim
  /// bugungi holatni ko'rishi kerak. Filter huddi tozalanib qolgandek ishlaydi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selected = ref.read(dailyReportProvider).selectedDate;
    if (selected != today) {
      ref.read(dailyReportProvider.notifier).loadToday();
    }
  }

  void refresh() {
    final selected = ref.read(dailyReportProvider).selectedDate;
    if (selected == null) {
      ref.read(dailyReportProvider.notifier).loadToday();
    } else {
      ref.read(dailyReportProvider.notifier).loadDate(selected);
    }
  }

  /// Sana filterini bugunga qaytaradi va ma'lumotlarni yangilaydi.
  /// Dashboard boshqa ekrandan qaytarilganda yoki bosh tabi tanlanganda
  /// chaqiriladi — foydalanuvchi doim bugungi holatni ko'radi.
  void resetToToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selected = ref.read(dailyReportProvider).selectedDate;
    if (selected != today) {
      ref.read(dailyReportProvider.notifier).loadToday();
    }
  }

  DateTime get _selectedDate {
    final iso = ref.read(dailyReportProvider).selectedDate;
    if (iso == null) return DateTime.now();
    return DateTime.tryParse(iso) ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = _selectedDate;
    final appLocale = ref.read(localeProvider).value ?? AppLocale.uz;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      locale: materialLocaleFor(appLocale),
    );
    if (picked == null) return;

    final iso = DateFormat('yyyy-MM-dd').format(picked);
    await ref.read(dailyReportProvider.notifier).loadDate(iso);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fmt(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;
    if (n == n.truncateToDouble()) {
      return NumberFormat('#,##0', 'uz').format(n);
    }
    return NumberFormat('#,##0.##', 'uz').format(n);
  }

  Future<void> _onShopSelected() async {
    // Do'kon o'zgarganda tanlangan sanani saqlab qolamiz (mavjud bo'lsa).
    final selected = ref.read(dailyReportProvider).selectedDate;
    final notifier = ref.read(dailyReportProvider.notifier);
    if (selected == null) {
      await notifier.loadToday();
    } else {
      await notifier.loadDate(selected);
    }
  }

  /// Biznes tanlash/boshqarish ekraniga o'tadi. Oldin bottom-sheet edi, ammo
  /// Android'da past qirralar tizim tugmalari bilan to'qnashib, bir biznesli
  /// holatda kartani yarmi tagiga yopiltirar edi — endi doim to'liq sahifa.
  /// Qaytganda joriy do'konning ma'lumotlarini qayta yuklaymiz.
  Future<void> _openShopManager() async {
    HapticFeedback.selectionClick();
    await context.push('/shop-select');
    if (!mounted) return;
    await _onShopSelected();
  }

  @override
  Widget build(BuildContext context) {
    final shop        = ref.watch(shopProvider.select((s) => s.selected));
    final reportState = ref.watch(dailyReportProvider);
    final report      = reportState.report;
    final cs          = Theme.of(context).colorScheme;
    final pad         = Responsive.horizontalPadding(context);
    final s           = S.of(context);
    final term        = ref.watch(terminologyProvider);
    final showHint    = ref.watch(shopTutorialProvider);

    final scaffold = Scaffold(
      body: Column(
        children: [
          _DashboardHeader(
            shop: shop,
            pad: pad,
            setupBtnKey: _setupBtnKey,
            onShopTap: _openShopManager,
            onSetupTap: () => context.push('/setup'),
            onProfileTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile');
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => refresh(),
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
                      child: RepaintBoundary(
                        child: _BalanceCard(
                          report: report,
                          fmt: _fmt,
                          selectedDate: _selectedDate,
                          isFiltered: !_isToday(_selectedDate),
                          onDateTap: _pickDate,
                          onHistoryTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/history');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      child: _ProductCarousel(
                        productions: reportState.productions,
                        fmt: _fmt,
                        batchCountSuffix: s.dashboardBatchUnitGeneric,
                        fallbackUnit: term.productUnit,
                        fallbackCurrency: s.currency,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: _DashboardSegmented(
                        section: _section,
                        onChanged: (v) => setState(() => _section = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: _section == _DashboardSection.output
                          ? _ProductionList(
                              productions: reportState.productions,
                              fmt: _fmt,
                              productUnit: term.productUnit,
                              batchCountSuffix: s.dashboardBatchUnitGeneric,
                            )
                          : _ExpenseList(
                              expenses: reportState.expenses,
                              fmt: _fmt,
                              currency: s.currency,
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
        ctaLabel: s.gotIt,
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
  final VoidCallback onProfileTap;

  const _DashboardHeader({
    required this.shop,
    required this.pad,
    required this.setupBtnKey,
    required this.onShopTap,
    required this.onSetupTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = (shop?.name.isNotEmpty == true) ? shop!.name : s.bakery;
    final addr = shop?.address?.trim();
    final bizColor = shop?.businessType?.color ?? cs.primary;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 16),
        child: Row(
          children: [
            _ShopMenuButton(onTap: onShopTap),
            const SizedBox(width: 8),
            _ShopBadge(bizColor: bizColor, onTap: onShopTap),
            const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShopTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
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
            _TealIconBtn(
              key: setupBtnKey,
              icon: Icons.tune_rounded,
              onTap: onSetupTap,
            ),
            const SizedBox(width: 6),
            _TealIconBtn(
              icon: Icons.person_outline_rounded,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chap chetda joylashgan zamonaviy "hamburger" tugma. Tapped → do'kon
/// tanlash/qo'shish ekraniga olib o'tadi (boshqa do'konlar ham bo'lishi mumkin).
class _ShopMenuButton extends StatelessWidget {
  const _ShopMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: cs.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.6 : 0.85,
      ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.menu_rounded,
            color: cs.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Do'konni bildiruvchi storefront ikoni — biznes turining rangi bilan
/// nozik tortilgan. Tapped → do'kon menyusi.
class _ShopBadge extends StatelessWidget {
  const _ShopBadge({required this.bizColor, required this.onTap});

  final Color bizColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = bizColor.withValues(alpha: isDark ? 0.22 : 0.13);
    final fg = isDark ? Color.lerp(bizColor, Colors.white, 0.25)! : bizColor;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.storefront_rounded,
            color: fg,
            size: 22,
          ),
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

class _DashboardSegmented extends StatelessWidget {
  final _DashboardSection section;
  final ValueChanged<_DashboardSection> onChanged;

  const _DashboardSegmented({
    required this.section,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.4 : 0.7,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _SegmentButton(
            label: s.dashboardTabOutput,
            selected: section == _DashboardSection.output,
            onTap: () => onChanged(_DashboardSection.output),
          ),
          _SegmentButton(
            label: s.dashboardTabExpense,
            selected: section == _DashboardSection.expense,
            onTap: () => onChanged(_DashboardSection.expense),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.55),
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DailyReportModel? report;
  final String Function(dynamic) fmt;
  final DateTime selectedDate;
  final bool isFiltered;
  final VoidCallback onDateTap;
  final VoidCallback onHistoryTap;

  const _BalanceCard({
    required this.report,
    required this.fmt,
    required this.selectedDate,
    required this.isFiltered,
    required this.onDateTap,
    required this.onHistoryTap,
  });

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

    final dateStr = _formatDateShort(context, selectedDate);
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isFiltered ? 0.22 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: isFiltered
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFiltered) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD166),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLoss
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: isLoss
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF98F4C8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                _DashboardIconBtn(
                  icon: Icons.history_rounded,
                  tooltip: S.of(context).historyTitle,
                  onTap: onHistoryTap,
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

/// Balans cardidagi mini-tugma (history kabi sub-amallar uchun).
class _DashboardIconBtn extends StatelessWidget {
  const _DashboardIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mahsulot bo'yicha karusel — har bitta tur uchun alohida card.
///
/// Bir kun ichida bir mahsulot bir necha marta yopilishi mumkin (3 partiya
/// = 3 ta `ProductionModel`). Bu yerda biz ularni `breadCategoryId` bo'yicha
/// guruhlaymiz va har bir tur uchun yagona xulosa cardini ko'rsatamiz:
/// - Sof miqdor (chiqarilgan − qaytarilgan)
/// - Sof tushum (yalpi summa − qaytarilgan summa)
/// - Birlik va valyuta — mahsulotning o'ziga xos ma'lumotidan.
class _ProductCarousel extends ConsumerWidget {
  const _ProductCarousel({
    required this.productions,
    required this.fmt,
    required this.batchCountSuffix,
    required this.fallbackUnit,
    required this.fallbackCurrency,
  });

  final List<ProductionModel> productions;
  final String Function(dynamic) fmt;
  final String batchCountSuffix;
  final String fallbackUnit;
  final String fallbackCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = Responsive.horizontalPadding(context);
    final localeCode =
        ref.watch(localeProvider.select((a) => (a.value ?? AppLocale.uz).code));

    if (productions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: const _ProductCarouselEmpty(),
      );
    }

    final groups = _groupProductions(
      productions,
      fallbackUnit: fallbackUnit,
      fallbackCurrency: fallbackCurrency,
      localeCode: localeCode,
    );

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pad),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => RepaintBoundary(
          child: _ProductSummaryCard(
            group: groups[i],
            fmt: fmt,
            onTap: () => _showProductDetail(
              context,
              group: groups[i],
              fmt: fmt,
              batchCountSuffix: batchCountSuffix,
            ),
          ),
        ),
      ),
    );
  }

  static List<_ProductGroup> _groupProductions(
    List<ProductionModel> list, {
    required String fallbackUnit,
    required String fallbackCurrency,
    required String localeCode,
  }) {
    final map = <String, _ProductGroup>{};
    for (final p in list) {
      final cat = p.breadCategory;
      final unit = cat?.measurementUnit?.localizedName(localeCode) ??
          cat?.measurementUnit?.code ??
          fallbackUnit;
      final currency = cat?.priceSuffix(fallbackCurrency) ?? fallbackCurrency;
      final name = cat?.name ?? '';

      final existing = map[p.breadCategoryId];
      if (existing == null) {
        map[p.breadCategoryId] = _ProductGroup(
          categoryId: p.breadCategoryId,
          name: name,
          unit: unit,
          currency: currency,
          producedQty: p.breadProduced.toDouble(),
          returnedQty: p.returnsQuantityAllocated.toDouble(),
          grossAmount: p.grossRevenue,
          returnsAmount: p.returnsAmount,
          batches: [p],
        );
      } else {
        existing
          ..producedQty += p.breadProduced
          ..returnedQty += p.returnsQuantityAllocated
          ..grossAmount += p.grossRevenue
          ..returnsAmount += p.returnsAmount
          ..batches.add(p);
      }
    }
    final groups = map.values.toList()
      ..sort((a, b) => b.netAmount.compareTo(a.netAmount));
    return groups;
  }

  static void _showProductDetail(
    BuildContext context, {
    required _ProductGroup group,
    required String Function(dynamic) fmt,
    required String batchCountSuffix,
  }) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        group: group,
        fmt: fmt,
        batchCountSuffix: batchCountSuffix,
      ),
    );
  }
}

/// Bitta mahsulot turi uchun bugungi xulosa.
class _ProductGroup {
  _ProductGroup({
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.currency,
    required this.producedQty,
    required this.returnedQty,
    required this.grossAmount,
    required this.returnsAmount,
    required this.batches,
  });

  final String categoryId;
  final String name;
  final String unit;
  final String currency;
  double producedQty;
  double returnedQty;
  double grossAmount;
  double returnsAmount;
  final List<ProductionModel> batches;

  double get netQty => producedQty - returnedQty;
  double get netAmount => grossAmount - returnsAmount;
  bool get hasReturns => returnedQty > 0 || returnsAmount > 0;
}

/// Karuseldagi yagona ko'rinadigan ikonka — har xil mahsulot uchun ham mos.
const IconData _kProductIcon = Icons.inventory_2_rounded;

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.group,
    required this.fmt,
    required this.onTap,
  });

  final _ProductGroup group;
  final String Function(dynamic) fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = Responsive.isTablet(context);

    return SizedBox(
      width: isTablet ? 158 : 132,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(_kProductIcon,
                            color: cs.primary, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          fmt(group.netQty),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.unit,
                        style: TextStyle(
                          color: cs.primary.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${fmt(group.netAmount)} ${group.currency}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCarouselEmpty extends StatelessWidget {
  const _ProductCarouselEmpty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 108,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.32 : 0.55,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.4 : 0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_kProductIcon,
                color: cs.primary.withValues(alpha: 0.7), size: 18),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dashboardCarouselEmptyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.dashboardCarouselEmptySubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
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

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({
    required this.group,
    required this.fmt,
    required this.batchCountSuffix,
  });

  final _ProductGroup group;
  final String Function(dynamic) fmt;
  final String batchCountSuffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_kProductIcon,
                        color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fmt(group.batches.length)} $batchCountSuffix',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _DetailStatBlock(
                    rows: [
                      _DetailStatRow(
                        label: s.productDetailProduced,
                        value: '${fmt(group.producedQty)} ${group.unit}',
                        color: cs.onSurface,
                      ),
                      _DetailStatRow(
                        label: s.productDetailReturnedQty,
                        value: group.returnedQty > 0
                            ? '${fmt(group.returnedQty)} ${group.unit}'
                            : '—',
                        color: group.returnedQty > 0
                            ? AppColors.error
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                      _DetailStatRow(
                        label: s.productDetailNetQty,
                        value: '${fmt(group.netQty)} ${group.unit}',
                        color: cs.onSurface,
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailStatBlock(
                    rows: [
                      _DetailStatRow(
                        label: s.productDetailGross,
                        value:
                            '${fmt(group.grossAmount)} ${group.currency}',
                        color: cs.onSurface,
                      ),
                      _DetailStatRow(
                        label: s.productDetailReturnsAmount,
                        value: group.returnsAmount > 0
                            ? '${fmt(group.returnsAmount)} ${group.currency}'
                            : '—',
                        color: group.returnsAmount > 0
                            ? AppColors.error
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                      _DetailStatRow(
                        label: s.productDetailNetAmount,
                        value:
                            '${fmt(group.netAmount)} ${group.currency}',
                        color: AppColors.success,
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.productDetailBatchesTitle,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < group.batches.length; i++) ...[
                    _BatchRow(
                      index: i + 1,
                      batch: group.batches[i],
                      unit: group.unit,
                      currency: group.currency,
                      fmt: fmt,
                      isDark: isDark,
                      cs: cs,
                      returnedSuffix: s.productDetailReturnedSuffix,
                    ),
                    if (i < group.batches.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatBlock extends StatelessWidget {
  const _DetailStatBlock({required this.rows});
  final List<_DetailStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.35 : 0.55,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 1,
                  color: cs.onSurface.withValues(alpha: 0.05),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailStatRow extends StatelessWidget {
  const _DetailStatRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.index,
    required this.batch,
    required this.unit,
    required this.currency,
    required this.fmt,
    required this.isDark,
    required this.cs,
    required this.returnedSuffix,
  });

  final int index;
  final ProductionModel batch;
  final String unit;
  final String currency;
  final String Function(dynamic) fmt;
  final bool isDark;
  final ColorScheme cs;
  final String returnedSuffix;

  @override
  Widget build(BuildContext context) {
    final time = formatTimeHm(batch.createdAt);
    final hasRet = batch.returnsQuantityAllocated > 0 || batch.returnsAmount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.25 : 0.4,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (time != null)
                TimeBadge(time: time, compact: true)
              else
                Text(
                  '—',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              const Spacer(),
              Text(
                '${fmt(batch.breadProduced)} $unit',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${fmt(batch.grossRevenue)} $currency',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (hasRet) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  const Icon(Icons.undo_rounded,
                      size: 12, color: AppColors.error),
                  const SizedBox(width: 5),
                  Text(
                    '$returnedSuffix ${fmt(batch.returnsQuantityAllocated)} $unit · ${fmt(batch.returnsAmount)} $currency',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    if (productions.isEmpty) {
      return const _DashboardEmptyState(
        icon: Icons.local_fire_department_outlined,
        textKey: _EmptyStateText.output,
      );
    }

    return Column(
      children: [
        for (final p in productions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductionSummaryCard(
              production: p,
              fmt: fmt,
              productUnit: productUnit,
              batchCountSuffix: batchCountSuffix,
            ),
          ),
      ],
    );
  }
}

enum _EmptyStateText { output, expense }

class _DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final _EmptyStateText textKey;

  const _DashboardEmptyState({required this.icon, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final text = switch (textKey) {
      _EmptyStateText.output => s.dashboardEmptyOutput,
      _EmptyStateText.expense => s.dashboardEmptyExpense,
    };

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
          Icon(icon, size: 40, color: cs.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  final List<ExpenseModel> expenses;
  final String Function(dynamic) fmt;
  final String currency;

  const _ExpenseList({
    required this.expenses,
    required this.fmt,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const _DashboardEmptyState(
        icon: Icons.payments_outlined,
        textKey: _EmptyStateText.expense,
      );
    }

    return Column(
      children: [
        for (final e in expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DashboardExpenseCard(
              expense: e,
              fmt: fmt,
              currency: currency,
              onTap: () => showExpenseActions(
                context,
                ref: ref,
                expense: e,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String Function(dynamic) fmt;
  final String currency;
  final VoidCallback? onTap;

  const _DashboardExpenseCard({
    required this.expense,
    required this.fmt,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    final timeStr = formatTimeHm(expense.createdAt);

    return Material(
      color: cs.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.error,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.displayCategoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (timeStr != null) ...[
                          const SizedBox(width: 8),
                          TimeBadge(time: timeStr, compact: true),
                        ],
                      ],
                    ),
                    if (expense.description != null &&
                        expense.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        expense.description!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${fmt(expense.amount)} $currency',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/shop_permissions.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/shell_tab_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../../home/presentation/screens/expenses_screen.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../../statistics/presentation/screens/report_screen.dart';

/// Shell tab turlari. Ko'rinishi foydalanuvchi ruxsatlariga bog'liq.
enum ShellTab { home, expenses, statistics }

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> with RouteAware {
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _expensesKey = GlobalKey<ExpensesScreenState>();

  /// Android hardware back uchun "ikki marta bosib chiqish" logikasi.
  DateTime? _lastBackPressAt;
  static const _backExitWindow = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(breadCategoryProvider.notifier).load();
      ref.read(ingredientProvider.notifier).load();
      ref.read(recipeProvider.notifier).load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Boshqa ekrandan shell'ga qaytilganda chaqiriladi.
  /// Bosh tab faol bo'lsa — dashboard sanasini bugunga tiklaymiz.
  @override
  void didPopNext() {
    final tabs = _visibleTabs(ref.read(currentPermissionsProvider));
    final index = _clampIndex(ref.read(shellTabIndexProvider), tabs.length);
    if (tabs[index] == ShellTab.home) {
      _dashboardKey.currentState?.resetToToday();
    }
  }

  /// Joriy ruxsatlarga qarab ko'rinadigan tablar ro'yxati.
  /// Home hammaga; Statistics -> view_reports; Expenses -> manage_expenses.
  List<ShellTab> _visibleTabs(Set<String> perms) {
    final isOwner = ref.read(isOwnerProvider);
    return [
      ShellTab.home,
      if (isOwner || perms.contains(ShopPermissions.manageExpenses))
        ShellTab.expenses,
      if (isOwner || perms.contains(ShopPermissions.viewReports))
        ShellTab.statistics,
    ];
  }

  int _clampIndex(int index, int length) {
    if (length == 0) return 0;
    return index.clamp(0, length - 1);
  }

  void _onTabTap(List<ShellTab> tabs, int index) {
    ref.read(shellTabIndexProvider.notifier).setIndex(index);

    switch (tabs[index]) {
      case ShellTab.home:
        _dashboardKey.currentState?.resetToToday();
      case ShellTab.expenses:
        _expensesKey.currentState?.refresh();
      case ShellTab.statistics:
        break;
    }
  }

  Future<void> _handleSystemBack(S s, List<ShellTab> tabs) async {
    final index = _clampIndex(ref.read(shellTabIndexProvider), tabs.length);

    if (tabs[index] != ShellTab.home) {
      HapticFeedback.selectionClick();
      _onTabTap(tabs, tabs.indexOf(ShellTab.home));
      return;
    }

    final now = DateTime.now();
    final last = _lastBackPressAt;
    if (last == null || now.difference(last) > _backExitWindow) {
      _lastBackPressAt = now;
      HapticFeedback.selectionClick();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: _backExitWindow,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            content: Text(s.pressBackAgainToExit),
          ),
        );
      return;
    }

    await SystemNavigator.pop();
  }

  Widget _buildTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.home:
        return DashboardScreen(key: _dashboardKey);
      case ShellTab.expenses:
        return ExpensesScreen(key: _expensesKey);
      case ShellTab.statistics:
        return const ReportScreen();
    }
  }

  ({IconData icon, IconData activeIcon, String label}) _navMeta(
      ShellTab tab, S s) {
    switch (tab) {
      case ShellTab.home:
        return (
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: s.home,
        );
      case ShellTab.expenses:
        return (
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          label: s.cashbox,
        );
      case ShellTab.statistics:
        return (
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          label: s.statistics,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final perms = ref.watch(currentPermissionsProvider);
    final tabs = _visibleTabs(perms);
    final currentIndex = _clampIndex(ref.watch(shellTabIndexProvider), tabs.length);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemBack(s, tabs);
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [for (final tab in tabs) _buildTab(tab)],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _NavItem(
                      meta: _navMeta(tabs[i], s),
                      isActive: currentIndex == i,
                      onTap: () => _onTabTap(tabs, i),
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

class _NavItem extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String label}) meta;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.meta,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color =
        isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.38);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? meta.activeIcon : meta.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(meta.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

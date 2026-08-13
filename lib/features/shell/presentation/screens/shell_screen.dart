import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../core/constants/shop_permissions.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/shell_tab.dart';
import '../../domain/shell_tab_provider.dart';
import '../../domain/shell_tab_utils.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../../cash/presentation/screens/cash_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> with RouteAware {
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _cashKey = GlobalKey<CashScreenState>();
  final _ordersKey = GlobalKey<OrdersScreenState>();
  final _activatedTabs = <ShellTab>{ShellTab.home};
  List<ShellTab> _previousVisibleTabs = const [ShellTab.home];
  ShellTab? _selectedTabIdentity;

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
    final storedIndex = ref.read(shellTabIndexProvider);
    final index = reconcileShellTabIndex(
      previousTabs: _previousVisibleTabs,
      previousIndex: storedIndex,
      nextTabs: tabs,
      selectedIdentity: _selectedTabIdentity,
    );
    if (tabs[index] == ShellTab.home) {
      _dashboardKey.currentState?.resetToToday();
    }
  }

  /// Joriy ruxsatlarga qarab ko'rinadigan tablar ro'yxati.
  /// Home va Profil hammaga; qolganlari — mos ruxsat bo'lsa.
  List<ShellTab> _visibleTabs(Set<String> perms) {
    final isOwner = ref.read(isOwnerProvider);
    return [
      ShellTab.home,
      if (isOwner || perms.contains(ShopPermissions.manageExpenses))
        ShellTab.expenses,
      if (isOwner || perms.contains(ShopPermissions.viewReports))
        ShellTab.statistics,
      if (isOwner || perms.contains(ShopPermissions.manageOrders))
        ShellTab.orders,
      ShellTab.profile,
    ];
  }

  int _clampIndex(int index, int length) {
    if (length == 0) return 0;
    return index.clamp(0, length - 1);
  }

  void _activateTab(ShellTab tab) {
    if (_activatedTabs.add(tab)) {
      setState(() {});
    }
  }

  void _onTabTap(List<ShellTab> tabs, int index) {
    _selectedTabIdentity = tabs[index];
    _activateTab(tabs[index]);
    ref.read(shellTabIndexProvider.notifier).setIndex(index);

    switch (tabs[index]) {
      case ShellTab.home:
        _dashboardKey.currentState?.resetToToday();
      case ShellTab.expenses:
        _cashKey.currentState?.refresh();
      case ShellTab.statistics:
        break;
      case ShellTab.orders:
        _ordersKey.currentState?.refresh();
      case ShellTab.profile:
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
    if (!_activatedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }
    switch (tab) {
      case ShellTab.home:
        return DashboardScreen(key: _dashboardKey);
      case ShellTab.expenses:
        return CashScreen(key: _cashKey);
      case ShellTab.statistics:
        return const StatisticsScreen();
      case ShellTab.orders:
        return OrdersScreen(key: _ordersKey);
      case ShellTab.profile:
        return const ProfileScreen();
    }
  }

  ({IconData icon, IconData activeIcon, String label}) _navMeta(
    ShellTab tab,
    S s,
  ) {
    switch (tab) {
      case ShellTab.home:
        return (
          icon: SolarIconsOutline.homeSmile,
          activeIcon: SolarIconsBold.homeSmile,
          label: s.home,
        );
      case ShellTab.expenses:
        return (
          icon: SolarIconsOutline.walletMoney,
          activeIcon: SolarIconsBold.walletMoney,
          label: s.cashbox,
        );
      case ShellTab.statistics:
        return (
          icon: SolarIconsOutline.chartSquare,
          activeIcon: SolarIconsBold.chartSquare,
          label: s.statistics,
        );
      case ShellTab.orders:
        return (
          icon: SolarIconsOutline.clipboardList,
          activeIcon: SolarIconsBold.clipboardList,
          label: s.orders,
        );
      case ShellTab.profile:
        return (
          icon: SolarIconsOutline.userCircle,
          activeIcon: SolarIconsBold.userCircle,
          label: s.profileTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final perms = ref.watch(currentPermissionsProvider);
    final tabs = _visibleTabs(perms);
    final storedIndex = ref.watch(shellTabIndexProvider);
    final reconciledIndex = reconcileShellTabIndex(
      previousTabs: _previousVisibleTabs,
      previousIndex: storedIndex,
      nextTabs: tabs,
      selectedIdentity: _selectedTabIdentity,
    );
    if (reconciledIndex != storedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(shellTabIndexProvider.notifier).setIndex(reconciledIndex);
      });
    }
    _previousVisibleTabs = tabs;
    if (_selectedTabIdentity == null ||
        !tabs.contains(_selectedTabIdentity)) {
      _selectedTabIdentity =
          reconciledIndex < tabs.length ? tabs[reconciledIndex] : ShellTab.home;
    }
    final currentIndex = reconciledIndex;

    if (!_activatedTabs.contains(tabs[currentIndex])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activateTab(tabs[currentIndex]);
      });
    }

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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        meta: _navMeta(tabs[i], s),
                        isActive: currentIndex == i,
                        onTap: () => _onTabTap(tabs, i),
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
    final color = isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? meta.activeIcon : meta.icon,
              size: 23,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              meta.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

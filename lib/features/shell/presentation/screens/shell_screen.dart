import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/translations.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/shell_tab_provider.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../../home/presentation/screens/history_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../../statistics/presentation/screens/report_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> with RouteAware {
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _historyKey = GlobalKey<HistoryScreenState>();

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
    final currentIndex = ref.read(shellTabIndexProvider);
    if (currentIndex == 0) {
      _dashboardKey.currentState?.resetToToday();
    }
  }

  void _onTabTap(int index) {
    ref.read(shellTabIndexProvider.notifier).setIndex(index);

    if (index == 0) {
      _dashboardKey.currentState?.resetToToday();
    } else if (index == 1) {
      _historyKey.currentState?.refresh();
    }
  }

  /// Handles the Android hardware back gesture for the shell.
  ///
  /// Order of resolution:
  /// 1. If current tab is not Home → switch to Home tab silently.
  /// 2. If already on Home → show a "press again to exit" snackbar; if the
  ///    user presses back again within [_backExitWindow], exit the app.
  Future<void> _handleSystemBack(S s) async {
    final index = ref.read(shellTabIndexProvider);

    if (index != 0) {
      HapticFeedback.selectionClick();
      _onTabTap(0);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentIndex = ref.watch(shellTabIndexProvider);
    final s = S.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemBack(s);
      },
      child: Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          DashboardScreen(key: _dashboardKey),
          HistoryScreen(key: _historyKey),
          const ReportScreen(),
          const OrdersScreen(),
        ],
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
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: s.home,
                  isActive: currentIndex == 0,
                  onTap: () => _onTabTap(0),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: s.navHistory,
                  isActive: currentIndex == 1,
                  onTap: () => _onTabTap(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: s.statistics,
                  isActive: currentIndex == 2,
                  onTap: () => _onTabTap(2),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: s.orders,
                  isActive: currentIndex == 3,
                  onTap: () => _onTabTap(3),
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
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
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
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(label,
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

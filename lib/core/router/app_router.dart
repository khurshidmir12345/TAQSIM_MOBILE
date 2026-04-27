import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/telegram_auth_screen.dart';
import '../../features/auth/presentation/screens/shop_create_screen.dart';
import '../../features/auth/presentation/screens/shop_select_screen.dart';
import '../../features/home/presentation/screens/production_create_screen.dart';
import '../../features/home/domain/models/production_model.dart';
import '../../features/home/presentation/screens/production_detail_screen.dart';
import '../l10n/translations.dart';
import '../../features/home/presentation/screens/return_create_screen.dart';
import '../../features/home/presentation/screens/expense_create_screen.dart';
import '../../features/home/presentation/screens/history_screen.dart';
import '../../features/onboarding/presentation/screens/language_selection_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/setup/presentation/screens/setup_screen.dart';
import '../../features/setup/presentation/screens/bread_categories_screen.dart';
import '../../features/setup/presentation/screens/ingredients_screen.dart';
import '../../features/setup/presentation/screens/recipe_create_screen.dart';
import '../../features/setup/presentation/screens/recipes_screen.dart';
import '../../features/shell/presentation/screens/shell_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/about_app_screen.dart';
import '../../features/profile/presentation/screens/profile_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/top_up_screen.dart';
import '../../features/statistics/presentation/screens/report_screen.dart';
import '../../features/statistics/presentation/screens/charts_screen.dart';

/// Global route observer — ekranlar RouteAware mixinini qo‘llab kuzatishi uchun.
/// Masalan, dashboard qayta ochilganda sana filterini tozalash uchun.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    observers: [appRouteObserver],
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isOnSplash = location == '/';
      final isOnOnboarding =
          location == '/language-selection' || location == '/onboarding';
      final isOnAuth = location == '/login' ||
          location == '/register' ||
          location == '/telegram-auth';

      if (isOnOnboarding) return null;

      if (authState.status == AuthStatus.initial) {
        return isOnSplash ? null : '/';
      }

      if (authState.status == AuthStatus.unauthenticated) {
        return isOnAuth ? null : '/login';
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isOnSplash || isOnAuth) {
          final shopState = ref.read(shopProvider);
          if (shopState.shops.isEmpty && !shopState.isLoading) {
            return '/shop-select';
          }
          return '/shell';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language-selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/telegram-auth',
        builder: (context, state) => const TelegramAuthScreen(),
      ),
      GoRoute(
        path: '/shop-select',
        builder: (context, state) => const ShopSelectScreen(),
      ),
      GoRoute(
        path: '/shop-create',
        builder: (context, state) => const ShopCreateScreen(),
      ),
      GoRoute(
        path: '/shell',
        builder: (context, state) => const ShellScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/bread-categories',
        builder: (context, state) => const BreadCategoriesScreen(),
      ),
      GoRoute(
        path: '/ingredients',
        builder: (context, state) => const IngredientsScreen(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipesScreen(),
      ),
      GoRoute(
        path: '/recipe-create',
        builder: (context, state) => const RecipeCreateScreen(),
      ),
      GoRoute(
        path: '/production-create',
        builder: (context, state) => const ProductionCreateScreen(),
      ),
      GoRoute(
        path: '/production-detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! ProductionModel) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    S.of(context).snackbarErrorGeneric,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return ProductionDetailScreen(production: extra);
        },
      ),
      GoRoute(
        path: '/return-create',
        builder: (context, state) => const ReturnCreateScreen(),
      ),
      GoRoute(
        path: '/expense-create',
        builder: (context, state) => const ExpenseCreateScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile-info',
        builder: (context, state) => const ProfileInfoScreen(),
      ),
      GoRoute(
        path: '/about-app',
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: '/top-up',
        builder: (context, state) => const TopUpScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/charts',
        builder: (context, state) => const ChartsScreen(),
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription _sub;

  _AuthRefreshNotifier(Ref ref) {
    _sub = ref.listen(authProvider, (_, _) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

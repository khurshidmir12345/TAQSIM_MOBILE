import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
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
import '../../features/profile/presentation/screens/telegram_connect_screen.dart';
import '../../features/profile/presentation/screens/devices_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/employees/presentation/screens/employees_screen.dart';
import '../../features/statistics/presentation/screens/report_screen.dart';
import '../../features/statistics/presentation/screens/charts_screen.dart';
import '../../features/orders/presentation/screens/order_create_screen.dart';
import '../../features/orders/presentation/screens/order_edit_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/customers_screen.dart';
import '../../features/orders/presentation/screens/customer_form_screen.dart';
import '../../features/orders/presentation/screens/customer_detail_screen.dart';
import '../../features/orders/domain/models/customer_model.dart';

/// Global route observer — ekranlar RouteAware mixinini qo‘llab kuzatishi uchun.
/// Masalan, dashboard qayta ochilganda sana filterini tozalash uchun.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Faqat biznes egasiga (owner) ruxsat etilgan sahifalar.
/// Seller bu manzillarga yozsa — `/shell`ga qaytariladi.
const Set<String> _ownerOnlyRoutes = {'/employees'};

/// Tizimga kirmagan foydalanuvchi ocha oladigan sahifalar.
/// Bu ro'yxatda bo'lmagan manzil `/login`ga qaytariladi — shuning uchun
/// parolni tiklash kabi yangi ochiq sahifalar shu yerga qo'shilishi shart.
const Set<String> _authRoutes = {
  '/login',
  '/register',
  '/telegram-auth',
  '/forgot-password',
};

/// Push bildirishnoma bosilganda ilova ichida yo'naltirish uchun kerak
/// (o'sha paytda BuildContext qo'lda bo'lmaydi).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    observers: [appRouteObserver],
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isOnSplash = location == '/';
      final isOnOnboarding =
          location == '/language-selection' || location == '/onboarding';
      final isOnAuth = _authRoutes.contains(location);

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
          // Biznes tanlangan bo'lsa — to'g'ri asosiy sahifaga (/shell).
          if (shopState.selected != null) return '/shell';
          // Yuklanib bo'lib, biznes umuman yo'q bo'lsa — biznes tanlash.
          if (shopState.loadedOnce) return '/shop-select';
          // Hali yuklanmagan — sahifani o'zgartirmaymiz; do'konlar yuklangach
          // (login ekrani yoki splash) aniq navigatsiya qiladi. Bu social
          // login'da "bizneslar" sahifasiga noto'g'ri o'tib ketishning oldini oladi.
          return null;
        }

        // Owner-only sahifalarga sellerni kiritmaslik (xavfsizlik to'ri).
        // Bu sahifalar UI menyusida sellerga ko'rsatilmaydi; bu — qo'shimcha himoya.
        if (_ownerOnlyRoutes.contains(location) && ref.read(isSellerProvider)) {
          return '/shell';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/language-selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
      GoRoute(path: '/shell', builder: (context, state) => const ShellScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
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
        path: '/telegram-connect',
        builder: (context, state) => const TelegramConnectScreen(),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DevicesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: '/about-app',
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/charts',
        builder: (context, state) => const ChartsScreen(),
      ),
      GoRoute(
        path: '/order-create',
        builder: (context, state) {
          final extra = state.extra;
          return OrderCreateScreen(
            initialCustomer: extra is CustomerModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderEditScreen(orderId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/customer-create',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customer-edit',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! CustomerModel) {
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
          return CustomerFormScreen(customer: extra);
        },
      ),
    ],
  );

  return router;
});

class _AuthRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _shopSub;

  _AuthRefreshNotifier(Ref ref) {
    _authSub = ref.listen(authProvider, (_, _) {
      notifyListeners();
    });
    // Do'konlar yuklanib, biznes tanlangach (yoki bo'sh ekani aniqlangach)
    // redirect qayta hisoblanib, to'g'ri sahifaga o'tadi.
    _shopSub = ref.listen(
      shopProvider.select((s) => (s.selected?.id, s.loadedOnce)),
      (_, _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _authSub.close();
    _shopSub.close();
    super.dispose();
  }
}

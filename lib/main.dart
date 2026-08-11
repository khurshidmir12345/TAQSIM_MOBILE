import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/api/api_client.dart';
import 'core/api/device_info.dart';
import 'core/l10n/app_locale.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'features/app_update/domain/app_update_provider.dart';
import 'features/app_update/presentation/app_update_dialog.dart';
import 'features/notifications/domain/providers/push_sync_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_environment.dart';
import 'core/widgets/dev_environment_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnvironment.ensureValidConfiguration();

  await initializeDateFormatting('uz');
  await initializeDateFormatting('ru');
  await initializeDateFormatting('kk');
  await initializeDateFormatting('tr');
  await initializeDateFormatting('en');

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase konfiguratsiyasi native fayllardan olinadi
  // (google-services.json / GoogleService-Info.plist).
  // Push sozlanmagan bo'lsa ham ilova ishlashda davom etsin.
  try {
    await Firebase.initializeApp();
    await PushService.init();
  } catch (e) {
    debugPrint('[push] Firebase ishga tushmadi: $e');
  }

  // Multi-device sessiya uchun qurilma metama'lumotini barcha so'rovlarga ulaymiz.
  await DeviceInfo.attachToClient(ApiClient());

  runApp(const ProviderScope(child: TaqseemApp()));
}

class TaqseemApp extends ConsumerStatefulWidget {
  const TaqseemApp({super.key});

  @override
  ConsumerState<TaqseemApp> createState() => _TaqseemAppState();
}

class _TaqseemAppState extends ConsumerState<TaqseemApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkHandlerProvider).start();
      ref.read(pushSyncProvider).start();
      _checkForUpdate();

      // Bildirishnoma bosilganda ro'yxat ekraniga o'tamiz.
      PushService.onOpened = () {
        rootNavigatorKey.currentContext?.push('/notifications');
      };
    });
  }

  /// Ilova ochilganda bir marta versiya tekshiriladi.
  ///
  /// Tekshiruv login'gacha ham ishlaydi. Xato bo'lsa jim o'tib ketiladi —
  /// modalka tufayli ilova ochilmay qolmasin.
  Future<void> _checkForUpdate() async {
    final info = await ref.read(appUpdateCheckProvider.future);

    if (!info.updateAvailable) return;

    // Splash o'z yo'nalishini tugatgach chiqsin — aks holda modalka
    // almashayotgan ekran ostida qolib ketishi mumkin.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await AppUpdateDialog.show(context, info);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeAsync = ref.watch(localeProvider);
    final appLocale = localeAsync.value ?? AppLocale.uz;
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: materialLocaleFor(appLocale),
      supportedLocales: AppLocale.values.map((e) => e.locale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        return materialLocaleFor(appLocale);
      },
      builder: (context, child) {
        return DevEnvironmentBanner(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
    );
  }
}

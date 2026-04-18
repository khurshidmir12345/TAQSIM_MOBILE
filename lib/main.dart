import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/l10n/app_locale.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('uz');
  await initializeDateFormatting('ru');
  await initializeDateFormatting('kk');
  await initializeDateFormatting('tr');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
    });
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
      routerConfig: router,
    );
  }
}

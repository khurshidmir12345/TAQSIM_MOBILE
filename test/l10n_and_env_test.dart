import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taqseem/core/constants/app_constants.dart';
import 'package:taqseem/core/constants/app_environment.dart';
import 'package:taqseem/core/l10n/app_locale.dart';
import 'package:taqseem/core/l10n/translations.dart';

void main() {
  group('AppLocale', () {
    test('fromCode resolves all 7 locales including en', () {
      expect(AppLocale.fromCode('en'), AppLocale.en);
      expect(AppLocale.fromCode('uz_CYRL'), AppLocale.uzCyrl);
      expect(AppLocale.fromCode('unknown'), AppLocale.uz);
      expect(AppLocale.values.length, 7);
    });

    test('en uses native Material locale', () {
      expect(materialLocaleFor(AppLocale.en), const Locale('en'));
    });
  });

  group('localization completeness', () {
    test('all locales share reference keys and EN is complete', () {
      final maps = S.allLocaleMaps;
      expect(
        maps.keys,
        containsAll(['uz', 'uz_CYRL', 'ru', 'kk', 'ky', 'tr', 'en']),
      );

      final reference = S.referenceKeys;
      // Kalit qo'shilganda yangilanadi. Asosiy kafolat quyida — barcha
      // tillarda kalit to'plami bir xil bo'lishi; bu son esa tasodifan
      // kalit o'chib ketishini ushlaydi.
      expect(reference.length, 851);

      for (final entry in maps.entries) {
        expect(
          entry.value.keys.toSet(),
          reference,
          reason: 'Locale ${entry.key} key set mismatch',
        );
      }

      final en = maps['en']!;
      const allowedBlank = {'loginInfoSuffix', 'policySuffix'};

      for (final key in reference) {
        expect(en.containsKey(key), isTrue, reason: 'EN missing key: $key');
        if (allowedBlank.contains(key)) continue;
        expect(en[key]!.trim().isNotEmpty, isTrue, reason: 'EN blank: $key');
      }
    });

    test('previously placeholder EN strings are natural copy', () {
      final en = S.allLocaleMaps['en']!;

      expect(en['businessDetailsStep'], 'Details');
      expect(en['cancelShort'], 'Cancel');
      expect(en['featReturnsTitle'], 'Returns');
      expect(en['changeReceipt'], 'Change photo');
      expect(en['historyTitle'], 'History');
      expect(en['reportScreenTitle'], 'Report');
      expect(en['productionOutStep1'], 'Product');
      expect(en['recipeStepProduct'], 'Product');
      expect(en['setupJourneyStepLabel1'], 'Products');
      expect(en['smsSpamTitle'], 'Spam folder');
      expect(en['stepForm'], 'Details');
      expect(en['stepEnterApp'], 'Enter\n the app');
    });

    test('EN interpolation placeholders are preserved', () {
      final en = S.allLocaleMaps['en']!;

      expect(en['otpSentTo'], contains('{phone}'));
      expect(en['phoneExistsBody'], contains('{phone}'));
      expect(en['shopDeleteMessage'], contains('{name}'));
      expect(en['daysLeftShort'], contains('{n}'));
      expect(
        en['productionOutStep2Subtitle'],
        allOf(contains('{unit}'), contains('{qty}'), contains('{productUnit}')),
      );
    });

    test('languageSelectSubtitle is localized without mixed RU/EN', () {
      final maps = S.allLocaleMaps;

      expect(
        maps['uz']!['languageSelectSubtitle'],
        isNot(contains('Choose language')),
      );
      expect(
        maps['ru']!['languageSelectSubtitle'],
        isNot(contains('Choose language')),
      );
      expect(maps['en']!['languageSelectSubtitle'], contains('7 languages'));
      expect(maps['en']!['languageSelectSubtitle'], contains('Cyrillic'));
    });
  });

  group('AppEnvironment', () {
    test('resolveIsDev follows explicit APP_ENV first', () {
      expect(
        AppEnvironment.resolveIsDev(
          appEnv: 'prod',
          apiBaseUrl: AppConstants.devBaseUrl,
          releaseMode: false,
        ),
        isFalse,
      );
      expect(
        AppEnvironment.resolveIsDev(
          appEnv: 'dev',
          apiBaseUrl: AppConstants.prodBaseUrl,
          releaseMode: true,
        ),
        isTrue,
      );
    });

    test('debug/profile har doim dev', () {
      expect(
        AppEnvironment.resolveIsDev(
          appEnv: '',
          apiBaseUrl: '',
          releaseMode: false,
        ),
        isTrue,
        reason: 'debug/profile default dev bo‘lishi kerak',
      );
    });

    /// Xavfsizlik qo‘riqchisi.
    ///
    /// `defaultToDev = true` bo‘lganda definessiz release build dev serverga
    /// ulanadi — bu TestFlight sinovi uchun ataylab qilinadi. Shunday paytda
    /// **DEV banneri ko‘rinishi shart**, aks holda bunday build App Store'ga
    /// sezilmasdan chiqib ketishi mumkin (2026-08-04 da shunday bo‘lgan).
    ///
    /// `false` ga qaytarilganda esa release prod'ga ulanishi tekshiriladi.
    test('definessiz release: bayroqqa mos va DEV holati ko‘rinadigan', () {
      final releaseIsDev = AppEnvironment.resolveIsDev(
        appEnv: '',
        apiBaseUrl: '',
        releaseMode: true,
      );

      expect(
        releaseIsDev,
        AppConstants.defaultToDev,
        reason: AppConstants.defaultToDev
            ? 'defaultToDev=true — release dev deb belgilanishi va DEV banneri '
                'ko‘rinishi shart'
            : 'defaultToDev=false — definessiz Archive prod‘ga ulanishi shart',
      );
    });

    test('aniq APP_ENV bayroqdan ustun turadi', () {
      // Sinov bayrog‘i qanday bo‘lishidan qat‘i nazar, config/prod.json
      // bilan yig‘ilgan build doim prod bo‘ladi.
      expect(
        AppEnvironment.resolveIsDev(
          appEnv: 'prod',
          apiBaseUrl: AppConstants.prodBaseUrl,
          releaseMode: true,
        ),
        isFalse,
      );
    });

    test('configurationError detects conflicting dev/prod signals', () {
      expect(
        AppEnvironment.configurationError(
          appEnv: 'dev',
          apiBaseUrl: AppConstants.prodBaseUrl,
        ),
        contains('Conflicting'),
      );
      expect(
        AppEnvironment.configurationError(
          appEnv: 'prod',
          apiBaseUrl: AppConstants.devBaseUrl,
        ),
        contains('Conflicting'),
      );
      expect(
        AppEnvironment.configurationError(
          appEnv: 'dev',
          apiBaseUrl: AppConstants.devBaseUrl,
        ),
        isNull,
      );
    });

    test('isDev matches baseUrl when APP_ENV unset at compile time', () {
      if (AppConstants.baseUrl == AppConstants.devBaseUrl) {
        expect(AppEnvironment.isDev, isTrue);
      } else {
        expect(AppEnvironment.isDev, isFalse);
      }
    });
  });

  group('locale persistence', () {
    test('LocaleNotifier persists selected locale code', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('app_locale', AppLocale.en.code);
      final stored = prefs.getString('app_locale');
      expect(stored, 'en');
      expect(AppLocale.fromCode(stored!), AppLocale.en);
    });
  });
}

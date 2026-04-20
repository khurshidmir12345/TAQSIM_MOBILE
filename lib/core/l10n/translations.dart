import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

class S {
  S._(this._locale);

  final String _locale;

  static S of(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      final async = container.read(localeProvider);
      final appLocale = async.value ?? AppLocale.uz;
      return S._(_appLocaleToKey(appLocale));
    } catch (_) {
      final locale = Localizations.localeOf(context);
      return S._(_resolveLocaleKey(locale));
    }
  }

  static String _appLocaleToKey(AppLocale app) {
    switch (app) {
      case AppLocale.uz:
        return 'uz';
      case AppLocale.uzCyrl:
        return 'uz_CYRL';
      case AppLocale.ru:
        return 'ru';
      case AppLocale.kk:
        return 'kk';
      case AppLocale.ky:
        return 'ky';
      case AppLocale.tr:
        return 'tr';
    }
  }

  /// `ru_RU` → `ru`, `uz_CYRL` → `uz_CYRL` — faqat [\_all] kalitlari bilan ishlaydi.
  static String _resolveLocaleKey(Locale locale) {
    final raw = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    if (_all.containsKey(raw)) return raw;
    final lang = locale.languageCode;
    if (_all.containsKey(lang)) return lang;
    return 'uz';
  }

  String _t(String key) => _all[_locale]?[key] ?? _all['uz']![key] ?? key;

  /// Kalit bo‘yicha matn (`s.tr('assetImagesPreview')` kabi).
  String tr(String key) => _t(key);

  // ─── Dashboard ───
  String greeting(String name) => '${_t('hello')}, $name';
  String get defaultUser => _t('defaultUser');
  String get bakery => _t('bakery');
  String get bakeries => _t('bakeries');
  String get selectBusiness => _t('selectBusiness');
  String get selectBusinessSubtitle => _t('selectBusinessSubtitle');
  String get noBusiness => _t('noBusiness');
  String get createFirstBusiness => _t('createFirstBusiness');
  String get addBusiness => _t('addBusiness');
  String get shopSettingsTitle => _t('shopSettingsTitle');
  String get shopNameLabel => _t('shopNameLabel');
  String get shopNameHint => _t('shopNameHint');
  String get shopAddressLabel => _t('shopAddressLabel');
  String get shopAddressHint => _t('shopAddressHint');
  String get shopUpdateSuccess => _t('shopUpdateSuccess');
  String get shopDeleteButton => _t('shopDeleteButton');
  String get shopDeleteTitle => _t('shopDeleteTitle');
  String shopDeleteMessage(String name) => _t('shopDeleteMessage').replaceAll('{name}', name);
  String get shopDeleteSuccess => _t('shopDeleteSuccess');
  String get manage => _t('manage');
  String get todayProfit => _t('todayProfit');
  String get todayLoss => _t('todayLoss');
  String get netRevenue => _t('netRevenue');
  String get expense => _t('expense');
  String get baked => _t('baked');
  String get sack => _t('sack');
  String get sold => _t('sold');
  String get returned => _t('returned');
  String get pcs => _t('pcs');
  String get sacks => _t('sacks');
  String get noBreadToday => _t('noBreadToday');
  String get income => _t('income');
  String get profit => _t('profit');
  String get productOut => _t('productOut');
  String get productReturned => _t('productReturned');
  String get currency => _t('currency');

  /// Asosiy sahifa — KPI va bo‘lim (biznesga umumiy)
  String get dashboardKpiOutput => _t('dashboardKpiOutput');
  String get dashboardKpiBatch => _t('dashboardKpiBatch');
  String get dashboardKpiSold => _t('dashboardKpiSold');
  String get dashboardKpiReturned => _t('dashboardKpiReturned');
  String get dashboardEmptyOutput => _t('dashboardEmptyOutput');
  String get dashboardSectionOutput => _t('dashboardSectionOutput');
  String get dashboardTabOutput => _t('dashboardTabOutput');
  String get dashboardTabExpense => _t('dashboardTabExpense');
  String get dashboardEmptyExpense => _t('dashboardEmptyExpense');
  /// To‘plam / partiya soni yonidagi umumiy birlik (mahsulotga xos emas)
  String get dashboardBatchUnitGeneric => _t('dashboardBatchUnitGeneric');

  // ─── Shell ───
  String get home => _t('home');
  String get cashRegister => _t('cashRegister');
  String get statistics => _t('statistics');
  String get orders => _t('orders');
  String get ordersComingSoon => _t('ordersComingSoon');
  String get ordersComingSoonDesc => _t('ordersComingSoonDesc');
  String get charts => _t('charts');
  String get chartsScreenTitle => _t('chartsScreenTitle');
  String get chartRevenue => _t('chartRevenue');
  String get chartProduction => _t('chartProduction');
  String get chartExpenses => _t('chartExpenses');
  String get chartProfitTrend => _t('chartProfitTrend');
  String get profileTab => _t('profileTab');
  String get navHistory => _t('navHistory');
  String get historyTitle => _t('historyTitle');
  String get historyTabCreated => _t('historyTabCreated');
  String get historyTabReturns => _t('historyTabReturns');
  String get historyTabCash => _t('historyTabCash');
  String get historyTotalReturns => _t('historyTotalReturns');
  String get historyCreatedEmpty => _t('historyCreatedEmpty');
  String get historyReturnsEmpty => _t('historyReturnsEmpty');
  String get returnDetailTitle => _t('returnDetailTitle');

  // ─── Hisobot (/report) ───
  String get reportScreenTitle => _t('reportScreenTitle');
  String get reportPickRange => _t('reportPickRange');
  String get reportPickSingleDate => _t('reportPickSingleDate');
  String get reportChipToday => _t('reportChipToday');
  String get reportChipYesterday => _t('reportChipYesterday');
  String get reportRangeLast7 => _t('reportRangeLast7');
  String get reportRangeLast30 => _t('reportRangeLast30');
  String get reportSectionSummary => _t('reportSectionSummary');
  String get reportSectionReturnsByType => _t('reportSectionReturnsByType');
  String get reportSectionProducts => _t('reportSectionProducts');
  String get reportGrossRevenue => _t('reportGrossRevenue');
  String get reportReturnsRecords => _t('reportReturnsRecords');
  String get reportProductionRecords => _t('reportProductionRecords');
  String get reportEmptyReturns => _t('reportEmptyReturns');
  String get reportEmptyProducts => _t('reportEmptyProducts');
  String get reportProductProduced => _t('reportProductProduced');
  /// Hisobot — ochiluvchi bo‘lim ichida: tur / mahsulot soni
  String reportExpandTypesCount(int n) =>
      _t('reportExpandTypesCount').replaceAll('{n}', '$n');
  String reportExpandProductsCount(int n) =>
      _t('reportExpandProductsCount').replaceAll('{n}', '$n');

  // ─── Kassa ───
  String get noExpenseToday => _t('noExpenseToday');
  String get addExpense => _t('addExpense');
  String get expenseCreateTitle => _t('expenseCreateTitle');
  String get expenseCreateSubtitle => _t('expenseCreateSubtitle');
  String get expenseCategorySearchHint => _t('expenseCategorySearchHint');
  String get expenseAddCategory => _t('expenseAddCategory');
  String get expenseAddCategoryTitle => _t('expenseAddCategoryTitle');
  String get expenseAddCategoryNameHint => _t('expenseAddCategoryNameHint');
  String get expenseAddCategorySave => _t('expenseAddCategorySave');
  String get expenseSelectCategory => _t('expenseSelectCategory');
  String get expenseAmountLabel => _t('expenseAmountLabel');
  String get expenseDescriptionLabel => _t('expenseDescriptionLabel');
  String get expenseSubmit => _t('expenseSubmit');
  String get expenseCategoriesEmpty => _t('expenseCategoriesEmpty');
  String get expenseCategoriesLoadError => _t('expenseCategoriesLoadError');

  // ─── Statistics ───
  String get daily => _t('daily');
  String get weekly => _t('weekly');
  String get monthly => _t('monthly');
  String get loss => _t('loss');
  String get noData => _t('noData');
  String get production => _t('production');
  String get flourUsage => _t('flourUsage');
  String get bakedBread => _t('bakedBread');
  String get ingredients => _t('ingredients');
  String get salesAndReturns => _t('salesAndReturns');
  String get totalProduced => _t('totalProduced');
  String get returns => _t('returns');
  String get soldAuto => _t('soldAuto');
  String get returnAmount => _t('returnAmount');
  String get netIncome => _t('netIncome');
  String get expenses => _t('expenses');
  String get internalIngredients => _t('internalIngredients');
  String get external => _t('external');
  String get total => _t('total');

  // ─── Setup ───
  String get settings => _t('settings');
  String get breadTypes => _t('breadTypes');
  String get breadTypesDesc => _t('breadTypesDesc');
  String get products => _t('products');
  String get productsDesc => _t('productsDesc');
  String get recipes => _t('recipes');
  String get recipesDesc => _t('recipesDesc');
  String get settingsCardTypesTitle => _t('settingsCardTypesTitle');
  String get settingsCardIngredientsTitle => _t('settingsCardIngredientsTitle');
  String get settingsCardRecipesTitle => _t('settingsCardRecipesTitle');

  /// Biznes `key` bo‘yicha (bakery, shashlik, …) misollar matni.
  String settingsTypesDesc(String? businessKey) =>
      _t('settingsTypesDesc_${_settingsBizGroup(businessKey)}');
  String settingsIngredientsDesc(String? businessKey) =>
      _t('settingsIngredientsDesc_${_settingsBizGroup(businessKey)}');
  String settingsRecipesDesc(String? businessKey) =>
      _t('settingsRecipesDesc_${_settingsBizGroup(businessKey)}');

  /// Sozlamalar — boshlash tartibi (step)
  String get setupJourneyTitle => _t('setupJourneyTitle');
  String get setupJourneyHint => _t('setupJourneyHint');
  String get setupJourneyStepLabel1 => _t('setupJourneyStepLabel1');
  String get setupJourneyStepLabel2 => _t('setupJourneyStepLabel2');
  String get setupJourneyStepLabel3 => _t('setupJourneyStepLabel3');
  String get setupJourneyAllDone => _t('setupJourneyAllDone');
  String get settingsCardCompleted => _t('settingsCardCompleted');

  // ─── Retseptlar (hisoblash) ───
  String get recipeScreenTitle => _t('recipeScreenTitle');
  String get recipeEmptyTitle => _t('recipeEmptyTitle');
  String get recipeEmptySubtitle => _t('recipeEmptySubtitle');
  String get recipeAddCta => _t('recipeAddCta');
  String get recipeDeletedSnackbar => _t('recipeDeletedSnackbar');
  String get recipeErrorSnackbar => _t('recipeErrorSnackbar');
  String get recipeCreateTitle => _t('recipeCreateTitle');
  String get recipeStepProduct => _t('recipeStepProduct');
  String get recipeStepBatch => _t('recipeStepBatch');
  String get recipeStepIngredients => _t('recipeStepIngredients');
  String get recipeSelectProductTitle => _t('recipeSelectProductTitle');
  String get recipeSelectProductSubtitle => _t('recipeSelectProductSubtitle');
  String get recipeAlreadyExists => _t('recipeAlreadyExists');
  String get recipeBatchCarouselTitle => _t('recipeBatchCarouselTitle');
  String get recipeBatchCarouselSubtitle => _t('recipeBatchCarouselSubtitle');
  String get recipeOutputLabel => _t('recipeOutputLabel');
  String get recipeOutputHint => _t('recipeOutputHint');
  String get recipeOutputSectionTitle => _t('recipeOutputSectionTitle');
  String get recipeOutputSectionHelper => _t('recipeOutputSectionHelper');
  String get recipeIngredientsSectionTitle => _t('recipeIngredientsSectionTitle');
  String get recipeIngredientsSectionSubtitle => _t('recipeIngredientsSectionSubtitle');

  /// Retsept 2-qadami: tanlangan partiya birligi bo'yicha mahsulot sonini
  /// so'rovchi dinamik sarlavha. `{unit}` joyiga kichik harfli birlik nomi
  /// qo'yiladi (masalan: "1 blokdan qancha mahsulot chiqadi?").
  String recipeOutputLabelDynamic(String unit) =>
      _t('recipeOutputLabelDynamic').replaceAll('{unit}', unit);

  /// Retsept 3-qadami: partiya birligiga mos xom ashyo bo'limi sarlavhasi.
  String recipeIngredientsSectionTitleDynamic(String unit) =>
      _t('recipeIngredientsSectionTitleDynamic').replaceAll('{unit}', unit);

  /// Retsept 3-qadami: partiya birligiga mos xom ashyo bo'limi tavsifi.
  String recipeIngredientsSectionSubtitleDynamic(String unit) =>
      _t('recipeIngredientsSectionSubtitleDynamic').replaceAll('{unit}', unit);
  String get recipeAddIngredient => _t('recipeAddIngredient');

  /// Retsept 3-qadam: "Yangi xom ashyo" blokining bo‘luvchi sarlavhasi.
  String get recipeCreateNewIngredientDivider =>
      _t('recipeCreateNewIngredientDivider');

  /// Retsept 3-qadam: "Yangi xom ashyo yaratish" tugmasi sarlavhasi.
  String get recipeCreateNewIngredient => _t('recipeCreateNewIngredient');

  /// Retsept 3-qadam: sarlavha yonidagi kompakt action matni (qisqa forma).
  String get recipeCreateNewIngredientShort =>
      _t('recipeCreateNewIngredientShort');

  /// Retsept 3-qadam: "Yangi xom ashyo yaratish" tugmasi tavsifi.
  String get recipeCreateNewIngredientHint =>
      _t('recipeCreateNewIngredientHint');
  String get recipeValidationSelectProduct => _t('recipeValidationSelectProduct');
  String get recipeValidationBatch => _t('recipeValidationBatch');
  String get recipeValidationOutput => _t('recipeValidationOutput');
  String get recipeValidationIngredients => _t('recipeValidationIngredients');
  String get recipeValidationDuplicateIngredient =>
      _t('recipeValidationDuplicateIngredient');
  String get recipeSaveSuccess => _t('recipeSaveSuccess');
  String recipeRecipeBatchLine(String unit, String qty) => _t('recipeRecipeBatchLine')
      .replaceAll('{unit}', unit)
      .replaceAll('{qty}', qty);
  String get recipeBack => _t('recipeBack');
  String get recipeIngredientSelectHint => _t('recipeIngredientSelectHint');

  /// Hisoblash ro‘yxagi — kartochka statistikasi
  String get recipeCardStatTitleOutput => _t('recipeCardStatTitleOutput');
  String get recipeCardStatTitleBatchCost => _t('recipeCardStatTitleBatchCost');
  String get recipeCardStatTitleUnitCost => _t('recipeCardStatTitleUnitCost');
  String get recipeCardSectionIngredients => _t('recipeCardSectionIngredients');
  String recipeCardIngredientLine(String name, String qty, String unit) =>
      _t('recipeCardIngredientLine')
          .replaceAll('{name}', name)
          .replaceAll('{qty}', qty)
          .replaceAll('{unit}', unit);
  String get recipeDeleteConfirmTitle => _t('recipeDeleteConfirmTitle');
  String recipeDeleteConfirmBody(String productName) =>
      _t('recipeDeleteConfirmBody').replaceAll('{name}', productName);
  String get recipeCardTooltipOutput => _t('recipeCardTooltipOutput');
  String get recipeCardTooltipBatchCost => _t('recipeCardTooltipBatchCost');
  String get recipeCardTooltipUnitCost => _t('recipeCardTooltipUnitCost');

  /// Partiya batafsil sahifasi
  String get productionDetailTitle => _t('productionDetailTitle');
  String get productionDetailSummary => _t('productionDetailSummary');
  String get productionDetailBatch => _t('productionDetailBatch');
  String get productionDetailOutput => _t('productionDetailOutput');
  String get productionDetailFlour => _t('productionDetailFlour');
  String get productionDetailIngredientCost => _t('productionDetailIngredientCost');
  String get productionDetailSalesEstimate => _t('productionDetailSalesEstimate');
  String get productionDetailBreakdown => _t('productionDetailBreakdown');
  String get productionDetailOneRecipeBatch => _t('productionDetailOneRecipeBatch');
  String get productionDetailQtyTotal => _t('productionDetailQtyTotal');
  String productionDetailGrams(String grams) =>
      _t('productionDetailGrams').replaceAll('{g}', grams);
  String get productionDetailPricePerUnit => _t('productionDetailPricePerUnit');
  String get productionDetailNoIngredients => _t('productionDetailNoIngredients');
  String get productionDetailReturnToday => _t('productionDetailReturnToday');
  String get productionDetailEdit => _t('productionDetailEdit');
  String get productionDetailEditSheetTitle => _t('productionDetailEditSheetTitle');
  String get productionDetailEditBatchLabel => _t('productionDetailEditBatchLabel');
  String get productionDetailEditReturnsTitle => _t('productionDetailEditReturnsTitle');
  String get productionDetailEditNoReturns => _t('productionDetailEditNoReturns');
  String get productionDetailEditSaveBatch => _t('productionDetailEditSaveBatch');
  String get productionDetailBatchUpdated => _t('productionDetailBatchUpdated');
  String get productionDetailReturnDeleted => _t('productionDetailReturnDeleted');
  String get productionDetailDeleteReturnTitle => _t('productionDetailDeleteReturnTitle');
  String get productionDetailDeleteReturnBody => _t('productionDetailDeleteReturnBody');
  String get productionDetailDeleteProductionTitle =>
      _t('productionDetailDeleteProductionTitle');
  String get productionDetailDeleteProductionBody =>
      _t('productionDetailDeleteProductionBody');
  String get productionDetailProductionDeleted =>
      _t('productionDetailProductionDeleted');

  /// Mahsulot chiqimi (chiqim qayd)
  String get productionOutTitle => _t('productionOutTitle');
  String get productionOutStep1 => _t('productionOutStep1');
  String get productionOutStep2 => _t('productionOutStep2');
  String get productionOutStep3 => _t('productionOutStep3');
  String get productionOutStep1Title => _t('productionOutStep1Title');
  String get productionOutStep1Subtitle => _t('productionOutStep1Subtitle');
  String get productionOutCategoryLabel => _t('productionOutCategoryLabel');
  String get productionOutCategoryHint => _t('productionOutCategoryHint');
  String get productionOutNoRecipeWarning => _t('productionOutNoRecipeWarning');
  String get productionOutStep2Title => _t('productionOutStep2Title');
  String productionOutStep2Subtitle(String unit, String outputQty, String productUnit) =>
      _t('productionOutStep2Subtitle')
          .replaceAll('{unit}', unit)
          .replaceAll('{qty}', outputQty)
          .replaceAll('{productUnit}', productUnit);
  String productionOutBatchFieldLabel(String unit) =>
      _t('productionOutBatchFieldLabel').replaceAll('{unit}', unit);
  String get productionOutSummaryTitle => _t('productionOutSummaryTitle');
  String productionOutTotalOutput(String qty, String productUnit) =>
      _t('productionOutTotalOutput')
          .replaceAll('{qty}', qty)
          .replaceAll('{unit}', productUnit);
  String get productionOutCostLabel => _t('productionOutCostLabel');
  String get productionOutIngredientsPreview => _t('productionOutIngredientsPreview');
  String get productionOutCta => _t('productionOutCta');
  String productionOutSuccess(String qty, String productUnit) =>
      _t('productionOutSuccess')
          .replaceAll('{qty}', qty)
          .replaceAll('{unit}', productUnit);
  String get productionOutValidationSelectProduct =>
      _t('productionOutValidationSelectProduct');
  String get productionOutValidationNoRecipe => _t('productionOutValidationNoRecipe');
  String get productionOutValidationBatch => _t('productionOutValidationBatch');
  String get productionOutStep3Title => _t('productionOutStep3Title');
  String get productionOutStep3Subtitle => _t('productionOutStep3Subtitle');
  String get productionOutNext => _t('productionOutNext');
  String get productionOutSearchHint => _t('productionOutSearchHint');
  String get productionOutSearchEmpty => _t('productionOutSearchEmpty');

  /// Mahsulot qaytdi (vozvrat)
  String get returnCreateTitle => _t('returnCreateTitle');
  String get returnCreateSubtitle => _t('returnCreateSubtitle');
  String get returnProfitInfoTitle => _t('returnProfitInfoTitle');
  String get returnProfitInfoBody => _t('returnProfitInfoBody');
  String get returnProfitInfoShort => _t('returnProfitInfoShort');
  String get returnProductionLabel => _t('returnProductionLabel');
  String get returnNoProductionForCategory =>
      _t('returnNoProductionForCategory');
  String get returnSearchHint => _t('returnSearchHint');
  String get returnSearchEmpty => _t('returnSearchEmpty');
  String get returnCategoryLabel => _t('returnCategoryLabel');
  String get returnQuantityTitle => _t('returnQuantityTitle');
  String get returnQuantitySubtitle => _t('returnQuantitySubtitle');
  String get returnPriceLabel => _t('returnPriceLabel');
  String get returnReasonLabel => _t('returnReasonLabel');
  String get returnReasonHint => _t('returnReasonHint');
  String get returnCta => _t('returnCta');
  String get returnValidationSelectProduct =>
      _t('returnValidationSelectProduct');
  String get returnValidationQty => _t('returnValidationQty');
  String get returnValidationPrice => _t('returnValidationPrice');
  String get returnSuccess => _t('returnSuccess');
  String get returnPieceSuffix => _t('returnPieceSuffix');

  // ─── Mahsulot turlari (bread-categories) ───
  String get productCategoriesTitle => _t('productCategoriesTitle');
  String get productCategoriesEmptyTitle => _t('productCategoriesEmptyTitle');
  String get productCategoriesEmptySubtitle =>
      _t('productCategoriesEmptySubtitle');
  String get addProductCategoryModalTitle => _t('addProductCategoryModalTitle');
  String get addProductCategoryModalSubtitle =>
      _t('addProductCategoryModalSubtitle');
  String get productCategoriesNameLabel => _t('productCategoriesNameLabel');
  String get productCategoriesNameHint => _t('productCategoriesNameHint');
  String get sellingPriceLabel => _t('sellingPriceLabel');
  String get sellingPriceHint => _t('sellingPriceHint');
  String get currencyPickerLabel => _t('currencyPickerLabel');
  String get productCategoriesAddCta => _t('productCategoriesAddCta');
  String get snackbarFillAllFields => _t('snackbarFillAllFields');
  String get snackbarErrorGeneric => _t('snackbarErrorGeneric');
  String get actionAdd => _t('actionAdd');
  String get actionSave => _t('actionSave');
  String get editProductCategoryModalTitle => _t('editProductCategoryModalTitle');
  String get editIngredientModalTitle => _t('editIngredientModalTitle');
  String snackbarCategoryAdded(String name) =>
      _t('snackbarCategoryAdded').replaceAll('{name}', name);
  String snackbarCategoryDeleted(String name) =>
      _t('snackbarCategoryDeleted').replaceAll('{name}', name);
  String snackbarCategoryUpdated(String name) =>
      _t('snackbarCategoryUpdated').replaceAll('{name}', name);

  // ─── Xom ashyolar (ingredients) ───
  String get ingredientsEmptyTitle => _t('ingredientsEmptyTitle');
  String get ingredientsEmptySubtitle => _t('ingredientsEmptySubtitle');
  String get addIngredientModalTitle => _t('addIngredientModalTitle');
  String get addIngredientModalSubtitle => _t('addIngredientModalSubtitle');
  String get ingredientNameLabel => _t('ingredientNameLabel');
  String get ingredientNameHint => _t('ingredientNameHint');
  String get ingredientUnitFieldLabel => _t('ingredientUnitFieldLabel');
  String get ingredientPricePerUnitLabel => _t('ingredientPricePerUnitLabel');

  /// Dinamik narx sarlavhasi: tanlangan birlik nomi `{unit}` o'rniga qo'yiladi.
  ///
  /// Misol: tanlangan birlik `kilogram` bo'lsa → `1 kilogram narxini kiriting`.
  String ingredientPricePerUnitLabelDynamic(String unit) =>
      _t('ingredientPricePerUnitLabelDynamic').replaceAll('{unit}', unit);
  String get ingredientsAddCta => _t('ingredientsAddCta');
  String get ingredientAddHeroTitle => _t('ingredientAddHeroTitle');
  String get ingredientPriceHintBanner => _t('ingredientPriceHintBanner');
  String get ingredientUnitChipsLabel => _t('ingredientUnitChipsLabel');
  String get ingredientPriceInfoTitle => _t('ingredientPriceInfoTitle');
  String get ingredientPriceInfoBody => _t('ingredientPriceInfoBody');
  String get gotIt => _t('gotIt');
  String ingredientUnitLabel(String code) {
    switch (code) {
      case 'kg':
        return _t('ingredientUnit_kg');
      case 'gram':
        return _t('ingredientUnit_gram');
      case 'litr':
        return _t('ingredientUnit_litr');
      case 'dona':
        return _t('ingredientUnit_dona');
      default:
        return code;
    }
  }

  String snackbarIngredientAdded(String name) =>
      _t('snackbarIngredientAdded').replaceAll('{name}', name);
  String snackbarIngredientDeleted(String name) =>
      _t('snackbarIngredientDeleted').replaceAll('{name}', name);
  String snackbarIngredientUpdated(String name) =>
      _t('snackbarIngredientUpdated').replaceAll('{name}', name);

  static String _settingsBizGroup(String? key) {
    if (key == null) return 'default';
    if (const {'bakery', 'samsa', 'sweets'}.contains(key)) return 'bakery';
    if (const {'shashlik', 'meat'}.contains(key)) return 'grill';
    if (const {'fastfood', 'restaurant', 'beverages'}.contains(key)) {
      return 'restaurant';
    }
    return 'default';
  }

  // ─── Profile ───
  String get general => _t('general');
  String get manageAndSwitch => _t('manageAndSwitch');
  String get staff => _t('staff');
  String get staffManagement => _t('staffManagement');
  String get darkMode => _t('darkMode');
  String get enabled => _t('enabled');
  String get disabled => _t('disabled');
  String get language => _t('language');
  String get aboutApp => _t('aboutApp');
  String get aboutAppDescription => _t('aboutAppDescription');
  String get developer => _t('developer');
  String get website => _t('website');
  String get support => _t('support');
  String get version => _t('version');
  String get logout => _t('logout');
  String get unknown => _t('unknown');
  String get balance => _t('balance');
  String get topUp => _t('topUp');
  String get profileInfo => _t('profileInfo');
  String get phoneNumber => _t('phoneNumber');
  String get email => _t('email');
  String get telegram => _t('telegram');
  String get linked => _t('linked');
  String get notLinked => _t('notLinked');
  String get link => _t('link');
  String get changePhoto => _t('changePhoto');
  String get takePhoto => _t('takePhoto');
  String get personalInfo => _t('personalInfo');
  String get pressBackAgainToExit => _t('pressBackAgainToExit');
  String get editAction => _t('editAction');
  String get deleteExpense => _t('deleteExpense');
  String get deleteExpenseConfirm => _t('deleteExpenseConfirm');
  String get expenseDeleted => _t('expenseDeleted');
  String get expenseUpdated => _t('expenseUpdated');
  String get expenseDeleteFailed => _t('expenseDeleteFailed');
  String get expenseUpdateFailed => _t('expenseUpdateFailed');
  String get undo => _t('undo');
  String get editExpense => _t('editExpense');
  String get aboutTagline => _t('aboutTagline');
  String get aboutWhyTitle => _t('aboutWhyTitle');
  String get aboutWhyBody => _t('aboutWhyBody');
  String get aboutFeaturesTitle => _t('aboutFeaturesTitle');
  String get featProductionTitle => _t('featProductionTitle');
  String get featProductionDesc => _t('featProductionDesc');
  String get featExpensesTitle => _t('featExpensesTitle');
  String get featExpensesDesc => _t('featExpensesDesc');
  String get featReturnsTitle => _t('featReturnsTitle');
  String get featReturnsDesc => _t('featReturnsDesc');
  String get featReportsTitle => _t('featReportsTitle');
  String get featReportsDesc => _t('featReportsDesc');
  String get featMultiShopTitle => _t('featMultiShopTitle');
  String get featMultiShopDesc => _t('featMultiShopDesc');
  String get featRecipesTitle => _t('featRecipesTitle');
  String get featRecipesDesc => _t('featRecipesDesc');
  String get featMultiLangTitle => _t('featMultiLangTitle');
  String get featMultiLangDesc => _t('featMultiLangDesc');
  String get featDarkModeTitle => _t('featDarkModeTitle');
  String get featDarkModeDesc => _t('featDarkModeDesc');
  String get aboutContactTitle => _t('aboutContactTitle');
  String get aboutTelegramChannel => _t('aboutTelegramChannel');
  String get aboutInstagram => _t('aboutInstagram');
  String get aboutSupport => _t('aboutSupport');
  String get aboutWebsite => _t('aboutWebsite');
  String get loginMethods => _t('loginMethods');
  String get editName => _t('editName');
  String get editEmail => _t('editEmail');
  String get profileUpdated => _t('profileUpdated');
  String get invalidEmail => _t('invalidEmail');
  String get nameRequired => _t('nameRequired');
  String get readOnly => _t('readOnly');
  String get chooseFromGallery => _t('chooseFromGallery');
  String get removePhoto => _t('removePhoto');
  String get removePhotoConfirm => _t('removePhotoConfirm');
  String get remove => _t('remove');
  String get uploadingPhoto => _t('uploadingPhoto');
  String get photoUpdated => _t('photoUpdated');
  String get photoRemoved => _t('photoRemoved');
  String get photoUploadFailed => _t('photoUploadFailed');
  String get businessOwner => _t('businessOwner');
  String get seller => _t('seller');
  String get profileInfoDesc => _t('profileInfoDesc');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountDesc => _t('deleteAccountDesc');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get privacyPolicy => _t('privacyPolicy');
  String get privacyPolicyDesc => _t('privacyPolicyDesc');
  String get termsOfService => _t('termsOfService');
  String get termsOfServiceDesc => _t('termsOfServiceDesc');
  String get account => _t('account');
  String get logoutDesc => _t('logoutDesc');
  String get logoutConfirm => _t('logoutConfirm');
  String get madeInUzbekistan => _t('madeInUzbekistan');
  String get topUpComingSoonTitle => _t('topUpComingSoonTitle');
  String get topUpComingSoonDesc => _t('topUpComingSoonDesc');
  String get goBack => _t('goBack');

  // ─── Onboarding ───
  String get onboardingTitle1 => _t('onboardingTitle1');
  String get onboardingDesc1 => _t('onboardingDesc1');
  String get onboardingTitle2 => _t('onboardingTitle2');
  String get onboardingDesc2 => _t('onboardingDesc2');
  String get onboardingTitle3 => _t('onboardingTitle3');
  String get onboardingDesc3 => _t('onboardingDesc3');
  String get skip => _t('skip');
  String get next => _t('next');
  String get getStarted => _t('getStarted');

  // ─── Auth ───
  String get welcomeBack => _t('welcomeBack');
  String get loginSubtitle => _t('loginSubtitle');
  String get password => _t('password');
  String get enterPhone => _t('enterPhone');
  String get enterPassword => _t('enterPassword');
  String get loginButton => _t('loginButton');
  String get noAccount => _t('noAccount');
  String get registerLink => _t('registerLink');
  String get tryAgain    => _t('tryAgain');
  String get noInternet  => _t('noInternet');
  String get appTagline           => _t('appTagline');
  String get firstTimeHint        => _t('firstTimeHint');
  String get createNewAccount     => _t('createNewAccount');
  String get registerTitle        => _t('registerTitle');
  String get registerSubtitle     => _t('registerSubtitle');
  String get fullNameHint         => _t('fullNameHint');
  String get enterName            => _t('enterName');
  String get confirmPasswordHint  => _t('confirmPasswordHint');
  String get passwordsNotMatch    => _t('passwordsNotMatch');
  String get otpTitle             => _t('otpTitle');
  String otpSentTo(String phone)  => _t('otpSentTo').replaceAll('{phone}', phone);
  String get resendCode           => _t('resendCode');
  String resendIn(String time)    => _t('resendIn').replaceAll('{time}', time);
  String get codeNotReceived      => _t('codeNotReceived');
  String get smsHelpTitle         => _t('smsHelpTitle');
  String get smsHelpCauses        => _t('smsHelpCauses');
  String get smsSpamTitle         => _t('smsSpamTitle');
  String get smsSpamBody          => _t('smsSpamBody');
  String get smsBalanceTitle      => _t('smsBalanceTitle');
  String get smsBalanceBody       => _t('smsBalanceBody');
  String get understood           => _t('understood');
  String get policyLoginPrefix    => _t('policyLoginPrefix');
  String get policyRegisterPrefix => _t('policyRegisterPrefix');
  String get policyAnd            => _t('policyAnd');
  String get policySuffix         => _t('policySuffix');
  String get policyTerms          => _t('policyTerms');
  String get policyPrivacy        => _t('policyPrivacy');
  String get stepForm             => _t('stepForm');
  String get stepVerify           => _t('stepVerify');
  String get stepEnterApp         => _t('stepEnterApp');
  String get phoneExistsTitle     => _t('phoneExistsTitle');
  String phoneExistsBody(String phone) =>
      _t('phoneExistsBody').replaceAll('{phone}', phone);
  String get cancelShort          => _t('cancelShort');
  String socialComingSoon(String name) =>
      _t('socialComingSoon').replaceAll('{name}', name);

  // ─── Telegram Auth ───
  String get telegramConnecting      => _t('telegramConnecting');
  String get telegramConnectingHint  => _t('telegramConnectingHint');
  String get telegramWaitingTitle    => _t('telegramWaitingTitle');
  String get telegramWaitingHint     => _t('telegramWaitingHint');
  String get telegramOpenAgain       => _t('telegramOpenAgain');
  String get telegramRetry           => _t('telegramRetry');
  String get telegramBackToLogin     => _t('telegramBackToLogin');
  String get telegramSessionExpired  => _t('telegramSessionExpired');
  String get loginInfoPrefix  => _t('loginInfoPrefix');
  String get loginInfoAction  => _t('loginInfoAction');
  String get loginInfoSuffix   => _t('loginInfoSuffix');
  String get tapMapToSelect    => _t('tapMapToSelect');
  String get locationPermDenied => _t('locationPermDenied');
  String get locationError     => _t('locationError');

  // Tutorial
  String get tutorialStep1Title => _t('tutorialStep1Title');
  String get tutorialStep1Desc  => _t('tutorialStep1Desc');
  String get tutorialStep2Title => _t('tutorialStep2Title');
  String get tutorialStep2Desc  => _t('tutorialStep2Desc');
  String get tutorialStep3Title => _t('tutorialStep3Title');
  String get tutorialStep3Desc  => _t('tutorialStep3Desc');
  String get tutorialGoAction   => _t('tutorialGoAction');
  String get tutorialSkip       => _t('tutorialSkip');
  String get tutorialStep4Title => _t('tutorialStep4Title');
  String get tutorialStep4Desc  => _t('tutorialStep4Desc');
  String get tutorialGoSetup    => _t('tutorialGoSetup');
  String get tutorialGoSetupSub => _t('tutorialGoSetupSub');
  String get tutorialTapAdd     => _t('tutorialTapAdd');
  // New tutorial keys
  String get tutorialProductIncomeTitle => _t('tutorialProductIncomeTitle');
  String get tutorialProductIncomeDesc  => _t('tutorialProductIncomeDesc');
  String get tutorialOpenCardTitle      => _t('tutorialOpenCardTitle');
  String get tutorialOpenCardDesc       => _t('tutorialOpenCardDesc');
  String get tutorialSettingsHintTitle   => _t('tutorialSettingsHintTitle');
  String get tutorialSettingsHintMessage => _t('tutorialSettingsHintMessage');

  // ─── Business Type / Shop Create ───
  String get createBusiness         => _t('createBusiness');
  String get businessTypeStep       => _t('businessTypeStep');
  String get businessDetailsStep    => _t('businessDetailsStep');
  String get businessLocationStep   => _t('businessLocationStep');
  String get selectBusinessType     => _t('selectBusinessType');
  String get selectBusinessTypeDesc => _t('selectBusinessTypeDesc');
  String get businessDetailsTitle   => _t('businessDetailsTitle');
  String get businessDetailsDesc    => _t('businessDetailsDesc');
  String get businessName           => _t('businessName');
  String get businessDescHint       => _t('businessDescHint');
  String get description            => _t('description');
  String get address                => _t('address');
  String get businessLocationTitle  => _t('businessLocationTitle');
  String get businessLocationDesc   => _t('businessLocationDesc');
  String get useGpsLocation         => _t('useGpsLocation');
  String get fetchingLocation       => _t('fetchingLocation');
  String get locationSaved          => _t('locationSaved');
  String get orManualAddress        => _t('orManualAddress');
  String get addressHint            => _t('addressHint');
  String get locationOptionalNote   => _t('locationOptionalNote');
  String get businessCreated        => _t('businessCreated');
  String get startWorking           => _t('startWorking');
  String get fieldRequired          => _t('fieldRequired');
  String get continueWizard         => _t('continueWizard');
  String get customBusinessTypeInfo => _t('customBusinessTypeInfo');
  String get customBusinessTypeHint => _t('customBusinessTypeHint');
  String get businessNameHint       => _t('businessNameHint');
  String get businessNameRequired => _t('businessNameRequired');
  String get businessNameMinLength  => _t('businessNameMinLength');
  String get selectCurrency         => _t('selectCurrency');
  String get selectCurrencyDesc     => _t('selectCurrencyDesc');
  String get gpsAutoDetectSubtitle  => _t('gpsAutoDetectSubtitle');
  String get orDivider              => _t('orDivider');
  String get manualAddressLabel     => _t('manualAddressLabel');
  String get createBusinessSubmit   => _t('createBusinessSubmit');

  String termBatchUnit(String unit) => unit;
  String businessCreatedDesc(String name) =>
      _t('businessCreatedDesc').replaceAll('{name}', name);

  /// BuildContext bo‘lmaganda (masalan, [ApiException]) — joriy til kodi bilan.
  static String apiClientString(String localeCode, String key) {
    final direct = _all[localeCode];
    if (direct != null) {
      return direct[key] ?? _all['uz']![key] ?? key;
    }
    final lang = localeCode.split('_').first.split('-').first;
    return _all[lang]?[key] ?? _all['uz']![key] ?? key;
  }

  // ─── All translations ───
  static const _all = <String, Map<String, String>>{
    'uz': _uz,
    'uz_CYRL': _uzCyrl,
    'ru': _ru,
    'kk': _kk,
    'ky': _ky,
    'tr': _tr,
  };

  static const _uz = {
    'hello': 'Salom',
    'defaultUser': 'Foydalanuvchi',
    'bakery': 'Biznes',
    'bakeries': 'Bizneslar',
    'selectBusiness': 'Biznes tanlang',
    'selectBusinessSubtitle': 'Boshqarmoqchi bo\'lgan biznesingizni tanlang',
    'noBusiness': 'Hali biznes yo\'q',
    'createFirstBusiness': 'Birinchi biznesingizni yarating\nva boshqaruvni boshlang',
    'addBusiness': 'Yangi biznes qo\'shish',
    'shopSettingsTitle': 'Biznes sozlamalari',
    'shopNameLabel': 'Biznes nomi',
    'shopNameHint': 'Masalan: Non do\'konim',
    'shopAddressLabel': 'Manzil',
    'shopAddressHint': 'Masalan: Toshkent, Chilonzor',
    'shopUpdateSuccess': 'Biznes yangilandi',
    'shopDeleteButton': 'Biznesni o\'chirish',
    'shopDeleteTitle': 'Biznesni o\'chirish',
    'shopDeleteMessage': '«{name}» biznesini o\'chirmoqchimisiz? Bu amalni qaytarib bo\'lmaydi.',
    'shopDeleteSuccess': 'Biznes o\'chirildi',
    'manage': 'Boshqarish',
    'todayProfit': 'Bugungi foyda',
    'todayLoss': 'Bugungi zarar',
    'netRevenue': 'Tushum (vozvratdan keyin)',
    'expense': 'Xarajat',
    'baked': 'Yopilgan',
    'sack': 'Qop',
    'sold': 'Sotilgan',
    'returned': 'Qaytarilgan',
    'pcs': 'ta',
    'sacks': 'qop',
    'noBreadToday': 'Bugun hali non yopilmadi',
    'income': 'Daromad',
    'profit': 'Foyda',
    'productOut': 'Maxsulot chiqdi',
    'productReturned': 'Maxsulot qaytdi',
    'dashboardKpiOutput': 'Mahsulot chiqimi',
    'dashboardKpiBatch': 'To\'plam',
    'dashboardKpiSold': 'Sotilgan',
    'dashboardKpiReturned': 'Qaytarilgan',
    'dashboardEmptyOutput': 'Chiqim qayd etilmagan',
    'dashboardSectionOutput': 'Bugungi chiqimlar',
    'dashboardTabOutput': 'Mahsulot chiqim',
    'dashboardTabExpense': 'Tashqi xarajat',
    'dashboardEmptyExpense': 'Xarajat qayd etilmagan',
    'dashboardBatchUnitGeneric': 'partiya',
    'currency': 'so\'m',
    'home': 'Asosiy',
    'cashRegister': 'Tashqi xarajat',
    'statistics': 'Statistika',
    'orders': 'Zakazlar',
    'ordersComingSoon': 'Tez kunda',
    'ordersComingSoonDesc': 'Zakazlar bo\'limi ustida ish olib borilmoqda.\nYaqin kunlarda tayyor bo\'ladi!',
    'charts': 'Grafiklar',
    'chartsScreenTitle': 'Batafsil grafiklar',
    'chartRevenue': 'Daromad taqsimoti',
    'chartProduction': 'Ishlab chiqarish',
    'chartExpenses': 'Xarajat taqsimoti',
    'chartProfitTrend': 'Foyda tendensiyasi',
    'reportScreenTitle': 'Hisobot',
    'reportPickRange': 'Oraliq',
    'reportPickSingleDate': 'Sana',
    'reportChipToday': 'Bugun',
    'reportChipYesterday': 'Kecha',
    'reportRangeLast7': '7 kun',
    'reportRangeLast30': '30 kun',
    'reportSectionSummary': 'Umumiy ko‘rsatkichlar',
    'reportSectionReturnsByType': 'Vozvratlar (tur bo‘yicha)',
    'reportSectionProducts': 'Mahsulot bo‘yicha',
    'reportGrossRevenue': 'Tushum (vozvratdan oldin)',
    'reportReturnsRecords': 'qayd',
    'reportProductionRecords': 'Chiqim yozuvlari',
    'reportEmptyReturns': 'Bu davrda vozvrat yo‘q',
    'reportEmptyProducts': 'Mahsulot bo‘yicha ma’lumot yo‘q',
    'reportProductProduced': 'Ishlab chiqarilgan',
    'reportExpandTypesCount': '{n} tur',
    'reportExpandProductsCount': '{n} mahsulot',
    'profileTab': 'Profil',
    'navHistory': 'Tarix',
    'historyTitle': 'Tarix',
    'historyTabCreated': 'Yaratilgan',
    'historyTabReturns': 'Qaytarilgan',
    'historyTabCash': 'Xarajatlar',
    'historyTotalReturns': 'Umumiy qaytarilgan',
    'historyCreatedEmpty': 'Hali mahsulot chiqimi yo\'q',
    'historyReturnsEmpty': 'Hali vozvrat qayd etilmagan',
    'returnDetailTitle': 'Vozvrat batafsil',
    'noExpenseToday': 'Bugun xarajat yozilmagan',
    'addExpense': 'Xarajat',
    'expenseCreateTitle': 'Xarajat qo‘shish',
    'expenseCreateSubtitle': 'Turini tanlang, summani kiriting — tez va tushunarli.',
    'expenseCategorySearchHint': 'Kategoriyalarni qidirish',
    'expenseAddCategory': 'Yangi kategoriya',
    'expenseAddCategoryTitle': 'O‘zingiz uchun kategoriya',
    'expenseAddCategoryNameHint': 'Masalan: reklama, soliq',
    'expenseAddCategorySave': 'Kategoriyani saqlash',
    'expenseSelectCategory': 'Tur',
    'expenseAmountLabel': 'Summa',
    'expenseDescriptionLabel': 'Izoh (ixtiyoriy)',
    'expenseSubmit': 'Xarajatni saqlash',
    'expenseCategoriesEmpty': 'Kategoriyalar topilmadi',
    'expenseCategoriesLoadError': 'Kategoriyalar yuklanmadi',
    'daily': 'Kunlik',
    'weekly': 'Xaftalik',
    'monthly': 'Oylik',
    'loss': 'Zarar',
    'noData': 'Ma\'lumot yo\'q',
    'production': 'Ishlab chiqarish',
    'flourUsage': 'Un sarfi',
    'bakedBread': 'Yopilgan non',
    'ingredients': 'Ingredientlar',
    'salesAndReturns': 'Sotuv va vozvrat',
    'totalProduced': 'Jami ishlab chiqarilgan',
    'returns': 'Vozvrat',
    'soldAuto': 'Sotilgan (avto)',
    'returnAmount': 'Vozvrat summa',
    'netIncome': 'Sof daromad',
    'expenses': 'Xarajatlar',
    'internalIngredients': 'Ichki xarajatlar',
    'external': 'Tashqi',
    'total': 'Jami',
    'settings': 'Sozlamalar',
    'breadTypes': 'Mahsulot turlari',
    'breadTypesDesc':
        'Sotadigan mahsulot yoki xizmat turlari — har biri uchun narx',
    'products': 'Mahsulotlar',
    'productsDesc': 'Un, suv, tuz, xamirturush, yog\'...',
    'recipes': 'Retseptlar',
    'recipesDesc': 'Non uchun tarkibiy qismlar va miqdorlar',
    'settingsCardTypesTitle': 'Mahsulotlaringiz turlari',
    'settingsCardIngredientsTitle': 'Xom ashyolar',
    'settingsCardRecipesTitle': 'Hisoblash tizimi',
    'settingsTypesDesc_default':
        'Sotadigan mahsulot va xizmat turlarini qo‘shing, narxlarni boshqaring.',
    'settingsTypesDesc_bakery':
        'Masalan: patir, somsa, lavash, tandir non... Har bir tur uchun alohida narx.',
    'settingsTypesDesc_grill':
        'Masalan: shashlik, tijora, rulet... Har bir pozitsiya uchun alohida narx.',
    'settingsTypesDesc_restaurant':
        'Masalan: taomlar, garnirlar, ichimliklar... Menyu bo‘yicha tartiblang.',
    'settingsIngredientsDesc_default':
        'Ingredientlar va xom ashyolarni narxlari va o‘lchov bilan kiriting.',
    'settingsIngredientsDesc_bakery':
        'Un, suv, tuz, xamirturush, yog‘ — har birining narxi va o‘lchovi.',
    'settingsIngredientsDesc_grill':
        'Go‘sht, ziravorlar, yog‘ — har birining narxi va o‘lchovi.',
    'settingsIngredientsDesc_restaurant':
        'Mahsulot va ingredientlar — ombor va tannarx bilan bog‘lang.',
    'settingsRecipesDesc_default':
        'Har bir mahsulot turiga bitta retsept: partiya birligi, chiqim va tannarx — foyda aniq.',
    'settingsRecipesDesc_bakery':
        'Har bir mahsulot uchun bitta retsept: partiya (qop va h.k.), chiqim va tannarx.',
    'settingsRecipesDesc_grill':
        'Har bir pozitsiya uchun bitta retsept: partiya, miqdor va tannarx.',
    'settingsRecipesDesc_restaurant':
        'Har bir menyu pozitsiyasi uchun bitta retsept va tannarx hisobi.',
    'setupJourneyTitle': 'Sozlash tartibi',
    'setupJourneyHint':
        'Avval sotadigan mahsulot turini yarating, keyin xom ashyo va narxlarni kiriting, oxirida retsept orqali hisoblashni tizimlashtiring — shunda tannarx va foyda aniq bo‘ladi.',
    'setupJourneyStepLabel1': 'Mahsulot',
    'setupJourneyStepLabel2': 'Xom ashyo',
    'setupJourneyStepLabel3': 'Hisoblash',
    'setupJourneyAllDone': 'Barcha qadamlar bajarildi',
    'settingsCardCompleted': 'Bajarildi',
    'recipeScreenTitle': 'Retseptlar',
    'recipeEmptyTitle': 'Hali retseptlar yo‘q',
    'recipeEmptySubtitle':
        'Mahsulot turlari uchun retsept qo‘shing — ishlab chiqarish hisobi aniq bo‘ladi.',
    'recipeAddCta': 'Retsept qo‘shish',
    'recipeDeletedSnackbar': 'Retsept o‘chirildi',
    'recipeErrorSnackbar': 'Xatolik yuz berdi',
    'recipeCreateTitle': 'Yangi retsept',
    'recipeStepProduct': 'Mahsulot',
    'recipeStepBatch': 'Partiya',
    'recipeStepIngredients': 'Tarkib',
    'recipeSelectProductTitle': 'Qaysi mahsulot uchun?',
    'recipeSelectProductSubtitle':
        'Bitta tur tanlang — har bir tur uchun bitta retsept bo‘ladi.',
    'recipeAlreadyExists': 'Retsept mavjud',
    'recipeBatchCarouselTitle': 'Partiya birligi',
    'recipeBatchCarouselSubtitle':
        'Ishlab chiqarishda qanday hisoblaysiz: qop, blok, to‘plam...',
    'recipeOutputLabel': 'Mahsulot soni',
    'recipeOutputHint': 'Masalan: 100',
    'recipeOutputSectionTitle': 'Mahsulot soni',
    'recipeOutputSectionHelper':
        '1 partiyadan nechta mahsulot chiqadi?',
    'recipeIngredientsSectionTitle': 'Bir partiya uchun xom ashyo miqdori',
    'recipeIngredientsSectionSubtitle':
        'Tanlangan birlikdagi bitta partiyaga ketadigan miqdorlarni kiriting.',
    'recipeOutputLabelDynamic': '1 {unit}dan qancha mahsulot chiqadi?',
    'recipeIngredientsSectionTitleDynamic':
        'Bir {unit} uchun xom ashyo miqdori',
    'recipeIngredientsSectionSubtitleDynamic':
        'Bir {unit}ga ketadigan har bir xom ashyo miqdorini kiriting.',
    'recipeAddIngredient': 'Mahsulot qo‘shish',
    'recipeCreateNewIngredientDivider': 'YOKI',
    'recipeCreateNewIngredient': 'Yangi xom ashyo yaratish',
    'recipeCreateNewIngredientShort': 'Yangi',
    'recipeCreateNewIngredientHint':
        'Ro‘yxatda yo‘q bo‘lsa, shu yerning o‘zidan qo‘shing',
    'recipeValidationSelectProduct': 'Mahsulot turini tanlang',
    'recipeValidationBatch': 'Partiya birligini tanlang',
    'recipeValidationOutput': 'Chiqim sonini kiriting',
    'recipeValidationIngredients': 'Kamida bitta xom ashyo qo‘shing',
    'recipeValidationDuplicateIngredient':
        'Bir xil mahsulot ikki marta qo‘shilgan',
    'recipeSaveSuccess': 'Retsept saqlandi',
    'recipeRecipeBatchLine': '1 {unit} → {qty} ta',
    'recipeBack': 'Orqaga',
    'recipeIngredientSelectHint': 'Xom ashyo',
    'recipeCardStatTitleOutput': 'Chiqim',
    'recipeCardStatTitleBatchCost': 'Partiya tannaxi',
    'recipeCardStatTitleUnitCost': '1 ta tannarx',
    'recipeCardSectionIngredients': 'Tarkib',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Retseptni o‘chirish?',
    'recipeDeleteConfirmBody':
        '“{name}” retsepti o‘chiriladi. Bu amalni qaytarib bo‘lmaydi.',
    'recipeCardTooltipOutput':
        'Bitta partiyadan chiqadigan mahsulot soni.',
    'recipeCardTooltipBatchCost':
        'Bitta partiya uchun xom ashyo tannaxi (jami).',
    'recipeCardTooltipUnitCost':
        'Bitta mahsulot birligi tannaxi (jami ÷ chiqim).',
    'productionDetailTitle': 'Partiya batafsil',
    'productionDetailSummary': 'Bugungi yopilgan partiya',
    'productionDetailBatch': 'Partiya soni',
    'productionDetailOutput': 'Chiqim',
    'productionDetailFlour': 'Sarflangan un',
    'productionDetailIngredientCost': 'Xom ashyo tannaxi',
    'productionDetailSalesEstimate': 'Taxminiy tushum',
    'productionDetailBreakdown': 'Ingredientlar bo\'yicha',
    'productionDetailOneRecipeBatch': '1 partiya (retsept)',
    'productionDetailQtyTotal': 'Jami miqdor',
    'productionDetailGrams': '{g} g',
    'productionDetailPricePerUnit': '1 birlik narxi',
    'productionDetailNoIngredients':
        'Retsept ingredientlari mavjud emas yoki yuklanmadi.',
    'productionDetailReturnToday': 'Bugungi vozvrat (shu tur bo\'yicha)',
    'productionDetailEdit': 'Tahrirlash',
    'productionDetailEditSheetTitle': 'Partiya va vozvratlar',
    'productionDetailEditBatchLabel': 'Bugungi partiya soni',
    'productionDetailEditReturnsTitle': 'Shu tur bo\'yicha vozvratlar (bugun)',
    'productionDetailEditNoReturns': 'Bugun bu tur uchun vozvrat qayd etilmagan',
    'productionDetailEditSaveBatch': 'Partiyani saqlash',
    'productionDetailBatchUpdated': 'Partiya yangilandi',
    'productionDetailReturnDeleted': 'Vozvrat o\'chirildi',
    'productionDetailDeleteReturnTitle': 'Vozvratni o\'chirish?',
    'productionDetailDeleteReturnBody':
        'Bu qayd o\'chiriladi. Bosh sahifa va summalar yangilanadi.',
    'productionDetailDeleteProductionTitle': 'Chiqimni o\'chirish?',
    'productionDetailDeleteProductionBody':
        'Ushbu chiqim qaydi o\'chiriladi. Shu tur va sanada boshqa partiya qolmasa, shu kunga yozilgan barcha vozvratlar ham o\'chiriladi.',
    'productionDetailProductionDeleted': 'Chiqim o\'chirildi',
    'productionOutTitle': 'Mahsulot chiqimi',
    'productionOutStep1': 'Mahsulot',
    'productionOutStep2': 'To\'plam',
    'productionOutStep3': 'Yakun',
    'productionOutStep1Title': 'Qaysi mahsulot?',
    'productionOutStep1Subtitle':
        'Hisoblashda bog\'langan mahsulot turini tanlang.',
    'productionOutCategoryLabel': 'Mahsulot turi',
    'productionOutCategoryHint': 'Tanlang',
    'productionOutNoRecipeWarning':
        'Bu tur uchun retsept yo\'q. Avval «Hisoblash» bo\'limida retsept yarating.',
    'productionOutStep2Title': 'Partiya miqdori',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Kasr sonlar mumkin (masalan: 1.5).',
    'productionOutBatchFieldLabel': '{unit} miqdori',
    'productionOutSummaryTitle': 'Hisob-kitob',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Xarajat',
    'productionOutIngredientsPreview': 'Sarflanadigan xom ashyo',
    'productionOutCta': 'Chiqimni qayd etish',
    'productionOutSuccess': '{qty} {unit} chiqim qayd etildi',
    'productionOutValidationSelectProduct': 'Mahsulot turini tanlang',
    'productionOutValidationNoRecipe': 'Bu tur uchun retsept topilmadi',
    'productionOutValidationBatch': 'Partiya miqdori 0 dan katta bo\'lsin',
    'productionOutStep3Title': 'Tekshirish va saqlash',
    'productionOutStep3Subtitle': 'Ma\'lumotlar to\'g\'ri bo\'lsa, saqlang.',
    'productionOutNext': 'Keyingi',
    'productionOutSearchHint': 'Mahsulot qidirish',
    'productionOutSearchEmpty': 'Hech narsa topilmadi',
    'returnCreateTitle': 'Mahsulot qaytdi',
    'returnCreateSubtitle':
        'Qaytarilgan tur va miqdorni kiriting. Tur tanlanganda sotuv narxi avtomatik chiqadi.',
    'returnProfitInfoTitle': 'Foyda va hisob',
    'returnProfitInfoBody':
        'Vozvrat qayd etilganda kunlik sotuv, tushum va foyda ko‘rsatkichlari (bosh sahifa va hisobotlar) shunga mos ravishda yangilanadi — bu real moliyaviy holatingizni aks ettiradi.',
    'returnProfitInfoShort':
        'Mahsulot qaytishi (vozvrat)ni kiritish foydani to‘g‘ri hisoblash uchun muhim.',
    'returnProductionLabel': 'Partiya (chiqim)',
    'returnNoProductionForCategory':
        'Bu tur uchun bugun chiqim qayd etilmagan. Avval chiqim kiriting.',
    'returnSearchHint': 'Mahsulot qidirish',
    'returnSearchEmpty': 'Hech narsa topilmadi',
    'returnCategoryLabel': 'Mahsulot turi',
    'returnQuantityTitle': 'Qaytarilgan miqdor',
    'returnQuantitySubtitle': 'Butun son (dona) kiriting.',
    'returnPriceLabel': 'Bir dona narxi',
    'returnReasonLabel': 'Sabab (ixtiyoriy)',
    'returnReasonHint': 'Masalan: mijoz, sifat',
    'returnCta': 'Vozvratni qayd etish',
    'returnValidationSelectProduct': 'Mahsulot turini tanlang',
    'returnValidationQty': 'Miqdor 0 dan katta bo‘lsin',
    'returnValidationPrice': 'Narxni to‘g‘ri kiriting',
    'returnSuccess': 'Vozvrat qayd etildi',
    'returnPieceSuffix': 'ta',
    'productCategoriesTitle': 'Mahsulot turlari',
    'productCategoriesEmptyTitle': 'Hali mahsulot turlari yo\'q',
    'productCategoriesEmptySubtitle':
        'Biznesingizda sotiladigan mahsulot yoki xizmat turlarini qo\'shing',
    'addProductCategoryModalTitle': 'Yangi tur',
    'addProductCategoryModalSubtitle': 'Nom va sotuv narxini kiriting',
    'productCategoriesNameLabel': 'Mahsulot nomi',
    'productCategoriesNameHint': 'Masalan: lavash, somsa, set-menu',
    'sellingPriceLabel': 'Sotuv narxi',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Valyuta',
    'productCategoriesAddCta': 'Tur qo\'shish',
    'snackbarFillAllFields': 'Iltimos, barcha maydonlarni to\'ldiring',
    'snackbarErrorGeneric': 'Xatolik yuz berdi',
    'apiClientTimeout': 'Ulanish vaqti tugadi',
    'apiClientNoConnection': 'Internet aloqasi yo\'q',
    'apiClientUnexpected': 'Kutilmagan xatolik',
    'apiInvalidResponseFormat': 'Kutilmagan javob formati',
    'actionAdd': 'Qo\'shish',
    'actionSave': 'Saqlash',
    'editProductCategoryModalTitle': 'Tur tahrirlash',
    'editIngredientModalTitle': 'Xom ashyoni tahrirlash',
    'snackbarCategoryAdded': '{name} qo\'shildi',
    'snackbarCategoryDeleted': '{name} o\'chirildi',
    'snackbarCategoryUpdated': '{name} yangilandi',
    'ingredientsEmptyTitle': 'Hali xom ashyo yo\'q',
    'ingredientsEmptySubtitle':
        'Retsept va tannarx uchun nom, o\'lchov birligi va 1 birlik narxini kiriting.',
    'addIngredientModalTitle': 'Yangi xom ashyo',
    'addIngredientModalSubtitle':
        'Nom, birlik va narx. Valyutani narx yonidagi tugma orqali tanlang.',
    'ingredientNameLabel': 'Nomi',
    'ingredientNameHint': 'Masalan: un, suv, tuz',
    'ingredientUnitFieldLabel': 'O\'lchov birligi',
    'ingredientPricePerUnitLabel': '1 birlik narxi',
    'ingredientPricePerUnitLabelDynamic': '1 {unit} narxini kiriting',
    'ingredientUnit_kg': 'Kilogramm (kg)',
    'ingredientUnit_gram': 'Gramm (g)',
    'ingredientUnit_litr': 'Litr (l)',
    'ingredientUnit_dona': 'Dona',
    'ingredientsAddCta': 'Xom ashyo qo\'shish',
    'ingredientAddHeroTitle': 'Yangi xom ashyo',
    'ingredientPriceHintBanner':
        'Narxni tanlangan birlik bo\'yicha to\'liq kiriting (masalan, 1 kg, 1 L yoki 1 dona). Retseptda g yoki ml ishlatsangiz ham, bu yerda umumiy narxni saqlaysiz.',
    'ingredientUnitChipsLabel': 'O\'lchov birligi',
    'snackbarIngredientAdded': '{name} qo\'shildi',
    'snackbarIngredientDeleted': '{name} o\'chirildi',
    'snackbarIngredientUpdated': '{name} yangilandi',
    'ingredientPriceInfoTitle': 'Narx haqida',
    'ingredientPriceInfoBody':
        'Xom ashyo narxini umumiy qilib kiriting (1 kg, 1 dona yoki 1 litr narxi). Keyin tizim o‘zi gram yoki ml bo‘yicha hisoblab beradi.',
    'gotIt': 'Tushunarli',
    'general': 'Umumiy',
    'manageAndSwitch': 'Boshqarish va almashtirish',
    'staff': 'Xodimlar',
    'staffManagement': 'Xodimlar boshqaruvi',
    'darkMode': 'Tungi rejim',
    'enabled': 'Yoqilgan',
    'disabled': 'O\'chirilgan',
    'language': 'Til',
    'aboutApp': 'Ilova haqida',
    'aboutAppDescription': "TAQSEEM — kichik va o'rta ishlab chiqaruvchi bizneslar uchun tannarx, foyda va xarajatlarni aniq hisoblash ilovasi.",
    'developer': 'Ishlab chiqaruvchi',
    'website': 'Veb-sayt',
    'support': 'Qo\'llab-quvvatlash',
    'assetImagesPreview': 'Rasmlar (ko‘rinish)',
    'version': 'Versiya',
    'logout': 'Tizimdan chiqish',
    'unknown': 'Noma\'lum',
    'balance': 'Asosiy Balans',
    'topUp': 'To\'ldirish',
    'profileInfo': 'Profil ma\'lumotlari',
    'profileInfoDesc': 'Telefon, email va Telegram sozlamalari',
    'phoneNumber': 'Telefon raqam',
    'email': 'Email',
    'telegram': 'Telegram',
    'linked': 'Ulangan',
    'notLinked': 'Ulanmagan',
    'link': 'Ulash',
    'changePhoto': 'Rasm o\'zgartirish',
    'aboutTagline': 'Biznesingizni bir qarashda boshqaring',
    'aboutWhyTitle': 'Nima uchun TAQSEEM?',
    'aboutWhyBody': 'TAQSEEM — kichik va o\'rta ishlab chiqaruvchi bizneslar uchun yaratilgan zamonaviy boshqaruv tizimi. Kunlik ishlab chiqarish, chiqimlar, qaytarilgan tovarlar va sof foydani bir joyda, real vaqtda ko\'ring. Ortiqcha qog\'ozbozliksiz, ishonchli va oson.',
    'aboutFeaturesTitle': 'Asosiy imkoniyatlar',
    'featProductionTitle': 'Ishlab chiqarish hisobi',
    'featProductionDesc': 'Kunlik ishlab chiqarilgan miqdor va tannarx nazorati.',
    'featExpensesTitle': 'Chiqimlar boshqaruvi',
    'featExpensesDesc': 'Kategoriyalar bo\'yicha barcha xarajatlarni kuzating.',
    'featReturnsTitle': 'Qaytarilganlar',
    'featReturnsDesc': 'Qaytgan tovarlar va yo\'qotishlarni aniq hisobga oling.',
    'featReportsTitle': 'Statistika va hisobotlar',
    'featReportsDesc': 'Kunlik, haftalik va oylik grafiklar hamda analitika.',
    'featMultiShopTitle': 'Ko\'p nonxona',
    'featMultiShopDesc': 'Bir nechta shoxobcha va filiallarni bitta akkauntdan boshqaring.',
    'featRecipesTitle': 'Retseptlar',
    'featRecipesDesc': 'Retsept va ingredientlar tannarxini avtomatik hisoblang.',
    'featMultiLangTitle': 'Ko\'p tilli',
    'featMultiLangDesc': 'Ilova 7 ta tilda: o\'zbek, rus, qozoq, qirg\'iz va boshqalar.',
    'featDarkModeTitle': 'Dark / Light mode',
    'featDarkModeDesc': 'Ko\'zingizga yoqimli tungi va kunduzgi rejimlar.',
    'aboutContactTitle': 'Biz bilan bog\'laning',
    'aboutTelegramChannel': 'Telegram kanal',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Yordam',
    'aboutWebsite': 'Veb-sayt',
    'personalInfo': 'Shaxsiy ma\'lumotlar',
    'pressBackAgainToExit': 'Chiqish uchun yana bir marta bosing',
    'editAction': 'Tahrirlash',
    'editExpense': 'Xarajatni tahrirlash',
    'deleteExpense': 'Xarajatni o\'chirish',
    'deleteExpenseConfirm': 'Bu xarajatni o\'chirishni tasdiqlaysizmi?',
    'expenseDeleted': 'Xarajat o\'chirildi',
    'expenseUpdated': 'Xarajat yangilandi',
    'expenseDeleteFailed': 'O\'chirishda xatolik',
    'expenseUpdateFailed': 'Yangilashda xatolik',
    'undo': 'Qaytarish',
    'loginMethods': 'Kirish usullari',
    'editName': 'Ismni o\'zgartirish',
    'editEmail': 'Emailni o\'zgartirish',
    'profileUpdated': 'Ma\'lumotlar yangilandi',
    'invalidEmail': 'Email noto\'g\'ri',
    'nameRequired': 'Ism kiritilishi kerak',
    'readOnly': 'O\'zgartirib bo\'lmaydi',
    'takePhoto': 'Kamera orqali olish',
    'chooseFromGallery': 'Galereyadan tanlash',
    'removePhoto': 'Rasmni olib tashlash',
    'removePhotoConfirm': 'Profil rasmini olib tashlaysizmi?',
    'remove': 'Olib tashlash',
    'uploadingPhoto': 'Yuklanmoqda...',
    'photoUpdated': 'Rasm yangilandi',
    'photoRemoved': 'Rasm olib tashlandi',
    'photoUploadFailed': 'Rasmni yuklab bo\'lmadi',
    'businessOwner': 'Biznes egasi',
    'seller': 'Sotuvchi',
    'deleteAccount': 'Hisobni o\'chirish',
    'deleteAccountDesc': 'Hisobingizni o\'chirsangiz, barcha do\'konlaringiz, hisobotlaringiz va ma\'lumotlaringiz butunlay o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
    'deleteAccountConfirm': 'Haqiqatan ham hisobingizni o\'chirmoqchimisiz?',
    'cancel': 'Bekor qilish',
    'delete': 'O\'chirish',
    'privacyPolicy': 'Maxfiylik siyosati',
    'privacyPolicyDesc': "Shaxsiy ma'lumotlar himoyasi",
    'termsOfService': 'Foydalanish shartlari',
    'termsOfServiceDesc': "Xizmat ko'rsatish qoidalari",
    'account': 'Hisob',
    'logoutDesc': 'Hisobingizdan chiqish',
    'logoutConfirm': 'Tizimdan chiqmoqchimisiz?',
    'madeInUzbekistan': "O'zbekistonda ishlab chiqilgan",
    'topUpComingSoonTitle': 'Tez orada ishga tushadi',
    'topUpComingSoonDesc': "Balans to'ldirish bo'limi ustida ish olib borilmoqda. Tez orada siz ilovadan to'liq foydalana olasiz.",
    'goBack': 'Ortga qaytish',
    'onboardingTitle1': 'Har qanday biznes uchun',
    'onboardingDesc1': 'Nonvoyxona, shashlikxona, somsahona, shirinliklar, fastfood — barchasini bir joydan boshqaring',
    'onboardingTitle2': 'Tan narx va foyda hisobi',
    'onboardingDesc2': 'Har bir mahsulotning tan narxini aniq hisoblab, real foydangizni bilib oling',
    'onboardingTitle3': 'Biznesingiz nazoratda',
    'onboardingDesc3': 'Sotuv, xarajat va ishlab chiqarishni real vaqtda kuzatib boring',
    'skip': 'O\'tkazib yuborish',
    'next': 'Keyingi',
    'getStarted': 'Boshlash',
    'welcomeBack': 'Xush kelibsiz!',
    'loginSubtitle': 'Davom etish uchun tizimga kiring',
    'password': 'Parol',
    'enterPhone': 'Telefon kiriting',
    'enterPassword': 'Parol kiriting',
    'loginButton': 'Kirish',
    'noAccount': 'Akkaunt yo\'qmi?',
    'registerLink': 'Ro\'yxatdan o\'ting',
    'tryAgain': 'Qayta urinish',
    'noInternet': 'Internet ulanishda xatolik',
    'appTagline': 'Kichik biznes uchun aqlli tizim',
    'firstTimeHint': "Birinchi marta kirayapsizmi? Avval ",
    'createNewAccount': 'yangi hisob yarating',
    'registerTitle': "Ro'yxatdan o'tish",
    'registerSubtitle': "Barcha ma'lumotlarni kiriting",
    'fullNameHint': 'Ism va familiya',
    'enterName': 'Ism kiriting',
    'confirmPasswordHint': 'Parolni tasdiqlang',
    'passwordsNotMatch': 'Parollar mos emas',
    'otpTitle': 'Kodni kiriting',
    'otpSentTo': "4 xonali tasdiqlash kodi\n{phone}\nraqamiga yuborildi.",
    'resendCode': 'Kodni qayta yuborish',
    'resendIn': 'Qayta yuborish: {time}',
    'codeNotReceived': 'Kod kelmayaptimi?',
    'smsHelpTitle': 'SMS kod kelmayaptimi?',
    'smsHelpCauses': "Quyidagi sabablar ko'pchilikda uchraydi:",
    'smsSpamTitle': 'Spam papkasi',
    'smsSpamBody':
        "SMS bo'limida \"Spam\" yoki \"Keraksiz\" papkasini tekshiring. Bizdan yuborilgan SMS 4546 raqamdan keladi.",
    'smsBalanceTitle': 'Uzmobile balansi',
    'smsBalanceBody':
        "Uzmobile operatorida balans bo'lmasa SIM karta SMS qabul qilmasligi mumkin.",
    'understood': 'Tushundim',
    'policyLoginPrefix': 'Kirish orqali ',
    'policyRegisterPrefix': "Ro'yxatdan o'tish orqali ",
    'policyAnd': ' va ',
    'policySuffix': ' siyosatini qabul qilasiz',
    'policyTerms': 'Shartlar',
    'policyPrivacy': 'Maxfiylik',
    'stepForm': "Ma'lumotlar",
    'stepVerify': 'Tasdiqlash',
    'stepEnterApp': 'Dasturga\nkiring',
    'phoneExistsTitle': "Raqam ro'yxatdan o'tgan",
    'phoneExistsBody':
        "{phone} raqami allaqachon ro'yxatdan o'tgan.\n\nUshbu raqam bilan tizimga kiring.",
    'cancelShort': 'Bekor',
    'socialComingSoon': '{name} orqali kirish tez orada ulashiladi',
    'telegramConnecting': 'Ulanmoqda...',
    'telegramConnectingHint': 'Telegram ochilmoqda',
    'telegramWaitingTitle': 'Telegram kutilmoqda',
    'telegramWaitingHint': 'Telegramda telefon raqamingizni yuboring va ilovaga qaytish tugmasini bosing',
    'telegramOpenAgain': 'Telegramni qayta ochish',
    'telegramRetry': 'Qaytadan urinish',
    'telegramBackToLogin': 'Kirishga qaytish',
    'telegramSessionExpired': "Vaqt tugadi. Qaytadan urinib ko'ring.",
    'loginInfoPrefix': "Oldin hisob yaratmagan bo'lsangiz ",
    'loginInfoAction': 'Hisob Yaratish',
    'loginInfoSuffix': ' ni bosing',
    'tapMapToSelect': 'Joylashuvni tanlash uchun xaritaga bosing',
    'locationPermDenied': "Joylashuvga ruxsat berilmagan. Sozlamalarga o'ting.",
    'locationError': 'Joylashuvni aniqlashda xatolik yuz berdi',
    'tutorialStep1Title': "Mahsulot qo'shing",
    'tutorialStep1Desc': 'Tayyorlaydigan mahsulot turini kiriting',
    'tutorialStep2Title': "Xom ashyo qo'shing",
    'tutorialStep2Desc': 'Retsept uchun kerakli ingredientlarni kiriting',
    'tutorialStep3Title': 'Hisoblash yarating',
    'tutorialStep3Desc': '1 ta mahsulot uchun xom ashyo miqdorini kiriting',
    'tutorialGoAction': "O'tish",
    'tutorialSkip': "O'tkazib yuborish",
    'tutorialStep4Title': 'Chiqimni qayd eting',
    'tutorialStep4Desc': 'Bugun qancha mahsulot chiqqanini kiriting',
    'tutorialGoSetup':    "Sozlamalar tugmasini bosing",
    'tutorialGoSetupSub': "Mahsulot, xom ashyo va hisoblashni sozlang",
    'tutorialTapAdd':     "Qo'shish tugmasini bosing",
    'tutorialProductIncomeTitle': "Mahsulot kirimi",
    'tutorialProductIncomeDesc':  "Bugungi mahsulot chiqimini shu tugma orqali qayd eting",
    'tutorialOpenCardTitle':      "Bo'limga o'ting",
    'tutorialOpenCardDesc':       "Bu kartani bosib, tegishli sozlamaga kiring",
    'tutorialSettingsHintTitle':   "Boshlash uchun sozlang",
    'tutorialSettingsHintMessage': "Mahsulot va xom ashyolarni kiriting — ilova tannarx va foydani o'zi hisoblab beradi.",
    'createBusiness': 'Biznes yaratish',
    'businessTypeStep': 'Kategoriya',
    'businessDetailsStep': "Ma'lumotlar",
    'businessLocationStep': 'Lokatsiya',
    'selectBusinessType': 'Biznes turini tanlang',
    'selectBusinessTypeDesc': 'O\'zingizga mos kategoriyani tanlang — ilova ichida hamma narsa shunga moslashadi',
    'businessDetailsTitle': 'Biznes haqida',
    'businessDetailsDesc': 'Biznesingizning asosiy ma\'lumotlarini kiriting',
    'businessName': 'Biznes nomi',
    'businessDescHint': 'Qisqacha tavsif (ixtiyoriy)',
    'description': 'Tavsif',
    'address': 'Manzil',
    'businessLocationTitle': 'Lokatsiya',
    'businessLocationDesc': 'GPS orqali aniq joylashuvni saqlang yoki manzilni qo\'lda kiriting',
    'useGpsLocation': 'GPS orqali joylashuv',
    'fetchingLocation': 'Joylashuv aniqlanmoqda...',
    'locationSaved': 'Joylashuv saqlandi',
    'orManualAddress': 'yoki qo\'lda kiriting',
    'addressHint': 'Masalan: Toshkent sh., Amir Temur ko\'chasi, 1',
    'locationOptionalNote': 'Lokatsiya ixtiyoriy. Keyinchalik ham qo\'shish mumkin.',
    'businessCreated': 'Biznes yaratildi! 🎉',
    'businessCreatedDesc': '{name} muvaffaqiyatli yaratildi. Endi boshqaruv panelidan foydalanishingiz mumkin.',
    'startWorking': 'Ishni boshlash',
    'fieldRequired': 'Bu maydon majburiy',
    'continueWizard': 'Davom etish',
    'customBusinessTypeInfo':
        'Biznesingiz turini yozing — biz uni hisobga olamiz',
    'customBusinessTypeHint': 'Masalan: Pishiriqlar, Limon limonadi...',
    'businessNameHint': 'Masalan: Markaziy Novvoyxona',
    'businessNameRequired': 'Biznes nomini kiriting',
    'businessNameMinLength': 'Kamida 2 ta harf',
    'selectCurrency': 'Valyuta',
    'selectCurrencyDesc':
        'Hisobot va narxlarda ishlatiladigan valyutani tanlang',
    'gpsAutoDetectSubtitle': 'Hozirgi joylashuvingizni avtomatik aniqlash',
    'orDivider': 'yoki',
    'manualAddressLabel': 'Manzilni qo\'lda kiriting',
    'createBusinessSubmit': 'Biznesni yaratish',
  };

  static const _uzCyrl = {
    'hello': 'Салом',
    'defaultUser': 'Фойдаланувчи',
    'bakery': 'Бизнес',
    'bakeries': 'Бизнеслар',
    'selectBusiness': 'Бизнес танланг',
    'selectBusinessSubtitle': 'Бошқармоқчи бўлган бизнесингизни танланг',
    'noBusiness': 'Ҳали бизнес йўқ',
    'createFirstBusiness': 'Биринчи бизнесингизни яратинг\nва бошқарувни бошланг',
    'addBusiness': 'Янги бизнес қўшиш',
    'shopSettingsTitle': 'Бизнес созламалари',
    'shopNameLabel': 'Бизнес номи',
    'shopNameHint': 'Масалан: Нон дўконим',
    'shopAddressLabel': 'Манзил',
    'shopAddressHint': 'Масалан: Тошкент, Чилонзор',
    'shopUpdateSuccess': 'Бизнес янгиланди',
    'shopDeleteButton': 'Бизнесни ўчириш',
    'shopDeleteTitle': 'Бизнесни ўчириш',
    'shopDeleteMessage': '«{name}» бизнесини ўчирмоқчимисиз? Бу амални қайтариб бўлмайди.',
    'shopDeleteSuccess': 'Бизнес ўчирилди',
    'manage': 'Бошқариш',
    'todayProfit': 'Бугунги фойда',
    'todayLoss': 'Бугунги зарар',
    'netRevenue': 'Тушум (возвратдан кейин)',
    'expense': 'Харажат',
    'baked': 'Ёпилган',
    'sack': 'Қоп',
    'sold': 'Сотилган',
    'returned': 'Қайтарилган',
    'pcs': 'та',
    'sacks': 'қоп',
    'noBreadToday': 'Бугун ҳали нон ёпилмади',
    'income': 'Даромад',
    'profit': 'Фойда',
    'productOut': 'Маҳсулот чиқди',
    'productReturned': 'Маҳсулот қайтди',
    'dashboardKpiOutput': 'Маҳсулот чиқими',
    'dashboardKpiBatch': 'Тўплам',
    'dashboardKpiSold': 'Сотилган',
    'dashboardKpiReturned': 'Қайтарилган',
    'dashboardEmptyOutput': 'Чиқим қайд этилмаган',
    'dashboardSectionOutput': 'Бугунги чиқимлар',
    'dashboardTabOutput': 'Маҳсулот чиқим',
    'dashboardTabExpense': 'Ташқи харажат',
    'dashboardEmptyExpense': 'Харажат қайд этилмаган',
    'dashboardBatchUnitGeneric': 'партия',
    'currency': 'сўм',
    'home': 'Асосий',
    'cashRegister': 'Ташқи харажат',
    'statistics': 'Статистика',
    'orders': 'Заказлар',
    'ordersComingSoon': 'Тез кунда',
    'ordersComingSoonDesc': 'Заказлар бўлими устида иш олиб борилмоқда.\nЯқин кунларда тайёр бўлади!',
    'charts': 'Графиклар',
    'chartsScreenTitle': 'Батафсил графиклар',
    'chartRevenue': 'Даромад тақсимоти',
    'chartProduction': 'Ишлаб чиқариш',
    'chartExpenses': 'Ҳаражат тақсимоти',
    'chartProfitTrend': 'Фойда тенденцияси',
    'reportScreenTitle': 'Ҳисобот',
    'reportPickRange': 'Оралиқ',
    'reportPickSingleDate': 'Сана',
    'reportChipToday': 'Бугун',
    'reportChipYesterday': 'Кеча',
    'reportRangeLast7': '7 кун',
    'reportRangeLast30': '30 кун',
    'reportSectionSummary': 'Умумий кўрсаткичлар',
    'reportSectionReturnsByType': 'Возвратлар (тур бўйича)',
    'reportSectionProducts': 'Маҳсулот бўйича',
    'reportGrossRevenue': 'Тушум (возвратдан олдин)',
    'reportReturnsRecords': 'қайд',
    'reportProductionRecords': 'Чиқим ёзувлари',
    'reportEmptyReturns': 'Бу даврда возврат йўқ',
    'reportEmptyProducts': 'Маҳсулот бўйича маълумот йўқ',
    'reportProductProduced': 'Ишлаб чиқарилган',
    'reportExpandTypesCount': '{n} тур',
    'reportExpandProductsCount': '{n} маҳсулот',
    'profileTab': 'Профил',
    'navHistory': 'Тарих',
    'historyTitle': 'Тарих',
    'historyTabCreated': 'Яратилган',
    'historyTabReturns': 'Қайтарилган',
    'historyTabCash': 'Харажатлар',
    'historyTotalReturns': 'Умумий қайтарилган',
    'historyCreatedEmpty': 'Ҳали маҳсулот чиқими йўқ',
    'historyReturnsEmpty': 'Ҳали возврат ёзилмаган',
    'returnDetailTitle': 'Возврат батафсил',
    'noExpenseToday': 'Бугун харажат ёзилмаган',
    'addExpense': 'Харажат',
    'expenseCreateTitle': 'Харажат қўшиш',
    'expenseCreateSubtitle': 'Турини танланг, суммани киритинг.',
    'expenseCategorySearchHint': 'Категорияларни қидириш',
    'expenseAddCategory': 'Янги категория',
    'expenseAddCategoryTitle': 'Ўзингиз учун категория',
    'expenseAddCategoryNameHint': 'Масалан: реклама',
    'expenseAddCategorySave': 'Сақлаш',
    'expenseSelectCategory': 'Тур',
    'expenseAmountLabel': 'Сумма',
    'expenseDescriptionLabel': 'Изоҳ (ихтиёрий)',
    'expenseSubmit': 'Сақлаш',
    'expenseCategoriesEmpty': 'Топилмади',
    'expenseCategoriesLoadError': 'Юкланмади',
    'daily': 'Кунлик',
    'weekly': 'Ҳафталик',
    'monthly': 'Ойлик',
    'loss': 'Зарар',
    'noData': 'Маълумот йўқ',
    'production': 'Ишлаб чиқариш',
    'flourUsage': 'Ун сарфи',
    'bakedBread': 'Ёпилган нон',
    'ingredients': 'Ингредиентлар',
    'salesAndReturns': 'Сотув ва возврат',
    'totalProduced': 'Жами ишлаб чиқарилган',
    'returns': 'Возврат',
    'soldAuto': 'Сотилган (авто)',
    'returnAmount': 'Возврат суммаси',
    'netIncome': 'Соф даромад',
    'expenses': 'Харажатлар',
    'internalIngredients': 'Ички харажатлар',
    'external': 'Ташқи',
    'total': 'Жами',
    'settings': 'Созламалар',
    'breadTypes': 'Маҳсулот турлари',
    'breadTypesDesc':
        'Сотадиган маҳсулот ёки хизмат турлари — ҳар бири учун нарх',
    'products': 'Маҳсулотлар',
    'productsDesc': 'Ун, сув, туз, хамиртуруш, ёғ...',
    'recipes': 'Рецептлар',
    'recipesDesc': 'Нон учун таркибий қисмлар ва миқдорлар',
    'settingsCardTypesTitle': 'Маҳсулотларингиз турлари',
    'settingsCardIngredientsTitle': 'Хом ашёлар',
    'settingsCardRecipesTitle': 'Ҳисоблаш тизими',
    'settingsTypesDesc_default':
        'Сотадиган маҳсулот ва хизмат турларини қўшинг, нархларни бошқаринг.',
    'settingsTypesDesc_bakery':
        'Масалан: патир, самса, лаваш, тандир нон... Ҳар бир тур учун алоҳида нарх.',
    'settingsTypesDesc_grill':
        'Масалан: шашлик, тижора, рулет... Ҳар бир позиция учун алоҳида нарх.',
    'settingsTypesDesc_restaurant':
        'Масалан: таомлар, гарнирлар, ичимликлар... Меню бўйича тартибланг.',
    'settingsIngredientsDesc_default':
        'Ингредиентлар ва хом ашёларни нархлари ва ўлчов билан киритинг.',
    'settingsIngredientsDesc_bakery':
        'Ун, сув, туз, хамиртуруш, ёғ — ҳар бирининг нархи ва ўлчови.',
    'settingsIngredientsDesc_grill':
        'Гўшт, зираворлар, ёғ — ҳар бирининг нархи ва ўлчови.',
    'settingsIngredientsDesc_restaurant':
        'Маҳсулот ва ингредиентлар — омбор ва таннарх билан боғланг.',
    'settingsRecipesDesc_default':
        'Рецептлар ва таннарх — ҳар бир маҳсулот учун маржа ва фойда ҳисоби.',
    'settingsRecipesDesc_bakery':
        'Ҳар бир маҳсулот учун ингредиентлар нисбати ва таннарх — фойда аниқ.',
    'settingsRecipesDesc_grill':
        'Ҳар бир таом учун грамм ва таннарх — нарх ва фойда ҳисоби.',
    'settingsRecipesDesc_restaurant':
        'Таом ва ичимликлар учун таннарх ва сотувлар — ҳисоботлар автоматик.',
    'setupJourneyTitle': 'Созлаш тартиби',
    'setupJourneyHint':
        'Аввал сотилаётган маҳсулот турини яратинг, кейин хом ашё ва нархларни киритинг, охирида рецепт орқали ҳисоблашни тизимлаштиринг — шунда таннарх ва фойда аниқ бўлади.',
    'setupJourneyStepLabel1': 'Маҳсулот',
    'setupJourneyStepLabel2': 'Хом ашё',
    'setupJourneyStepLabel3': 'Ҳисоблаш',
    'setupJourneyAllDone': 'Барча қадамлар бажарилди',
    'settingsCardCompleted': 'Бажарилди',
    'recipeScreenTitle': 'Рецептлар',
    'recipeEmptyTitle': 'Ҳали рецептлар йўқ',
    'recipeEmptySubtitle':
        'Маҳсулот турлари учун рецепт қўшинг — ишлаб чиқариш ҳисоби аниқ бўлади.',
    'recipeAddCta': 'Рецепт қўшиш',
    'recipeDeletedSnackbar': 'Рецепт ўчирилди',
    'recipeErrorSnackbar': 'Хатолик юз берди',
    'recipeCreateTitle': 'Янги рецепт',
    'recipeStepProduct': 'Маҳсулот',
    'recipeStepBatch': 'Партия',
    'recipeStepIngredients': 'Таркиб',
    'recipeSelectProductTitle': 'Қайси маҳсулот учун?',
    'recipeSelectProductSubtitle':
        'Битта тур танланг — ҳар бир тур учун бита рецепт бўлади.',
    'recipeAlreadyExists': 'Рецепт мавжуд',
    'recipeBatchCarouselTitle': 'Партия бирлиги',
    'recipeBatchCarouselSubtitle':
        'Ишлаб чиқаришда қандай ҳисоблайсиз: қоп, блок, тўплам...',
    'recipeOutputLabel': 'Маҳсулот сони',
    'recipeOutputHint': 'Масалан: 100',
    'recipeOutputSectionTitle': 'Маҳсулот сони',
    'recipeOutputSectionHelper':
        '1 партиядан нечта маҳсулот чиқади?',
    'recipeIngredientsSectionTitle': 'Бир партия учун хом ашё миқдори',
    'recipeOutputLabelDynamic': '1 {unit}дан қанча маҳсулот чиқади?',
    'recipeIngredientsSectionTitleDynamic':
        'Бир {unit} учун хом ашё миқдори',
    'recipeIngredientsSectionSubtitleDynamic':
        'Бир {unit}га кетадиган ҳар бир хом ашё миқдорини киритинг.',
    'recipeIngredientsSectionSubtitle':
        'Танланган бирликдаги битта партияга кетадиган миқдорларни киритинг.',
    'recipeAddIngredient': 'Маҳсулот қўшиш',
    'recipeCreateNewIngredientDivider': 'ЁКИ',
    'recipeCreateNewIngredient': 'Янги хом ашё яратиш',
    'recipeCreateNewIngredientShort': 'Янги',
    'recipeCreateNewIngredientHint':
        'Рўйхатда йўқ бўлса, шу ернинг ўзидан қўшинг',
    'recipeValidationSelectProduct': 'Маҳсулот турини танланг',
    'recipeValidationBatch': 'Партия бирлигини танланг',
    'recipeValidationOutput': 'Чиқим сонини киритинг',
    'recipeValidationIngredients': 'Камида бита хом ашё қўшинг',
    'recipeValidationDuplicateIngredient':
        'Бир хил маҳсулот икки марта қўшилган',
    'recipeSaveSuccess': 'Рецепт сақланди',
    'recipeRecipeBatchLine': '1 {unit} → {qty} та',
    'recipeBack': 'Орқага',
    'recipeIngredientSelectHint': 'Хом ашё',
    'recipeCardStatTitleOutput': 'Чиқим',
    'recipeCardStatTitleBatchCost': 'Партия таннахи',
    'recipeCardStatTitleUnitCost': '1 та таннах',
    'recipeCardSectionIngredients': 'Таркиб',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Рецептни ўчириш?',
    'recipeDeleteConfirmBody':
        '«{name}» рецепти ўчирилади. Бу амални қайтариб бўлмайди.',
    'recipeCardTooltipOutput':
        'Битта партиядан чиқадиган маҳсулот сони.',
    'recipeCardTooltipBatchCost':
        'Битта партия учун хом ашё таннахи (жами).',
    'recipeCardTooltipUnitCost':
        'Битта маҳсулот бирлиги таннахи (жами ÷ чиқим).',
    'productionDetailTitle': 'Партия батафсил',
    'productionDetailSummary': 'Бугун ёпилган партия',
    'productionDetailBatch': 'Партия сони',
    'productionDetailOutput': 'Чиқим',
    'productionDetailFlour': 'Сарфланган ун',
    'productionDetailIngredientCost': 'Хом ашё таннахи',
    'productionDetailSalesEstimate': 'Тахминий тушум',
    'productionDetailBreakdown': 'Ингредиентлар бўйича',
    'productionDetailOneRecipeBatch': '1 партия (рецепт)',
    'productionDetailQtyTotal': 'Жами миқдор',
    'productionDetailGrams': '{g} г',
    'productionDetailPricePerUnit': '1 бирлик нархи',
    'productionDetailNoIngredients':
        'Рецепт ингредиентлари мавжуд эмас ёки юкланмади.',
    'productionDetailReturnToday': 'Бугунги возврат (шу тур бўйича)',
    'productionDetailEdit': 'Таҳрирлаш',
    'productionDetailEditSheetTitle': 'Партия ва возвратлар',
    'productionDetailEditBatchLabel': 'Бугунги партия сони',
    'productionDetailEditReturnsTitle': 'Шу тур бўйича возвратлар (бугун)',
    'productionDetailEditNoReturns': 'Бугун бу тур учун возврат ёзилмаган',
    'productionDetailEditSaveBatch': 'Партияни сақлаш',
    'productionDetailBatchUpdated': 'Партия янгиланди',
    'productionDetailReturnDeleted': 'Возврат ўчирилди',
    'productionDetailDeleteReturnTitle': 'Возвратни ўчириш?',
    'productionDetailDeleteReturnBody':
        'Бу ёзув ўчирилади. Асосий саҳифа ва суммалар янгиланади.',
    'productionDetailDeleteProductionTitle': 'Чиқимни ўчириш?',
    'productionDetailDeleteProductionBody':
        'Бу чиқим ёзуви ўчирилади. Шу тур ва санада бошқа партия қолмаса, шу кунга ёзилган барча возвратлар ҳам ўчирилади.',
    'productionDetailProductionDeleted': 'Чиқим ўчирилди',
    'productionOutTitle': 'Маҳсулот чиқими',
    'productionOutStep1': 'Маҳсулот',
    'productionOutStep2': 'Тўплам',
    'productionOutStep3': 'Якун',
    'productionOutStep1Title': 'Қайси маҳсулот?',
    'productionOutStep1Subtitle':
        'Ҳисоблашда боғланган маҳсулот турини танланг.',
    'productionOutCategoryLabel': 'Маҳсулот тури',
    'productionOutCategoryHint': 'Танланг',
    'productionOutNoRecipeWarning':
        'Бу тур учун рецепт йўқ. Аввал «Ҳисоблаш» бўлимида рецепт яратинг.',
    'productionOutStep2Title': 'Партия миқдори',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Каср сонлар мумкин (масалан: 1.5).',
    'productionOutBatchFieldLabel': '{unit} миқдори',
    'productionOutSummaryTitle': 'Ҳисоб-китоб',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Харажат',
    'productionOutIngredientsPreview': 'Сарфланадиган хом ашё',
    'productionOutCta': 'Чиқимни қайд этиш',
    'productionOutSuccess': '{qty} {unit} чиқим қайд этилди',
    'productionOutValidationSelectProduct': 'Маҳсулот турини танланг',
    'productionOutValidationNoRecipe': 'Бу тур учун рецепт топилмади',
    'productionOutValidationBatch': 'Партия миқдори 0 дан катта бўлсин',
    'productionOutStep3Title': 'Текшириш ва сақлаш',
    'productionOutStep3Subtitle': 'Маълумотлар тўғри бўлса, сақланг.',
    'productionOutNext': 'Кейинги',
    'productionOutSearchHint': 'Маҳсулот қидириш',
    'productionOutSearchEmpty': 'Ҳеч нарса топилмади',
    'returnCreateTitle': 'Маҳсулот қайтди',
    'returnCreateSubtitle':
        'Қайтарилган тур ва миқдорни киритинг. Тур танланганда сотув нархи автоматик чиқади.',
    'returnProfitInfoTitle': 'Фойда ва ҳисоб',
    'returnProfitInfoBody':
        'Возврат қайд этилганда кунлик сотув, тушум ва фойда кўрсаткичлари (бош саҳифа ва ҳисоботлар) шунга мос равишда янгиланади — бу реал молиявий ҳолатни акс эттиради.',
    'returnProfitInfoShort':
        'Маҳсулот қайтиши (возврат)ни киритиш фойдани тўғри ҳисоблаш учун муҳим.',
    'returnProductionLabel': 'Партия (чиқим)',
    'returnNoProductionForCategory':
        'Бу тур учун бугун чиқим ёзилмаган. Аввал чиқим киритинг.',
    'returnSearchHint': 'Маҳсулот қидириш',
    'returnSearchEmpty': 'Ҳеч нарса топилмади',
    'returnCategoryLabel': 'Маҳсулот тури',
    'returnQuantityTitle': 'Қайтарилган миқдор',
    'returnQuantitySubtitle': 'Бутун сон (дона) киритинг.',
    'returnPriceLabel': 'Бир дона нархи',
    'returnReasonLabel': 'Сабаб (ихтиёрий)',
    'returnReasonHint': 'Масалан: мижоз, сифат',
    'returnCta': 'Возвратни қайд этиш',
    'returnValidationSelectProduct': 'Маҳсулот турини танланг',
    'returnValidationQty': 'Миқдор 0 дан катта бўлсин',
    'returnValidationPrice': 'Нархни тўғри киритинг',
    'returnSuccess': 'Возврат қайд этилди',
    'returnPieceSuffix': 'та',
    'productCategoriesTitle': 'Маҳсулот турлари',
    'productCategoriesEmptyTitle': 'Ҳали маҳсулот турлари йўқ',
    'productCategoriesEmptySubtitle':
        'Бизнесингизда сотиладиган маҳсулот ёки хизмат турларини қўшинг',
    'addProductCategoryModalTitle': 'Янги тур',
    'addProductCategoryModalSubtitle': 'Ном ва сотув нархини киритинг',
    'productCategoriesNameLabel': 'Маҳсулот номи',
    'productCategoriesNameHint': 'Масалан: лаваш, самса, сет-меню',
    'sellingPriceLabel': 'Сотув нархи',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Валюта',
    'productCategoriesAddCta': 'Тур қўшиш',
    'snackbarFillAllFields': 'Илтимос, барча майдонларни тўлдиринг',
    'snackbarErrorGeneric': 'Хатолик юз берди',
    'apiClientTimeout': 'Уланиш вақти тугади',
    'apiClientNoConnection': 'Интернет алоқаси йўқ',
    'apiClientUnexpected': 'Кутилмаган хатолик',
    'apiInvalidResponseFormat': 'Кутилмаган жавоб формати',
    'actionAdd': 'Қўшиш',
    'actionSave': 'Сақлаш',
    'editProductCategoryModalTitle': 'Турни таҳрирлаш',
    'editIngredientModalTitle': 'Хом ашёни таҳрирлаш',
    'snackbarCategoryAdded': '{name} қўшилди',
    'snackbarCategoryDeleted': '{name} ўчирилди',
    'snackbarCategoryUpdated': '{name} янгиланди',
    'ingredientsEmptyTitle': 'Ҳали хом ашё йўқ',
    'ingredientsEmptySubtitle':
        'Рецепт ва таннарх учун ном, ўлчов бирлиги ва 1 бирлик нархини киритинг.',
    'addIngredientModalTitle': 'Янги хом ашё',
    'addIngredientModalSubtitle':
        'Ном, бирлик ва нарх. Валютани нарх ёнидаги тугма орқали танланг.',
    'ingredientNameLabel': 'Номи',
    'ingredientNameHint': 'Масалан: ун, сув, туз',
    'ingredientUnitFieldLabel': 'Ўлчов бирлиги',
    'ingredientPricePerUnitLabel': '1 бирлик нархи',
    'ingredientPricePerUnitLabelDynamic': '1 {unit} нархини киритинг',
    'ingredientUnit_kg': 'Килограмм (kg)',
    'ingredientUnit_gram': 'Грамм (g)',
    'ingredientUnit_litr': 'Литр (l)',
    'ingredientUnit_dona': 'Дона',
    'ingredientsAddCta': 'Хом ашё қўшиш',
    'ingredientAddHeroTitle': 'Янги хом ашё',
    'ingredientPriceHintBanner':
        'Нархни танланган бирлик бўйича тўлиқ киритинг (масалан, 1 кг, 1 Л ёки 1 дона). Рецептда г ёки мл ишлатсангиз ҳам, бу ерда умумий нархни сақлайсиз.',
    'ingredientUnitChipsLabel': 'Ўлчов бирлиги',
    'snackbarIngredientAdded': '{name} қўшилди',
    'snackbarIngredientDeleted': '{name} ўчирилди',
    'snackbarIngredientUpdated': '{name} янгиланди',
    'ingredientPriceInfoTitle': 'Нарх ҳақида',
    'ingredientPriceInfoBody':
        'Хом ашё нархини умумий қилиб киритинг (1 кг, 1 дона ёки 1 л нархи). Кейин тизим ўзи грамм ёки мл бўйича ҳисоблаб беради.',
    'gotIt': 'Тушунарли',
    'general': 'Умумий',
    'manageAndSwitch': 'Бошқариш ва алмаштириш',
    'staff': 'Ходимлар',
    'staffManagement': 'Ходимлар бошқаруви',
    'darkMode': 'Тунги режим',
    'enabled': 'Ёқилган',
    'disabled': 'Ўчирилган',
    'language': 'Тил',
    'aboutApp': 'Илова ҳақида',
    'aboutAppDescription': 'ТАҚСЕЕМ — кичик ва ўрта ишлаб чиқарувчи бизнеслар учун таннарх, фойда ва харажатларни аниқ ҳисоблаш иловаси.',
    'developer': 'Ишлаб чиқарувчи',
    'website': 'Веб-сайт',
    'support': 'Қўллаб-қувватлаш',
    'assetImagesPreview': 'Расмлар (кўриниш)',
    'version': 'Версия',
    'logout': 'Тизимдан чиқиш',
    'unknown': 'Номаълум',
    'balance': 'Асосий Баланс',
    'topUp': 'Тўлдириш',
    'profileInfo': 'Профил маълумотлари',
    'profileInfoDesc': 'Телефон, эмайл ва Телеграм созламалари',
    'phoneNumber': 'Телефон рақам',
    'email': 'Эмайл',
    'telegram': 'Телеграм',
    'linked': 'Уланган',
    'notLinked': 'Уланмаган',
    'link': 'Улаш',
    'changePhoto': 'Расм ўзгартириш',
    'aboutTagline': 'Бизнесингизни бир қарашда бошқаринг',
    'aboutWhyTitle': 'Нима учун ТАҚСЕЕМ?',
    'aboutWhyBody': 'ТАҚСЕЕМ — кичик ва ўрта ишлаб чиқарувчи бизнеслар учун яратилган замонавий бошқарув тизими. Кунлик ишлаб чиқариш, чиқимлар, қайтарилган товарлар ва соф фойдани бир жойда, реал вақтда кўринг.',
    'aboutFeaturesTitle': 'Асосий имкониятлар',
    'featProductionTitle': 'Ишлаб чиқариш ҳисоби',
    'featProductionDesc': 'Кунлик ишлаб чиқарилган миқдор ва таннарх назорати.',
    'featExpensesTitle': 'Чиқимлар бошқаруви',
    'featExpensesDesc': 'Категориялар бўйича барча харажатларни кузатинг.',
    'featReturnsTitle': 'Қайтарилганлар',
    'featReturnsDesc': 'Қайтган товарлар ва йўқотишларни аниқ ҳисобга олинг.',
    'featReportsTitle': 'Статистика ва ҳисоботлар',
    'featReportsDesc': 'Кунлик, ҳафталик ва ойлик графиклар ва аналитика.',
    'featMultiShopTitle': 'Кўп нонхона',
    'featMultiShopDesc': 'Бир нечта шохобча ва филиалларни битта аккаундан бошқаринг.',
    'featRecipesTitle': 'Рецептлар',
    'featRecipesDesc': 'Рецепт ва ингредиентлар таннархини автоматик ҳисобланг.',
    'featMultiLangTitle': 'Кўп тилли',
    'featMultiLangDesc': 'Илова 7 та тилда: ўзбек, рус, қозоқ, қирғиз ва бошқалар.',
    'featDarkModeTitle': 'Dark / Light режими',
    'featDarkModeDesc': 'Кўзингизга ёқимли тунги ва кундузги режимлар.',
    'aboutContactTitle': 'Биз билан боғланинг',
    'aboutTelegramChannel': 'Telegram канал',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Ёрдам',
    'aboutWebsite': 'Веб-сайт',
    'personalInfo': 'Шахсий маълумотлар',
    'pressBackAgainToExit': 'Чиқиш учун яна бир марта босинг',
    'editAction': 'Таҳрирлаш',
    'editExpense': 'Харажатни таҳрирлаш',
    'deleteExpense': 'Харажатни ўчириш',
    'deleteExpenseConfirm': 'Бу харажатни ўчиришни тасдиқлайсизми?',
    'expenseDeleted': 'Харажат ўчирилди',
    'expenseUpdated': 'Харажат янгиланди',
    'expenseDeleteFailed': 'Ўчиришда хатолик',
    'expenseUpdateFailed': 'Янгилашда хатолик',
    'undo': 'Қайтариш',
    'loginMethods': 'Кириш усуллари',
    'editName': 'Исмни ўзгартириш',
    'editEmail': 'Эмаилни ўзгартириш',
    'profileUpdated': 'Маълумотлар янгиланди',
    'invalidEmail': 'Эмаил нотўғри',
    'nameRequired': 'Исм киритилиши керак',
    'readOnly': 'Ўзгартириб бўлмайди',
    'takePhoto': 'Камера орқали олиш',
    'chooseFromGallery': 'Галереядан танлаш',
    'removePhoto': 'Расмни олиб ташлаш',
    'removePhotoConfirm': 'Профил расмини олиб ташлайсизми?',
    'remove': 'Олиб ташлаш',
    'uploadingPhoto': 'Юкланмоқда...',
    'photoUpdated': 'Расм янгиланди',
    'photoRemoved': 'Расм олиб ташланди',
    'photoUploadFailed': 'Расмни юклаб бўлмади',
    'businessOwner': 'Бизнес эгаси',
    'seller': 'Сотувчи',
    'deleteAccount': 'Ҳисобни ўчириш',
    'deleteAccountDesc': 'Ҳисобингизни ўчирсангиз, барча дўконларингиз, ҳисоботларингиз ва маълумотларингиз бутунлай ўчирилади.',
    'deleteAccountConfirm': 'Ҳақиқатан ҳам ҳисобингизни ўчирмоқчимисиз?',
    'cancel': 'Бекор қилиш',
    'delete': 'Ўчириш',
    'privacyPolicy': 'Махфийлик сиёсати',
    'privacyPolicyDesc': "Шахсий маълумотлар ҳимояси",
    'termsOfService': 'Фойдаланиш шартлари',
    'termsOfServiceDesc': "Хизмат кўрсатиш қоидалари",
    'account': 'Ҳисоб',
    'logoutDesc': 'Ҳисобингиздан чиқиш',
    'logoutConfirm': 'Тизимдан чиқмоқчимисиз?',
    'madeInUzbekistan': "Ўзбекистонда ишлаб чиқилган",
    'topUpComingSoonTitle': 'Тез орада ишга тушади',
    'topUpComingSoonDesc': "Баланс тўлдириш бўлими устида иш олиб борилмоқда. Тез орада сиз иловадан тўлиқ фойдалана оласиз.",
    'goBack': 'Ортга қайтиш',
    'onboardingTitle1': 'Ҳар қандай бизнес учун',
    'onboardingDesc1': 'Нонвойхона, шашликхона, сомсахона, ширинликлар, фастфуд — барчасини бир жойдан бошқаринг',
    'onboardingTitle2': 'Тан нарх ва фойда ҳисоби',
    'onboardingDesc2': 'Ҳар бир маҳсулотнинг тан нархини аниқ ҳисоблаб, реал фойдангизни билиб олинг',
    'onboardingTitle3': 'Бизнесингиз назоратда',
    'onboardingDesc3': 'Сотув, харажат ва ишлаб чиқаришни реал вақтда кузатиб боринг',
    'skip': 'Ўтказиб юбориш',
    'next': 'Кейинги',
    'getStarted': 'Бошлаш',
    'welcomeBack': 'Хуш келибсиз!',
    'loginSubtitle': 'Давом этиш учун тизимга киринг',
    'password': 'Парол',
    'enterPhone': 'Телефон киритинг',
    'enterPassword': 'Парол киритинг',
    'loginButton': 'Кириш',
    'noAccount': 'Аккаунт йўқми?',
    'registerLink': 'Рўйхатдан ўтинг',
    'tryAgain': 'Қайта уриниш',
    'noInternet': 'Интернет уланишда хатолик',
    'appTagline': 'Кичик бизнес учун ақлли тизим',
    'firstTimeHint': 'Биринчи марта киряпсизми? Аввал ',
    'createNewAccount': 'янги ҳисоб яратинг',
    'registerTitle': 'Рўйхатдан ўтиш',
    'registerSubtitle': 'Барча маълумотларни киритинг',
    'fullNameHint': 'Исм ва фамилия',
    'enterName': 'Исм киритинг',
    'confirmPasswordHint': 'Паролни тасдиқланг',
    'passwordsNotMatch': 'Паролlar мос эмас',
    'otpTitle': 'Кодни киритинг',
    'otpSentTo': '4 хонали тасдиқлаш коди\n{phone}\nрақамига юборилди.',
    'resendCode': 'Кодни қайта юбориш',
    'resendIn': 'Қайта юбориш: {time}',
    'codeNotReceived': 'Код келмаяптими?',
    'smsHelpTitle': 'SMS код келмаяптими?',
    'smsHelpCauses': 'Қуйидаги сабаблар кўпчиликда учрайди:',
    'smsSpamTitle': 'Spam папкаси',
    'smsSpamBody':
        'SMS бўлимида "Spam" ёки "Кераксиз" папкасини текширинг. Биздан юборилган SMS 4546 рақамдан келади.',
    'smsBalanceTitle': 'Uzmobile баланси',
    'smsBalanceBody':
        'Uzmobile операторида баланс бўлмаса SIM карта SMS қабул қилмаслиги мумкин.',
    'understood': 'Тушундим',
    'policyLoginPrefix': 'Кириш орқали ',
    'policyRegisterPrefix': 'Рўйхатдан ўтиш орқали ',
    'policyAnd': ' ва ',
    'policySuffix': ' сиёсатини қабул қиласиз',
    'policyTerms': 'Шартлар',
    'policyPrivacy': 'Махфийлик',
    'stepForm': 'Маълумотлар',
    'stepVerify': 'Тасдиқлаш',
    'stepEnterApp': 'Дастурга\nкиринг',
    'phoneExistsTitle': 'Рақам рўйхатдан ўтган',
    'phoneExistsBody':
        '{phone} рақами аллақачон рўйхатдан ўтган.\n\nУшбу рақам билан тизимга киринг.',
    'cancelShort': 'Бекор',
    'socialComingSoon': '{name} орқали кириш тез орада улашилади',
    'telegramConnecting': 'Уланмоқда...',
    'telegramConnectingHint': 'Телеграм очилмоқда',
    'telegramWaitingTitle': 'Телеграм кутилмоқда',
    'telegramWaitingHint': 'Телеграмда телефон рақамингизни юборинг ва иловага қайтиш тугмасини босинг',
    'telegramOpenAgain': 'Телеграмни қайта очиш',
    'telegramRetry': 'Қайтадан уриниш',
    'telegramBackToLogin': 'Киришга қайтиш',
    'telegramSessionExpired': 'Вақт тугади. Қайтадан уриниб кўринг.',
    'loginInfoPrefix': 'Аввал ҳисоб яратмаган бўлсангиз ',
    'loginInfoAction': 'Ҳисоб Яратиш',
    'loginInfoSuffix': ' ни босинг',
    'tapMapToSelect': 'Жойлашувни танлаш учун харитага босинг',
    'locationPermDenied': 'Жойлашувга рухсат берилмаган. Созламаларга ўтинг.',
    'locationError': 'Жойлашувни аниқлашда хатолик юз берди',
    'tutorialStep1Title': "Mahsulot qo'shing",
    'tutorialStep1Desc': 'Tayyorlanadigan mahsulot turini kiriting',
    'tutorialStep2Title': "Xom ashyo qo'shing",
    'tutorialStep2Desc': 'Retsept uchun ingredientlarni kiriting',
    'tutorialStep3Title': 'Hisoblash yarating',
    'tutorialStep3Desc': "1 ta mahsulot uchun miqdorini kiriting",
    'tutorialGoAction': "O'tish",
    'tutorialSkip': "O'tkazib yuborish",
    'tutorialStep4Title': 'Chiqimni qayd eting',
    'tutorialStep4Desc': 'Bugun qancha mahsulot chiqqanini kiriting',
    'tutorialGoSetup':    "Sozlamalar tugmasini bosing",
    'tutorialGoSetupSub': "Mahsulot, xom ashyo va hisoblashni sozlang",
    'tutorialTapAdd':     "Qo'shish tugmasini bosing",
    'tutorialProductIncomeTitle': "Mahsulot kirimi",
    'tutorialProductIncomeDesc':  "Bugungi mahsulot chiqimini shu tugma orqali qayd eting",
    'tutorialOpenCardTitle':      "Bo'limga o'ting",
    'tutorialOpenCardDesc':       "Bu kartani bosib, tegishli sozlamaga kiring",
    'tutorialSettingsHintTitle':   "Бошлаш учун созланг",
    'tutorialSettingsHintMessage': "Маҳсулот ва хом ашёларни киритинг — илова таннарх ва фойдани ўзи ҳисоблаб беради.",
    'createBusiness': 'Бизнес яратиш',
    'businessTypeStep': 'Категория',
    'businessDetailsStep': 'Маълумотлар',
    'businessLocationStep': 'Локация',
    'selectBusinessType': 'Бизнес турини танланг',
    'selectBusinessTypeDesc': 'Ўзингизга мос категорияни танланг',
    'businessDetailsTitle': 'Бизнес ҳақида',
    'businessDetailsDesc': 'Бизнесингизнинг асосий маълумотларини киритинг',
    'businessName': 'Бизнес номи',
    'businessDescHint': 'Қисқача тавсиф (ихтиёрий)',
    'description': 'Тавсиф',
    'address': 'Манзил',
    'businessLocationTitle': 'Локация',
    'businessLocationDesc': 'GPS орқали жойлашувни сақланг ёки мanzilni қўлда киритинг',
    'useGpsLocation': 'GPS орқали жойлашув',
    'fetchingLocation': 'Жойлашув аниқланмоқда...',
    'locationSaved': 'Жойлашув сақланди',
    'orManualAddress': 'ёки қўлда киритинг',
    'addressHint': 'Масалан: Тошкент ш., Амир Темур кўчаси, 1',
    'locationOptionalNote': 'Локация ихтиёрий. Кейинчалик ҳам қўшиш мумкин.',
    'businessCreated': 'Бизнес яратилди! 🎉',
    'businessCreatedDesc': '{name} муваффақиятли яратилди.',
    'startWorking': 'Ишни бошлаш',
    'fieldRequired': 'Бу майдон мажбурий',
    'continueWizard': 'Давом этиш',
    'customBusinessTypeInfo':
        'Бизнесингиз турини ёзинг — биз уни ҳисобга оламиз',
    'customBusinessTypeHint': 'Масалан: Пишириқлар, Лимон лимонади...',
    'businessNameHint': 'Масалан: Марказий Новвойхона',
    'businessNameRequired': 'Бизнес номини киритинг',
    'businessNameMinLength': 'Камида 2 та ҳарф',
    'selectCurrency': 'Валюта',
    'selectCurrencyDesc':
        'Ҳисобот ва нархларда ишлатиладиган валютани танланг',
    'gpsAutoDetectSubtitle':
        'Ҳозирги жойлашувингизни автоматик аниқлаш',
    'orDivider': 'ёки',
    'manualAddressLabel': 'Манзилни қўлда киритинг',
    'createBusinessSubmit': 'Бизнесни яратиш',
  };

  static const _ru = {
    'hello': 'Привет',
    'defaultUser': 'Пользователь',
    'bakery': 'Бизнес',
    'bakeries': 'Бизнесы',
    'selectBusiness': 'Выберите бизнес',
    'selectBusinessSubtitle': 'Выберите бизнес, которым хотите управлять',
    'noBusiness': 'Бизнесов пока нет',
    'createFirstBusiness': 'Создайте свой первый бизнес\nи начните управление',
    'addBusiness': 'Добавить бизнес',
    'shopSettingsTitle': 'Настройки бизнеса',
    'shopNameLabel': 'Название',
    'shopNameHint': 'Например: Моя пекарня',
    'shopAddressLabel': 'Адрес',
    'shopAddressHint': 'Например: Ташкент, Чиланзар',
    'shopUpdateSuccess': 'Бизнес обновлён',
    'shopDeleteButton': 'Удалить бизнес',
    'shopDeleteTitle': 'Удалить бизнес',
    'shopDeleteMessage': 'Удалить бизнес «{name}»? Это действие нельзя отменить.',
    'shopDeleteSuccess': 'Бизнес удалён',
    'manage': 'Управление',
    'todayProfit': 'Прибыль за сегодня',
    'todayLoss': 'Убыток за сегодня',
    'netRevenue': 'Выручка после возвратов',
    'expense': 'Расход',
    'baked': 'Выпечено',
    'sack': 'Мешок',
    'sold': 'Продано',
    'returned': 'Возвращено',
    'pcs': 'шт',
    'sacks': 'мешк.',
    'noBreadToday': 'Сегодня хлеб ещё не выпекался',
    'income': 'Доход',
    'profit': 'Прибыль',
    'productOut': 'Продукция выпущена',
    'productReturned': 'Возврат продукции',
    'dashboardKpiOutput': 'Выпуск',
    'dashboardKpiBatch': 'Партии',
    'dashboardKpiSold': 'Продано',
    'dashboardKpiReturned': 'Возврат',
    'dashboardEmptyOutput': 'Выпуск не записан',
    'dashboardSectionOutput': 'Выпуск за сегодня',
    'dashboardTabOutput': 'Выпуск продукции',
    'dashboardTabExpense': 'Внешние расходы',
    'dashboardEmptyExpense': 'Расходы не записаны',
    'dashboardBatchUnitGeneric': 'парт.',
    'currency': 'сум',
    'home': 'Главная',
    'cashRegister': 'Внешний расход',
    'statistics': 'Статистика',
    'orders': 'Заказы',
    'ordersComingSoon': 'Скоро',
    'ordersComingSoonDesc': 'Раздел заказов находится в разработке.\nСкоро будет готов!',
    'charts': 'Графики',
    'chartsScreenTitle': 'Подробные графики',
    'chartRevenue': 'Распределение доходов',
    'chartProduction': 'Производство',
    'chartExpenses': 'Распределение расходов',
    'chartProfitTrend': 'Тренд прибыли',
    'reportScreenTitle': 'Отчёт',
    'reportPickRange': 'Период',
    'reportPickSingleDate': 'Дата',
    'reportChipToday': 'Сегодня',
    'reportChipYesterday': 'Вчера',
    'reportRangeLast7': '7 дней',
    'reportRangeLast30': '30 дней',
    'reportSectionSummary': 'Сводка',
    'reportSectionReturnsByType': 'Возвраты по типу',
    'reportSectionProducts': 'По продуктам',
    'reportGrossRevenue': 'Выручка до возвратов',
    'reportReturnsRecords': 'зап.',
    'reportProductionRecords': 'Записей выпуска',
    'reportEmptyReturns': 'Нет возвратов за период',
    'reportEmptyProducts': 'Нет данных по продуктам',
    'reportProductProduced': 'Выпущено',
    'reportExpandTypesCount': '{n} типов',
    'reportExpandProductsCount': '{n} поз.',
    'profileTab': 'Профиль',
    'navHistory': 'История',
    'historyTitle': 'История',
    'historyTabCreated': 'Создано',
    'historyTabReturns': 'Возвраты',
    'historyTabCash': 'Расходы',
    'historyTotalReturns': 'Всего возвратов',
    'historyCreatedEmpty': 'Пока нет выпусков продукции',
    'historyReturnsEmpty': 'Пока нет возвратов',
    'returnDetailTitle': 'Возврат',
    'noExpenseToday': 'Сегодня расходов нет',
    'addExpense': 'Расход',
    'expenseCreateTitle': 'Добавить расход',
    'expenseCreateSubtitle': 'Выберите тип и введите сумму.',
    'expenseCategorySearchHint': 'Поиск категорий',
    'expenseAddCategory': 'Новая категория',
    'expenseAddCategoryTitle': 'Своя категория',
    'expenseAddCategoryNameHint': 'Например: реклама',
    'expenseAddCategorySave': 'Сохранить категорию',
    'expenseSelectCategory': 'Тип',
    'expenseAmountLabel': 'Сумма',
    'expenseDescriptionLabel': 'Комментарий (необязательно)',
    'expenseSubmit': 'Сохранить расход',
    'expenseCategoriesEmpty': 'Ничего не найдено',
    'expenseCategoriesLoadError': 'Не удалось загрузить',
    'daily': 'Дневной',
    'weekly': 'Недельный',
    'monthly': 'Месячный',
    'loss': 'Убыток',
    'noData': 'Нет данных',
    'production': 'Производство',
    'flourUsage': 'Расход муки',
    'bakedBread': 'Выпечено хлеба',
    'ingredients': 'Ингредиенты',
    'salesAndReturns': 'Продажи и возвраты',
    'totalProduced': 'Всего произведено',
    'returns': 'Возвраты',
    'soldAuto': 'Продано (авто)',
    'returnAmount': 'Сумма возвратов',
    'netIncome': 'Чистый доход',
    'expenses': 'Расходы',
    'internalIngredients': 'Внутренние расходы',
    'external': 'Внешние',
    'total': 'Итого',
    'settings': 'Настройки',
    'breadTypes': 'Типы продукции',
    'breadTypesDesc':
        'Виды товаров или услуг — цена для каждой позиции',
    'products': 'Продукты',
    'productsDesc': 'Мука, вода, соль, дрожжи, масло...',
    'recipes': 'Рецепты',
    'recipesDesc': 'Состав и количество для хлеба',
    'settingsCardTypesTitle': 'Типы вашей продукции',
    'settingsCardIngredientsTitle': 'Сырьё и ингредиенты',
    'settingsCardRecipesTitle': 'Система расчёта',
    'settingsTypesDesc_default':
        'Добавляйте категории продукции и услуг, управляйте ценами.',
    'settingsTypesDesc_bakery':
        'Например: патир, самса, лаваш, тандыр... Отдельная цена для каждого вида.',
    'settingsTypesDesc_grill':
        'Например: шашлык, люля, рулет... Отдельная цена за каждую позицию.',
    'settingsTypesDesc_restaurant':
        'Например: блюда, гарниры, напитки... Структурируйте по меню.',
    'settingsIngredientsDesc_default':
        'Введите ингредиенты и сырьё с ценами и единицами измерения.',
    'settingsIngredientsDesc_bakery':
        'Мука, вода, соль, дрожжи, масло — цена и единица для каждого.',
    'settingsIngredientsDesc_grill':
        'Мясо, специи, масло — цена и единица для каждого.',
    'settingsIngredientsDesc_restaurant':
        'Продукты и ингредиенты — связь со складом и себестоимостью.',
    'settingsRecipesDesc_default':
        'Рецепты и себестоимость — маржа и прибыль по каждому товару.',
    'settingsRecipesDesc_bakery':
        'Соотношение ингредиентов и себестоимость — прибыль понятна.',
    'settingsRecipesDesc_grill':
        'Граммы и себестоимость на блюдо — цена и прибыль.',
    'settingsRecipesDesc_restaurant':
        'Себестоимость блюд и напитков — отчёты автоматически.',
    'setupJourneyTitle': 'Порядок настройки',
    'setupJourneyHint':
        'Сначала создайте тип продукции, затем добавьте сырьё и цены, затем настройте расчёт по рецепту — так себестоимость и прибыль будут точными.',
    'setupJourneyStepLabel1': 'Продукция',
    'setupJourneyStepLabel2': 'Сырьё',
    'setupJourneyStepLabel3': 'Расчёт',
    'setupJourneyAllDone': 'Все шаги выполнены',
    'settingsCardCompleted': 'Готово',
    'recipeScreenTitle': 'Рецепты',
    'recipeEmptyTitle': 'Рецептов пока нет',
    'recipeEmptySubtitle':
        'Добавьте рецепты для типов продукции — учёт производства будет точным.',
    'recipeAddCta': 'Добавить рецепт',
    'recipeDeletedSnackbar': 'Рецепт удалён',
    'recipeErrorSnackbar': 'Произошла ошибка',
    'recipeCreateTitle': 'Новый рецепт',
    'recipeStepProduct': 'Продукция',
    'recipeStepBatch': 'Партия',
    'recipeStepIngredients': 'Состав',
    'recipeSelectProductTitle': 'Для какого продукта?',
    'recipeSelectProductSubtitle':
        'Выберите один тип — для каждого типа один рецепт.',
    'recipeAlreadyExists': 'Рецепт уже создан',
    'recipeBatchCarouselTitle': 'Единица партии',
    'recipeBatchCarouselSubtitle':
        'Как считаете на производстве: мешок, блок, комплект...',
    'recipeOutputLabel': 'Количество продукции',
    'recipeOutputHint': 'Например: 100',
    'recipeOutputSectionTitle': 'Количество продукции',
    'recipeOutputSectionHelper':
        'Сколько единиц продукции получается из 1 партии?',
    'recipeIngredientsSectionTitle': 'Количество сырья на одну партию',
    'recipeOutputLabelDynamic': 'Сколько продукции с 1 {unit}?',
    'recipeIngredientsSectionTitleDynamic':
        'Количество сырья на 1 {unit}',
    'recipeIngredientsSectionSubtitleDynamic':
        'Укажите, сколько каждого сырья идёт на 1 {unit}.',
    'recipeIngredientsSectionSubtitle':
        'Введите количества на одну партию в выбранной единице.',
    'recipeAddIngredient': 'Добавить позицию',
    'recipeCreateNewIngredientDivider': 'ИЛИ',
    'recipeCreateNewIngredient': 'Создать новое сырьё',
    'recipeCreateNewIngredientShort': 'Новое',
    'recipeCreateNewIngredientHint':
        'Если его нет в списке — добавьте прямо отсюда',
    'recipeValidationSelectProduct': 'Выберите тип продукции',
    'recipeValidationBatch': 'Выберите единицу партии',
    'recipeValidationOutput': 'Введите количество выпуска',
    'recipeValidationIngredients': 'Добавьте хотя бы одно сырьё',
    'recipeValidationDuplicateIngredient':
        'Один и тот же ингредиент добавлен дважды',
    'recipeSaveSuccess': 'Рецепт сохранён',
    'recipeRecipeBatchLine': '1 {unit} → {qty} шт',
    'recipeBack': 'Назад',
    'recipeIngredientSelectHint': 'Сырьё',
    'recipeCardStatTitleOutput': 'Выпуск',
    'recipeCardStatTitleBatchCost': 'Себестоимость партии',
    'recipeCardStatTitleUnitCost': 'Себестоимость 1 шт',
    'recipeCardSectionIngredients': 'Состав',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Удалить рецепт?',
    'recipeDeleteConfirmBody':
        'Рецепт «{name}» будет удалён. Это действие нельзя отменить.',
    'recipeCardTooltipOutput':
        'Количество продукции за одну партию.',
    'recipeCardTooltipBatchCost':
        'Себестоимость сырья на одну партию (всего).',
    'recipeCardTooltipUnitCost':
        'Себестоимость единицы продукции (всего ÷ выпуск).',
    'productionDetailTitle': 'Партия подробно',
    'productionDetailSummary': 'Закрытая сегодня партия',
    'productionDetailBatch': 'Количество партий',
    'productionDetailOutput': 'Выпуск',
    'productionDetailFlour': 'Расход муки',
    'productionDetailIngredientCost': 'Себестоимость сырья',
    'productionDetailSalesEstimate': 'Ориентировочная выручка',
    'productionDetailBreakdown': 'По ингредиентам',
    'productionDetailOneRecipeBatch': '1 партия (рецепт)',
    'productionDetailQtyTotal': 'Итого количество',
    'productionDetailGrams': '{g} г',
    'productionDetailPricePerUnit': 'Цена за единицу',
    'productionDetailNoIngredients':
        'Ингредиенты рецепта отсутствуют или не загрузились.',
    'productionDetailReturnToday': 'Возврат за сегодня (по этому типу)',
    'productionDetailEdit': 'Редактировать',
    'productionDetailEditSheetTitle': 'Партия и возвраты',
    'productionDetailEditBatchLabel': 'Количество партий сегодня',
    'productionDetailEditReturnsTitle': 'Возвраты по этому типу (сегодня)',
    'productionDetailEditNoReturns': 'За сегодня возвратов по этому типу нет',
    'productionDetailEditSaveBatch': 'Сохранить партию',
    'productionDetailBatchUpdated': 'Партия обновлена',
    'productionDetailReturnDeleted': 'Возврат удалён',
    'productionDetailDeleteReturnTitle': 'Удалить возврат?',
    'productionDetailDeleteReturnBody':
        'Запись будет удалена. Главная и суммы обновятся.',
    'productionDetailDeleteProductionTitle': 'Удалить выпуск?',
    'productionDetailDeleteProductionBody':
        'Запись о выпуске будет удалена. Если по этому типу за дату не останется других партий, все возвраты за этот день для этого типа тоже будут удалены.',
    'productionDetailProductionDeleted': 'Выпуск удалён',
    'productionOutTitle': 'Выпуск продукции',
    'productionOutStep1': 'Продукция',
    'productionOutStep2': 'Партия',
    'productionOutStep3': 'Итог',
    'productionOutStep1Title': 'Какая продукция?',
    'productionOutStep1Subtitle':
        'Выберите тип, привязанный к расчёту (рецепту).',
    'productionOutCategoryLabel': 'Тип продукции',
    'productionOutCategoryHint': 'Выберите',
    'productionOutNoRecipeWarning':
        'Для этого типа нет рецепта. Сначала создайте расчёт в разделе «Система расчёта».',
    'productionOutStep2Title': 'Количество партий',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Допускаются дроби (например: 1.5).',
    'productionOutBatchFieldLabel': 'Количество ({unit})',
    'productionOutSummaryTitle': 'Расчёт',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Затраты',
    'productionOutIngredientsPreview': 'Расход сырья',
    'productionOutCta': 'Записать выпуск',
    'productionOutSuccess': 'Выпуск {qty} {unit} записан',
    'productionOutValidationSelectProduct': 'Выберите тип продукции',
    'productionOutValidationNoRecipe': 'Для этого типа нет рецепта',
    'productionOutValidationBatch': 'Введите количество партий больше 0',
    'productionOutStep3Title': 'Проверка и сохранение',
    'productionOutStep3Subtitle': 'Проверьте данные и сохраните.',
    'productionOutNext': 'Далее',
    'productionOutSearchHint': 'Поиск продукции',
    'productionOutSearchEmpty': 'Ничего не найдено',
    'returnCreateTitle': 'Возврат продукции',
    'returnCreateSubtitle':
        'Укажите тип и количество возврата. При выборе типа цена продажи подставится автоматически.',
    'returnProfitInfoTitle': 'Прибыль и учёт',
    'returnProfitInfoBody':
        'После записи возврата обновятся дневные продажи, выручка и прибыль (главная и отчёты) — так отражается реальное финансовое положение.',
    'returnProfitInfoShort':
        'Учёт возврата важен для корректной прибыли.',
    'returnProductionLabel': 'Партия (выпуск)',
    'returnNoProductionForCategory':
        'За сегодня нет выпуска по этому типу. Сначала запишите выпуск.',
    'returnSearchHint': 'Поиск продукции',
    'returnSearchEmpty': 'Ничего не найдено',
    'returnCategoryLabel': 'Тип продукции',
    'returnQuantityTitle': 'Количество возврата',
    'returnQuantitySubtitle': 'Введите целое число (шт.).',
    'returnPriceLabel': 'Цена за штуку',
    'returnReasonLabel': 'Причина (необязательно)',
    'returnReasonHint': 'Например: клиент, качество',
    'returnCta': 'Записать возврат',
    'returnValidationSelectProduct': 'Выберите тип продукции',
    'returnValidationQty': 'Количество должно быть больше 0',
    'returnValidationPrice': 'Введите корректную цену',
    'returnSuccess': 'Возврат записан',
    'returnPieceSuffix': 'шт.',
    'productCategoriesTitle': 'Типы продукции',
    'productCategoriesEmptyTitle': 'Пока нет типов продукции',
    'productCategoriesEmptySubtitle':
        'Добавьте виды товаров или услуг, которые продаёте',
    'addProductCategoryModalTitle': 'Новый тип',
    'addProductCategoryModalSubtitle': 'Введите название и цену продажи',
    'productCategoriesNameLabel': 'Название',
    'productCategoriesNameHint': 'Например: лаваш, сет-меню',
    'sellingPriceLabel': 'Цена продажи',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Валюта',
    'productCategoriesAddCta': 'Добавить тип',
    'snackbarFillAllFields': 'Заполните все поля',
    'snackbarErrorGeneric': 'Произошла ошибка',
    'apiClientTimeout': 'Время ожидания истекло',
    'apiClientNoConnection': 'Нет подключения к интернету',
    'apiClientUnexpected': 'Неожиданная ошибка',
    'apiInvalidResponseFormat': 'Неверный формат ответа',
    'actionAdd': 'Добавить',
    'actionSave': 'Сохранить',
    'editProductCategoryModalTitle': 'Редактировать тип',
    'editIngredientModalTitle': 'Редактировать сырьё',
    'snackbarCategoryAdded': '{name} добавлено',
    'snackbarCategoryDeleted': '{name} удалено',
    'snackbarCategoryUpdated': '{name} обновлено',
    'ingredientsEmptyTitle': 'Сырья пока нет',
    'ingredientsEmptySubtitle':
        'Укажите название, единицу измерения и цену за единицу для рецептов и себестоимости.',
    'addIngredientModalTitle': 'Новое сырьё',
    'addIngredientModalSubtitle':
        'Название, единица и цена. Валюта — кнопка справа от суммы.',
    'ingredientNameLabel': 'Название',
    'ingredientNameHint': 'Например: мука, вода, соль',
    'ingredientUnitFieldLabel': 'Единица измерения',
    'ingredientPricePerUnitLabel': 'Цена за 1 единицу',
    'ingredientPricePerUnitLabelDynamic': 'Цена за 1 {unit}',
    'ingredientUnit_kg': 'Килограмм (kg)',
    'ingredientUnit_gram': 'Грамм (g)',
    'ingredientUnit_litr': 'Литр (l)',
    'ingredientUnit_dona': 'Штука',
    'ingredientsAddCta': 'Добавить сырьё',
    'ingredientAddHeroTitle': 'Новое сырьё',
    'ingredientPriceHintBanner':
        'Введите полную цену за выбранную единицу (например, за 1 кг, 1 л или 1 шт.). В рецепте можно использовать г или мл — здесь хранится общая цена.',
    'ingredientUnitChipsLabel': 'Единица измерения',
    'snackbarIngredientAdded': '{name} добавлено',
    'snackbarIngredientDeleted': '{name} удалено',
    'snackbarIngredientUpdated': '{name} обновлено',
    'ingredientPriceInfoTitle': 'О цене',
    'ingredientPriceInfoBody':
        'Введите общую цену сырья за единицу (1 кг, 1 шт. или 1 л). В рецептах система сама пересчитает в граммы или миллилитры.',
    'gotIt': 'Понятно',
    'general': 'Общие',
    'manageAndSwitch': 'Управление и переключение',
    'staff': 'Сотрудники',
    'staffManagement': 'Управление персоналом',
    'darkMode': 'Тёмная тема',
    'enabled': 'Включено',
    'disabled': 'Выключено',
    'language': 'Язык',
    'aboutApp': 'О приложении',
    'aboutAppDescription': 'TAQSEEM — приложение для точного расчёта себестоимости, прибыли и расходов малого и среднего производственного бизнеса.',
    'developer': 'Разработчик',
    'website': 'Сайт',
    'support': 'Поддержка',
    'assetImagesPreview': 'Изображения (просмотр)',
    'version': 'Версия',
    'logout': 'Выйти из системы',
    'unknown': 'Неизвестно',
    'balance': 'Основной Баланс',
    'topUp': 'Пополнить',
    'profileInfo': 'Данные профиля',
    'profileInfoDesc': 'Телефон, почта и настройки Telegram',
    'phoneNumber': 'Номер телефона',
    'email': 'Эл. почта',
    'telegram': 'Телеграм',
    'linked': 'Привязан',
    'notLinked': 'Не привязан',
    'link': 'Привязать',
    'changePhoto': 'Изменить фото',
    'aboutTagline': 'Управляйте бизнесом одним взглядом',
    'aboutWhyTitle': 'Почему TAQSEEM?',
    'aboutWhyBody': 'TAQSEEM — современная система управления для малого и среднего производственного бизнеса. Видите ежедневное производство, расходы, возвраты и чистую прибыль в одном месте, в реальном времени.',
    'aboutFeaturesTitle': 'Основные возможности',
    'featProductionTitle': 'Учёт производства',
    'featProductionDesc': 'Контроль ежедневного объёма и себестоимости.',
    'featExpensesTitle': 'Управление расходами',
    'featExpensesDesc': 'Отслеживайте все расходы по категориям.',
    'featReturnsTitle': 'Возвраты',
    'featReturnsDesc': 'Точный учёт возвратов и потерь.',
    'featReportsTitle': 'Статистика и отчёты',
    'featReportsDesc': 'Дневные, недельные и месячные графики и аналитика.',
    'featMultiShopTitle': 'Несколько точек',
    'featMultiShopDesc': 'Управляйте несколькими точками из одного аккаунта.',
    'featRecipesTitle': 'Рецепты',
    'featRecipesDesc': 'Автоматический расчёт себестоимости ингредиентов.',
    'featMultiLangTitle': 'Мультиязычность',
    'featMultiLangDesc': 'Приложение на 7 языках: узбекский, русский, казахский и др.',
    'featDarkModeTitle': 'Тёмная / светлая тема',
    'featDarkModeDesc': 'Удобные ночной и дневной режимы.',
    'aboutContactTitle': 'Свяжитесь с нами',
    'aboutTelegramChannel': 'Telegram-канал',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Поддержка',
    'aboutWebsite': 'Веб-сайт',
    'personalInfo': 'Личные данные',
    'pressBackAgainToExit': 'Нажмите ещё раз, чтобы выйти',
    'editAction': 'Редактировать',
    'editExpense': 'Редактировать расход',
    'deleteExpense': 'Удалить расход',
    'deleteExpenseConfirm': 'Удалить этот расход?',
    'expenseDeleted': 'Расход удалён',
    'expenseUpdated': 'Расход обновлён',
    'expenseDeleteFailed': 'Ошибка удаления',
    'expenseUpdateFailed': 'Ошибка обновления',
    'undo': 'Отменить',
    'loginMethods': 'Способы входа',
    'editName': 'Изменить имя',
    'editEmail': 'Изменить email',
    'profileUpdated': 'Данные обновлены',
    'invalidEmail': 'Неверный email',
    'nameRequired': 'Имя обязательно',
    'readOnly': 'Нельзя изменить',
    'takePhoto': 'Сделать фото',
    'chooseFromGallery': 'Выбрать из галереи',
    'removePhoto': 'Удалить фото',
    'removePhotoConfirm': 'Удалить фото профиля?',
    'remove': 'Удалить',
    'uploadingPhoto': 'Загрузка...',
    'photoUpdated': 'Фото обновлено',
    'photoRemoved': 'Фото удалено',
    'photoUploadFailed': 'Не удалось загрузить фото',
    'businessOwner': 'Владелец бизнеса',
    'seller': 'Продавец',
    'deleteAccount': 'Удалить аккаунт',
    'deleteAccountDesc': 'При удалении аккаунта все ваши магазины, отчёты и данные будут безвозвратно удалены.',
    'deleteAccountConfirm': 'Вы действительно хотите удалить аккаунт?',
    'cancel': 'Отмена',
    'delete': 'Удалить',
    'privacyPolicy': 'Политика конфиденциальности',
    'privacyPolicyDesc': 'Защита персональных данных',
    'termsOfService': 'Условия использования',
    'termsOfServiceDesc': 'Правила оказания услуг',
    'account': 'Аккаунт',
    'logoutDesc': 'Выйти из аккаунта',
    'logoutConfirm': 'Вы хотите выйти из системы?',
    'madeInUzbekistan': 'Сделано в Узбекистане',
    'topUpComingSoonTitle': 'Скоро будет доступно',
    'topUpComingSoonDesc': 'Раздел пополнения баланса находится в разработке. Скоро вы сможете полноценно пользоваться приложением.',
    'goBack': 'Вернуться назад',
    'onboardingTitle1': 'Для любого бизнеса',
    'onboardingDesc1': 'Пекарня, шашлычная, самсахана, кондитерская, фастфуд — управляйте из одного места',
    'onboardingTitle2': 'Себестоимость и прибыль',
    'onboardingDesc2': 'Точно рассчитайте себестоимость каждого продукта и узнайте реальную прибыль',
    'onboardingTitle3': 'Бизнес под контролем',
    'onboardingDesc3': 'Отслеживайте продажи, расходы и производство в реальном времени',
    'skip': 'Пропустить',
    'next': 'Далее',
    'getStarted': 'Начать',
    'welcomeBack': 'Добро пожаловать!',
    'loginSubtitle': 'Войдите для продолжения',
    'password': 'Пароль',
    'enterPhone': 'Введите телефон',
    'enterPassword': 'Введите пароль',
    'loginButton': 'Войти',
    'noAccount': 'Нет аккаунта?',
    'registerLink': 'Зарегистрируйтесь',
    'tryAgain': 'Повторить',
    'noInternet': 'Ошибка подключения к интернету',
    'appTagline': 'Умная система для малого бизнеса',
    'firstTimeHint': 'Входите впервые? Сначала ',
    'createNewAccount': 'создайте новый аккаунт',
    'registerTitle': 'Регистрация',
    'registerSubtitle': 'Введите все данные',
    'fullNameHint': 'Имя и фамилия',
    'enterName': 'Введите имя',
    'confirmPasswordHint': 'Подтвердите пароль',
    'passwordsNotMatch': 'Пароли не совпадают',
    'otpTitle': 'Введите код',
    'otpSentTo': '4-значный код подтверждения\nотправлен на {phone}.',
    'resendCode': 'Отправить код повторно',
    'resendIn': 'Повторная отправка: {time}',
    'codeNotReceived': 'Код не пришёл?',
    'smsHelpTitle': 'SMS код не пришёл?',
    'smsHelpCauses': 'Частые причины:',
    'smsSpamTitle': 'Папка Спам',
    'smsSpamBody':
        'Проверьте папку «Спам» в SMS. Наш SMS отправлен с номера 4546.',
    'smsBalanceTitle': 'Баланс Uzmobile',
    'smsBalanceBody':
        'Если у вас нет баланса на Uzmobile, SIM-карта может не принимать SMS.',
    'understood': 'Понятно',
    'policyLoginPrefix': 'Входя, вы принимаете ',
    'policyRegisterPrefix': 'Регистрируясь, вы принимаете ',
    'policyAnd': ' и ',
    'policySuffix': '',
    'policyTerms': 'Условия',
    'policyPrivacy': 'Конфиденциальность',
    'stepForm': 'Данные',
    'stepVerify': 'Подтверждение',
    'stepEnterApp': 'Войти\nв приложение',
    'phoneExistsTitle': 'Номер уже зарегистрирован',
    'phoneExistsBody':
        'Номер {phone} уже зарегистрирован.\n\nВойдите с этим номером.',
    'cancelShort': 'Отмена',
    'socialComingSoon': 'Вход через {name} скоро появится',
    'telegramConnecting': 'Подключение...',
    'telegramConnectingHint': 'Открываем Telegram',
    'telegramWaitingTitle': 'Ожидание Telegram',
    'telegramWaitingHint': 'Отправьте номер телефона в Telegram и нажмите кнопку возврата в приложение',
    'telegramOpenAgain': 'Открыть Telegram снова',
    'telegramRetry': 'Попробовать снова',
    'telegramBackToLogin': 'Вернуться к входу',
    'telegramSessionExpired': 'Время истекло. Попробуйте снова.',
    'loginInfoPrefix': 'Если у вас нет аккаунта, ',
    'loginInfoAction': 'Создайте аккаунт',
    'loginInfoSuffix': '',
    'tapMapToSelect': 'Нажмите на карту, чтобы выбрать местоположение',
    'locationPermDenied': 'Доступ к местоположению запрещён. Откройте настройки.',
    'locationError': 'Не удалось определить местоположение',
    'tutorialStep1Title': 'Добавьте продукт',
    'tutorialStep1Desc': 'Введите тип производимого продукта',
    'tutorialStep2Title': 'Добавьте сырьё',
    'tutorialStep2Desc': 'Введите ингредиенты для рецепта',
    'tutorialStep3Title': 'Создайте расчёт',
    'tutorialStep3Desc': 'Укажите количество сырья на 1 продукт',
    'tutorialGoAction': 'Перейти',
    'tutorialSkip': 'Пропустить',
    'tutorialStep4Title': 'Запишите расход',
    'tutorialStep4Desc': 'Введите сколько продуктов выпущено сегодня',
    'tutorialGoSetup':    'Нажмите кнопку настройки',
    'tutorialGoSetupSub': 'Настройте продукты, сырьё и расчёты',
    'tutorialTapAdd':     'Нажмите кнопку добавить',
    'tutorialProductIncomeTitle': 'Приход продукта',
    'tutorialProductIncomeDesc':  'Запишите сегодняшний выпуск продукции через эту кнопку',
    'tutorialOpenCardTitle':      'Откройте раздел',
    'tutorialOpenCardDesc':       'Нажмите на эту карточку, чтобы войти в настройки',
    'tutorialSettingsHintTitle':   'Сначала настройте',
    'tutorialSettingsHintMessage': 'Добавьте продукты и сырьё — приложение само посчитает себестоимость и прибыль.',
    'createBusiness': 'Создать бизнес',
    'businessTypeStep': 'Категория',
    'businessDetailsStep': 'Информация',
    'businessLocationStep': 'Локация',
    'selectBusinessType': 'Выберите тип бизнеса',
    'selectBusinessTypeDesc': 'Выберите подходящую категорию — интерфейс адаптируется',
    'businessDetailsTitle': 'О бизнесе',
    'businessDetailsDesc': 'Введите основные данные вашего бизнеса',
    'businessName': 'Название бизнеса',
    'businessDescHint': 'Краткое описание (необязательно)',
    'description': 'Описание',
    'address': 'Адрес',
    'businessLocationTitle': 'Местоположение',
    'businessLocationDesc': 'Сохраните GPS-координаты или введите адрес вручную',
    'useGpsLocation': 'Определить по GPS',
    'fetchingLocation': 'Определение местоположения...',
    'locationSaved': 'Местоположение сохранено',
    'orManualAddress': 'или введите вручную',
    'addressHint': 'Например: г. Ташкент, ул. Амира Темура, 1',
    'locationOptionalNote': 'Местоположение необязательно. Можно добавить позже.',
    'businessCreated': 'Бизнес создан! 🎉',
    'businessCreatedDesc': '{name} успешно создан.',
    'startWorking': 'Начать работу',
    'fieldRequired': 'Это поле обязательно',
    'continueWizard': 'Продолжить',
    'customBusinessTypeInfo':
        'Укажите тип бизнеса — мы это учтём',
    'customBusinessTypeHint': 'Например: Выпечка, Лимонады...',
    'businessNameHint': 'Например: Центральная пекарня',
    'businessNameRequired': 'Введите название бизнеса',
    'businessNameMinLength': 'Минимум 2 символа',
    'selectCurrency': 'Валюта',
    'selectCurrencyDesc':
        'Валюта для отчётов и цен',
    'gpsAutoDetectSubtitle':
        'Автоматически определить текущее местоположение',
    'orDivider': 'или',
    'manualAddressLabel': 'Введите адрес вручную',
    'createBusinessSubmit': 'Создать бизнес',
  };

  static const _kk = {
    'hello': 'Сәлем',
    'defaultUser': 'Пайдаланушы',
    'bakery': 'Бизнес',
    'bakeries': 'Бизнестер',
    'selectBusiness': 'Бизнес таңдаңыз',
    'selectBusinessSubtitle': 'Басқарғыңыз келген бизнесті таңдаңыз',
    'noBusiness': 'Бизнес жоқ',
    'createFirstBusiness': 'Алғашқы бизнесіңізді жасаңыз\nжәне басқаруды бастаңыз',
    'addBusiness': 'Жаңа бизнес қосу',
    'shopSettingsTitle': 'Бизнес баптаулары',
    'shopNameLabel': 'Бизнес атауы',
    'shopNameHint': 'Мысалы: Нан дүкенім',
    'shopAddressLabel': 'Мекенжай',
    'shopAddressHint': 'Мысалы: Ташкент, Чиланзар',
    'shopUpdateSuccess': 'Бизнес жаңартылды',
    'shopDeleteButton': 'Бизнесті жою',
    'shopDeleteTitle': 'Бизнесті жою',
    'shopDeleteMessage': '«{name}» бизнесін жоюды қалайсыз ба? Бұл әрекетті қайтару мүмкін емес.',
    'shopDeleteSuccess': 'Бизнес жойылды',
    'manage': 'Басқару',
    'todayProfit': 'Бүгінгі пайда',
    'todayLoss': 'Бүгінгі шығын',
    'netRevenue': 'Түсім (қайтарудан кейін)',
    'expense': 'Шығын',
    'baked': 'Пісірілген',
    'sack': 'Қап',
    'sold': 'Сатылған',
    'returned': 'Қайтарылған',
    'pcs': 'дана',
    'sacks': 'қап',
    'noBreadToday': 'Бүгін нан әлі пісірілмеді',
    'income': 'Табыс',
    'profit': 'Пайда',
    'productOut': 'Өнім шығарылды',
    'productReturned': 'Өнім қайтарылды',
    'dashboardKpiOutput': 'Өнім шығымы',
    'dashboardKpiBatch': 'Топтам',
    'dashboardKpiSold': 'Сатылған',
    'dashboardKpiReturned': 'Қайтарылған',
    'dashboardEmptyOutput': 'Шығыс тіркелмеген',
    'dashboardSectionOutput': 'Бүгінгі шығыстар',
    'dashboardTabOutput': 'Өнім шығысы',
    'dashboardTabExpense': 'Сыртқы шығын',
    'dashboardEmptyExpense': 'Шығын тіркелмеген',
    'dashboardBatchUnitGeneric': 'партия',
    'currency': 'сом',
    'home': 'Басты',
    'cashRegister': 'Сыртқы шығын',
    'statistics': 'Статистика',
    'orders': 'Тапсырыстар',
    'ordersComingSoon': 'Жақында',
    'ordersComingSoonDesc': 'Тапсырыстар бөлімі әзірленуде.\nЖақын арада дайын болады!',
    'charts': 'Графиктер',
    'chartsScreenTitle': 'Толық графиктер',
    'chartRevenue': 'Табыс бөлінісі',
    'chartProduction': 'Өндіріс',
    'chartExpenses': 'Шығын бөлінісі',
    'chartProfitTrend': 'Пайда трендi',
    'reportScreenTitle': 'Есеп',
    'reportPickRange': 'Аралық',
    'reportPickSingleDate': 'Күн',
    'reportChipToday': 'Бүгін',
    'reportChipYesterday': 'Кеше',
    'reportRangeLast7': '7 күн',
    'reportRangeLast30': '30 күн',
    'reportSectionSummary': 'Жалпы көрсеткіштер',
    'reportSectionReturnsByType': 'Қайтарулар (түрі бойынша)',
    'reportSectionProducts': 'Өнім бойынша',
    'reportGrossRevenue': 'Түсім (қайтарудан бұрын)',
    'reportReturnsRecords': 'жазба',
    'reportProductionRecords': 'Шығыс жазбалары',
    'reportEmptyReturns': 'Бұл кезеңде қайтару жоқ',
    'reportEmptyProducts': 'Өнім бойынша дерек жоқ',
    'reportProductProduced': 'Өндірілген',
    'reportExpandTypesCount': '{n} түр',
    'reportExpandProductsCount': '{n} өнім',
    'profileTab': 'Профиль',
    'navHistory': 'Тарих',
    'historyTitle': 'Тарих',
    'historyTabCreated': 'Жасалған',
    'historyTabReturns': 'Қайтарылған',
    'historyTabCash': 'Шығындар',
    'historyTotalReturns': 'Жалпы қайтарылған',
    'historyCreatedEmpty': 'Әлі өнім шығымы жоқ',
    'historyReturnsEmpty': 'Әлі қайтару жазылмаған',
    'returnDetailTitle': 'Қайтару толығырақ',
    'noExpenseToday': 'Бүгін шығын жазылмаған',
    'addExpense': 'Шығын',
    'expenseCreateTitle': 'Шығын қосу',
    'expenseCreateSubtitle': 'Түрін таңдаңыз, соманы енгізіңіз.',
    'expenseCategorySearchHint': 'Іздеу',
    'expenseAddCategory': 'Жаңа санат',
    'expenseAddCategoryTitle': 'Өз санатыңыз',
    'expenseAddCategoryNameHint': 'Мысалы: жарнама',
    'expenseAddCategorySave': 'Сақтау',
    'expenseSelectCategory': 'Түрі',
    'expenseAmountLabel': 'Сома',
    'expenseDescriptionLabel': 'Түсініктеме (міндетті емес)',
    'expenseSubmit': 'Сақтау',
    'expenseCategoriesEmpty': 'Табылмады',
    'expenseCategoriesLoadError': 'Жүктелмеді',
    'daily': 'Күнделікті',
    'weekly': 'Апталық',
    'monthly': 'Айлық',
    'loss': 'Шығын',
    'noData': 'Деректер жоқ',
    'production': 'Өндіріс',
    'flourUsage': 'Ұн шығыны',
    'bakedBread': 'Пісірілген нан',
    'ingredients': 'Ингредиенттер',
    'salesAndReturns': 'Сату және қайтару',
    'totalProduced': 'Барлығы өндірілген',
    'returns': 'Қайтару',
    'soldAuto': 'Сатылған (авто)',
    'returnAmount': 'Қайтару сомасы',
    'netIncome': 'Таза табыс',
    'expenses': 'Шығындар',
    'internalIngredients': 'Ішкі шығындар',
    'external': 'Сыртқы',
    'total': 'Барлығы',
    'settings': 'Баптаулар',
    'breadTypes': 'Өнім түрлері',
    'breadTypesDesc':
        'Сататын өнім немесе қызмет түрлері — әрқайсысына баға',
    'products': 'Өнімдер',
    'productsDesc': 'Ұн, су, тұз, ашытқы, май...',
    'recipes': 'Рецепттер',
    'recipesDesc': 'Нан үшін құрамы мен мөлшері',
    'settingsCardTypesTitle': 'Өнім түрлеріңіз',
    'settingsCardIngredientsTitle': 'Шикізат',
    'settingsCardRecipesTitle': 'Есептеу жүйесі',
    'settingsTypesDesc_default':
        'Сататын өнім мен қызмет түрлерін қосыңыз, бағаларды басқарыңыз.',
    'settingsTypesDesc_bakery':
        'Мысалы: патир, самса, лаваш, тандыр... Әр түр үшін бөлек баға.',
    'settingsTypesDesc_grill':
        'Мысалы: шашлық, люля, рулет... Әр позиция үшін бөлек баға.',
    'settingsTypesDesc_restaurant':
        'Мысалы: тағамдар, гарнирлер, сусындар... Мәзір бойынша реттеңіз.',
    'settingsIngredientsDesc_default':
        'Ингредиенттер мен шикізатты бағасы мен өлшемімен енгізіңіз.',
    'settingsIngredientsDesc_bakery':
        'Ұн, су, тұз, ашытқы, май — әрқайсысының бағасы мен өлшемі.',
    'settingsIngredientsDesc_grill':
        'Ет, дәмдеуіштер, май — әрқайсысының бағасы мен өлшемі.',
    'settingsIngredientsDesc_restaurant':
        'Өнім мен ингредиенттер — қойма және өзіндік құнмен байланысыңыз.',
    'settingsRecipesDesc_default':
        'Рецепттер мен өзіндік құн — әр тауар үшін маржа мен пайда.',
    'settingsRecipesDesc_bakery':
        'Әр өнім үшін ингредиенттер қатынасы мен өзіндік құн — пайда анық.',
    'settingsRecipesDesc_grill':
        'Әр тағам үшін грамм және өзіндік құн — баға мен пайда есебі.',
    'settingsRecipesDesc_restaurant':
        'Тағам мен сусындар үшін өзіндік құн және сату — есептер автоматты.',
    'setupJourneyTitle': 'Баптау реті',
    'setupJourneyHint':
        'Алдымен сатылатын өнім түрін жасаңыз, содан кейін шикізат пен бағаларды енгізіңіз, соңында рецепт арқылы есептеуді жүйелеңіз — сонда өзіндік құн пен пайда нақты болады.',
    'setupJourneyStepLabel1': 'Өнім',
    'setupJourneyStepLabel2': 'Шикізат',
    'setupJourneyStepLabel3': 'Есептеу',
    'setupJourneyAllDone': 'Барлық қадам орындалды',
    'settingsCardCompleted': 'Орындалды',
    'recipeScreenTitle': 'Рецепттер',
    'recipeEmptyTitle': 'Әлі рецепттер жоқ',
    'recipeEmptySubtitle':
        'Өнім түрлері үшін рецепт қосыңыз — өндіріс есебі дәл болады.',
    'recipeAddCta': 'Рецепт қосу',
    'recipeDeletedSnackbar': 'Рецепт жойылды',
    'recipeErrorSnackbar': 'Қате пайда болды',
    'recipeCreateTitle': 'Жаңа рецепт',
    'recipeStepProduct': 'Өнім',
    'recipeStepBatch': 'Партия',
    'recipeStepIngredients': 'Құрам',
    'recipeSelectProductTitle': 'Қай өнім үшін?',
    'recipeSelectProductSubtitle':
        'Бір түрді таңдаңыз — әр түр үшін бір рецепт.',
    'recipeAlreadyExists': 'Рецепт бар',
    'recipeBatchCarouselTitle': 'Партия бірлігі',
    'recipeBatchCarouselSubtitle':
        'Өндірісте қалай есептейсіз: қап, блок, жиынтық...',
    'recipeOutputLabel': 'Өнім саны',
    'recipeOutputHint': 'Мысалы: 100',
    'recipeOutputSectionTitle': 'Өнім саны',
    'recipeOutputSectionHelper':
        '1 партиядан неше өнім шығады?',
    'recipeIngredientsSectionTitle': 'Бір партияға шикізат мөлшері',
    'recipeOutputLabelDynamic': '1 {unit}тан қанша өнім шығады?',
    'recipeIngredientsSectionTitleDynamic':
        '1 {unit} үшін шикізат мөлшері',
    'recipeIngredientsSectionSubtitleDynamic':
        '1 {unit}ға қанша шикізат кететінін көрсетіңіз.',
    'recipeIngredientsSectionSubtitle':
        'Таңдалған бірліктегі бір партияға кететін мөлшерлерді енгізіңіз.',
    'recipeAddIngredient': 'Қосу',
    'recipeCreateNewIngredientDivider': 'НЕМЕСЕ',
    'recipeCreateNewIngredient': 'Жаңа шикізат қосу',
    'recipeCreateNewIngredientShort': 'Жаңа',
    'recipeCreateNewIngredientHint':
        'Тізімде болмаса — осы жерден қоса беріңіз',
    'recipeValidationSelectProduct': 'Өнім түрін таңдаңыз',
    'recipeValidationBatch': 'Партия бірлігін таңдаңыз',
    'recipeValidationOutput': 'Шығу санын енгізіңіз',
    'recipeValidationIngredients': 'Кемінде бір шикізат қосыңыз',
    'recipeValidationDuplicateIngredient':
        'Бір ингредиент екі рет қосылған',
    'recipeSaveSuccess': 'Рецепт сақталды',
    'recipeRecipeBatchLine': '1 {unit} → {qty} дана',
    'recipeBack': 'Артқа',
    'recipeIngredientSelectHint': 'Шикізат',
    'recipeCardStatTitleOutput': 'Шығару',
    'recipeCardStatTitleBatchCost': 'Партия өзіндік құны',
    'recipeCardStatTitleUnitCost': '1 дана өзіндік құны',
    'recipeCardSectionIngredients': 'Құрам',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Рецептті жою?',
    'recipeDeleteConfirmBody':
        '«{name}» рецепті жойылады. Бұл әрекетті болдырмауға болмайды.',
    'recipeCardTooltipOutput':
        'Бір партиядан шығатын өнім саны.',
    'recipeCardTooltipBatchCost':
        'Бір партияға шикізаттың өзіндік құны (жалпы).',
    'recipeCardTooltipUnitCost':
        'Бір өнім бірлігінің өзіндік құны (жалпы ÷ шығару).',
    'productionDetailTitle': 'Партия толығырақ',
    'productionDetailSummary': 'Бүгін жабылған партия',
    'productionDetailBatch': 'Партия саны',
    'productionDetailOutput': 'Шығару',
    'productionDetailFlour': 'Ұн шығыны',
    'productionDetailIngredientCost': 'Шикізат құны',
    'productionDetailSalesEstimate': 'Болжамды түсім',
    'productionDetailBreakdown': 'Ингредиенттер бойынша',
    'productionDetailOneRecipeBatch': '1 партия (рецепт)',
    'productionDetailQtyTotal': 'Жалпы мөлшер',
    'productionDetailGrams': '{g} г',
    'productionDetailPricePerUnit': 'Бірлік бағасы',
    'productionDetailNoIngredients':
        'Рецепт ингредиенттері жоқ немесе жүктелмеді.',
    'productionDetailReturnToday': 'Бүгінгі қайтару (осы түр бойынша)',
    'productionDetailEdit': 'Өңдеу',
    'productionDetailEditSheetTitle': 'Партия және қайтарулар',
    'productionDetailEditBatchLabel': 'Бүгінгі партия саны',
    'productionDetailEditReturnsTitle': 'Осы түр бойынша қайтарулар (бүгін)',
    'productionDetailEditNoReturns': 'Бүгін осы түр бойынша қайтару жоқ',
    'productionDetailEditSaveBatch': 'Партияны сақтау',
    'productionDetailBatchUpdated': 'Партия жаңартылды',
    'productionDetailReturnDeleted': 'Қайтару жойылды',
    'productionDetailDeleteReturnTitle': 'Қайтаруды жою керек пе?',
    'productionDetailDeleteReturnBody':
        'Жазба жойылады. Басты бет пен соммалар жаңартылады.',
    'productionDetailDeleteProductionTitle': 'Шығымды жою керек пе?',
    'productionDetailDeleteProductionBody':
        'Бұл шығыс жазбасы жойылады. Осы түр мен күнде басқа партия қалмаса, сол күнге жазылған барлық қайтарулар да жойылады.',
    'productionDetailProductionDeleted': 'Шығыс жойылды',
    'productionOutTitle': 'Өнім шығарылымы',
    'productionOutStep1': 'Өнім',
    'productionOutStep2': 'Топтам',
    'productionOutStep3': 'Қорытынды',
    'productionOutStep1Title': 'Қай өнім?',
    'productionOutStep1Subtitle':
        'Есептеуге байланған өнім түрін таңдаңыз.',
    'productionOutCategoryLabel': 'Өнім түрі',
    'productionOutCategoryHint': 'Таңдаңыз',
    'productionOutNoRecipeWarning':
        'Бұл түр үшін рецепт жоқ. Алдымен «Есептеу» бөлімінде рецепт жасаңыз.',
    'productionOutStep2Title': 'Партия мөлшері',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Бөлшек сандарға рұқсат (мысалы: 1.5).',
    'productionOutBatchFieldLabel': '{unit} мөлшері',
    'productionOutSummaryTitle': 'Есеп',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Шығын',
    'productionOutIngredientsPreview': 'Шикізат шығыны',
    'productionOutCta': 'Шығымды тіркеу',
    'productionOutSuccess': '{qty} {unit} шығым тіркелді',
    'productionOutValidationSelectProduct': 'Өнім түрін таңдаңыз',
    'productionOutValidationNoRecipe': 'Бұл түр үшін рецепт жоқ',
    'productionOutValidationBatch': 'Партия мөлшері 0-дан үлкен болсын',
    'productionOutStep3Title': 'Тексеру және сақтау',
    'productionOutStep3Subtitle': 'Дұрыс болса, сақтаңыз.',
    'productionOutNext': 'Келесі',
    'productionOutSearchHint': 'Өнім іздеу',
    'productionOutSearchEmpty': 'Ештеңе табылмады',
    'returnCreateTitle': 'Өнім қайтарылды',
    'returnCreateSubtitle':
        'Қайтарылған түр мен мөлшерді енгізіңіз. Түр таңдалғанда сату бағасы автоматты шығады.',
    'returnProfitInfoTitle': 'Пайда және есеп',
    'returnProfitInfoBody':
        'Қайтару тіркелгенде күнделікті сату, түсім және пайда көрсеткіштері (басты бет және есептер) сәйкес жаңартылады — бұл нақты қаржылық жағдайды білдіреді.',
    'returnProfitInfoShort':
        'Өнім қайтарылуын енгізу пайданы дұрыс есептеу үшін маңызды.',
    'returnProductionLabel': 'Партия (шығару)',
    'returnNoProductionForCategory':
        'Бұл түр үшін бүгін шығарыл жоқ. Алдымен шығарылым қосыңыз.',
    'returnSearchHint': 'Өнім іздеу',
    'returnSearchEmpty': 'Ештеңе табылмады',
    'returnCategoryLabel': 'Өнім түрі',
    'returnQuantityTitle': 'Қайтарылған мөлшер',
    'returnQuantitySubtitle': 'Бүтін сан (дана) енгізіңіз.',
    'returnPriceLabel': 'Бір дана бағасы',
    'returnReasonLabel': 'Себебі (міндетті емес)',
    'returnReasonHint': 'Мысалы: тұтынушы, сапа',
    'returnCta': 'Қайтаруды тіркеу',
    'returnValidationSelectProduct': 'Өнім түрін таңдаңыз',
    'returnValidationQty': 'Мөлшер 0-дан үлкен болсын',
    'returnValidationPrice': 'Бағаны дұрыс енгізіңіз',
    'returnSuccess': 'Қайтару тіркелді',
    'returnPieceSuffix': 'дана',
    'productCategoriesTitle': 'Өнім түрлері',
    'productCategoriesEmptyTitle': 'Әлі өнім түрлері жоқ',
    'productCategoriesEmptySubtitle':
        'Сататын өнім немесе қызмет түрлерін қосыңыз',
    'addProductCategoryModalTitle': 'Жаңа түр',
    'addProductCategoryModalSubtitle': 'Атауы мен сату бағасын енгізіңіз',
    'productCategoriesNameLabel': 'Өнім атауы',
    'productCategoriesNameHint': 'Мысалы: лаваш, сет-меню',
    'sellingPriceLabel': 'Сату бағасы',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Валюта',
    'productCategoriesAddCta': 'Түр қосу',
    'snackbarFillAllFields': 'Барлық өрістерді толтырыңыз',
    'snackbarErrorGeneric': 'Қате пайда болды',
    'apiClientTimeout': 'Қосылу уақыты бітті',
    'apiClientNoConnection': 'Интернет байланысы жоқ',
    'apiClientUnexpected': 'Күтпеген қате',
    'apiInvalidResponseFormat': 'Күтпеген жауап форматы',
    'actionAdd': 'Қосу',
    'actionSave': 'Сақтау',
    'editProductCategoryModalTitle': 'Түрді өңдеу',
    'editIngredientModalTitle': 'Шикізатты өңдеу',
    'snackbarCategoryAdded': '{name} қосылды',
    'snackbarCategoryDeleted': '{name} жойылды',
    'snackbarCategoryUpdated': '{name} жаңартылды',
    'ingredientsEmptyTitle': 'Әлі шикізат жоқ',
    'ingredientsEmptySubtitle':
        'Рецепт және өзіндік құн үшін атау, өлшем бірлігі және 1 бірлік бағасын енгізіңіз.',
    'addIngredientModalTitle': 'Жаңа шикізат',
    'addIngredientModalSubtitle':
        'Атау, бірлік және баға. Валютаны баға жанындағы түйме арқылы таңдаңыз.',
    'ingredientNameLabel': 'Атауы',
    'ingredientNameHint': 'Мысалы: ұн, су, тұз',
    'ingredientUnitFieldLabel': 'Өлшем бірлігі',
    'ingredientPricePerUnitLabel': '1 бірлік бағасы',
    'ingredientPricePerUnitLabelDynamic': '1 {unit} бағасын енгізіңіз',
    'ingredientUnit_kg': 'Килограмм (kg)',
    'ingredientUnit_gram': 'Грамм (g)',
    'ingredientUnit_litr': 'Литр (l)',
    'ingredientUnit_dona': 'Дана',
    'ingredientsAddCta': 'Шикізат қосу',
    'ingredientAddHeroTitle': 'Жаңа шикізат',
    'ingredientPriceHintBanner':
        'Бағаны таңдалған бірлік бойынша толық енгізіңіз (мысалы, 1 кг, 1 л немесе 1 дана). Рецептте г немесе мл қолдансаңыз да, мұнда жалпы баға сақталады.',
    'ingredientUnitChipsLabel': 'Өлшем бірлігі',
    'snackbarIngredientAdded': '{name} қосылды',
    'snackbarIngredientDeleted': '{name} жойылды',
    'snackbarIngredientUpdated': '{name} жаңартылды',
    'ingredientPriceInfoTitle': 'Баға туралы',
    'ingredientPriceInfoBody':
        'Шикізат бағасын бірлікке қарай жазыңыз (1 кг, 1 дана немесе 1 л). Рецепттерде жүйе грамм немесе мл-ге өзі есептейді.',
    'gotIt': 'Түсінікті',
    'general': 'Жалпы',
    'manageAndSwitch': 'Басқару және ауыстыру',
    'staff': 'Қызметкерлер',
    'staffManagement': 'Персоналды басқару',
    'darkMode': 'Түнгі режим',
    'enabled': 'Қосулған',
    'disabled': 'Өшірілген',
    'language': 'Тіл',
    'aboutApp': 'Қолданба туралы',
    'aboutAppDescription': 'TAQSEEM — шағын және орта өндірістік бизнестердің өзіндік құнын, пайдасын және шығындарын дәл есептеу қолданбасы.',
    'developer': 'Әзірлеуші',
    'website': 'Веб-сайт',
    'support': 'Қолдау',
    'assetImagesPreview': 'Суреттер (көрініс)',
    'version': 'Нұсқа',
    'logout': 'Жүйеден шығу',
    'unknown': 'Белгісіз',
    'balance': 'Негізгі Баланс',
    'topUp': 'Толтыру',
    'profileInfo': 'Профиль деректері',
    'profileInfoDesc': 'Телефон, пошта және Телеграм баптаулары',
    'phoneNumber': 'Телефон нөмірі',
    'email': 'Эл. пошта',
    'telegram': 'Телеграм',
    'linked': 'Байланған',
    'notLinked': 'Байланбаған',
    'link': 'Байлау',
    'changePhoto': 'Суретті өзгерту',
    'aboutTagline': 'Бизнесіңізді бір қарауда басқарыңыз',
    'aboutWhyTitle': 'Неге TAQSEEM?',
    'aboutWhyBody': 'TAQSEEM — шағын және орта өндірістік бизнеске арналған заманауи басқару жүйесі. Күнделікті өндіріс, шығын, қайтарымдар мен таза пайданы бір жерде, нақты уақытта көріңіз.',
    'aboutFeaturesTitle': 'Негізгі мүмкіндіктер',
    'featProductionTitle': 'Өндіріс есебі',
    'featProductionDesc': 'Күнделікті көлем мен өзіндік құн бақылауы.',
    'featExpensesTitle': 'Шығын басқару',
    'featExpensesDesc': 'Барлық шығындарды санаттар бойынша бақылаңыз.',
    'featReturnsTitle': 'Қайтарымдар',
    'featReturnsDesc': 'Қайтарылғандар мен шығындарды дәл есепке алыңыз.',
    'featReportsTitle': 'Статистика және есептер',
    'featReportsDesc': 'Күндік, апталық, айлық графиктер және аналитика.',
    'featMultiShopTitle': 'Бірнеше нүкте',
    'featMultiShopDesc': 'Бірнеше нүктені бір аккаунттан басқарыңыз.',
    'featRecipesTitle': 'Рецепттер',
    'featRecipesDesc': 'Рецепт және ингредиент құнын автоматты есептеу.',
    'featMultiLangTitle': 'Көп тілді',
    'featMultiLangDesc': '7 тілде: қазақ, өзбек, орыс, қырғыз және басқалары.',
    'featDarkModeTitle': 'Қараңғы / жарық режим',
    'featDarkModeDesc': 'Көзге жайлы түнгі және күндізгі режимдер.',
    'aboutContactTitle': 'Бізбен байланысыңыз',
    'aboutTelegramChannel': 'Telegram арнасы',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Қолдау',
    'aboutWebsite': 'Веб-сайт',
    'personalInfo': 'Жеке деректер',
    'pressBackAgainToExit': 'Шығу үшін тағы бір рет басыңыз',
    'editAction': 'Өңдеу',
    'editExpense': 'Шығынды өңдеу',
    'deleteExpense': 'Шығынды жою',
    'deleteExpenseConfirm': 'Бұл шығынды жоюды растайсыз ба?',
    'expenseDeleted': 'Шығын жойылды',
    'expenseUpdated': 'Шығын жаңартылды',
    'expenseDeleteFailed': 'Жою кезінде қате',
    'expenseUpdateFailed': 'Жаңарту кезінде қате',
    'undo': 'Қайтару',
    'loginMethods': 'Кіру тәсілдері',
    'editName': 'Атын өзгерту',
    'editEmail': 'Email өзгерту',
    'profileUpdated': 'Деректер жаңартылды',
    'invalidEmail': 'Email дұрыс емес',
    'nameRequired': 'Аты қажет',
    'readOnly': 'Өзгерту мүмкін емес',
    'takePhoto': 'Сурет түсіру',
    'chooseFromGallery': 'Галереядан таңдау',
    'removePhoto': 'Суретті жою',
    'removePhotoConfirm': 'Профиль суретін жоясыз ба?',
    'remove': 'Жою',
    'uploadingPhoto': 'Жүктелуде...',
    'photoUpdated': 'Сурет жаңартылды',
    'photoRemoved': 'Сурет жойылды',
    'photoUploadFailed': 'Суретті жүктеу мүмкін болмады',
    'businessOwner': 'Бизнес иесі',
    'seller': 'Сатушы',
    'deleteAccount': 'Аккаунтты жою',
    'deleteAccountDesc': 'Аккаунтыңызды жойсаңыз, барлық дүкендеріңіз, есептеріңіз және деректеріңіз мүлдем жойылады.',
    'deleteAccountConfirm': 'Шынымен аккаунтыңызды жоюды қалайсыз ба?',
    'cancel': 'Бас тарту',
    'delete': 'Жою',
    'privacyPolicy': 'Құпиялылық саясаты',
    'privacyPolicyDesc': 'Жеке деректерді қорғау',
    'termsOfService': 'Қолдану шарттары',
    'termsOfServiceDesc': 'Қызмет көрсету ережелері',
    'account': 'Аккаунт',
    'logoutDesc': 'Аккаунттан шығу',
    'logoutConfirm': 'Жүйеден шығғыңыз келе ме?',
    'madeInUzbekistan': 'Өзбекстанда жасалған',
    'topUpComingSoonTitle': 'Жақын арада іске қосылады',
    'topUpComingSoonDesc': 'Балансты толтыру бөлімі әзірлену үстінде. Жақын арада қолданбаны толық пайдалана аласыз.',
    'goBack': 'Артқа қайту',
    'onboardingTitle1': 'Кез келген бизнес үшін',
    'onboardingDesc1': 'Наубайхана, шашлықхана, самсахана, кондитерлік, фастфуд — барлығын бір жерден басқарыңыз',
    'onboardingTitle2': 'Өзіндік құн және пайда есебі',
    'onboardingDesc2': 'Әр өнімнің өзіндік құнын дәл есептеп, нақты пайданы біліңіз',
    'onboardingTitle3': 'Бизнесіңіз бақылауда',
    'onboardingDesc3': 'Сатылым, шығын және өндірісті нақты уақытта қадағалаңыз',
    'skip': 'Өткізіп жіберу',
    'next': 'Келесі',
    'getStarted': 'Бастау',
    'welcomeBack': 'Қош келдіңіз!',
    'loginSubtitle': 'Жалғастыру үшін жүйеге кіріңіз',
    'password': 'Құпия сөз',
    'enterPhone': 'Телефонды енгізіңіз',
    'enterPassword': 'Құпия сөзді енгізіңіз',
    'loginButton': 'Кіру',
    'noAccount': 'Аккаунт жоқ па?',
    'registerLink': 'Тіркеліңіз',
    'tryAgain': 'Қайта көру',
    'noInternet': 'Интернет қосылымында қате',
    'appTagline': 'Шағын бизнес үшін ақылды жүйе',
    'firstTimeHint': 'Алғаш рет кіріп жатырсыз ба? Алдымен ',
    'createNewAccount': 'жаңа аккаунт жасаңыз',
    'registerTitle': 'Тіркелу',
    'registerSubtitle': 'Барлық деректерді енгізіңіз',
    'fullNameHint': 'Аты-жөні',
    'enterName': 'Атыңызды енгізіңіз',
    'confirmPasswordHint': 'Құпия сөзді растаңыз',
    'passwordsNotMatch': 'Құпия сөздер сәйкес емес',
    'otpTitle': 'Кодты енгізіңіз',
    'otpSentTo': '4 санды растау коды\n{phone}\nнөміріне жіберілді.',
    'resendCode': 'Кодты қайта жіберу',
    'resendIn': 'Қайта жіберу: {time}',
    'codeNotReceived': 'Код келмеді ме?',
    'smsHelpTitle': 'SMS код келмеді ме?',
    'smsHelpCauses': 'Жиі кездесетін себептер:',
    'smsSpamTitle': 'Spam қалтасы',
    'smsSpamBody':
        'SMS бөлімінде «Spam» немесе «Қажетсіз» қалтасын тексеріңіз. Біздің SMS 4546 нөмірінен келеді.',
    'smsBalanceTitle': 'Uzmobile балансы',
    'smsBalanceBody':
        'Uzmobile операторында баланс болмаса SIM карта SMS қабылдамауы мүмкін.',
    'understood': 'Түсіндім',
    'policyLoginPrefix': 'Кіру арқылы ',
    'policyRegisterPrefix': 'Тіркелу арқылы ',
    'policyAnd': ' және ',
    'policySuffix': ' саясатын қабылдайсыз',
    'policyTerms': 'Шарттар',
    'policyPrivacy': 'Құпиялылық',
    'stepForm': 'Деректер',
    'stepVerify': 'Растау',
    'stepEnterApp': 'Қолданбаға\nкіру',
    'phoneExistsTitle': 'Нөмір тіркелген',
    'phoneExistsBody':
        '{phone} нөмірі бұрыннан тіркелген.\n\nОсы нөмірмен жүйеге кіріңіз.',
    'cancelShort': 'Болдырмау',
    'socialComingSoon': '{name} арқылы кіру жақында қосылады',
    'telegramConnecting': 'Қосылуда...',
    'telegramConnectingHint': 'Telegram ашылуда',
    'telegramWaitingTitle': 'Telegram күтілуде',
    'telegramWaitingHint': 'Telegram-да телефон нөміріңізді жіберіп, қолданбаға қайту батырмасын басыңыз',
    'telegramOpenAgain': 'Telegram-ды қайта ашу',
    'telegramRetry': 'Қайталап көру',
    'telegramBackToLogin': 'Кіруге қайту',
    'telegramSessionExpired': 'Уақыт бітті. Қайталап көріңіз.',
    'loginInfoPrefix': 'Бұрын аккаунт жасамаған болсаңыз ',
    'loginInfoAction': 'Аккаунт Жасаңыз',
    'loginInfoSuffix': ' деп басыңыз',
    'tapMapToSelect': 'Орынды таңдау үшін картаға басыңыз',
    'locationPermDenied': 'Орынға рұқсат жоқ. Параметрлерге өтіңіз.',
    'locationError': 'Орынды анықтауда қате орын алды',
    'tutorialStep1Title': 'Өнім қосыңыз',
    'tutorialStep1Desc': 'Өндірілетін өнім түрін енгізіңіз',
    'tutorialStep2Title': 'Шикізат қосыңыз',
    'tutorialStep2Desc': 'Рецепт үшін ингредиенттерді енгізіңіз',
    'tutorialStep3Title': 'Есеп жасаңыз',
    'tutorialStep3Desc': '1 өнімге шикізат мөлшерін енгізіңіз',
    'tutorialGoAction': 'Өту',
    'tutorialSkip': 'Өткізіп жіберу',
    'tutorialStep4Title': 'Шығымды жазыңыз',
    'tutorialStep4Desc': 'Бүгін қанша өнім шыққанын енгізіңіз',
    'tutorialGoSetup':    'Баптау түймесін басыңыз',
    'tutorialGoSetupSub': 'Өнімдер, шикізат және есептеуді баптаңыз',
    'tutorialTapAdd':     'Қосу түймесін басыңыз',
    'tutorialProductIncomeTitle': 'Өнім кірісі',
    'tutorialProductIncomeDesc':  'Бүгінгі өнім шығарылымын осы түйме арқылы тіркеңіз',
    'tutorialOpenCardTitle':      'Бөлімге өтіңіз',
    'tutorialOpenCardDesc':       'Осы картаны басып, тиісті параметрге кіріңіз',
    'tutorialSettingsHintTitle':   'Алдымен баптаңыз',
    'tutorialSettingsHintMessage': 'Өнімдер мен шикізатты қосыңыз — қолданба өзіндік құн мен пайданы өзі есептейді.',
    'createBusiness': 'Бизнес жасау',
    'businessTypeStep': 'Санат',
    'businessDetailsStep': 'Деректер',
    'businessLocationStep': 'Орналасу',
    'selectBusinessType': 'Бизнес түрін таңдаңыз',
    'selectBusinessTypeDesc': 'Өзіңізге сәйкес санатты таңдаңыз',
    'businessDetailsTitle': 'Бизнес туралы',
    'businessDetailsDesc': 'Бизнесіңіздің негізгі деректерін енгізіңіз',
    'businessName': 'Бизнес атауы',
    'businessDescHint': 'Қысқаша сипаттама (міндетті емес)',
    'description': 'Сипаттама',
    'address': 'Мекенжай',
    'businessLocationTitle': 'Орналасу',
    'businessLocationDesc': 'GPS арқылы орнын сақтаңыз немесе мекенжайды қолмен енгізіңіз',
    'useGpsLocation': 'GPS арқылы анықтау',
    'fetchingLocation': 'Орналасу анықталуда...',
    'locationSaved': 'Орналасу сақталды',
    'orManualAddress': 'немесе қолмен енгізіңіз',
    'addressHint': 'Мысалы: Ташкент қ., Амир Темур к., 1',
    'locationOptionalNote': 'Орналасу міндетті емес. Кейінірек қосуға болады.',
    'businessCreated': 'Бизнес жасалды! 🎉',
    'businessCreatedDesc': '{name} сәтті жасалды.',
    'startWorking': 'Жұмысты бастау',
    'fieldRequired': 'Бұл өріс міндетті',
    'continueWizard': 'Жалғастыру',
    'customBusinessTypeInfo':
        'Бизнес түріңізді жазыңыз — біз ескереміз',
    'customBusinessTypeHint': 'Мысалы: Пісірімдер, Лимонад...',
    'businessNameHint': 'Мысалы: Орталық наубайхана',
    'businessNameRequired': 'Бизнес атауын енгізіңіз',
    'businessNameMinLength': 'Кемінде 2 таңба',
    'selectCurrency': 'Валюта',
    'selectCurrencyDesc':
        'Есептер мен бағалар үшін валюта',
    'gpsAutoDetectSubtitle':
        'Ағымдағы орныңызды автоматты анықтау',
    'orDivider': 'немесе',
    'manualAddressLabel': 'Мекенжайды қолмен енгізіңіз',
    'createBusinessSubmit': 'Бизнес жасау',
  };

  static const _ky = {
    'hello': 'Салам',
    'defaultUser': 'Колдонуучу',
    'bakery': 'Бизнес',
    'bakeries': 'Бизнестер',
    'selectBusiness': 'Бизнес тандаңыз',
    'selectBusinessSubtitle': 'Башкаргыңыз келген бизнести тандаңыз',
    'noBusiness': 'Азырынча бизнес жок',
    'createFirstBusiness': 'Биринчи бизнесиңизди жасаңыз\nжана башкарууну баштаңыз',
    'addBusiness': 'Жаңы бизнес кошуу',
    'shopSettingsTitle': 'Бизнес жөндөөлөрү',
    'shopNameLabel': 'Бизнес аталышы',
    'shopNameHint': 'Мисалы: Нан дүкөнүм',
    'shopAddressLabel': 'Дарек',
    'shopAddressHint': 'Мисалы: Ташкент, Чиланзар',
    'shopUpdateSuccess': 'Бизнес жаңыланды',
    'shopDeleteButton': 'Бизнести жок кылуу',
    'shopDeleteTitle': 'Бизнести жок кылуу',
    'shopDeleteMessage': '«{name}» бизнесин жок кылгыңыз келеби? Бул аракетти кайтаруу мүмкүн эмес.',
    'shopDeleteSuccess': 'Бизнес жок кылынды',
    'manage': 'Башкаруу',
    'todayProfit': 'Бүгүнкү пайда',
    'todayLoss': 'Бүгүнкү зыян',
    'netRevenue': 'Түшүм (кайтаруудан кийин)',
    'expense': 'Чыгым',
    'baked': 'Бышырылган',
    'sack': 'Кап',
    'sold': 'Сатылган',
    'returned': 'Кайтарылган',
    'pcs': 'даана',
    'sacks': 'кап',
    'noBreadToday': 'Бүгүн нан бышырылган жок',
    'income': 'Киреше',
    'profit': 'Пайда',
    'productOut': 'Продукция чыгарылды',
    'productReturned': 'Продукция кайтарылды',
    'dashboardKpiOutput': 'Өнүм чыгымы',
    'dashboardKpiBatch': 'Топтом',
    'dashboardKpiSold': 'Сатылган',
    'dashboardKpiReturned': 'Кайтарылган',
    'dashboardEmptyOutput': 'Чыгым жазылган эмес',
    'dashboardSectionOutput': 'Бүгүнкү чыгымдар',
    'dashboardTabOutput': 'Продукт чыгымы',
    'dashboardTabExpense': 'Сырткы чыгым',
    'dashboardEmptyExpense': 'Чыгым жазылган эмес',
    'dashboardBatchUnitGeneric': 'партия',
    'currency': 'сом',
    'home': 'Башкы',
    'cashRegister': 'Тышкы чыгаша',
    'statistics': 'Статистика',
    'orders': 'Буйрутмалар',
    'ordersComingSoon': 'Жакында',
    'ordersComingSoonDesc': 'Буйрутмалар бөлүмү иштелүүдө.\nЖакын арада даяр болот!',
    'charts': 'Графиктер',
    'chartsScreenTitle': 'Толук графиктер',
    'chartRevenue': 'Киреше бөлүнүшү',
    'chartProduction': 'Өндүрүш',
    'chartExpenses': 'Чыгым бөлүнүшү',
    'chartProfitTrend': 'Пайда тренди',
    'reportScreenTitle': 'Отчёт',
    'reportPickRange': 'Аралык',
    'reportPickSingleDate': 'Күн',
    'reportChipToday': 'Бүгүн',
    'reportChipYesterday': 'Кечээ',
    'reportRangeLast7': '7 күн',
    'reportRangeLast30': '30 күн',
    'reportSectionSummary': 'Жалпы көрсөткүчтөр',
    'reportSectionReturnsByType': 'Кайтаруулар (түрү боюнча)',
    'reportSectionProducts': 'Өнүм боюнча',
    'reportGrossRevenue': 'Түшүм (кайтаруудан мурун)',
    'reportReturnsRecords': 'жазуу',
    'reportProductionRecords': 'Чыгым жазмалары',
    'reportEmptyReturns': 'Бул мезгилде кайтаруу жок',
    'reportEmptyProducts': 'Өнүм боюнча маалымат жок',
    'reportProductProduced': 'Чыгарылган',
    'reportExpandTypesCount': '{n} түр',
    'reportExpandProductsCount': '{n} өнүм',
    'profileTab': 'Профиль',
    'navHistory': 'Тарых',
    'historyTitle': 'Тарых',
    'historyTabCreated': 'Жаратылган',
    'historyTabReturns': 'Кайтарылган',
    'historyTabCash': 'Чыгашалар',
    'historyTotalReturns': 'Жалпы кайтарылган',
    'historyCreatedEmpty': 'Азырынча өнүм чыгымы жок',
    'historyReturnsEmpty': 'Азырынча кайтаруу жок',
    'returnDetailTitle': 'Кайтаруу',
    'noExpenseToday': 'Бүгүн чыгым жазылган жок',
    'addExpense': 'Чыгым',
    'expenseCreateTitle': 'Чыгым кошуу',
    'expenseCreateSubtitle': 'Түрүн тандаңыз, сумманы киргизиңиз.',
    'expenseCategorySearchHint': 'Издөө',
    'expenseAddCategory': 'Жаңы категория',
    'expenseAddCategoryTitle': 'Өзүңүз үчүн',
    'expenseAddCategoryNameHint': 'Мисалы: жарнама',
    'expenseAddCategorySave': 'Сактоо',
    'expenseSelectCategory': 'Түрү',
    'expenseAmountLabel': 'Сумма',
    'expenseDescriptionLabel': 'Эскертүү (милдеттүү эмес)',
    'expenseSubmit': 'Сактоо',
    'expenseCategoriesEmpty': 'Табылган жок',
    'expenseCategoriesLoadError': 'Жүктөлбөй калды',
    'daily': 'Күндүк',
    'weekly': 'Жумалык',
    'monthly': 'Айлык',
    'loss': 'Зыян',
    'noData': 'Маалымат жок',
    'production': 'Өндүрүш',
    'flourUsage': 'Ун чыгымы',
    'bakedBread': 'Бышырылган нан',
    'ingredients': 'Ингредиенттер',
    'salesAndReturns': 'Сатуу жана кайтаруу',
    'totalProduced': 'Жалпы өндүрүлгөн',
    'returns': 'Кайтаруу',
    'soldAuto': 'Сатылган (авто)',
    'returnAmount': 'Кайтаруу суммасы',
    'netIncome': 'Таза киреше',
    'expenses': 'Чыгымдар',
    'internalIngredients': 'Ички чыгымдар',
    'external': 'Тышкы',
    'total': 'Бардыгы',
    'settings': 'Жөндөөлөр',
    'breadTypes': 'Өнүм түрлөрү',
    'breadTypesDesc':
        'Сатылган өнүм же кызмат түрлөрү — ар бирине баа',
    'products': 'Продукттар',
    'productsDesc': 'Ун, суу, туз, ачыткы, май...',
    'recipes': 'Рецепттер',
    'recipesDesc': 'Нан үчүн курамы жана өлчөмү',
    'settingsCardTypesTitle': 'Өнүм түрлөрүңүз',
    'settingsCardIngredientsTitle': 'Чийки зат',
    'settingsCardRecipesTitle': 'Эсептөө системасы',
    'settingsTypesDesc_default':
        'Сатылган өнүм жана кызмат түрлөрүн кошуңуз, бааларды башкарыңыз.',
    'settingsTypesDesc_bakery':
        'Мисалы: патир, самса, лаваш, тандыр... Ар бир түр үчүн өзүнчө баа.',
    'settingsTypesDesc_grill':
        'Мисалы: шашлык, люля, рулет... Ар бир позиция үчүн өзүнчө баа.',
    'settingsTypesDesc_restaurant':
        'Мисалы: тамактар, гарнирлер, суусундуктар... Меню боюнча тартиптеңиз.',
    'settingsIngredientsDesc_default':
        'Ингредиенттер жана чийки заттарды баасы жана өлчөмү менен киргизиңиз.',
    'settingsIngredientsDesc_bakery':
        'Ун, суу, туз, ачыткы, май — ар биринин баасы жана өлчөмү.',
    'settingsIngredientsDesc_grill':
        'Эт, татымалдар, май — ар биринин баасы жана өлчөмү.',
    'settingsIngredientsDesc_restaurant':
        'Өнүм жана ингредиенттер — кампа жана өзүнүн баасы менен байланышыңыз.',
    'settingsRecipesDesc_default':
        'Рецепттер жана өзүнүн баасы — ар бир өнүм үчүн маржа жана пайда.',
    'settingsRecipesDesc_bakery':
        'Ар бир өнүм үчүн ингредиенттер катышы жана өзүнүн баасы — пайда анык.',
    'settingsRecipesDesc_grill':
        'Ар бир тамак үчүн грамм жана өзүнүн баасы — баа жана пайда эсеби.',
    'settingsRecipesDesc_restaurant':
        'Тамак жана суусундуктар үчүн өзүнүн баасы жана сатуу — отчёттор автоматтык.',
    'setupJourneyTitle': 'Орнотуу тартиби',
    'setupJourneyHint':
        'Алды менен сатылган өнүм түрүн түзүңүз, андан кийин чийки зат жана бааларды киргизиңиз, акырында рецепт аркылуу эсептөөнү жөндөңүз — ошондо өзүнүн баасы жана пайда так болот.',
    'setupJourneyStepLabel1': 'Өнүм',
    'setupJourneyStepLabel2': 'Чийки зат',
    'setupJourneyStepLabel3': 'Эсептөө',
    'setupJourneyAllDone': 'Бардык кадамдар аткарылды',
    'settingsCardCompleted': 'Аткарылды',
    'recipeScreenTitle': 'Рецепттер',
    'recipeEmptyTitle': 'Азырынча рецепттер жок',
    'recipeEmptySubtitle':
        'Өнүм түрлөрү үчүн рецепт кошуңуз — өндүрүш эсеби так болот.',
    'recipeAddCta': 'Рецепт кошуу',
    'recipeDeletedSnackbar': 'Рецепт өчүрүлдү',
    'recipeErrorSnackbar': 'Ката кетти',
    'recipeCreateTitle': 'Жаңы рецепт',
    'recipeStepProduct': 'Өнүм',
    'recipeStepBatch': 'Партия',
    'recipeStepIngredients': 'Курамы',
    'recipeSelectProductTitle': 'Кайсы өнүм үчүн?',
    'recipeSelectProductSubtitle':
        'Бир түрдү тандаңыз — ар бир түр үчүн бир рецепт.',
    'recipeAlreadyExists': 'Рецепт бар',
    'recipeBatchCarouselTitle': 'Партия бирдиги',
    'recipeBatchCarouselSubtitle':
        'Өндүрүштө кантип эсептейсиз: кап, блок, топтом...',
    'recipeOutputLabel': 'Өнүм саны',
    'recipeOutputHint': 'Мисалы: 100',
    'recipeOutputSectionTitle': 'Өнүм саны',
    'recipeOutputSectionHelper':
        '1 партиядан канча өнүм чыгат?',
    'recipeIngredientsSectionTitle': 'Бир партия үчүн чийки зат өлчөмү',
    'recipeOutputLabelDynamic': '1 {unit}тан канча өнүм чыгат?',
    'recipeIngredientsSectionTitleDynamic':
        '1 {unit} үчүн чийки зат өлчөмү',
    'recipeIngredientsSectionSubtitleDynamic':
        '1 {unit}га канча чийки зат кетерин көрсөтүңүз.',
    'recipeIngredientsSectionSubtitle':
        'Тандалган бирдикте бир партияга кеткен көлөмдөрдү киргизиңиз.',
    'recipeAddIngredient': 'Кошуу',
    'recipeCreateNewIngredientDivider': 'ЖЕ',
    'recipeCreateNewIngredient': 'Жаңы чийки зат кошуу',
    'recipeCreateNewIngredientShort': 'Жаңы',
    'recipeCreateNewIngredientHint':
        'Тизимде болбосо — ушул жерден кошуп коюңуз',
    'recipeValidationSelectProduct': 'Өнүм түрүн тандаңыз',
    'recipeValidationBatch': 'Партия бирдигин тандаңыз',
    'recipeValidationOutput': 'Чыгым санын киргизиңиз',
    'recipeValidationIngredients': 'Эң аз бир чийки зат кошуңуз',
    'recipeValidationDuplicateIngredient':
        'Ошол эле ингредиент эки жолу кошулган',
    'recipeSaveSuccess': 'Рецепт сакталды',
    'recipeRecipeBatchLine': '1 {unit} → {qty} даана',
    'recipeBack': 'Артка',
    'recipeIngredientSelectHint': 'Чийки зат',
    'recipeCardStatTitleOutput': 'Чыгым',
    'recipeCardStatTitleBatchCost': 'Партия өзүнүн баасы',
    'recipeCardStatTitleUnitCost': '1 даана өзүнүн баасы',
    'recipeCardSectionIngredients': 'Курамы',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Рецептти өчүрүү?',
    'recipeDeleteConfirmBody':
        '«{name}» рецепти өчүрүлөт. Бул аракетти кайтаруу мүмкүн эмес.',
    'recipeCardTooltipOutput':
        'Бир партиядан чыккан өнүм саны.',
    'recipeCardTooltipBatchCost':
        'Бир партия үчүн чийки заттын өзүнүн баасы (жалпы).',
    'recipeCardTooltipUnitCost':
        'Бир өнүм бирдигинин өзүнүн баасы (жалпы ÷ чыгым).',
    'productionDetailTitle': 'Партия толук маалымат',
    'productionDetailSummary': 'Бүгүн жабылган партия',
    'productionDetailBatch': 'Партия саны',
    'productionDetailOutput': 'Чыгым',
    'productionDetailFlour': 'Ун чыгымы',
    'productionDetailIngredientCost': 'Чийки зат баасы',
    'productionDetailSalesEstimate': 'Болжолдуу түшүм',
    'productionDetailBreakdown': 'Ингредиенттер боюнча',
    'productionDetailOneRecipeBatch': '1 партия (рецепт)',
    'productionDetailQtyTotal': 'Жалпы көлөм',
    'productionDetailGrams': '{g} г',
    'productionDetailPricePerUnit': 'Бирдик баасы',
    'productionDetailNoIngredients':
        'Рецепт ингредиенттери жок же жүктөлбөдү.',
    'productionDetailReturnToday': 'Бүгүнкү кайтаруу (бул түр боюнча)',
    'productionDetailEdit': 'Оңдоо',
    'productionDetailEditSheetTitle': 'Партия жана кайтаруулар',
    'productionDetailEditBatchLabel': 'Бүгүнкү партия саны',
    'productionDetailEditReturnsTitle': 'Бул түр боюнча кайтаруулар (бүгүн)',
    'productionDetailEditNoReturns': 'Бүгүн бул түр боюнча кайтаруу жок',
    'productionDetailEditSaveBatch': 'Партияны сактоо',
    'productionDetailBatchUpdated': 'Партия жаңыланды',
    'productionDetailReturnDeleted': 'Кайтаруу өчүрүлдү',
    'productionDetailDeleteReturnTitle': 'Кайтарууну өчүрөсүзбү?',
    'productionDetailDeleteReturnBody':
        'Жазуу өчүрүлөт. Башкы бет жана суммалар жаңыланат.',
    'productionDetailDeleteProductionTitle': 'Чыгымды өчүрүү?',
    'productionDetailDeleteProductionBody':
        'Бул чыгым жазуусу өчүрүлөт. Ошол түр жана күнү боюнча башка партия калбаса, ошол күнгө жазылган бардык кайтаруулар да өчүрүлөт.',
    'productionDetailProductionDeleted': 'Чыгым өчүрүлдү',
    'productionOutTitle': 'Өнүм чыгымы',
    'productionOutStep1': 'Өнүм',
    'productionOutStep2': 'Топтом',
    'productionOutStep3': 'Жыйынтык',
    'productionOutStep1Title': 'Кайсы өнүм?',
    'productionOutStep1Subtitle':
        'Эсептөөгө байланган өнүм түрүн тандаңыз.',
    'productionOutCategoryLabel': 'Өнүм түрү',
    'productionOutCategoryHint': 'Тандаңыз',
    'productionOutNoRecipeWarning':
        'Бул түр үчүн рецепт жок. Алдын ала «Эсептөө» бөлүмүндө рецепт түзүңүз.',
    'productionOutStep2Title': 'Партия көлөмү',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Бөлүнгөн сандар (мисалы: 1.5).',
    'productionOutBatchFieldLabel': '{unit} көлөмү',
    'productionOutSummaryTitle': 'Эсеп',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Чыгым',
    'productionOutIngredientsPreview': 'Чийки зат чыгымы',
    'productionOutCta': 'Чыгымды каттоо',
    'productionOutSuccess': '{qty} {unit} чыгым катталды',
    'productionOutValidationSelectProduct': 'Өнүм түрүн тандаңыз',
    'productionOutValidationNoRecipe': 'Бул түр үчүн рецепт жок',
    'productionOutValidationBatch': 'Партия көлөмү 0дон чоң болсун',
    'productionOutStep3Title': 'Текшерүү жана сактоо',
    'productionOutStep3Subtitle': 'Туура болсо, сактаңыз.',
    'productionOutNext': 'Кийинки',
    'productionOutSearchHint': 'Өнүм издөө',
    'productionOutSearchEmpty': 'Эч нерсе табылган жок',
    'returnCreateTitle': 'Өнүм кайтарылды',
    'returnCreateSubtitle':
        'Кайтарылган түр жана көлөмдү киргизиңиз. Түр тандалганда сату баасы автоматтык чыгат.',
    'returnProfitInfoTitle': 'Пайда жана эсеп',
    'returnProfitInfoBody':
        'Кайтаруу катталганда күндөлүк сатуу, түшүм жана пайда көрсөткүчтөрү (башкы бет жана отчеттор) ошого ылайык жаңыланат — бул чыныгы каржылык абалды чагылдырат.',
    'returnProfitInfoShort':
        'Өнүм кайтаруусун киргизүү пайданы туура эсептөө үчүн маанилүү.',
    'returnProductionLabel': 'Партия (чыгым)',
    'returnNoProductionForCategory':
        'Бул түр боюнча бүгүн чыгым жазылган жок. Алды менен чыгым киргизиңиз.',
    'returnSearchHint': 'Өнүм издөө',
    'returnSearchEmpty': 'Эч нерсе табылган жок',
    'returnCategoryLabel': 'Өнүм түрү',
    'returnQuantityTitle': 'Кайтарылган көлөм',
    'returnQuantitySubtitle': 'Бүтүн сан (дана) киргизиңиз.',
    'returnPriceLabel': 'Бир дана баасы',
    'returnReasonLabel': 'Себеп (милдеттүү эмес)',
    'returnReasonHint': 'Мисалы: кардар, сапат',
    'returnCta': 'Кайтарууну каттоо',
    'returnValidationSelectProduct': 'Өнүм түрүн тандаңыз',
    'returnValidationQty': 'Көлөм 0дон чоң болсун',
    'returnValidationPrice': 'Бааны туура киргизиңиз',
    'returnSuccess': 'Кайтаруу катталды',
    'returnPieceSuffix': 'дана',
    'productCategoriesTitle': 'Өнүм түрлөрү',
    'productCategoriesEmptyTitle': 'Азырынча өнүм түрлөрү жок',
    'productCategoriesEmptySubtitle':
        'Сатылган өнүм же кызмат түрлөрүн кошуңуз',
    'addProductCategoryModalTitle': 'Жаңы түр',
    'addProductCategoryModalSubtitle': 'Ат жана сатуу баасын киргизиңиз',
    'productCategoriesNameLabel': 'Өнүм аты',
    'productCategoriesNameHint': 'Мисалы: лаваш, сет-меню',
    'sellingPriceLabel': 'Сатуу баасы',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Валюта',
    'productCategoriesAddCta': 'Түр кошуу',
    'snackbarFillAllFields': 'Бардык талааларды толтуруңуз',
    'snackbarErrorGeneric': 'Ката кетти',
    'apiClientTimeout': 'Байланыш убактысы бүттү',
    'apiClientNoConnection': 'Интернет байланышы жок',
    'apiClientUnexpected': 'Күтүлбөгөн ката',
    'apiInvalidResponseFormat': 'Күтүлбөгөн жооп форматы',
    'actionAdd': 'Кошуу',
    'actionSave': 'Сактоо',
    'editProductCategoryModalTitle': 'Түрдү оңдоо',
    'editIngredientModalTitle': 'Чийки затты оңдоо',
    'snackbarCategoryAdded': '{name} кошулду',
    'snackbarCategoryDeleted': '{name} өчүрүлдү',
    'snackbarCategoryUpdated': '{name} жаңыланды',
    'ingredientsEmptyTitle': 'Азырынча чийки зат жок',
    'ingredientsEmptySubtitle':
        'Рецепт жана өздүк баа үчүн ат, өлчөм бирдиги жана 1 бирдик баасын киргизиңиз.',
    'addIngredientModalTitle': 'Жаңы чийки зат',
    'addIngredientModalSubtitle':
        'Ат, бирдик жана баа. Валютаны баанын жанындагы баскыч менен тандаңыз.',
    'ingredientNameLabel': 'Аталышы',
    'ingredientNameHint': 'Мисалы: ун, суу, туз',
    'ingredientUnitFieldLabel': 'Өлчөм бирдиги',
    'ingredientPricePerUnitLabel': '1 бирдик баасы',
    'ingredientPricePerUnitLabelDynamic': '1 {unit} баасын жазыңыз',
    'ingredientUnit_kg': 'Килограмм (kg)',
    'ingredientUnit_gram': 'Грамм (g)',
    'ingredientUnit_litr': 'Литр (l)',
    'ingredientUnit_dona': 'Дана',
    'ingredientsAddCta': 'Чийки зат кошуу',
    'ingredientAddHeroTitle': 'Жаңы чийки зат',
    'ingredientPriceHintBanner':
        'Бааны тандалган бирдик боюнча толук киргизиңиз (мисалы, 1 кг, 1 л же 1 дана). Рецептте г же мл колдонсоңуз да, бул жерде жалпы баа сакталат.',
    'ingredientUnitChipsLabel': 'Өлчөм бирдиги',
    'snackbarIngredientAdded': '{name} кошулду',
    'snackbarIngredientDeleted': '{name} өчүрүлдү',
    'snackbarIngredientUpdated': '{name} жаңыланды',
    'ingredientPriceInfoTitle': 'Баа жөнүндө',
    'ingredientPriceInfoBody':
        'Чийки заттын баасын бирдикке карата киргизиңиз (1 кг, 1 дана же 1 л). Рецепттерде система грамм же мл өзү эсептейт.',
    'gotIt': 'Түшүнүктү',
    'general': 'Жалпы',
    'manageAndSwitch': 'Башкаруу жана алмаштыруу',
    'staff': 'Кызматкерлер',
    'staffManagement': 'Персоналды башкаруу',
    'darkMode': 'Түнкү режим',
    'enabled': 'Күйгүзүлгөн',
    'disabled': 'Өчүрүлгөн',
    'language': 'Тил',
    'aboutApp': 'Тиркеме жөнүндө',
    'aboutAppDescription': 'TAQSEEM — чакан жана орто өндүрүш бизнестеринин өздүк наркын, пайдасын жана чыгымдарын так эсептөө тиркемеси.',
    'developer': 'Иштеп чыгуучу',
    'website': 'Веб-сайт',
    'support': 'Колдоо',
    'assetImagesPreview': 'Сүрөттөр (көрүнүш)',
    'version': 'Версия',
    'logout': 'Тутумдан чыгуу',
    'unknown': 'Белгисиз',
    'balance': 'Негизги Баланс',
    'topUp': 'Толтуруу',
    'profileInfo': 'Профиль маалыматы',
    'profileInfoDesc': 'Телефон, почта жана Телеграм жөндөөлөрү',
    'phoneNumber': 'Телефон номери',
    'email': 'Эл. почта',
    'telegram': 'Телеграм',
    'linked': 'Байланган',
    'notLinked': 'Байланбаган',
    'link': 'Байлоо',
    'changePhoto': 'Сүрөттү өзгөртүү',
    'aboutTagline': 'Бизнесиңизди бир караштан башкарыңыз',
    'aboutWhyTitle': 'Эмне үчүн TAQSEEM?',
    'aboutWhyBody': 'TAQSEEM — чакан жана орто өндүрүш бизнеси үчүн заманбап башкаруу тутуму. Күнүмдүк өндүрүш, чыгашалар, кайтарымдар жана таза кирешени бир жерден реалдуу убакытта көрүңүз.',
    'aboutFeaturesTitle': 'Негизги мүмкүнчүлүктөр',
    'featProductionTitle': 'Өндүрүш эсеби',
    'featProductionDesc': 'Күнүмдүк көлөм жана өздүк нарк көзөмөлү.',
    'featExpensesTitle': 'Чыгаша башкаруусу',
    'featExpensesDesc': 'Бардык чыгашаларды категория боюнча көзөмөлдөңүз.',
    'featReturnsTitle': 'Кайтарымдар',
    'featReturnsDesc': 'Кайтарылгандар жана жоготууларды так эсептеңиз.',
    'featReportsTitle': 'Статистика жана отчёттор',
    'featReportsDesc': 'Күнүмдүк, жумалык, айлык графиктер жана аналитика.',
    'featMultiShopTitle': 'Бир нече чекит',
    'featMultiShopDesc': 'Бир нече чекитти бир аккаунттан башкарыңыз.',
    'featRecipesTitle': 'Рецепттер',
    'featRecipesDesc': 'Рецепт жана ингредиент наркын автоматтык эсептөө.',
    'featMultiLangTitle': 'Көп тилдүү',
    'featMultiLangDesc': '7 тилде: кыргыз, өзбек, орус, казак ж.б.',
    'featDarkModeTitle': 'Караңгы / жарык режим',
    'featDarkModeDesc': 'Көзгө жагымдуу түнкү жана күндүзгү режимдер.',
    'aboutContactTitle': 'Биз менен байланышыңыз',
    'aboutTelegramChannel': 'Telegram каналы',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Колдоо',
    'aboutWebsite': 'Веб-сайт',
    'personalInfo': 'Жеке маалымат',
    'pressBackAgainToExit': 'Чыгуу үчүн дагы бир жолу басыңыз',
    'editAction': 'Түзөтүү',
    'editExpense': 'Чыгашаны түзөтүү',
    'deleteExpense': 'Чыгашаны өчүрүү',
    'deleteExpenseConfirm': 'Бул чыгашаны өчүрүүнү тастыктайсызбы?',
    'expenseDeleted': 'Чыгаша өчүрүлдү',
    'expenseUpdated': 'Чыгаша жаңыртылды',
    'expenseDeleteFailed': 'Өчүрүүдө ката',
    'expenseUpdateFailed': 'Жаңыртууда ката',
    'undo': 'Кайтаруу',
    'loginMethods': 'Кирүү ыкмалары',
    'editName': 'Атты өзгөртүү',
    'editEmail': 'Email өзгөртүү',
    'profileUpdated': 'Маалымат жаңыртылды',
    'invalidEmail': 'Email туура эмес',
    'nameRequired': 'Ат керек',
    'readOnly': 'Өзгөртүү мүмкүн эмес',
    'takePhoto': 'Сүрөт тартуу',
    'chooseFromGallery': 'Галереядан тандоо',
    'removePhoto': 'Сүрөттү өчүрүү',
    'removePhotoConfirm': 'Профиль сүрөтүн өчүрөсүзбү?',
    'remove': 'Өчүрүү',
    'uploadingPhoto': 'Жүктөлүүдө...',
    'photoUpdated': 'Сүрөт жаңыртылды',
    'photoRemoved': 'Сүрөт өчүрүлдү',
    'photoUploadFailed': 'Сүрөттү жүктөө мүмкүн болгон жок',
    'businessOwner': 'Бизнес ээси',
    'seller': 'Сатуучу',
    'deleteAccount': 'Аккаунтту жок кылуу',
    'deleteAccountDesc': 'Аккаунтуңузду жок кылсаңыз, бардык дүкөндөрүңүз, эсептериңиз жана маалыматтарыңыз толугу менен жок кылынат.',
    'deleteAccountConfirm': 'Чынында эле аккаунтуңузду жок кылгыңыз келеби?',
    'cancel': 'Жокко чыгаруу',
    'delete': 'Жок кылуу',
    'privacyPolicy': 'Купуялуулук саясаты',
    'privacyPolicyDesc': 'Жеке маалыматтарды коргоо',
    'termsOfService': 'Колдонуу шарттары',
    'termsOfServiceDesc': 'Кызмат көрсөтүү эрежелери',
    'account': 'Аккаунт',
    'logoutDesc': 'Аккаунттан чыгуу',
    'logoutConfirm': 'Системадан чыккыңыз келеби?',
    'madeInUzbekistan': 'Өзбекстанда жасалган',
    'topUpComingSoonTitle': 'Жакында иштей баштайт',
    'topUpComingSoonDesc': 'Балансты толтуруу бөлүмү иштеп чыгууда. Жакында тиркемеден толук пайдалана аласыз.',
    'goBack': 'Артка кайтуу',
    'onboardingTitle1': 'Каалаган бизнес үчүн',
    'onboardingDesc1': 'Нан цехи, шашлыкхана, самсахана, кондитердик, фастфуд — баарын бир жерден башкарыңыз',
    'onboardingTitle2': 'Баа жана пайда эсеби',
    'onboardingDesc2': 'Ар бир продуктун өздүк баасын так эсептеп, чыныгы пайданы билиңиз',
    'onboardingTitle3': 'Бизнесиңиз көзөмөлдө',
    'onboardingDesc3': 'Сатуу, чыгым жана өндүрүштү реалдуу убакытта көзөмөлдөңүз',
    'skip': 'Өткөрүп жиберүү',
    'next': 'Кийинки',
    'getStarted': 'Баштоо',
    'welcomeBack': 'Кош келиңиз!',
    'loginSubtitle': 'Улантуу үчүн тутумга кириңиз',
    'password': 'Сыр сөз',
    'enterPhone': 'Телефонду киргизиңиз',
    'enterPassword': 'Сыр сөздү киргизиңиз',
    'loginButton': 'Кирүү',
    'noAccount': 'Аккаунт жокпу?',
    'registerLink': 'Катталыңыз',
    'tryAgain': 'Кайра аракет',
    'noInternet': 'Интернет туташуусунда ката',
    'appTagline': 'Кичи бизнес үчүн акылдуу тутум',
    'firstTimeHint': 'Биринчи жолу кирип жатасызбы? Алгач ',
    'createNewAccount': 'жаңы аккаунт түзүңүз',
    'registerTitle': 'Катталуу',
    'registerSubtitle': 'Бардык маалыматтарды киргизиңиз',
    'fullNameHint': 'Аты-жөнү',
    'enterName': 'Атыңызды киргизиңиз',
    'confirmPasswordHint': 'Сыр сөздү ырастаңыз',
    'passwordsNotMatch': 'Сыр сөздөр дал келбейт',
    'otpTitle': 'Кодду киргизиңиз',
    'otpSentTo': '4 орундуу ырастоо коду\n{phone}\nномерине жөнөтүлдү.',
    'resendCode': 'Кодду кайра жөнөтүү',
    'resendIn': 'Кайра жөнөтүү: {time}',
    'codeNotReceived': 'Код келбедиби?',
    'smsHelpTitle': 'SMS код келбедиби?',
    'smsHelpCauses': 'Жалпы себептер:',
    'smsSpamTitle': 'Spam папкасы',
    'smsSpamBody':
        'SMS бөлүмүндөгү «Spam» же «Керексиз» папкасын текшериңиз. Биздин SMS 4546 номерден келет.',
    'smsBalanceTitle': 'Uzmobile балансы',
    'smsBalanceBody':
        'Uzmobile операторунда баланс болбосо SIM карта SMS кабыл албашы мүмкүн.',
    'understood': 'Түшүндүм',
    'policyLoginPrefix': 'Кирүү менен ',
    'policyRegisterPrefix': 'Катталуу менен ',
    'policyAnd': ' жана ',
    'policySuffix': ' саясатын кабыл аласыз',
    'policyTerms': 'Шарттар',
    'policyPrivacy': 'Купуялык',
    'stepForm': 'Маалыматтар',
    'stepVerify': 'Ырастоо',
    'stepEnterApp': 'Колдонмого\nкирүү',
    'phoneExistsTitle': 'Номер катталган',
    'phoneExistsBody':
        '{phone} номери мурунтан катталган.\n\nОшол номер менен тутумга кириңиз.',
    'cancelShort': 'Жокко чыгаруу',
    'socialComingSoon': '{name} аркылуу кирүү жакында кошулат',
    'telegramConnecting': 'Туташууда...',
    'telegramConnectingHint': 'Telegram ачылууда',
    'telegramWaitingTitle': 'Telegram күтүлүүдө',
    'telegramWaitingHint': 'Telegram-да телефон номериңизди жөнөтүп, колдонмого кайтуу баскычын басыңыз',
    'telegramOpenAgain': 'Telegram-ды кайра ачуу',
    'telegramRetry': 'Кайра аракет кылуу',
    'telegramBackToLogin': 'Кирүүгө кайтуу',
    'telegramSessionExpired': 'Убакыт бүттү. Кайра аракет кылыңыз.',
    'loginInfoPrefix': 'Мурда аккаунт жасабаган болсоңуз ',
    'loginInfoAction': 'Аккаунт Жасаңыз',
    'loginInfoSuffix': ' деп басыңыз',
    'tapMapToSelect': 'Жайгашуу тандоо үчүн картага басыңыз',
    'locationPermDenied': 'Жайгашууга уруксат берилген эмес. Жөндөөлөргө өтүңүз.',
    'locationError': 'Жайгашууну аныктоодо ката чыкты',
    'tutorialStep1Title': 'Продукт кошуңуз',
    'tutorialStep1Desc': 'Өндүрүлүүчү продукт түрүн киргизиңиз',
    'tutorialStep2Title': 'Чийки зат кошуңуз',
    'tutorialStep2Desc': 'Рецепт үчүн ингредиенттерди киргизиңиз',
    'tutorialStep3Title': 'Эсеп жасаңыз',
    'tutorialStep3Desc': '1 продуктка чийки зат өлчөмүн киргизиңиз',
    'tutorialGoAction': 'Өтүү',
    'tutorialSkip': 'Өткөрүп жибер',
    'tutorialStep4Title': 'Чыгымды жазыңыз',
    'tutorialStep4Desc': 'Бүгүн канча продукт чыкканын киргизиңиз',
    'tutorialGoSetup':    'Жөндөөлөр баскычын басыңыз',
    'tutorialGoSetupSub': 'Продукт, чийки зат жана эсепти жөндөңүз',
    'tutorialTapAdd':     'Кошуу баскычын басыңыз',
    'tutorialProductIncomeTitle': 'Продукт кирими',
    'tutorialProductIncomeDesc':  'Бүгүнкү продукт чыгарылышын ушул баскыч аркылуу каттаңыз',
    'tutorialOpenCardTitle':      'Бөлүмгө өтүңүз',
    'tutorialOpenCardDesc':       'Бул картаны басып, тиешелүү жөндөөгө кириңиз',
    'tutorialSettingsHintTitle':   'Адегенде жөндөңүз',
    'tutorialSettingsHintMessage': 'Продукт жана чийки затты кошуңуз — тиркеме өздүк нарк жана кирешени өзү эсептейт.',
    'createBusiness': 'Бизнес түзүү',
    'businessTypeStep': 'Категория',
    'businessDetailsStep': 'Маалыматтар',
    'businessLocationStep': 'Жайгашуу',
    'selectBusinessType': 'Бизнес түрүн тандаңыз',
    'selectBusinessTypeDesc': 'Өзүңүзгө ылайык категорияны тандаңыз',
    'businessDetailsTitle': 'Бизнес жөнүндө',
    'businessDetailsDesc': 'Бизнесиңиздин негизги маалыматтарын киргизиңиз',
    'businessName': 'Бизнес аты',
    'businessDescHint': 'Кыскача сыпаттама (милдеттүү эмес)',
    'description': 'Сыпаттама',
    'address': 'Дарек',
    'businessLocationTitle': 'Жайгашуу',
    'businessLocationDesc': 'GPS аркылуу жайгашуун сактаңыз же даректи кол менен киргизиңиз',
    'useGpsLocation': 'GPS аркылуу аныктоо',
    'fetchingLocation': 'Жайгашуу аныкталууда...',
    'locationSaved': 'Жайгашуу сакталды',
    'orManualAddress': 'же кол менен киргизиңиз',
    'addressHint': 'Мисалы: Ташкент ш., Амир Темур көч., 1',
    'locationOptionalNote': 'Жайгашуу милдеттүү эмес. Кийинчерек кошсо болот.',
    'businessCreated': 'Бизнес түзүлдү! 🎉',
    'businessCreatedDesc': '{name} ийгиликтүү түзүлдү.',
    'startWorking': 'Иштеп баштоо',
    'fieldRequired': 'Бул талаа милдеттүү',
    'continueWizard': 'Улантуу',
    'customBusinessTypeInfo':
        'Бизнес түрүңүздү жазыңыз — биз эске алабыз',
    'customBusinessTypeHint': 'Мисалы: Пишириктер, Лимонад...',
    'businessNameHint': 'Мисалы: Борбордук наан цехи',
    'businessNameRequired': 'Бизнес атын киргизиңиз',
    'businessNameMinLength': 'Эң аз 2 символ',
    'selectCurrency': 'Валюта',
    'selectCurrencyDesc':
        'Отчёттор жана баалар үчүн валюта',
    'gpsAutoDetectSubtitle':
        'Учурдагы жайгашуунузду автоматтык аныктоо',
    'orDivider': 'же',
    'manualAddressLabel': 'Даректи кол менен киргизиңиз',
    'createBusinessSubmit': 'Бизнес түзүү',
  };

  static const _tr = {
    'hello': 'Merhaba',
    'defaultUser': 'Kullanıcı',
    'bakery': 'İşletme',
    'bakeries': 'İşletmeler',
    'selectBusiness': 'İşletme seçin',
    'selectBusinessSubtitle': 'Yönetmek istediğiniz işletmeyi seçin',
    'noBusiness': 'Henüz işletme yok',
    'createFirstBusiness': 'İlk işletmenizi oluşturun\nve yönetmeye başlayın',
    'addBusiness': 'Yeni işletme ekle',
    'shopSettingsTitle': 'İşletme ayarları',
    'shopNameLabel': 'İşletme adı',
    'shopNameHint': 'Örn: Fırınım',
    'shopAddressLabel': 'Adres',
    'shopAddressHint': 'Örn: Taşkent, Çilanzar',
    'shopUpdateSuccess': 'İşletme güncellendi',
    'shopDeleteButton': 'İşletmeyi sil',
    'shopDeleteTitle': 'İşletmeyi sil',
    'shopDeleteMessage': '«{name}» işletmesini silmek istiyor musunuz? Bu işlem geri alınamaz.',
    'shopDeleteSuccess': 'İşletme silindi',
    'manage': 'Yönet',
    'todayProfit': 'Bugünkü kâr',
    'todayLoss': 'Bugünkü zarar',
    'netRevenue': 'Gelir (iadeden sonra)',
    'expense': 'Gider',
    'baked': 'Pişirilen',
    'sack': 'Çuval',
    'sold': 'Satılan',
    'returned': 'İade edildi',
    'pcs': 'adet',
    'sacks': 'çuval',
    'noBreadToday': 'Bugün henüz ekmek pişirilmedi',
    'income': 'Gelir',
    'profit': 'Kâr',
    'productOut': 'Ürün çıktı',
    'productReturned': 'Ürün iadesi',
    'dashboardKpiOutput': 'Ürün çıkışı',
    'dashboardKpiBatch': 'Toplam',
    'dashboardKpiSold': 'Satılan',
    'dashboardKpiReturned': 'İade',
    'dashboardEmptyOutput': 'Çıkış kaydı yok',
    'dashboardSectionOutput': 'Bugünkü çıkışlar',
    'dashboardTabOutput': 'Ürün çıkışı',
    'dashboardTabExpense': 'Dış giderler',
    'dashboardEmptyExpense': 'Gider kaydı yok',
    'dashboardBatchUnitGeneric': 'parti',
    'currency': 'som',
    'home': 'Ana sayfa',
    'cashRegister': 'Dış gider',
    'statistics': 'İstatistik',
    'orders': 'Siparişler',
    'ordersComingSoon': 'Yakında',
    'ordersComingSoonDesc': 'Siparişler bölümü geliştiriliyor.\nYakında hazır olacak!',
    'charts': 'Grafikler',
    'chartsScreenTitle': 'Detaylı grafikler',
    'chartRevenue': 'Gelir dağılımı',
    'chartProduction': 'Üretim',
    'chartExpenses': 'Gider dağılımı',
    'chartProfitTrend': 'Kâr trendi',
    'reportScreenTitle': 'Rapor',
    'reportPickRange': 'Aralık',
    'reportPickSingleDate': 'Tarih',
    'reportChipToday': 'Bugün',
    'reportChipYesterday': 'Dün',
    'reportRangeLast7': '7 gün',
    'reportRangeLast30': '30 gün',
    'reportSectionSummary': 'Özet',
    'reportSectionReturnsByType': 'İadeler (türe göre)',
    'reportSectionProducts': 'Ürüne göre',
    'reportGrossRevenue': 'Gelir (iadeden önce)',
    'reportReturnsRecords': 'kayıt',
    'reportProductionRecords': 'Çıkış kayıtları',
    'reportEmptyReturns': 'Bu dönemde iade yok',
    'reportEmptyProducts': 'Ürün verisi yok',
    'reportProductProduced': 'Üretilen',
    'reportExpandTypesCount': '{n} tür',
    'reportExpandProductsCount': '{n} ürün',
    'profileTab': 'Profil',
    'navHistory': 'Geçmiş',
    'historyTitle': 'Geçmiş',
    'historyTabCreated': 'Üretilen',
    'historyTabReturns': 'İadeler',
    'historyTabCash': 'Giderler',
    'historyTotalReturns': 'Toplam iadeler',
    'historyCreatedEmpty': 'Henüz ürün çıkışı yok',
    'historyReturnsEmpty': 'Henüz iade kaydı yok',
    'returnDetailTitle': 'İade detayı',
    'noExpenseToday': 'Bugün gider kaydedilmedi',
    'addExpense': 'Gider',
    'expenseCreateTitle': 'Gider ekle',
    'expenseCreateSubtitle': 'Türü seçin ve tutarı girin.',
    'expenseCategorySearchHint': 'Kategori ara',
    'expenseAddCategory': 'Yeni kategori',
    'expenseAddCategoryTitle': 'Kendi kategoriniz',
    'expenseAddCategoryNameHint': 'Örn: reklam',
    'expenseAddCategorySave': 'Kategoriyi kaydet',
    'expenseSelectCategory': 'Tür',
    'expenseAmountLabel': 'Tutar',
    'expenseDescriptionLabel': 'Açıklama (isteğe bağlı)',
    'expenseSubmit': 'Kaydet',
    'expenseCategoriesEmpty': 'Sonuç yok',
    'expenseCategoriesLoadError': 'Yüklenemedi',
    'daily': 'Günlük',
    'weekly': 'Haftalık',
    'monthly': 'Aylık',
    'loss': 'Zarar',
    'noData': 'Veri yok',
    'production': 'Üretim',
    'flourUsage': 'Un tüketimi',
    'bakedBread': 'Pişirilen ekmek',
    'ingredients': 'Malzemeler',
    'salesAndReturns': 'Satış ve iade',
    'totalProduced': 'Toplam üretilen',
    'returns': 'İade',
    'soldAuto': 'Satılan (oto)',
    'returnAmount': 'İade tutarı',
    'netIncome': 'Net gelir',
    'expenses': 'Giderler',
    'internalIngredients': 'İç giderler',
    'external': 'Dış',
    'total': 'Toplam',
    'settings': 'Ayarlar',
    'breadTypes': 'Ürün türleri',
    'breadTypesDesc':
        'Satılan ürün veya hizmet türleri — her biri için fiyat',
    'products': 'Ürünler',
    'productsDesc': 'Un, su, tuz, maya, yağ...',
    'recipes': 'Tarifler',
    'recipesDesc': 'Ekmek için malzeme ve miktarlar',
    'settingsCardTypesTitle': 'Ürün türleriniz',
    'settingsCardIngredientsTitle': 'Hammaddeler',
    'settingsCardRecipesTitle': 'Hesaplama sistemi',
    'settingsTypesDesc_default':
        'Satış ürün ve hizmet türlerini ekleyin, fiyatları yönetin.',
    'settingsTypesDesc_bakery':
        'Örneğin: patır, samsa, lavaş, tandır... Her tür için ayrı fiyat.',
    'settingsTypesDesc_grill':
        'Örneğin: şiş, köfte, rulo... Her kalem için ayrı fiyat.',
    'settingsTypesDesc_restaurant':
        'Örneğin: yemekler, garnitürler, içecekler... Menüye göre düzenleyin.',
    'settingsIngredientsDesc_default':
        'Malzemeleri fiyat ve birimle girin.',
    'settingsIngredientsDesc_bakery':
        'Un, su, tuz, maya, yağ — her biri için fiyat ve birim.',
    'settingsIngredientsDesc_grill':
        'Et, baharat, yağ — her biri için fiyat ve birim.',
    'settingsIngredientsDesc_restaurant':
        'Ürün ve malzemeler — depo ve maliyetle bağlayın.',
    'settingsRecipesDesc_default':
        'Tarifler ve maliyet — her ürün için marj ve kâr.',
    'settingsRecipesDesc_bakery':
        'Her ürün için oran ve maliyet — kâr net.',
    'settingsRecipesDesc_grill':
        'Her yemek için gram ve maliyet — fiyat ve kâr.',
    'settingsRecipesDesc_restaurant':
        'Yemek ve içecekler için maliyet ve satış — raporlar otomatik.',
    'setupJourneyTitle': 'Kurulum sırası',
    'setupJourneyHint':
        'Önce ürün türünü oluşturun, ardından hammaddeleri ve fiyatları girin, son olarak reçete ile hesaplamayı düzenleyin — böylece maliyet ve kâr net olur.',
    'setupJourneyStepLabel1': 'Ürün',
    'setupJourneyStepLabel2': 'Hammadde',
    'setupJourneyStepLabel3': 'Hesaplama',
    'setupJourneyAllDone': 'Tüm adımlar tamam',
    'settingsCardCompleted': 'Tamam',
    'recipeScreenTitle': 'Tarifler',
    'recipeEmptyTitle': 'Henüz tarif yok',
    'recipeEmptySubtitle':
        'Ürün türleri için tarif ekleyin — üretim hesabı net olsun.',
    'recipeAddCta': 'Tarif ekle',
    'recipeDeletedSnackbar': 'Tarif silindi',
    'recipeErrorSnackbar': 'Bir hata oluştu',
    'recipeCreateTitle': 'Yeni tarif',
    'recipeStepProduct': 'Ürün',
    'recipeStepBatch': 'Parti',
    'recipeStepIngredients': 'İçerik',
    'recipeSelectProductTitle': 'Hangi ürün için?',
    'recipeSelectProductSubtitle':
        'Tek tür seçin — her tür için bir tarif olur.',
    'recipeAlreadyExists': 'Tarif mevcut',
    'recipeBatchCarouselTitle': 'Parti birimi',
    'recipeBatchCarouselSubtitle':
        'Üretimde nasıl sayıyorsunuz: çuval, blok, set...',
    'recipeOutputLabel': 'Ürün adedi',
    'recipeOutputHint': 'Örn: 100',
    'recipeOutputSectionTitle': 'Ürün adedi',
    'recipeOutputSectionHelper':
        '1 partiden kaç ürün çıkar?',
    'recipeIngredientsSectionTitle': '1 parti için hammadde miktarı',
    'recipeOutputLabelDynamic': '1 {unit}dan ne kadar ürün çıkar?',
    'recipeIngredientsSectionTitleDynamic':
        '1 {unit} için hammadde miktarı',
    'recipeIngredientsSectionSubtitleDynamic':
        '1 {unit} için gereken her hammadde miktarını girin.',
    'recipeIngredientsSectionSubtitle':
        'Seçilen birimde tek partiye giren miktarları girin.',
    'recipeAddIngredient': 'Kalem ekle',
    'recipeCreateNewIngredientDivider': 'VEYA',
    'recipeCreateNewIngredient': 'Yeni hammadde oluştur',
    'recipeCreateNewIngredientShort': 'Yeni',
    'recipeCreateNewIngredientHint':
        'Listede yoksa doğrudan buradan ekleyin',
    'recipeValidationSelectProduct': 'Ürün türünü seçin',
    'recipeValidationBatch': 'Parti birimini seçin',
    'recipeValidationOutput': 'Çıkış miktarını girin',
    'recipeValidationIngredients': 'En az bir hammadde ekleyin',
    'recipeValidationDuplicateIngredient':
        'Aynı malzeme iki kez eklenmiş',
    'recipeSaveSuccess': 'Tarif kaydedildi',
    'recipeRecipeBatchLine': '1 {unit} → {qty} adet',
    'recipeBack': 'Geri',
    'recipeIngredientSelectHint': 'Hammadde',
    'recipeCardStatTitleOutput': 'Çıkış',
    'recipeCardStatTitleBatchCost': 'Parti maliyeti',
    'recipeCardStatTitleUnitCost': '1 adet maliyeti',
    'recipeCardSectionIngredients': 'İçerik',
    'recipeCardIngredientLine': '{name} · {qty} {unit}',
    'recipeDeleteConfirmTitle': 'Tarif silinsin mi?',
    'recipeDeleteConfirmBody':
        '«{name}» tarifi silinecek. Bu işlem geri alınamaz.',
    'recipeCardTooltipOutput':
        'Tek partide çıkan ürün adedi.',
    'recipeCardTooltipBatchCost':
        'Tek parti için hammadde maliyeti (toplam).',
    'recipeCardTooltipUnitCost':
        'Birim ürün maliyeti (toplam ÷ çıkış).',
    'productionDetailTitle': 'Parti detayı',
    'productionDetailSummary': 'Bugün kapanan parti',
    'productionDetailBatch': 'Parti sayısı',
    'productionDetailOutput': 'Çıkış',
    'productionDetailFlour': 'Kullanılan un',
    'productionDetailIngredientCost': 'Hammadde maliyeti',
    'productionDetailSalesEstimate': 'Tahmini gelir',
    'productionDetailBreakdown': 'Malzemelere göre',
    'productionDetailOneRecipeBatch': '1 parti (reçete)',
    'productionDetailQtyTotal': 'Toplam miktar',
    'productionDetailGrams': '{g} g',
    'productionDetailPricePerUnit': 'Birim fiyat',
    'productionDetailNoIngredients':
        'Reçete malzemeleri yok veya yüklenemedi.',
    'productionDetailReturnToday': 'Bugünkü iade (bu tür için)',
    'productionDetailEdit': 'Düzenle',
    'productionDetailEditSheetTitle': 'Parti ve iadeler',
    'productionDetailEditBatchLabel': 'Bugünkü parti sayısı',
    'productionDetailEditReturnsTitle': 'Bu türe ait iadeler (bugün)',
    'productionDetailEditNoReturns': 'Bugün bu tür için iade kaydı yok',
    'productionDetailEditSaveBatch': 'Partiyi kaydet',
    'productionDetailBatchUpdated': 'Parti güncellendi',
    'productionDetailReturnDeleted': 'İade silindi',
    'productionDetailDeleteReturnTitle': 'İade silinsin mi?',
    'productionDetailDeleteReturnBody':
        'Kayıt silinecek. Ana sayfa ve tutarlar güncellenir.',
    'productionDetailDeleteProductionTitle': 'Çıkışı sil?',
    'productionDetailDeleteProductionBody':
        'Bu çıkış kaydı silinir. Bu tür ve tarihte başka parti kalmazsa, o güne ait tüm iadeler de silinir.',
    'productionDetailProductionDeleted': 'Çıkış silindi',
    'productionOutTitle': 'Ürün çıkışı',
    'productionOutStep1': 'Ürün',
    'productionOutStep2': 'Toplam',
    'productionOutStep3': 'Onay',
    'productionOutStep1Title': 'Hangi ürün?',
    'productionOutStep1Subtitle':
        'Hesaplamaya bağlı ürün türünü seçin.',
    'productionOutCategoryLabel': 'Ürün türü',
    'productionOutCategoryHint': 'Seçin',
    'productionOutNoRecipeWarning':
        'Bu tür için tarif yok. Önce «Hesaplama» bölümünde tarif oluşturun.',
    'productionOutStep2Title': 'Parti miktarı',
    'productionOutStep2Subtitle':
        '1 {unit} = {qty} {productUnit}. Ondalıklar kullanılabilir (ör. 1.5).',
    'productionOutBatchFieldLabel': '{unit} miktarı',
    'productionOutSummaryTitle': 'Hesap',
    'productionOutTotalOutput': '{qty} {unit}',
    'productionOutCostLabel': 'Maliyet',
    'productionOutIngredientsPreview': 'Hammadde kullanımı',
    'productionOutCta': 'Çıkışı kaydet',
    'productionOutSuccess': '{qty} {unit} çıkış kaydedildi',
    'productionOutValidationSelectProduct': 'Ürün türünü seçin',
    'productionOutValidationNoRecipe': 'Bu tür için tarif yok',
    'productionOutValidationBatch': 'Parti miktarı 0\'dan büyük olsun',
    'productionOutStep3Title': 'Kontrol ve kayıt',
    'productionOutStep3Subtitle': 'Doğruysa kaydedin.',
    'productionOutNext': 'İleri',
    'productionOutSearchHint': 'Ürün ara',
    'productionOutSearchEmpty': 'Sonuç yok',
    'returnCreateTitle': 'Ürün iadesi',
    'returnCreateSubtitle':
        'İade türü ve miktarı girin. Tür seçildiğinde satış fiyatı otomatik gelir.',
    'returnProfitInfoTitle': 'Kâr ve hesap',
    'returnProfitInfoBody':
        'İade kaydedildiğinde günlük satış, gelir ve kâr göstergeleri (ana sayfa ve raporlar) buna göre güncellenir — gerçek finansal durumu yansıtır.',
    'returnProfitInfoShort':
        'İade girmek kârın doğru hesaplanması için önemlidir.',
    'returnProductionLabel': 'Parti (çıkış)',
    'returnNoProductionForCategory':
        'Bu tür için bugün çıkış yok. Önce çıkış girin.',
    'returnSearchHint': 'Ürün ara',
    'returnSearchEmpty': 'Sonuç yok',
    'returnCategoryLabel': 'Ürün türü',
    'returnQuantityTitle': 'İade miktarı',
    'returnQuantitySubtitle': 'Tam sayı (adet) girin.',
    'returnPriceLabel': 'Birim fiyat',
    'returnReasonLabel': 'Sebep (isteğe bağlı)',
    'returnReasonHint': 'Örn.: müşteri, kalite',
    'returnCta': 'İadeyi kaydet',
    'returnValidationSelectProduct': 'Ürün türünü seçin',
    'returnValidationQty': 'Miktar 0’dan büyük olmalı',
    'returnValidationPrice': 'Geçerli bir fiyat girin',
    'returnSuccess': 'İade kaydedildi',
    'returnPieceSuffix': 'adet',
    'productCategoriesTitle': 'Ürün türleri',
    'productCategoriesEmptyTitle': 'Henüz ürün türü yok',
    'productCategoriesEmptySubtitle':
        'Sattığınız ürün veya hizmet türlerini ekleyin',
    'addProductCategoryModalTitle': 'Yeni tür',
    'addProductCategoryModalSubtitle': 'Ad ve satış fiyatını girin',
    'productCategoriesNameLabel': 'Ürün adı',
    'productCategoriesNameHint': 'Örn: lavaş, set menü',
    'sellingPriceLabel': 'Satış fiyatı',
    'sellingPriceHint': '0',
    'currencyPickerLabel': 'Para birimi',
    'productCategoriesAddCta': 'Tür ekle',
    'snackbarFillAllFields': 'Lütfen tüm alanları doldurun',
    'snackbarErrorGeneric': 'Bir hata oluştu',
    'apiClientTimeout': 'Bağlantı zaman aşımı',
    'apiClientNoConnection': 'İnternet bağlantısı yok',
    'apiClientUnexpected': 'Beklenmeyen hata',
    'apiInvalidResponseFormat': 'Geçersiz yanıt formatı',
    'actionAdd': 'Ekle',
    'actionSave': 'Kaydet',
    'editProductCategoryModalTitle': 'Türü düzenle',
    'editIngredientModalTitle': 'Hammaddeyi düzenle',
    'snackbarCategoryAdded': '{name} eklendi',
    'snackbarCategoryDeleted': '{name} silindi',
    'snackbarCategoryUpdated': '{name} güncellendi',
    'ingredientsEmptyTitle': 'Henüz hammadde yok',
    'ingredientsEmptySubtitle':
        'Reçete ve maliyet için ad, birim ve birim fiyatını girin.',
    'addIngredientModalTitle': 'Yeni hammadde',
    'addIngredientModalSubtitle':
        'Ad, birim ve fiyat. Para birimini fiyatın yanındaki düğmeden seçin.',
    'ingredientNameLabel': 'Ad',
    'ingredientNameHint': 'Örn: un, su, tuz',
    'ingredientUnitFieldLabel': 'Ölçü birimi',
    'ingredientPricePerUnitLabel': '1 birim fiyatı',
    'ingredientPricePerUnitLabelDynamic': '1 {unit} fiyatını girin',
    'ingredientUnit_kg': 'Kilogram (kg)',
    'ingredientUnit_gram': 'Gram (g)',
    'ingredientUnit_litr': 'Litre (l)',
    'ingredientUnit_dona': 'Adet',
    'ingredientsAddCta': 'Hammadde ekle',
    'ingredientAddHeroTitle': 'Yeni hammadde',
    'ingredientPriceHintBanner':
        'Fiyatı seçilen birim için tam girin (ör. 1 kg, 1 L veya 1 adet). Reçetede g veya ml kullanılsa da burada toplam fiyat saklanır.',
    'ingredientUnitChipsLabel': 'Ölçü birimi',
    'snackbarIngredientAdded': '{name} eklendi',
    'snackbarIngredientDeleted': '{name} silindi',
    'snackbarIngredientUpdated': '{name} güncellendi',
    'ingredientPriceInfoTitle': 'Fiyat hakkında',
    'ingredientPriceInfoBody':
        'Hammadde fiyatını birim başına girin (1 kg, 1 adet veya 1 l). Tariflerde sistem gram veya ml’ye kendisi çevirir.',
    'gotIt': 'Anladım',
    'general': 'Genel',
    'manageAndSwitch': 'Yönetim ve değiştirme',
    'staff': 'Çalışanlar',
    'staffManagement': 'Personel yönetimi',
    'darkMode': 'Karanlık mod',
    'enabled': 'Açık',
    'disabled': 'Kapalı',
    'language': 'Dil',
    'aboutApp': 'Uygulama hakkında',
    'aboutAppDescription': 'TAQSEEM — küçük ve orta ölçekli üretim işletmeleri için maliyet, kâr ve giderleri doğru hesaplama uygulaması.',
    'developer': 'Geliştirici',
    'website': 'Web sitesi',
    'support': 'Destek',
    'assetImagesPreview': 'Görseller (önizleme)',
    'version': 'Sürüm',
    'logout': 'Çıkış yap',
    'unknown': 'Bilinmiyor',
    'balance': 'Ana Bakiye',
    'topUp': 'Yükle',
    'profileInfo': 'Profil bilgileri',
    'profileInfoDesc': 'Telefon, e-posta ve Telegram ayarları',
    'phoneNumber': 'Telefon numarası',
    'email': 'E-posta',
    'telegram': 'Telegram',
    'linked': 'Bağlı',
    'notLinked': 'Bağlı değil',
    'link': 'Bağla',
    'changePhoto': 'Fotoğrafı değiştir',
    'aboutTagline': 'İşinizi tek bakışta yönetin',
    'aboutWhyTitle': 'Neden TAQSEEM?',
    'aboutWhyBody': 'TAQSEEM — küçük ve orta ölçekli üretim işletmeleri için modern yönetim sistemi. Günlük üretim, gider, iadeler ve net kârı tek yerde, gerçek zamanlı görün.',
    'aboutFeaturesTitle': 'Temel özellikler',
    'featProductionTitle': 'Üretim takibi',
    'featProductionDesc': 'Günlük üretim miktarı ve maliyet kontrolü.',
    'featExpensesTitle': 'Gider yönetimi',
    'featExpensesDesc': 'Tüm giderleri kategorilere göre takip edin.',
    'featReturnsTitle': 'İadeler',
    'featReturnsDesc': 'İadelerin ve kayıpların hassas takibi.',
    'featReportsTitle': 'İstatistik ve raporlar',
    'featReportsDesc': 'Günlük, haftalık, aylık grafikler ve analitik.',
    'featMultiShopTitle': 'Çoklu şube',
    'featMultiShopDesc': 'Birden fazla şubeyi tek hesaptan yönetin.',
    'featRecipesTitle': 'Reçeteler',
    'featRecipesDesc': 'Reçete ve malzeme maliyetini otomatik hesaplayın.',
    'featMultiLangTitle': 'Çok dilli',
    'featMultiLangDesc': '7 dil: Türkçe, Özbekçe, Rusça, Kazakça ve diğerleri.',
    'featDarkModeTitle': 'Koyu / açık tema',
    'featDarkModeDesc': 'Göze rahat gece ve gündüz modları.',
    'aboutContactTitle': 'Bize ulaşın',
    'aboutTelegramChannel': 'Telegram kanalı',
    'aboutInstagram': 'Instagram',
    'aboutSupport': 'Destek',
    'aboutWebsite': 'Web sitesi',
    'personalInfo': 'Kişisel bilgiler',
    'pressBackAgainToExit': 'Çıkmak için tekrar basın',
    'editAction': 'Düzenle',
    'editExpense': 'Gideri düzenle',
    'deleteExpense': 'Gideri sil',
    'deleteExpenseConfirm': 'Bu gideri silmek istediğinize emin misiniz?',
    'expenseDeleted': 'Gider silindi',
    'expenseUpdated': 'Gider güncellendi',
    'expenseDeleteFailed': 'Silme başarısız',
    'expenseUpdateFailed': 'Güncelleme başarısız',
    'undo': 'Geri al',
    'loginMethods': 'Giriş yöntemleri',
    'editName': 'Adı düzenle',
    'editEmail': 'E-postayı düzenle',
    'profileUpdated': 'Bilgiler güncellendi',
    'invalidEmail': 'E-posta geçersiz',
    'nameRequired': 'Ad gerekli',
    'readOnly': 'Değiştirilemez',
    'takePhoto': 'Fotoğraf çek',
    'chooseFromGallery': 'Galeriden seç',
    'removePhoto': 'Fotoğrafı kaldır',
    'removePhotoConfirm': 'Profil fotoğrafı kaldırılsın mı?',
    'remove': 'Kaldır',
    'uploadingPhoto': 'Yükleniyor...',
    'photoUpdated': 'Fotoğraf güncellendi',
    'photoRemoved': 'Fotoğraf kaldırıldı',
    'photoUploadFailed': 'Fotoğraf yüklenemedi',
    'businessOwner': 'İşletme sahibi',
    'seller': 'Satıcı',
    'deleteAccount': 'Hesabı sil',
    'deleteAccountDesc': 'Hesabınızı silerseniz tüm mağazalarınız, raporlarınız ve verileriniz kalıcı olarak silinir.',
    'deleteAccountConfirm': 'Hesabınızı gerçekten silmek istiyor musunuz?',
    'cancel': 'İptal',
    'delete': 'Sil',
    'privacyPolicy': 'Gizlilik Politikası',
    'privacyPolicyDesc': 'Kişisel verilerin korunması',
    'termsOfService': 'Kullanım Koşulları',
    'termsOfServiceDesc': 'Hizmet şartları',
    'account': 'Hesap',
    'logoutDesc': 'Hesabınızdan çıkın',
    'logoutConfirm': 'Sistemden çıkmak istiyor musunuz?',
    'madeInUzbekistan': "Özbekistan'da üretildi",
    'topUpComingSoonTitle': 'Yakında kullanıma açılacak',
    'topUpComingSoonDesc': 'Bakiye yükleme bölümü üzerinde çalışılmaktadır. Yakında uygulamayı tam olarak kullanabileceksiniz.',
    'goBack': 'Geri dön',
    'onboardingTitle1': 'Her işletme için',
    'onboardingDesc1': 'Fırın, mangal evi, börekçi, pastane, fast food — hepsini tek yerden yönetin',
    'onboardingTitle2': 'Maliyet ve kâr hesabı',
    'onboardingDesc2': 'Her ürünün maliyetini doğru hesaplayın ve gerçek kârınızı öğrenin',
    'onboardingTitle3': 'İşletmeniz kontrol altında',
    'onboardingDesc3': 'Satış, gider ve üretimi gerçek zamanlı takip edin',
    'skip': 'Atla',
    'next': 'İleri',
    'getStarted': 'Başla',
    'welcomeBack': 'Hoş geldiniz!',
    'loginSubtitle': 'Devam etmek için giriş yapın',
    'password': 'Şifre',
    'enterPhone': 'Telefon girin',
    'enterPassword': 'Şifre girin',
    'loginButton': 'Giriş yap',
    'noAccount': 'Hesabınız yok mu?',
    'registerLink': 'Kayıt olun',
    'tryAgain': 'Tekrar dene',
    'noInternet': 'İnternet bağlantısında hata',
    'appTagline': 'Küçük işletmeler için akıllı sistem',
    'firstTimeHint': 'İlk kez mi giriyorsunuz? Önce ',
    'createNewAccount': 'yeni hesap oluşturun',
    'registerTitle': 'Kayıt ol',
    'registerSubtitle': 'Tüm bilgileri girin',
    'fullNameHint': 'Ad ve soyad',
    'enterName': 'Adınızı girin',
    'confirmPasswordHint': 'Şifreyi onaylayın',
    'passwordsNotMatch': 'Şifreler eşleşmiyor',
    'otpTitle': 'Kodu girin',
    'otpSentTo': '4 haneli doğrulama kodu\n{phone}\nnumarasına gönderildi.',
    'resendCode': 'Kodu yeniden gönder',
    'resendIn': 'Yeniden gönder: {time}',
    'codeNotReceived': 'Kod gelmedi mi?',
    'smsHelpTitle': 'SMS kodu gelmedi mi?',
    'smsHelpCauses': 'Sık karşılaşılan nedenler:',
    'smsSpamTitle': 'Spam klasörü',
    'smsSpamBody':
        'SMS bölümündeki «Spam» veya «Gereksiz» klasörünü kontrol edin. SMS\'imiz 4546 numarasından gelir.',
    'smsBalanceTitle': 'Uzmobile bakiyesi',
    'smsBalanceBody':
        'Uzmobile operatöründe bakiye yoksa SIM kart SMS alamayabilir.',
    'understood': 'Anladım',
    'policyLoginPrefix': 'Giriş yaparak ',
    'policyRegisterPrefix': 'Kayıt olarak ',
    'policyAnd': ' ve ',
    'policySuffix': "'ni kabul etmiş olursunuz",
    'policyTerms': 'Koşulları',
    'policyPrivacy': 'Gizlilik Politikası',
    'stepForm': 'Bilgiler',
    'stepVerify': 'Doğrulama',
    'stepEnterApp': 'Uygulamaya\ngiriş',
    'phoneExistsTitle': 'Numara kayıtlı',
    'phoneExistsBody':
        '{phone} numarası zaten kayıtlı.\n\nBu numara ile giriş yapın.',
    'cancelShort': 'İptal',
    'socialComingSoon': '{name} ile giriş yakında eklenecek',
    'telegramConnecting': 'Bağlanıyor...',
    'telegramConnectingHint': 'Telegram açılıyor',
    'telegramWaitingTitle': 'Telegram bekleniyor',
    'telegramWaitingHint': "Telegram'da telefon numaranızı gönderin ve uygulamaya dönüş düğmesine basın",
    'telegramOpenAgain': "Telegram'ı tekrar aç",
    'telegramRetry': 'Tekrar dene',
    'telegramBackToLogin': 'Girişe dön',
    'telegramSessionExpired': 'Süre doldu. Tekrar deneyin.',
    'loginInfoPrefix': 'Daha önce hesap oluşturmadıysanız ',
    'loginInfoAction': 'Hesap Oluşturun',
    'loginInfoSuffix': "'a tıklayın",
    'tapMapToSelect': 'Konum seçmek için haritaya dokunun',
    'locationPermDenied': 'Konum izni reddedildi. Ayarlardan açın.',
    'locationError': 'Konum belirlenirken hata oluştu',
    'tutorialStep1Title': 'Ürün ekleyin',
    'tutorialStep1Desc': 'Ürettiğiniz ürün türünü girin',
    'tutorialStep2Title': 'Hammadde ekleyin',
    'tutorialStep2Desc': 'Tarif için gerekli malzemeleri girin',
    'tutorialStep3Title': 'Hesaplama oluşturun',
    'tutorialStep3Desc': '1 ürün için hammadde miktarını girin',
    'tutorialGoAction': 'Git',
    'tutorialSkip': 'Atla',
    'tutorialStep4Title': 'Çıkışı kaydedin',
    'tutorialStep4Desc': 'Bugün kaç ürün çıktığını girin',
    'tutorialGoSetup':    'Ayarlar düğmesine basın',
    'tutorialGoSetupSub': 'Ürünler, hammadde ve hesaplamayı ayarlayın',
    'tutorialTapAdd':     'Ekle düğmesine basın',
    'tutorialProductIncomeTitle': 'Ürün girişi',
    'tutorialProductIncomeDesc':  'Bugünkü ürün çıkışını bu düğme ile kaydedin',
    'tutorialOpenCardTitle':      'Bölüme gidin',
    'tutorialOpenCardDesc':       'Bu kartaya basarak ilgili ayara girin',
    'tutorialSettingsHintTitle':   'Önce ayarlayın',
    'tutorialSettingsHintMessage': 'Ürünleri ve hammaddeleri girin — uygulama maliyet ve kârı otomatik hesaplar.',
    'createBusiness': 'İşletme oluştur',
    'businessTypeStep': 'Kategori',
    'businessDetailsStep': 'Bilgiler',
    'businessLocationStep': 'Konum',
    'selectBusinessType': 'İşletme türü seçin',
    'selectBusinessTypeDesc': 'Size uygun kategoriyi seçin — uygulama buna göre uyarlanır',
    'businessDetailsTitle': 'İşletme hakkında',
    'businessDetailsDesc': 'İşletmenizin temel bilgilerini girin',
    'businessName': 'İşletme adı',
    'businessDescHint': 'Kısa açıklama (isteğe bağlı)',
    'description': 'Açıklama',
    'address': 'Adres',
    'businessLocationTitle': 'Konum',
    'businessLocationDesc': 'GPS ile konumu kaydedin veya adresi elle girin',
    'useGpsLocation': 'GPS ile konumu belirle',
    'fetchingLocation': 'Konum belirleniyor...',
    'locationSaved': 'Konum kaydedildi',
    'orManualAddress': 'veya elle girin',
    'addressHint': 'Örneğin: Taşkent, Amir Timur Cd., 1',
    'locationOptionalNote': 'Konum isteğe bağlıdır. Daha sonra da eklenebilir.',
    'businessCreated': 'İşletme oluşturuldu! 🎉',
    'businessCreatedDesc': '{name} başarıyla oluşturuldu.',
    'startWorking': 'Çalışmaya başla',
    'fieldRequired': 'Bu alan zorunludur',
    'continueWizard': 'Devam et',
    'customBusinessTypeInfo':
        'İşletme türünüzü yazın — dikkate alırız',
    'customBusinessTypeHint': 'Örneğin: Hamur işleri, Limonata...',
    'businessNameHint': 'Örneğin: Merkez Fırın',
    'businessNameRequired': 'İşletme adını girin',
    'businessNameMinLength': 'En az 2 karakter',
    'selectCurrency': 'Para birimi',
    'selectCurrencyDesc':
        'Raporlar ve fiyatlar için para birimi',
    'gpsAutoDetectSubtitle':
        'Mevcut konumunuzu otomatik belirle',
    'orDivider': 'veya',
    'manualAddressLabel': 'Adresi elle girin',
    'createBusinessSubmit': 'İşletmeyi oluştur',
  };
}

import 'package:flutter/material.dart';

/// Terminologiya — biznes turiga qarab UI labellarini o'zgartiradi.
class BusinessTerminology {
  final String rawMaterial;      // 'Un' | 'Go\'sht' | 'Xom ashyo'
  final String rawMaterialUnit;  // 'qop' | 'kg' | 'litr'
  final String batchLabel;       // 'Qoplar' | 'Partiyalar'
  final String batchUnit;        // 'qop' | 'partiya'
  final String productLabel;     // 'Mahsulot' | 'Taom'
  final String productUnit;      // 'dona' | 'porsiya'
  final String productionVerb;   // 'yopildi' | 'tayyorlandi'
  final String recipeLabel;      // 'Retsept' | 'Tarkib'
  final String categoryLabel;    // 'Non turi' | 'Taom turi'
  final String ingredientsLabel; // 'Ingredientlar' | 'Tarkiblar'

  const BusinessTerminology({
    required this.rawMaterial,
    required this.rawMaterialUnit,
    required this.batchLabel,
    required this.batchUnit,
    required this.productLabel,
    required this.productUnit,
    required this.productionVerb,
    required this.recipeLabel,
    required this.categoryLabel,
    required this.ingredientsLabel,
  });

  factory BusinessTerminology.fromJson(Map<String, dynamic> json) {
    return BusinessTerminology(
      rawMaterial:      json['rawMaterial']      as String? ?? 'Xom ashyo',
      rawMaterialUnit:  json['rawMaterialUnit']  as String? ?? 'dona',
      batchLabel:       json['batchLabel']       as String? ?? 'Partiyalar',
      batchUnit:        json['batchUnit']        as String? ?? 'partiya',
      productLabel:     json['productLabel']     as String? ?? 'Mahsulot',
      productUnit:      json['productUnit']      as String? ?? 'dona',
      productionVerb:   json['productionVerb']   as String? ?? 'tayyorlandi',
      recipeLabel:      json['recipeLabel']      as String? ?? 'Retsept',
      categoryLabel:    json['categoryLabel']    as String? ?? 'Mahsulot turi',
      ingredientsLabel: json['ingredientsLabel'] as String? ?? 'Ingredientlar',
    );
  }

  static const defaultTerminology = BusinessTerminology(
    rawMaterial:      'Xom ashyo',
    rawMaterialUnit:  'dona',
    batchLabel:       'Partiyalar',
    batchUnit:        'partiya',
    productLabel:     'Mahsulot',
    productUnit:      'dona',
    productionVerb:   'tayyorlandi',
    recipeLabel:      'Retsept',
    categoryLabel:    'Mahsulot turi',
    ingredientsLabel: 'Ingredientlar',
  );
}

class BusinessTypeModel {
  final String id;
  final String key;
  final String icon;
  final Color color;
  final int sortOrder;
  final String name;
  final Map<String, String> names;
  final Map<String, BusinessTerminology> terminology;

  const BusinessTypeModel({
    required this.id,
    required this.key,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.name,
    required this.names,
    required this.terminology,
  });

  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) {
    final rawTerminology = json['terminology'] as Map<String, dynamic>? ?? {};
    final parsedTerminology = rawTerminology.map(
      (locale, data) => MapEntry(
        locale,
        BusinessTerminology.fromJson(data as Map<String, dynamic>),
      ),
    );

    final rawNames = json['names'] as Map<String, dynamic>? ?? {};
    final parsedNames = rawNames.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    );

    return BusinessTypeModel(
      id:         json['id'] as String,
      key:        json['key'] as String,
      icon:       json['icon'] as String? ?? '🏭',
      color:      _parseColor(json['color'] as String? ?? '#546E7A'),
      sortOrder:  json['sort_order'] as int? ?? 0,
      name:       json['name'] as String? ?? json['key'] as String,
      names:      parsedNames,
      terminology: parsedTerminology,
    );
  }

  /// Get terminology for current locale, fallback to 'uz'.
  BusinessTerminology getTerminology(String locale) {
    return terminology[locale] ??
        terminology['uz'] ??
        BusinessTerminology.defaultTerminology;
  }

  static Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF546E7A);
    }
  }

  /// API `names` kalitlari: uz, uz_CYRL, ru, kk, ky, tr, ...
  String displayNameForLocale(Locale locale) {
    final country = locale.countryCode;
    final fullCode = country != null && country.isNotEmpty
        ? '${locale.languageCode}_$country'
        : locale.languageCode;
    final fromFull = names[fullCode];
    if (fromFull != null && fromFull.isNotEmpty) return fromFull;
    final fromLang = names[locale.languageCode];
    if (fromLang != null && fromLang.isNotEmpty) return fromLang;
    final uz = names['uz'];
    if (uz != null && uz.isNotEmpty) return uz;
    return name;
  }
}

import '../../../../core/utils/json_numbers.dart';

/// Kassa yozuvining yo'nalishi.
enum CashType { income, expense }

/// Yozuv qayerdan paydo bo'lgan.
///
/// `manual` — foydalanuvchi kassada o'zi yozgan, tahrirlash mumkin.
/// Qolganlari asosiy sahifadagi amaldan avtomatik olingan.
enum CashSource { manual, production, breadReturn }

class CashEntry {
  final String id;
  final CashType type;
  final CashSource source;

  /// Tizim kaliti — filtrlash uchun.
  final String category;

  /// Foydalanuvchi tilidagi nom — ko'rsatish uchun.
  final String categoryName;

  final double amount;
  final String? description;
  final String date;
  final DateTime? createdAt;

  /// Avtomatik yozuvda `false` — ilova tahrir tugmasini ko'rsatmaydi.
  final bool isEditable;

  const CashEntry({
    required this.id,
    required this.type,
    required this.source,
    required this.category,
    required this.categoryName,
    required this.amount,
    this.description,
    required this.date,
    this.createdAt,
    required this.isEditable,
  });

  bool get isIncome => type == CashType.income;

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] as String?;

    return CashEntry(
      id: json['id'] as String,
      type: json['type'] == 'income' ? CashType.income : CashType.expense,
      source: switch (json['source']) {
        'production' => CashSource.production,
        'return' => CashSource.breadReturn,
        _ => CashSource.manual,
      },
      category: json['category'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      amount: jsonDouble(json['amount']),
      description: json['description'] as String?,
      date: json['date'] as String? ?? '',
      createdAt: created == null ? null : DateTime.tryParse(created)?.toLocal(),
      isEditable: json['is_editable'] as bool? ?? false,
    );
  }
}

/// Davr xulosasi — kirim, chiqim va sof natija.
class CashSummary {
  final double income;
  final double expense;
  final double net;
  final int incomeCount;
  final int expenseCount;

  /// Kategoriya kesimi — kirim va chiqim uchun alohida.
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;

  const CashSummary({
    this.income = 0,
    this.expense = 0,
    this.net = 0,
    this.incomeCount = 0,
    this.expenseCount = 0,
    this.incomeByCategory = const {},
    this.expenseByCategory = const {},
  });

  bool get isProfit => net >= 0;

  bool get isEmpty => incomeCount == 0 && expenseCount == 0;

  factory CashSummary.fromJson(Map<String, dynamic> json) {
    final income = json['income'] as Map<String, dynamic>? ?? const {};
    final expense = json['expense'] as Map<String, dynamic>? ?? const {};

    return CashSummary(
      income: jsonDouble(income['total']),
      expense: jsonDouble(expense['total']),
      net: jsonDouble(json['net']),
      incomeCount: (income['count'] as num?)?.toInt() ?? 0,
      expenseCount: (expense['count'] as num?)?.toInt() ?? 0,
      incomeByCategory: _categories(income['by_category']),
      expenseByCategory: _categories(expense['by_category']),
    );
  }

  /// Server bo'sh kesimni `{}` qaytaradi — boshqa turdagi javobga ham
  /// chidamli bo'lsin.
  static Map<String, double> _categories(dynamic raw) {
    if (raw is! Map) return const {};

    return raw.map((key, value) => MapEntry('$key', jsonDouble(value)));
  }
}

/// Kassa sozlamasi — asosiy sahifadagi amallar kassaga ko'chirilsinmi.
class CashSettings {
  final bool trackProduction;
  final bool trackReturns;

  const CashSettings({
    this.trackProduction = true,
    this.trackReturns = true,
  });

  factory CashSettings.fromJson(Map<String, dynamic> json) {
    return CashSettings(
      trackProduction: json['track_production'] as bool? ?? true,
      trackReturns: json['track_returns'] as bool? ?? true,
    );
  }

  CashSettings copyWith({bool? trackProduction, bool? trackReturns}) {
    return CashSettings(
      trackProduction: trackProduction ?? this.trackProduction,
      trackReturns: trackReturns ?? this.trackReturns,
    );
  }
}

/// Kirim turi (server tarjima qilib beradi).
class CashCategoryOption {
  final String key;
  final String name;

  const CashCategoryOption({required this.key, required this.name});

  factory CashCategoryOption.fromJson(Map<String, dynamic> json) {
    return CashCategoryOption(
      key: json['key'] as String,
      name: json['name'] as String? ?? json['key'] as String,
    );
  }
}

/// Kassa ekranining bitta so'rovdagi to'liq holati.
class CashPage {
  final CashSummary summary;
  final CashSettings settings;
  final List<CashEntry> entries;
  final int currentPage;
  final int lastPage;

  const CashPage({
    required this.summary,
    required this.settings,
    required this.entries,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;

  factory CashPage.fromJson(Map<String, dynamic> json) {
    final list = json['entries'] as List<dynamic>? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return CashPage(
      summary: CashSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      settings: CashSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
      entries: list
          .map((e) => CashEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}

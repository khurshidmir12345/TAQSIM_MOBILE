import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../data/cash_repository.dart';
import '../models/cash_model.dart';

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  return CashRepository(ref.read(apiClientProvider));
});

/// Ekranda tanlangan davr. Boshlang'ich qiymat — bugun.
class CashRange {
  final DateTime from;
  final DateTime to;

  const CashRange(this.from, this.to);

  factory CashRange.today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return CashRange(today, today);
  }

  @override
  bool operator ==(Object other) =>
      other is CashRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Tanlangan davr. Riverpod 3'da `StateProvider` yo'q — oddiy `Notifier`.
class CashRangeNotifier extends Notifier<CashRange> {
  @override
  CashRange build() => CashRange.today();

  void set(DateTime from, DateTime to) {
    final next = CashRange(from, to);

    if (next == state) return;

    state = next;
  }
}

final cashRangeProvider =
    NotifierProvider<CashRangeNotifier, CashRange>(CashRangeNotifier.new);

class CashState {
  final CashSummary summary;
  final CashSettings settings;
  final List<CashEntry> entries;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  const CashState({
    this.summary = const CashSummary(),
    this.settings = const CashSettings(),
    this.entries = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  CashState copyWith({
    CashSummary? summary,
    CashSettings? settings,
    List<CashEntry>? entries,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return CashState(
      summary: summary ?? this.summary,
      settings: settings ?? this.settings,
      entries: entries ?? this.entries,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final cashProvider =
    AsyncNotifierProvider<CashNotifier, CashState>(CashNotifier.new);

class CashNotifier extends AsyncNotifier<CashState> {
  CashRepository get _repo => ref.read(cashRepositoryProvider);

  String? get _shopId => ref.read(shopProvider).selected?.id;

  @override
  Future<CashState> build() async {
    // Davr o'zgarsa ekran o'zi qayta yuklanadi.
    final range = ref.watch(cashRangeProvider);
    final shopId = _shopId;

    if (shopId == null) return const CashState();

    final page = await _repo.fetch(shopId, from: range.from, to: range.to);

    return _stateFrom(page);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final shopId = _shopId;

      if (shopId == null) return const CashState();

      final range = ref.read(cashRangeProvider);
      final page = await _repo.fetch(shopId, from: range.from, to: range.to);

      return _stateFrom(page);
    });
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    final shopId = _shopId;

    if (current == null || shopId == null) return;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final range = ref.read(cashRangeProvider);
      final page = await _repo.fetch(
        shopId,
        from: range.from,
        to: range.to,
        page: current.currentPage + 1,
      );

      state = AsyncData(current.copyWith(
        entries: [...current.entries, ...page.entries],
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Yozuv qo'shilgach xulosa ham o'zgaradi — to'liq qayta yuklaymiz.
  Future<void> create({
    required CashType type,
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    final shopId = _shopId;

    if (shopId == null) return;

    await _repo.create(
      shopId,
      type: type,
      amount: amount,
      category: category,
      description: description,
      date: date,
    );

    await refresh();
  }

  Future<void> delete(String entryId) async {
    final shopId = _shopId;
    final current = state.asData?.value;

    if (shopId == null || current == null) return;

    // Ro'yxatdan darhol olib tashlaymiz — javob kutilmasin.
    state = AsyncData(current.copyWith(
      entries: current.entries.where((e) => e.id != entryId).toList(),
    ));

    try {
      await _repo.delete(shopId, entryId);
      await refresh();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> updateEntry(
    String entryId, {
    double? amount,
    String? category,
    String? description,
    DateTime? date,
  }) async {
    final shopId = _shopId;

    if (shopId == null) return;

    await _repo.update(
      shopId,
      entryId,
      amount: amount,
      category: category,
      description: description,
      date: date,
    );

    await refresh();
  }

  /// Sozlama o'zgarganda server avtomatik yozuvlarni qayta quradi —
  /// shuning uchun ekranni to'liq yangilaymiz.
  Future<void> setSetting({bool? trackProduction, bool? trackReturns}) async {
    final shopId = _shopId;
    final current = state.asData?.value;

    if (shopId == null || current == null) return;

    // Tugma darhol o'zgarsin, so'ng server javobiga moslanadi.
    state = AsyncData(current.copyWith(
      settings: current.settings.copyWith(
        trackProduction: trackProduction,
        trackReturns: trackReturns,
      ),
    ));

    try {
      await _repo.updateSettings(
        shopId,
        trackProduction: trackProduction,
        trackReturns: trackReturns,
      );
      await refresh();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  CashState _stateFrom(CashPage page) {
    return CashState(
      summary: page.summary,
      settings: page.settings,
      entries: page.entries,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
    );
  }
}

/// Kategoriya ro'yxati so'rovi — yo'nalish, til va qidiruv bo'yicha.
class CashCategoryQuery {
  final CashType type;
  final String locale;
  final String search;

  const CashCategoryQuery({
    required this.type,
    required this.locale,
    this.search = '',
  });

  @override
  bool operator ==(Object other) =>
      other is CashCategoryQuery &&
      other.type == type &&
      other.locale == locale &&
      other.search == search;

  @override
  int get hashCode => Object.hash(type, locale, search);
}

/// Kassa kategoriyalari — kirim va chiqim uchun bir xil manba.
final cashCategoriesProvider = FutureProvider.autoDispose
    .family<List<CashCategory>, CashCategoryQuery>((ref, query) async {
  final shopId = ref.watch(shopProvider).selected?.id;

  if (shopId == null) return const [];

  return ref.read(cashRepositoryProvider).categories(
        shopId,
        type: query.type,
        locale: query.locale,
        search: query.search,
      );
});

/// Kategoriya qo'shish, nomini o'zgartirish va o'chirish.
class CashCategoryActions {
  const CashCategoryActions(this._ref);

  final Ref _ref;

  String? get _shopId => _ref.read(shopProvider).selected?.id;

  Future<void> create(CashType type, String name) async {
    final shopId = _shopId;

    if (shopId == null) return;

    await _ref
        .read(cashRepositoryProvider)
        .createCategory(shopId, type: type, name: name);
  }

  Future<void> rename(String categoryId, String name) async {
    final shopId = _shopId;

    if (shopId == null) return;

    await _ref
        .read(cashRepositoryProvider)
        .renameCategory(shopId, categoryId, name: name);
  }

  Future<void> remove(String categoryId) async {
    final shopId = _shopId;

    if (shopId == null) return;

    await _ref.read(cashRepositoryProvider).deleteCategory(shopId, categoryId);
  }
}

final cashCategoryActionsProvider =
    Provider<CashCategoryActions>(CashCategoryActions.new);

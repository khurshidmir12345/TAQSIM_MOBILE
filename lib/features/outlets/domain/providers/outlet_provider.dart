import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/domain/providers/daily_provider.dart';
import '../../data/outlets_repository.dart';
import '../models/outlet_model.dart';

final outletsRepositoryProvider = Provider<OutletsRepository>((ref) {
  return OutletsRepository(ref.read(apiClientProvider));
});

String _shopId(Ref ref) => ref.read(shopProvider).selected!.id;

// ─── Ro'yxat ────────────────────────────────────────────────────────────

class OutletsState {
  final List<OutletModel> items;
  final bool isLoading;
  final bool loadedOnce;
  final String? error;

  const OutletsState({
    this.items = const [],
    this.isLoading = false,
    this.loadedOnce = false,
    this.error,
  });

  OutletsState copyWith({
    List<OutletModel>? items,
    bool? isLoading,
    bool? loadedOnce,
    String? error,
  }) => OutletsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    loadedOnce: loadedOnce ?? this.loadedOnce,
    error: error,
  );
}

class OutletsNotifier extends Notifier<OutletsState> {
  @override
  OutletsState build() {
    // Do'kon almashsa ro'yxat tozalanadi; ekran ochilganda qayta yuklanadi.
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) state = const OutletsState();
    });
    return const OutletsState();
  }

  OutletsRepository get _repo => ref.read(outletsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: !state.loadedOnce);
    try {
      final items = await _repo.list(_shopId(ref));
      state = state.copyWith(items: items, isLoading: false, loadedOnce: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadedOnce: true,
        error: e.toString(),
      );
    }
  }

  /// Bitta do'konni ro'yxatda yangilaydi (daftar o'zgarganda qoldiq ham).
  void upsert(OutletModel outlet) {
    final items = [...state.items];
    final i = items.indexWhere((o) => o.id == outlet.id);
    if (i >= 0) {
      items[i] = outlet;
    } else {
      items.add(outlet);
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    state = state.copyWith(items: items);
  }

  /// Xatolikda [ApiException] otadi — ekran xabarni ko'rsatadi.
  Future<OutletModel> create({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? phones,
    String? note,
  }) async {
    final outlet = await _repo.create(
      _shopId(ref),
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phones: phones,
      note: note,
    );
    upsert(outlet);
    return outlet;
  }

  Future<OutletModel> update(
    String id, {
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? phones,
    String? note,
  }) async {
    final outlet = await _repo.update(
      _shopId(ref),
      id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phones: phones,
      note: note,
    );
    upsert(outlet);
    return outlet;
  }

  Future<void> delete(String id) async {
    await _repo.delete(_shopId(ref), id);
    state = state.copyWith(
      items: state.items.where((o) => o.id != id).toList(),
    );
  }

  Future<OutletModel> uploadImage(String id, String filePath) async {
    final outlet = await _repo.uploadImage(_shopId(ref), id, filePath);
    upsert(outlet);
    return outlet;
  }

  Future<OutletModel> deleteImage(String id) async {
    final outlet = await _repo.deleteImage(_shopId(ref), id);
    upsert(outlet);
    return outlet;
  }
}

final outletsProvider = NotifierProvider<OutletsNotifier, OutletsState>(
  OutletsNotifier.new,
);

// ─── Daftar (bitta do'kon) ──────────────────────────────────────────────

class OutletLedgerState {
  final OutletModel? outlet;
  final List<OutletEntryModel> entries;
  final bool isLoading;
  final String? error;

  /// Sana filtri (ikkalasi `null` — butun davr).
  final DateTime? from;
  final DateTime? to;

  const OutletLedgerState({
    this.outlet,
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.from,
    this.to,
  });

  bool get isFiltered => from != null || to != null;

  OutletLedgerState copyWith({
    OutletModel? outlet,
    List<OutletEntryModel>? entries,
    bool? isLoading,
    String? error,
    DateTime? from,
    DateTime? to,
    bool clearRange = false,
  }) => OutletLedgerState(
    outlet: outlet ?? this.outlet,
    entries: entries ?? this.entries,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    from: clearRange ? null : (from ?? this.from),
    to: clearRange ? null : (to ?? this.to),
  );
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class OutletLedgerNotifier extends Notifier<OutletLedgerState> {
  OutletLedgerNotifier(this.outletId);

  final String outletId;

  @override
  OutletLedgerState build() {
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) state = const OutletLedgerState();
    });
    return const OutletLedgerState();
  }

  OutletsRepository get _repo => ref.read(outletsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: state.outlet == null);
    try {
      final (outlet, entries) = await _repo.entries(
        _shopId(ref),
        outletId,
        from: state.from == null ? null : _iso(state.from!),
        to: state.to == null ? null : _iso(state.to!),
      );
      state = state.copyWith(
        outlet: outlet,
        entries: entries,
        isLoading: false,
      );
      ref.read(outletsProvider.notifier).upsert(outlet);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setRange(DateTime? from, DateTime? to) async {
    state = from == null && to == null
        ? state.copyWith(clearRange: true)
        : state.copyWith(from: from, to: to);
    await load();
  }

  /// Yangi qator; asosiy sahifa foydasi ham o'zgaradi — kunlik hisobot yangilanadi.
  Future<void> addEntry({
    required OutletEntryType type,
    required DateTime date,
    List<OutletItemInput> items = const [],
    double? amount,
    double? paidAmount,
    String? note,
  }) async {
    final (outlet, _) = await _repo.createEntry(
      _shopId(ref),
      outletId,
      type: type,
      date: _iso(date),
      items: items,
      amount: amount,
      paidAmount: paidAmount,
      note: note,
    );
    state = state.copyWith(outlet: outlet);
    await load();
    ref.read(dailyReportProvider.notifier).loadToday();
  }

  Future<void> deleteEntry(String entryId) async {
    final outlet = await _repo.deleteEntry(_shopId(ref), outletId, entryId);
    state = state.copyWith(outlet: outlet);
    await load();
    ref.read(dailyReportProvider.notifier).loadToday();
  }
}

final outletLedgerProvider =
    NotifierProvider.family<OutletLedgerNotifier, OutletLedgerState, String>(
      OutletLedgerNotifier.new,
    );

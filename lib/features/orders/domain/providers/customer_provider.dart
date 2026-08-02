import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/providers/shop_provider.dart';
import '../../data/orders_repository.dart';
import '../models/customer_model.dart';
import '../utils/money_utils.dart';
import '../utils/orders_api_utils.dart';

class CustomerListState {
  const CustomerListState({
    this.items = const [],
    this.search = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.errorForbidden = false,
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.shopId,
  });

  final List<CustomerModel> items;
  final String search;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool errorForbidden;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? shopId;

  bool get hasMore => currentPage < lastPage;

  CustomerListState copyWith({
    List<CustomerModel>? items,
    String? search,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? errorForbidden,
    int? currentPage,
    int? lastPage,
    int? total,
    String? shopId,
  }) {
    return CustomerListState(
      items: items ?? this.items,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      errorForbidden: errorForbidden ?? this.errorForbidden,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      shopId: shopId ?? this.shopId,
    );
  }
}

class CustomerListNotifier extends Notifier<CustomerListState> {
  CancelToken? _cancelToken;
  Timer? _debounce;
  int _requestGen = 0;

  CustomerRepository get _repo => ref.read(customerRepositoryProvider);

  String? get _shopId => ref.read(shopProvider).selected?.id;

  @override
  CustomerListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel('dispose');
    });
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) {
        _cancelToken?.cancel('shop changed');
        state = const CustomerListState(isLoading: true);
        refresh();
      }
    });
    Future.microtask(refresh);
    return const CustomerListState(isLoading: true);
  }

  Future<void> refresh() async {
    final shopId = _shopId;
    if (shopId == null) {
      state = const CustomerListState();
      return;
    }

    final gen = ++_requestGen;
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      shopId: shopId,
      items: const [],
      currentPage: 0,
    );

    try {
      final result = await _repo.fetchCustomersPaginated(
        shopId,
        page: 1,
        search: state.search,
        cancelToken: _cancelToken,
      );

      if (gen != _requestGen) return;

      state = state.copyWith(
        items: result.items,
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        shopId: shopId,
      );
    } catch (e) {
      if (gen != _requestGen || e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ordersProviderErrorMessage(e).isEmpty
            ? null
            : ordersProviderErrorMessage(e),
        errorForbidden: ordersErrorIsForbidden(e),
        shopId: shopId,
      );
    }
  }

  Future<void> loadMore() async {
    final shopId = _shopId;
    if (shopId == null || !state.hasMore || state.isLoadingMore) return;

    final gen = ++_requestGen;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.fetchCustomersPaginated(
        shopId,
        page: nextPage,
        search: state.search,
      );

      if (gen != _requestGen) return;

      state = state.copyWith(
        items: mergePaginatedItems(
          state.items,
          result.items,
          idOf: (c) => c.id,
        ),
        isLoadingMore: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } catch (e) {
      if (gen != _requestGen) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: ordersProviderErrorMessage(e).isEmpty
            ? null
            : ordersProviderErrorMessage(e),
        errorForbidden: ordersErrorIsForbidden(e),
      );
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), refresh);
  }
}

final customerListProvider =
    NotifierProvider<CustomerListNotifier, CustomerListState>(
      CustomerListNotifier.new,
    );

// ─── Order form: initial list + debounced search ─────────────────────────────

class CustomerPickerState {
  const CustomerPickerState({
    this.items = const [],
    this.query = '',
    this.isLoading = false,
    this.error,
    this.shopId,
  });

  final List<CustomerModel> items;
  final String query;
  final bool isLoading;
  final Object? error;
  final String? shopId;
}

class CustomerPickerNotifier extends Notifier<CustomerPickerState> {
  CancelToken? _cancelToken;
  Timer? _debounce;
  int _requestGen = 0;
  bool _loadStarted = false;

  CustomerRepository get _repo => ref.read(customerRepositoryProvider);

  String? get _shopId => ref.read(shopProvider).selected?.id;

  @override
  CustomerPickerState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel('dispose');
    });
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) {
        _loadStarted = false;
        _requestGen++;
        state = const CustomerPickerState();
      }
    });
    return const CustomerPickerState();
  }

  Future<void> ensureLoaded() async {
    final shopId = _shopId;
    if (shopId == null) return;
    if (_loadStarted &&
        state.shopId == shopId &&
        (state.items.isNotEmpty || state.error != null) &&
        !state.isLoading) {
      return;
    }
    _loadStarted = true;
    await loadInitial();
  }

  Future<void> loadInitial() async {
    final shopId = _shopId;
    if (shopId == null) {
      state = const CustomerPickerState();
      return;
    }

    final gen = ++_requestGen;
    _cancelToken?.cancel('initial');
    _cancelToken = CancelToken();

    state = CustomerPickerState(isLoading: true, shopId: shopId);

    try {
      final result = await _repo.fetchCustomersPaginated(
        shopId,
        page: 1,
        cancelToken: _cancelToken,
      );
      if (gen != _requestGen) return;
      state = CustomerPickerState(items: result.items, shopId: shopId);
    } catch (e) {
      if (gen != _requestGen || e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = CustomerPickerState(
        error: e,
        shopId: shopId,
      );
    }
  }

  void setQuery(String query) {
    state = CustomerPickerState(
      items: state.items,
      query: query,
      shopId: state.shopId,
    );
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    final shopId = _shopId;
    if (shopId == null) return;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadInitial();
      return;
    }

    final gen = ++_requestGen;
    _cancelToken?.cancel('search');
    _cancelToken = CancelToken();
    state = CustomerPickerState(query: query, isLoading: true, shopId: shopId);

    try {
      final items = await _repo.searchCustomers(
        shopId,
        search: trimmed,
        cancelToken: _cancelToken,
      );
      if (gen != _requestGen) return;
      state = CustomerPickerState(items: items, query: query, shopId: shopId);
    } catch (e) {
      if (gen != _requestGen || e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      state = CustomerPickerState(
        query: query,
        error: e,
        shopId: shopId,
      );
    }
  }
}

final customerPickerProvider =
    NotifierProvider<CustomerPickerNotifier, CustomerPickerState>(
      CustomerPickerNotifier.new,
    );

// ─── Customer detail (shop-scoped) ───────────────────────────────────────────

typedef CustomerDetailKey = ({String shopId, String customerId});

class CustomerDetailNotifier extends Notifier<AsyncValue<CustomerModel?>> {
  CustomerDetailNotifier(this._key);

  final CustomerDetailKey _key;

  CustomerRepository get _repo => ref.read(customerRepositoryProvider);

  @override
  AsyncValue<CustomerModel?> build() {
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next && prev != null) {
        state = const AsyncData(null);
      }
    });
    Future.microtask(refresh);
    return const AsyncLoading();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getCustomer(_key.shopId, _key.customerId),
    );
  }
}

final customerDetailProvider =
    NotifierProvider.family<
      CustomerDetailNotifier,
      AsyncValue<CustomerModel?>,
      CustomerDetailKey
    >(CustomerDetailNotifier.new);

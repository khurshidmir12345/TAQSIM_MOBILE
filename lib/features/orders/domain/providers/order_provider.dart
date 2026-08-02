import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/providers/shop_provider.dart';
import '../../data/orders_repository.dart';
import '../models/customer_model.dart';
import '../models/customer_order_model.dart';
import '../utils/money_utils.dart';
import '../utils/orders_api_utils.dart';
import '../../../../core/api/api_exceptions.dart';

class OrderListState {
  const OrderListState({
    this.items = const [],
    this.filters = const OrderListFilters(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.shopId,
    this.started = false,
    this.errorForbidden = false,
  });

  final List<CustomerOrderModel> items;
  final OrderListFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? shopId;
  final bool started;
  final bool errorForbidden;

  bool get hasMore => currentPage < lastPage;

  OrderListState copyWith({
    List<CustomerOrderModel>? items,
    OrderListFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? lastPage,
    int? total,
    String? shopId,
    bool? started,
    bool? errorForbidden,
  }) {
    return OrderListState(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      shopId: shopId ?? this.shopId,
      started: started ?? this.started,
      errorForbidden: errorForbidden ?? this.errorForbidden,
    );
  }
}

String _ordersErrorMessage(Object e) => ordersProviderErrorMessage(e);

bool _ordersErrorForbidden(Object e) {
  return e is ApiException && e.isForbiddenPermission;
}

class OrderListNotifier extends Notifier<OrderListState> {
  CancelToken? _cancelToken;
  int _requestGen = 0;

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  String? get _shopId => ref.read(shopProvider).selected?.id;

  @override
  OrderListState build() {
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) {
        _invalidateAndReload();
      }
    });
    return const OrderListState();
  }

  void _invalidateAndReload() {
    _cancelToken?.cancel('shop changed');
    _requestGen++;
    state = const OrderListState();
  }

  /// Shell tab birinchi marta ochilganda chaqiriladi — ortiqcha API chaqiruvini oldini oladi.
  void ensureLoaded() {
    if (state.started) return;
    state = state.copyWith(started: true);
    unawaited(refresh());
  }

  ({String? date, String? from, String? to}) _dateParams(
    OrderListFilters filters,
  ) {
    return switch (filters.dateTab) {
      OrderDateTab.today => (
        date: toDateString(todayDateOnly()),
        from: null,
        to: null,
      ),
      OrderDateTab.tomorrow => (
        date: toDateString(tomorrowDateOnly()),
        from: null,
        to: null,
      ),
      OrderDateTab.all => (date: null, from: null, to: null),
    };
  }

  Future<void> refresh() async {
    final shopId = _shopId;
    if (shopId == null) {
      state = const OrderListState();
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
      started: true,
    );

    try {
      final dateParams = _dateParams(state.filters);
      final result = await _repo.fetchOrdersPaginated(
        shopId,
        page: 1,
        date: dateParams.date,
        from: dateParams.from,
        to: dateParams.to,
        status: state.filters.status != null
            ? customerOrderStatusToApi(state.filters.status!)
            : null,
        customerId: state.filters.customerId,
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
        error: _ordersErrorMessage(e),
        errorForbidden: _ordersErrorForbidden(e),
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
      final dateParams = _dateParams(state.filters);
      final nextPage = state.currentPage + 1;
      final result = await _repo.fetchOrdersPaginated(
        shopId,
        page: nextPage,
        date: dateParams.date,
        from: dateParams.from,
        to: dateParams.to,
        status: state.filters.status != null
            ? customerOrderStatusToApi(state.filters.status!)
            : null,
        customerId: state.filters.customerId,
      );

      if (gen != _requestGen) return;

      state = state.copyWith(
        items: mergePaginatedItems(
          state.items,
          result.items,
          idOf: (o) => o.id,
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
        error: _ordersErrorMessage(e),
        errorForbidden: _ordersErrorForbidden(e),
      );
    }
  }

  Future<void> setFilters(OrderListFilters filters) async {
    if (state.filters == filters) return;
    state = state.copyWith(filters: filters);
    await refresh();
  }

  Future<void> setCustomerFilter(String? customerId) async {
    await setFilters(
      state.filters.copyWith(
        customerId: customerId,
        clearCustomerId: customerId == null,
      ),
    );
  }
}

final orderListProvider = NotifierProvider<OrderListNotifier, OrderListState>(
  OrderListNotifier.new,
);

// ─── Customer order history (detail) ─────────────────────────────────────────

typedef CustomerOrderHistoryKey = ({String shopId, String customerId});

class CustomerOrderHistoryState {
  const CustomerOrderHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.errorForbidden = false,
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<CustomerOrderModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool errorForbidden;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  CustomerOrderHistoryState copyWith({
    List<CustomerOrderModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? errorForbidden,
    int? currentPage,
    int? lastPage,
    int? total,
  }) {
    return CustomerOrderHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      errorForbidden: errorForbidden ?? this.errorForbidden,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }
}

class CustomerOrderHistoryNotifier extends Notifier<CustomerOrderHistoryState> {
  CustomerOrderHistoryNotifier(this._key);

  final CustomerOrderHistoryKey _key;
  int _requestGen = 0;
  bool _loadMoreInFlight = false;

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  CustomerOrderHistoryState build() {
    ref.listen(shopProvider.select((s) => s.selected?.id), (prev, next) {
      if (prev != next) {
        _requestGen++;
        state = const CustomerOrderHistoryState();
      }
    });
    Future.microtask(refresh);
    return const CustomerOrderHistoryState(isLoading: true);
  }

  Future<void> refresh() async {
    final gen = ++_requestGen;
    _loadMoreInFlight = false;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: const [],
      currentPage: 0,
    );

    try {
      final result = await _repo.fetchOrdersPaginated(
        _key.shopId,
        page: 1,
        customerId: _key.customerId,
      );
      if (gen != _requestGen) return;
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } catch (e) {
      if (gen != _requestGen) return;
      state = state.copyWith(
        isLoading: false,
        error: _ordersErrorMessage(e),
        errorForbidden: _ordersErrorForbidden(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || _loadMoreInFlight) return;

    final gen = ++_requestGen;
    _loadMoreInFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.fetchOrdersPaginated(
        _key.shopId,
        page: nextPage,
        customerId: _key.customerId,
      );
      if (gen != _requestGen) return;

      state = state.copyWith(
        items: mergePaginatedItems(
          state.items,
          result.items,
          idOf: (o) => o.id,
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
        error: _ordersErrorMessage(e),
        errorForbidden: _ordersErrorForbidden(e),
      );
    } finally {
      _loadMoreInFlight = false;
    }
  }
}

final customerOrderHistoryProvider =
    NotifierProvider.family<
      CustomerOrderHistoryNotifier,
      CustomerOrderHistoryState,
      CustomerOrderHistoryKey
    >(CustomerOrderHistoryNotifier.new);

// ─── Order detail (shop-scoped) ──────────────────────────────────────────────

typedef OrderDetailKey = ({String shopId, String orderId});

class OrderDetailNotifier extends Notifier<AsyncValue<CustomerOrderModel?>> {
  OrderDetailNotifier(this._key);

  final OrderDetailKey _key;

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  AsyncValue<CustomerOrderModel?> build() {
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
      () => _repo.getOrder(_key.shopId, _key.orderId),
    );
  }
}

final orderDetailProvider =
    NotifierProvider.family<
      OrderDetailNotifier,
      AsyncValue<CustomerOrderModel?>,
      OrderDetailKey
    >(OrderDetailNotifier.new);

// ─── Mutations ───────────────────────────────────────────────────────────────

class OrderMutationsNotifier extends Notifier<bool> {
  bool _busy = false;

  OrderRepository get _repo => ref.read(orderRepositoryProvider);
  CustomerRepository get _customers => ref.read(customerRepositoryProvider);

  String? get _shopId => ref.read(shopProvider).selected?.id;

  @override
  bool build() => false;

  Future<T?> _singleFlight<T>(Future<T> Function() action) async {
    if (_busy) return null;
    _busy = true;
    state = true;
    try {
      return await action();
    } finally {
      _busy = false;
      state = false;
    }
  }

  Future<CustomerOrderModel?> createOrder(Map<String, dynamic> payload) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(() => _repo.createOrder(shopId, payload));
  }

  Future<CustomerOrderModel?> updateOrder(
    String orderId,
    Map<String, dynamic> payload,
  ) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(() => _repo.updateOrder(shopId, orderId, payload));
  }

  Future<CustomerOrderModel?> addPayment(
    String orderId, {
    required num amount,
    String? paidAt,
    String? note,
  }) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(
      () => _repo.addPayment(
        shopId,
        orderId,
        amount: amount,
        paidAt: paidAt,
        note: note,
      ),
    );
  }

  Future<CustomerOrderModel?> deliverOrder(
    String orderId, {
    num? paymentAmount,
    String? paymentNote,
  }) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(
      () => _repo.deliverOrder(
        shopId,
        orderId,
        paymentAmount: paymentAmount,
        paymentNote: paymentNote,
      ),
    );
  }

  Future<CustomerOrderModel?> cancelOrder(String orderId) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(() => _repo.cancelOrder(shopId, orderId));
  }

  Future<bool> deleteOrder(String orderId) async {
    final shopId = _shopId;
    if (shopId == null) return false;
    final result = await _singleFlight(() async {
      await _repo.deleteOrder(shopId, orderId);
      return true;
    });
    return result ?? false;
  }

  Future<CustomerModel?> createCustomer({
    required String name,
    String? phone,
    String? note,
  }) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(
      () => _customers.createCustomer(
        shopId,
        name: name,
        phone: phone,
        note: note,
      ),
    );
  }

  Future<CustomerModel?> updateCustomer(
    String customerId, {
    required String name,
    String? phone,
    String? note,
  }) {
    final shopId = _shopId;
    if (shopId == null) return Future.value(null);
    return _singleFlight(
      () => _customers.updateCustomer(
        shopId,
        customerId,
        name: name,
        phone: phone,
        note: note,
      ),
    );
  }

  Future<bool> deleteCustomer(String customerId) async {
    final shopId = _shopId;
    if (shopId == null) return false;
    final result = await _singleFlight(() async {
      await _customers.deleteCustomer(shopId, customerId);
      return true;
    });
    return result ?? false;
  }
}

final orderMutationsProvider = NotifierProvider<OrderMutationsNotifier, bool>(
  OrderMutationsNotifier.new,
);

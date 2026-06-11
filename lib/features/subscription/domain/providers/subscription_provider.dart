import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/subscription_repository.dart';
import '../models/order_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/wallet_transaction_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.read(apiClientProvider));
});

/// Joriy obuna holati + limit/usage + balans.
class SubscriptionStatusNotifier extends AsyncNotifier<SubscriptionStatusModel> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<SubscriptionStatusModel> build() => _repo.getStatus();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getStatus());
  }

  /// Tarifni sotib oladi va holatni yangilaydi. Xato bo'lsa qayta otiladi.
  Future<void> purchase(String planId) async {
    await _repo.purchase(planId);
    await refresh();
  }
}

final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatusModel>(
  SubscriptionStatusNotifier.new,
);

/// Sotib olinadigan tariflar ro'yxati.
final plansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlanModel>>((ref) async {
  return ref.read(subscriptionRepositoryProvider).getPlans();
});

/// Balans tarixi (birinchi sahifa).
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransactionModel>>((ref) async {
  final res = await ref.read(subscriptionRepositoryProvider).getTransactions();
  return res.items;
});

/// Buyurtmalar tarixi (birinchi sahifa).
final ordersListProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final res = await ref.read(subscriptionRepositoryProvider).getOrders();
  return res.items;
});

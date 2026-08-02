import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/providers/customer_provider.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/money_utils.dart';
import '../../domain/utils/orders_api_utils.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_card.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shopId = ref.read(shopProvider).selected?.id;
    if (shopId == null || !_scrollController.hasClients) return;
    final key = (shopId: shopId, customerId: widget.customerId);
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(customerOrderHistoryProvider(key).notifier).loadMore();
    }
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return localeTagFrom(l.languageCode, l.countryCode);
  }

  String _fmtMoney(BuildContext context, num value) {
    return formatMoneyAmount(value, localeTag: _localeTag(context));
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _delete(CustomerModel customer) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.customersDeleteTitle,
      message: s.customersDeleteConfirm,
      confirmLabel: s.delete,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final deleted = await ref
          .read(orderMutationsProvider.notifier)
          .deleteCustomer(customer.id);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.customersDeleted)));
        context.pop();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ordersUserErrorMessage(e, s))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final shopId = ref.watch(shopProvider.select((s) => s.selected?.id));

    if (shopId == null) {
      return ManageOrdersGuard(
        child: Scaffold(
          appBar: AppBar(title: Text(s.customersDetailTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detailKey = (shopId: shopId, customerId: widget.customerId);
    final historyKey = (shopId: shopId, customerId: widget.customerId);
    final detail = ref.watch(customerDetailProvider(detailKey));
    final history = ref.watch(customerOrderHistoryProvider(historyKey));
    final mutationsBusy = ref.watch(orderMutationsProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.customersDetailTitle),
          actions: [
            IconButton(
              onPressed: detail.value == null || mutationsBusy
                  ? null
                  : () async {
                      final customer = detail.value;
                      if (customer == null) return;
                      await context.push('/customer-edit', extra: customer);
                      if (mounted) {
                        ref
                            .read(customerDetailProvider(detailKey).notifier)
                            .refresh();
                      }
                    },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        floatingActionButton: detail.maybeWhen(
          data: (customer) => customer == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: mutationsBusy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          context.push('/order-create', extra: customer);
                        },
                  icon: const Icon(Icons.add),
                  label: Text(s.customersCreateOrder),
                ),
          orElse: () => null,
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: ordersErrorIsForbidden(e)
                ? EmptyStateWidget(
                    icon: Icons.lock_outline,
                    title: s.noPermissionTitle,
                    subtitle: s.noPermissionDesc,
                  )
                : Text(ordersUserErrorMessage(e, s)),
          ),
          data: (customer) {
            if (customer == null) {
              return EmptyStateWidget(
                icon: Icons.person_off_outlined,
                title: s.customersNotFound,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(customerDetailProvider(detailKey).notifier)
                    .refresh();
                await ref
                    .read(customerOrderHistoryProvider(historyKey).notifier)
                    .refresh();
              },
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (customer.phone != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => _callPhone(customer.phone!),
                      icon: const Icon(Icons.phone_outlined),
                      label: Text(customer.phone!),
                    ),
                  ],
                  if (customer.note != null && customer.note!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(customer.note!),
                  ],
                  TextButton(
                    onPressed: mutationsBusy ? null : () => _delete(customer),
                    child: Text(
                      s.delete,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    s.customersOrdersHistory,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (history.isLoading && history.items.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (history.error != null && history.items.isEmpty)
                    history.errorForbidden
                        ? EmptyStateWidget(
                            icon: Icons.lock_outline,
                            title: s.noPermissionTitle,
                            subtitle: s.noPermissionDesc,
                          )
                        : ErrorRetryWidget(
                            message: history.error!.isNotEmpty
                                ? history.error!
                                : s.snackbarErrorGeneric,
                            onRetry: () => ref
                                .read(
                                  customerOrderHistoryProvider(historyKey)
                                      .notifier,
                                )
                                .refresh(),
                          )
                  else if (history.items.isEmpty)
                    Text(s.ordersEmpty)
                  else ...[
                    for (final order in history.items) ...[
                      OrderCard(
                        order: order,
                        formatMoney: (v) => _fmtMoney(context, v),
                        formatDeliveryDate: (raw) => formatDateOnlyLocale(
                          raw,
                          localeTag: _localeTag(context),
                        ),
                        showDate: true,
                        onTap: () => context.push('/orders/${order.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (history.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (history.hasMore)
                      OutlinedButton(
                        onPressed: () => ref
                            .read(
                              customerOrderHistoryProvider(historyKey)
                                  .notifier,
                            )
                            .loadMore(),
                        child: Text(s.ordersLoadMore),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

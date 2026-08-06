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
import '../widgets/initials_avatar.dart';
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

  Future<void> _edit(CustomerModel customer) async {
    final shopId = ref.read(shopProvider).selected?.id;
    if (shopId == null) return;
    await context.push('/customer-edit', extra: customer);
    if (mounted) {
      ref
          .read(
            customerDetailProvider(
              (shopId: shopId, customerId: widget.customerId),
            ).notifier,
          )
          .refresh();
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.customersDeleted)));
        context.pop();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ordersUserErrorMessage(e, s))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
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
            if (detail.value != null) ...[
              IconButton(
                onPressed: mutationsBusy
                    ? null
                    : () => _edit(detail.value!),
                tooltip: s.customersEditTitle,
                icon: const Icon(Icons.edit_outlined, size: 22),
              ),
              IconButton(
                onPressed: mutationsBusy
                    ? null
                    : () => _delete(detail.value!),
                tooltip: s.delete,
                icon: Icon(Icons.delete_outline, size: 22, color: cs.error),
              ),
            ],
          ],
        ),
        floatingActionButton: detail.maybeWhen(
          data: (customer) => customer == null
              ? null
              : FloatingActionButton(
                  onPressed: mutationsBusy
                      ? null
                      : () async {
                          HapticFeedback.selectionClick();
                          await context.push('/order-create', extra: customer);
                          if (context.mounted) {
                            ref
                                .read(
                                  customerOrderHistoryProvider(
                                    historyKey,
                                  ).notifier,
                                )
                                .refresh();
                          }
                        },
                  tooltip: s.customersCreateOrder,
                  child: const Icon(Icons.add_rounded, size: 28),
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  96,
                ),
                children: [
                  _CustomerHeaderCard(
                    customer: customer,
                    onCall: _callPhone,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.customersOrdersHistory,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  if (history.isLoading && history.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
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
                                  customerOrderHistoryProvider(
                                    historyKey,
                                  ).notifier,
                                )
                                .refresh(),
                          )
                  else if (history.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        s.ordersEmpty,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
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
                        onTap: () async {
                          await context.push('/orders/${order.id}');
                          if (context.mounted) {
                            ref
                                .read(
                                  customerOrderHistoryProvider(
                                    historyKey,
                                  ).notifier,
                                )
                                .refresh();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (history.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (history.hasMore)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(
                                customerOrderHistoryProvider(
                                  historyKey,
                                ).notifier,
                              )
                              .loadMore(),
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          label: Text(s.ordersLoadMore),
                        ),
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

class _CustomerHeaderCard extends StatelessWidget {
  const _CustomerHeaderCard({required this.customer, required this.onCall});

  final CustomerModel customer;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final phone = customer.phone;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: customer.name, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onCall(phone);
                  },
                  tooltip: phone,
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary.withValues(alpha: 0.08),
                    foregroundColor: cs.primary,
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 20),
                ),
            ],
          ),
          if (customer.note != null && customer.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.note!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

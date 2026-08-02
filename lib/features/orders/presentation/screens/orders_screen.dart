import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/models/customer_order_model.dart';
import '../../domain/providers/order_provider.dart';
import '../../domain/utils/money_utils.dart';
import '../widgets/deliver_order_sheet.dart';
import '../widgets/manage_orders_guard.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderListProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void refresh() {
    ref.read(orderListProvider.notifier).refresh();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 200) {
      ref.read(orderListProvider.notifier).loadMore();
    }
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return localeTagFrom(l.languageCode, l.countryCode);
  }

  String _fmtMoney(BuildContext context, num value) {
    return formatMoneyAmount(value, localeTag: _localeTag(context));
  }

  Future<void> _openCreate() async {
    HapticFeedback.selectionClick();
    await context.push('/order-create');
    if (mounted) refresh();
  }

  Future<void> _openCustomers() async {
    HapticFeedback.selectionClick();
    await context.push('/customers');
  }

  Future<void> _openDetail(String id) async {
    await context.push('/orders/$id');
    if (mounted) refresh();
  }

  Future<void> _deliver(CustomerOrderModel order) async {
    final changed = await showDeliverOrderSheet(context, order: order);
    if (changed == true && mounted) refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final state = ref.watch(orderListProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.orders,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openCustomers,
                      icon: const Icon(Icons.people_outline),
                      label: Text(s.customersTitle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: FilledButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add),
                  label: Text(s.ordersCreate),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Row(
                  children: [
                    for (final tab in OrderDateTab.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(switch (tab) {
                            OrderDateTab.today => s.ordersTabToday,
                            OrderDateTab.tomorrow => s.ordersTabTomorrow,
                            OrderDateTab.all => s.ordersTabAll,
                          }),
                          selected: state.filters.dateTab == tab,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(orderListProvider.notifier)
                                .setFilters(
                                  state.filters.copyWith(dateTab: tab),
                                );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (state.filters.dateTab == OrderDateTab.all) ...[
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(
                    children: [
                      _StatusChip(
                        label: s.ordersFilterAll,
                        selected: state.filters.status == null,
                        onTap: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(
                              state.filters.copyWith(clearStatus: true),
                            ),
                      ),
                      _StatusChip(
                        label: s.ordersStatusActive,
                        selected:
                            state.filters.status == CustomerOrderStatus.active,
                        onTap: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(
                              state.filters.copyWith(
                                status: CustomerOrderStatus.active,
                              ),
                            ),
                      ),
                      _StatusChip(
                        label: s.ordersStatusDelivered,
                        selected:
                            state.filters.status ==
                            CustomerOrderStatus.delivered,
                        onTap: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(
                              state.filters.copyWith(
                                status: CustomerOrderStatus.delivered,
                              ),
                            ),
                      ),
                      _StatusChip(
                        label: s.ordersStatusCancelled,
                        selected:
                            state.filters.status ==
                            CustomerOrderStatus.cancelled,
                        onTap: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(
                              state.filters.copyWith(
                                status: CustomerOrderStatus.cancelled,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(orderListProvider.notifier).refresh(),
                  child: _buildBody(context, s, pad, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    S s,
    double pad,
    OrderListState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        children: const [SkeletonLoader(itemCount: 3, itemHeight: 120)],
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          state.errorForbidden
              ? EmptyStateWidget(
                  icon: Icons.lock_outline,
                  title: s.noPermissionTitle,
                  subtitle: s.noPermissionDesc,
                )
              : ErrorRetryWidget(message: state.error!, onRetry: refresh),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: s.ordersEmpty,
            subtitle: s.ordersEmptyDesc,
            actionLabel: s.ordersCreate,
            onAction: _openCreate,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final order = state.items[index];
        return OrderCard(
          order: order,
          formatMoney: (v) => _fmtMoney(context, v),
          formatDeliveryDate: (raw) =>
              formatDateOnlyLocale(raw, localeTag: _localeTag(context)),
          showDate: state.filters.dateTab == OrderDateTab.all,
          onTap: () => _openDetail(order.id),
          onDeliver: order.isActive ? () => _deliver(order) : null,
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}

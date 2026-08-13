import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/segmented_tabs.dart';
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
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final state = ref.watch(orderListProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreate,
          tooltip: s.ordersCreate,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad - 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.orders,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: _openCustomers,
                      tooltip: s.customersTitle,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary.withValues(alpha: 0.08),
                        foregroundColor: cs.primary,
                      ),
                      icon: const Icon(Icons.people_alt_outlined, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: SegmentedTabs<OrderDateTab>(
                  // Hammasi — birinchi.
                  tabs: const [
                    OrderDateTab.all,
                    OrderDateTab.today,
                    OrderDateTab.tomorrow,
                  ],
                  labelOf: (tab) => switch (tab) {
                    OrderDateTab.today => s.ordersTabToday,
                    OrderDateTab.tomorrow => s.ordersTabTomorrow,
                    OrderDateTab.all => s.ordersTabAll,
                  },
                  selected: state.filters.dateTab,
                  // Bugun/Ertagaga o'tilganda yashirin status filtri qolib
                  // ketmasligi uchun tozalaymiz.
                  onChanged: (tab) => ref
                      .read(orderListProvider.notifier)
                      .setFilters(
                        state.filters.copyWith(
                          dateTab: tab,
                          clearStatus: tab != OrderDateTab.all,
                        ),
                      ),
                ),
              ),
              if (state.filters.dateTab == OrderDateTab.all) ...[
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: s.ordersFilterAll,
                        selected: state.filters.status == null,
                        onTap: () => ref
                            .read(orderListProvider.notifier)
                            .setFilters(
                              state.filters.copyWith(clearStatus: true),
                            ),
                      ),
                      for (final status in CustomerOrderStatus.values)
                        _FilterChip(
                          label: switch (status) {
                            CustomerOrderStatus.active => s.ordersStatusActive,
                            CustomerOrderStatus.delivered =>
                              s.ordersStatusDelivered,
                            CustomerOrderStatus.cancelled =>
                              s.ordersStatusCancelled,
                          },
                          selected: state.filters.status == status,
                          onTap: () => ref
                              .read(orderListProvider.notifier)
                              .setFilters(
                                state.filters.copyWith(status: status),
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
        children: const [SkeletonLoader(itemHeight: 82)],
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
      // Pastdagi bo'shliq FAB kartani to'sib qo'ymasligi uchun.
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 96),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

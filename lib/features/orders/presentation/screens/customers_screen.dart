import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/providers/customer_provider.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/manage_orders_guard.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtl = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).loadMore();
    }
  }

  Future<void> _openCreate() async {
    HapticFeedback.selectionClick();
    await context.push('/customer-create');
    if (mounted) ref.read(customerListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final state = ref.watch(customerListProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(title: Text(s.customersTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreate,
          tooltip: s.customersNewTitle,
          child: const Icon(Icons.person_add_alt_1_outlined, size: 24),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 10),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: s.customersSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) =>
                    ref.read(customerListProvider.notifier).setSearch(v),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(customerListProvider.notifier).refresh(),
                child: _buildBody(context, s, pad, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    S s,
    double pad,
    CustomerListState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(pad),
        children: const [SkeletonLoader(itemCount: 6, itemHeight: 64)],
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
              : ErrorRetryWidget(
                  message: state.error!.isNotEmpty
                      ? state.error!
                      : s.snackbarErrorGeneric,
                  onRetry: () =>
                      ref.read(customerListProvider.notifier).refresh(),
                ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyStateWidget(
            icon: Icons.people_outline,
            title: s.customersEmpty,
            subtitle: s.customersEmptyDesc,
            actionLabel: s.customersNewTitle,
            onAction: _openCreate,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Pastdagi bo'shliq FAB oxirgi qatorni to'sib qo'ymasligi uchun.
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 96),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final customer = state.items[index];
        return _CustomerTile(
          customer: customer,
          onTap: () => context.push('/customers/${customer.id}'),
        );
      },
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final CustomerModel customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              InitialsAvatar(name: customer.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.phone!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

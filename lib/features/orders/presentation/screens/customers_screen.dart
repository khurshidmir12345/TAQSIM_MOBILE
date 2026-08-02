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
import '../../domain/providers/customer_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final state = ref.watch(customerListProvider);

    return ManageOrdersGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.customersTitle),
          actions: [
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/customer-create');
              },
              icon: const Icon(Icons.person_add_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: s.customersSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadius,
                    ),
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
        children: const [SkeletonLoader(itemCount: 2, itemHeight: 72)],
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
            onAction: () => context.push('/customer-create'),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final c = state.items[index];
        return ListTile(
          title: Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: c.phone != null ? Text(c.phone!) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/customers/${c.id}'),
        );
      },
    );
  }
}

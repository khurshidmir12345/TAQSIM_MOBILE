import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/l10n/translations.dart';
import '../../../../../core/providers/terminology_provider.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../../core/widgets/error_retry_widget.dart';
import '../../../../auth/domain/providers/auth_provider.dart';
import '../../../domain/models/production_model.dart';
import '../../../domain/providers/daily_provider.dart';
import '../production_summary_card.dart';
import 'date_divider.dart';

class ProductionHistoryTab extends ConsumerStatefulWidget {
  const ProductionHistoryTab({super.key});

  @override
  ProductionHistoryTabState createState() => ProductionHistoryTabState();
}

class ProductionHistoryTabState extends ConsumerState<ProductionHistoryTab> {
  final List<ProductionModel> _items = [];
  final ScrollController _scroll = ScrollController();
  int _page = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(_loadFirst);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  void refresh() => _loadFirst();

  Future<void> _loadFirst() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null) {
      setState(() {
        _loading = false;
        _items.clear();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _items.clear();
      _hasMore = true;
    });
    try {
      final repo = ref.read(dailyRepositoryProvider);
      final res = await repo.fetchProductionsPaginated(shop.id, page: 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page = 1;
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final shop = ref.read(shopProvider).selected;
    if (shop == null || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final repo = ref.read(dailyRepositoryProvider);
      final res =
          await repo.fetchProductionsPaginated(shop.id, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page++;
        _hasMore = res.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _fmt(BuildContext context, dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;
    final l = Localizations.localeOf(context);
    final tag = l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
    if (n == n.truncateToDouble()) {
      return NumberFormat.decimalPattern(tag).format(n);
    }
    return NumberFormat.decimalPatternDigits(
      locale: tag,
      decimalDigits: 2,
    ).format(n);
  }

  String _normDate(String d) =>
      d.length >= 10 ? d.substring(0, 10) : d.split('T').first;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final pad = Responsive.horizontalPadding(context);
    final term = ref.watch(terminologyProvider);

    if (_loading) {
      return const Center(child: AppLoading());
    }
    if (_error != null) {
      return ErrorRetryWidget(message: _error!, onRetry: _loadFirst);
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(pad + 8),
          child: Text(
            s.historyCreatedEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              height: 1.4,
                  fontSize: 15,
            ),
          ),
        ),
      );
    }

    String? lastDate;
    final children = <Widget>[];

    for (final p in _items) {
      final d = _normDate(p.date);
      if (d != lastDate) {
        children.add(HistoryDateDivider(dateIso: p.date));
        lastDate = d;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ProductionSummaryCard(
            production: p,
            fmt: (v) => _fmt(context, v),
            productUnit: term.productUnit,
            batchCountSuffix: s.dashboardBatchUnitGeneric,
          ),
        ),
      );
    }

    if (_loadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _loadFirst,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate(children),
            ),
          ),
        ],
      ),
    );
  }
}

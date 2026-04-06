import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/production_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../setup/domain/models/bread_category_model.dart';
import '../../../setup/domain/providers/setup_provider.dart';
import '../../domain/providers/daily_provider.dart';

class ReturnCreateScreen extends ConsumerStatefulWidget {
  const ReturnCreateScreen({super.key});

  @override
  ConsumerState<ReturnCreateScreen> createState() =>
      _ReturnCreateScreenState();
}

class _ReturnCreateScreenState extends ConsumerState<ReturnCreateScreen> {
  final _searchCtl = TextEditingController();
  final _quantityCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _reasonCtl = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedProductionId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(breadCategoryProvider.notifier).load();
      await ref.read(dailyReportProvider.notifier).loadToday();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _quantityCtl.dispose();
    _priceCtl.dispose();
    _reasonCtl.dispose();
    super.dispose();
  }

  String _localeTag(BuildContext context) {
    final l = Localizations.localeOf(context);
    return l.countryCode != null && l.countryCode!.isNotEmpty
        ? '${l.languageCode}_${l.countryCode}'
        : l.languageCode;
  }

  String _fmtPriceLine(BuildContext context, BreadCategoryModel c, S s) {
    final n = double.tryParse(c.sellingPrice) ?? 0;
    final tag = _localeTag(context);
    final numStr = NumberFormat.decimalPattern(tag).format(n);
    return '$numStr ${c.priceSuffix(s.currency)}';
  }

  String _moneySuffix(WidgetRef ref, S s) {
    final sym = ref.read(shopProvider).selected?.currency?.symbol;
    if (sym != null && sym.isNotEmpty) return sym;
    return s.currency;
  }

  String _todayIso() {
    return DateTime.now().toIso8601String().split('T').first;
  }

  List<ProductionModel> _productionsForCategory(String categoryId) {
    final day = _todayIso();
    final list = ref
        .read(dailyReportProvider)
        .productions
        .where(
          (p) => p.breadCategoryId == categoryId && p.date == day,
        )
        .toList();
    list.sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca != null && cb != null) {
        return cb.compareTo(ca);
      }
      return 0;
    });
    return list;
  }

  void _ensureProductionSelection(String categoryId) {
    final list = _productionsForCategory(categoryId);
    if (list.isEmpty) {
      if (_selectedProductionId != null) {
        setState(() => _selectedProductionId = null);
      }
      return;
    }
    final valid = _selectedProductionId != null &&
        list.any((p) => p.id == _selectedProductionId);
    if (!valid) {
      setState(() => _selectedProductionId = list.first.id);
    }
  }

  String _fmtBatch(BuildContext context, double n) {
    final tag = _localeTag(context);
    if (n == n.truncateToDouble()) {
      return NumberFormat.decimalPattern(tag).format(n);
    }
    return NumberFormat.decimalPatternDigits(
      locale: tag,
      decimalDigits: 2,
    ).format(n);
  }

  String _productionLine(BuildContext context, ProductionModel p, S s) {
    final unit = p.recipe?.measurementUnit?.code ?? '';
    final b = _fmtBatch(context, p.batchCount);
    return '$b $unit · ${p.breadProduced} ${s.pcs}';
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      for (final c in ref.read(breadCategoryProvider).items) {
        if (c.id == categoryId) {
          _priceCtl.text = c.sellingPrice;
          break;
        }
      }
    });
    _ensureProductionSelection(categoryId);
  }

  List<BreadCategoryModel> _visibleCategories(List<BreadCategoryModel> all) {
    final q = _searchCtl.text.trim().toLowerCase();
    List<BreadCategoryModel> list;
    if (q.isEmpty) {
      list = List<BreadCategoryModel>.from(all);
    } else {
      list = all.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategoryId != null) {
      BreadCategoryModel? sel;
      for (final c in all) {
        if (c.id == _selectedCategoryId) {
          sel = c;
          break;
        }
      }
      if (sel != null) {
        final selectedCat = sel;
        final has = list.any((c) => c.id == selectedCat.id);
        if (!has) {
          list = [selectedCat, ...list];
        }
      }
    }
    return list;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_selectedCategoryId == null) {
      _showError(s.returnValidationSelectProduct);
      return;
    }
    final qty = int.tryParse(_quantityCtl.text.trim());
    if (qty == null || qty <= 0) {
      _showError(s.returnValidationQty);
      return;
    }
    final price = double.tryParse(_priceCtl.text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0) {
      _showError(s.returnValidationPrice);
      return;
    }

    if (_selectedProductionId == null) {
      _showError(s.returnNoProductionForCategory);
      return;
    }

    setState(() => _isSaving = true);
    final shopId = ref.read(shopProvider).selected!.id;
    final today = _todayIso();

    try {
      await ref.read(dailyRepositoryProvider).createReturn(
            shopId,
            productionId: _selectedProductionId!,
            breadCategoryId: _selectedCategoryId!,
            date: today,
            quantity: qty,
            pricePerUnit: price,
            reason: _reasonCtl.text.trim().isEmpty
                ? null
                : _reasonCtl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.returnSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(dailyReportProvider.notifier).loadToday();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg =
            e is ApiException ? e.message : S.of(context).snackbarErrorGeneric;
        _showError(msg);
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final categories = ref.watch(breadCategoryProvider).items;
    final visible = _visibleCategories(categories);

    ref.listen(dailyReportProvider, (previous, next) {
      final id = _selectedCategoryId;
      if (id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureProductionSelection(id);
        });
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text(s.returnCreateTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                _ReturnInfoStrip(s: s, cs: cs),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchCtl,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: s.returnSearchHint,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: cs.primary.withValues(alpha: 0.75),
                    ),
                    suffixIcon: _searchCtl.text.isNotEmpty
                        ? IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .cancelButtonLabel,
                            onPressed: () {
                              _searchCtl.clear();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusLg),
                      borderSide:
                          BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusLg),
                      borderSide:
                          BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusLg),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  s.returnCategoryLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (categories.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: cs.primary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          s.productCategoriesEmptyTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          s.productCategoriesEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        s.returnSearchEmpty,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final c = visible[i];
                        final selected = _selectedCategoryId == c.id;
                        return _ReturnCategoryCarouselCard(
                          category: c,
                          selected: selected,
                          priceLine: _fmtPriceLine(context, c, s),
                          onTap: () => _selectCategory(c.id),
                          cs: cs,
                        );
                      },
                    ),
                  ),
                if (_selectedCategoryId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      s.returnProductionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (context) {
                      final prods =
                          _productionsForCategory(_selectedCategoryId!);
                      if (prods.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.borderRadiusLg),
                            border: Border.all(
                              color:
                                  AppColors.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  s.returnNoProductionForCategory,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.85),
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final v = _selectedProductionId != null &&
                              prods.any((p) => p.id == _selectedProductionId)
                          ? _selectedProductionId
                          : null;
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusLg,
                          ),
                          border: Border.all(
                            color: cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: v,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadiusLg,
                              ),
                              hint: Text(
                                s.returnProductionLabel,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                              items: prods
                                  .map(
                                    (p) => DropdownMenuItem<String>(
                                      value: p.id,
                                      child: Text(
                                        _productionLine(context, p, s),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (x) =>
                                  setState(() => _selectedProductionId = x),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.returnQuantityTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.returnQuantitySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? 0.2
                                : 0.06,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityCtl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              hintText: '1',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.22),
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.returnPieceSuffix,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.returnPriceLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _priceCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      suffixText: _moneySuffix(ref, s),
                      suffixStyle: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                        borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                        borderSide:
                            BorderSide(color: cs.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _reasonCtl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: s.returnReasonLabel,
                      hintText: s.returnReasonHint,
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                        borderSide: BorderSide(
                          color: cs.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                        borderSide:
                            BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          Material(
            color: cs.surface,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusLg),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.returnCta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnInfoStrip extends StatelessWidget {
  const _ReturnInfoStrip({required this.s, required this.cs});

  final S s;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.returnProfitInfoShort,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.82),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnCategoryCarouselCard extends StatelessWidget {
  const _ReturnCategoryCarouselCard({
    required this.category,
    required this.selected,
    required this.priceLine,
    required this.onTap,
    required this.cs,
  });

  final BreadCategoryModel category;
  final bool selected;
  final String priceLine;
  final VoidCallback onTap;
  final ColorScheme cs;

  static const double _cardWidth = 132;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: _cardWidth,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.1)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : cs.outline.withValues(alpha: isDark ? 0.35 : 0.22),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: cs.onSurface,
                      letterSpacing: -0.15,
                      fontSize: 13,
                    ),
              ),
              Text(
                priceLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

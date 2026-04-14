import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/models/shop_model.dart';
import '../../domain/providers/auth_provider.dart';

class ShopSelectScreen extends ConsumerStatefulWidget {
  const ShopSelectScreen({super.key});

  @override
  ConsumerState<ShopSelectScreen> createState() => _ShopSelectScreenState();
}

class _ShopSelectScreenState extends ConsumerState<ShopSelectScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopProvider.notifier).loadShops());
  }

  void _openCreate() {
    context.push('/shop-create').then((_) {
      if (mounted) ref.read(shopProvider.notifier).loadShops();
    });
  }

  void _selectShop(ShopModel shop) {
    ref.read(shopProvider.notifier).selectShop(shop);
    context.go('/shell');
  }

  void _showEditSheet(ShopModel shop) {
    final nameCtl = TextEditingController(text: shop.name);
    final addressCtl = TextEditingController(text: shop.address ?? '');
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.shopSettingsTitle,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtl,
                decoration: InputDecoration(
                  labelText: s.shopNameLabel,
                  hintText: s.shopNameHint,
                  prefixIcon: const Icon(Icons.store_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtl,
                decoration: InputDecoration(
                  labelText: s.shopAddressLabel,
                  hintText: s.shopAddressHint,
                  prefixIcon:
                      const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtl.text.trim();
                  if (name.isEmpty) return;
                  final ok = await ref.read(shopProvider.notifier).updateShop(
                        shop.id,
                        name: name,
                        address: addressCtl.text.trim().isNotEmpty
                            ? addressCtl.text.trim()
                            : null,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.shopUpdateSuccess),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Text(s.actionSave),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDelete(shop);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                label: Text(
                  s.shopDeleteButton,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(ShopModel shop) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(s.shopDeleteTitle),
        content: Text(s.shopDeleteMessage(shop.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok =
                  await ref.read(shopProvider.notifier).deleteShop(shop.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.shopDeleteSuccess),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              s.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);
    final canGoBack = shopState.selected != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  if (canGoBack)
                    IconButton(
                      onPressed: () => context.go('/shell'),
                      icon: Icon(Icons.arrow_back_rounded,
                          color: cs.onSurface),
                    ),
                  if (canGoBack) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.selectBusiness,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.selectBusinessSubtitle,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.logout_rounded,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: shopState.isLoading
                  ? const AppLoading()
                  : shopState.shops.isEmpty
                      ? _EmptyState(onCreateTap: _openCreate)
                      : _ShopList(
                          shops: shopState.shops,
                          selectedId: shopState.selected?.id,
                          onSelect: _selectShop,
                          onEdit: _showEditSheet,
                          onCreateTap: _openCreate,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(18),
              child: SvgPicture.asset(
                AppIcons.store,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.noBusiness,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.createFirstBusiness,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(s.createBusiness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopList extends StatelessWidget {
  final List<ShopModel> shops;
  final String? selectedId;
  final ValueChanged<ShopModel> onSelect;
  final ValueChanged<ShopModel> onEdit;
  final VoidCallback onCreateTap;

  const _ShopList({
    required this.shops,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: shops.length + 1,
      itemBuilder: (context, index) {
        if (index == shops.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InkWell(
              onTap: onCreateTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.addBusiness,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final shop = shops[index];
        final isCurrent = shop.id == selectedId;
        final categoryName = shop.businessType?.displayNameForLocale(
              Localizations.localeOf(context),
            ) ??
            shop.customBusinessTypeName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(shop),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : cs.outline.withValues(alpha: 0.1),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        AppIcons.store,
                        colorFilter: ColorFilter.mode(
                          isCurrent
                              ? Colors.white
                              : cs.onSurface.withValues(alpha: 0.5),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (categoryName != null &&
                              categoryName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              categoryName,
                              style: TextStyle(
                                color:
                                    cs.onSurface.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (shop.address != null &&
                              shop.address!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.35)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    shop.address!,
                                    style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(shop),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

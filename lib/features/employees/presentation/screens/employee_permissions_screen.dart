import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/providers/employee_provider.dart';

class EmployeePermissionsScreen extends ConsumerStatefulWidget {
  final EmployeeModel employee;

  const EmployeePermissionsScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeePermissionsScreen> createState() =>
      _EmployeePermissionsScreenState();
}

class _EmployeePermissionsScreenState
    extends ConsumerState<EmployeePermissionsScreen> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.employee.permissions.toSet();
  }

  static (IconData, String) _meta(S s, String key) => switch (key) {
        'view_reports' => (Icons.bar_chart_rounded, s.permViewReports),
        'manage_products' => (Icons.bakery_dining_rounded, s.permManageProducts),
        'manage_recipes' => (Icons.menu_book_rounded, s.permManageRecipes),
        'manage_production' => (Icons.precision_manufacturing_rounded, s.permManageProduction),
        'manage_expenses' => (Icons.receipt_long_rounded, s.permManageExpenses),
        'manage_sales' => (Icons.point_of_sale_rounded, s.permManageSales),
        _ => (Icons.tune_rounded, key),
      };

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : null,
        content: Text(message),
      ));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(employeesProvider.notifier)
          .updatePermissions(widget.employee.id, _selected.toList());
      if (!mounted) return;
      _snack(S.of(context).employeePermsSaved);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final s = S.of(context);
    HapticFeedback.selectionClick();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.employeeRemoveTitle),
        content: Text(s.employeeRemoveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.remove),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(employeesProvider.notifier).remove(widget.employee.id);
      if (!mounted) return;
      _snack(s.employeeRemovedMsg);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.employeePermsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _Header(employee: widget.employee),
                  const SizedBox(height: AppSpacing.md),
                  Text(s.employeePermsDesc,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < kShopPermissions.length; i++)
                          _PermissionRow(
                            permKey: kShopPermissions[i],
                            value: _selected.contains(kShopPermissions[i]),
                            showDivider: i > 0,
                            metaResolver: _meta,
                            onChanged: (v) => setState(() {
                              if (v) {
                                _selected.add(kShopPermissions[i]);
                              } else {
                                _selected.remove(kShopPermissions[i]);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: s.employeeRemoveTitle,
                    variant: AppButtonVariant.outline,
                    icon: Icons.person_remove_alt_1_rounded,
                    onPressed: _saving ? null : _remove,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: s.employeeSaveBtn,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final EmployeeModel employee;
  const _Header({required this.employee});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        employee.name.trim().isEmpty ? '?' : employee.name.trim()[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (employee.phone != null)
                Text(employee.phone!,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String permKey;
  final bool value;
  final bool showDivider;
  final (IconData, String) Function(S, String) metaResolver;
  final ValueChanged<bool> onChanged;

  const _PermissionRow({
    required this.permKey,
    required this.value,
    required this.showDivider,
    required this.metaResolver,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final (icon, label) = metaResolver(s, permKey);

    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, indent: 60, color: cs.onSurface.withValues(alpha: 0.06)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: cs.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

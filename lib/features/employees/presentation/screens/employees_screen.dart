import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/shop_features.dart';
import '../../../../core/l10n/translations.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../../core/widgets/feature_guard.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/providers/employee_provider.dart';
import 'add_employee_screen.dart';
import 'employee_permissions_screen.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      // Bo'lim yoqilmagan bo'lsa so'rov yubormaymiz — server 403 qaytaradi
      // va ro'yxat xato holatida qolib ketardi.
      if (!ref.read(hasFeatureProvider(ShopFeatures.employees))) return;
      ref.read(employeesProvider.notifier).refresh();
    });
  }

  Future<void> _openAdd() async {
    HapticFeedback.selectionClick();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
    );
    if (created == true && mounted) {
      ref.read(employeesProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(employeesProvider);

    final appBar = AppBar(
      title: Text(s.employeesTitle,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      centerTitle: true,
    );

    if (!ref.watch(hasFeatureProvider(ShopFeatures.employees))) {
      return Scaffold(
        appBar: appBar,
        body: FeatureGuard.lockedBody(s),
      );
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: state.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: _openAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(s.addEmployee),
        ),
        orElse: () => null,
      ),
      body: state.when(
        loading: () => const _EmployeesSkeleton(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.read(employeesProvider.notifier).refresh(),
        ),
        data: (employees) {
          return RefreshIndicator(
            onRefresh: () => ref.read(employeesProvider.notifier).refresh(),
            child: employees.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyStateWidget(
                        icon: Icons.groups_2_rounded,
                        title: s.employeesEmptyTitle,
                        subtitle: s.employeesEmptyDesc,
                        actionLabel: s.addEmployee,
                        onAction: _openAdd,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
                    children: [
                      for (final e in employees)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _EmployeeTile(
                            employee: e,
                            onTap: () => _openPermissions(e),
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _openPermissions(EmployeeModel e) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmployeePermissionsScreen(employee: e)),
    );
    if (mounted) ref.read(employeesProvider.notifier).refresh();
  }
}

// ─── Xodim kartochkasi ───────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;

  const _EmployeeTile({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final initial = employee.name.trim().isEmpty
        ? '?'
        : employee.name.trim()[0].toUpperCase();

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  employee.phone ?? '',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 3),
                Text(
                  '${s.employeePermsTitle}: ${employee.permissions.length}',
                  style: TextStyle(
                      fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.25)),
        ],
      ),
    );
  }
}

class _EmployeesSkeleton extends StatelessWidget {
  const _EmployeesSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(itemHeight: 88);
  }
}

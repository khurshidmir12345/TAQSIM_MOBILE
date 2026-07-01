import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
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
      if (mounted) ref.read(employeesProvider.notifier).refresh();
    });
  }

  String _money(double v) => '${NumberFormat('#,##0', 'uz').format(v)} UZS';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(s.employeesTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
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
        data: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(employeesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                _MetaCard(meta: data.meta, money: _money),
                const SizedBox(height: AppSpacing.md),
                if (data.employees.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: EmptyStateWidget(
                      icon: Icons.groups_2_rounded,
                      title: s.employeesEmptyTitle,
                      subtitle: s.employeesEmptyDesc,
                      actionLabel: s.addEmployee,
                      onAction: _openAdd,
                    ),
                  )
                else
                  ...data.employees.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _EmployeeTile(
                        employee: e,
                        onTap: () => _openPermissions(e),
                      ),
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

// ─── Meta (limit / narx) ─────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final EmployeesMeta meta;
  final String Function(double) money;

  const _MetaCard({required this.meta, required this.money});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    final String slotText;
    if (meta.unlimited) {
      slotText = s.planFeatureEmployeesUnlimited;
    } else if (meta.remaining != null && meta.remaining! > 0) {
      slotText = s.employeeFreeSlotsLeft.replaceAll('{n}', '${meta.remaining}');
    } else {
      slotText = s.employeeNoFreeSlots;
    }

    final showPaid = !meta.unlimited && (meta.remaining == null || meta.remaining! <= 0);

    return AppCard(
      color: cs.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.groups_2_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  slotText,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
          if (showPaid) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: cs.outline.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.payments_rounded,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.employeePaidPerMonth.replaceAll('{price}', money(meta.seatPriceLocal)),
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (meta.fridayDiscount) ...[
              const SizedBox(height: 6),
              _DiscountChip(
                label: s.employeeFridayDiscount
                    .replaceAll('{percent}', '${meta.fridayDiscountPercent}'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  final String label;
  const _DiscountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded, size: 13, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.gold)),
        ],
      ),
    );
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    if (employee.isPaidSeat) ...[
                      const SizedBox(width: 6),
                      _Badge(
                        label: employee.isSuspended
                            ? s.employeeSeatPastDue
                            : s.employeePaidBadge,
                        color: employee.isSuspended ? AppColors.error : AppColors.gold,
                      ),
                    ],
                  ],
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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

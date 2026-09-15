import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/models/outlet_model.dart';
import '../../domain/providers/outlet_provider.dart';
import '../widgets/outlet_avatar.dart';
import '../widgets/outlet_balance_chip.dart';
import '../widgets/outlet_entry_sheet.dart';
import '../widgets/outlet_format.dart';

/// Do'kon bilan hisob-kitob: qoldiq, jami summalar, sana filtri, daftar.
class OutletDetailScreen extends ConsumerStatefulWidget {
  const OutletDetailScreen({super.key, required this.outletId});

  final String outletId;

  @override
  ConsumerState<OutletDetailScreen> createState() => _OutletDetailScreenState();
}

class _OutletDetailScreenState extends ConsumerState<OutletDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(outletLedgerProvider(widget.outletId).notifier).load(),
    );
  }

  OutletLedgerNotifier get _notifier =>
      ref.read(outletLedgerProvider(widget.outletId).notifier);

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _addEntry(OutletEntryType type) async {
    HapticFeedback.selectionClick();
    final ok = await showOutletEntrySheet(
      context,
      outletId: widget.outletId,
      type: type,
    );
    if (ok && mounted) {
      _snack(S.of(context).outletEntrySaved);
    }
  }

  Future<void> _deleteEntry(OutletEntryModel e) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.delete,
      message: s.outletEntryDeleteBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _notifier.deleteEntry(e.id);
    } catch (err) {
      if (mounted) {
        _snack(
          err is ApiException ? err.message : s.snackbarErrorGeneric,
          error: true,
        );
      }
    }
  }

  Future<void> _deleteOutlet(OutletModel o) async {
    final s = S.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: s.outletDeleteTitle,
      message: s.outletDeleteBody(o.name),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(outletsProvider.notifier).delete(o.id);
      if (mounted) {
        context.pop();
      }
    } catch (err) {
      if (mounted) {
        _snack(
          err is ApiException ? err.message : s.snackbarErrorGeneric,
          error: true,
        );
      }
    }
  }

  Future<void> _pickRange(OutletLedgerState st) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: st.from != null && st.to != null
          ? DateTimeRange(start: st.from!, end: st.to!)
          : null,
    );
    if (picked != null && mounted) {
      await _notifier.setRange(picked.start, picked.end);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final st = ref.watch(outletLedgerProvider(widget.outletId));
    // Ro'yxatdagi nusxa — daftar hali yuklanmaguncha nom/rasm shu yerdan.
    final listed = ref
        .watch(outletsProvider)
        .items
        .where((o) => o.id == widget.outletId)
        .firstOrNull;
    final outlet = st.outlet ?? listed;
    final cur = outletCurrency(ref, s);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: outlet == null
            ? const SizedBox.shrink()
            : Row(
                children: [
                  OutletAvatar(
                    name: outlet.name,
                    imageUrl: outlet.imageUrl,
                    size: 34,
                    radius: 10,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      outlet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          if (outlet != null)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  final updated = await context.push<OutletModel>(
                    '/outlets/${outlet.id}/edit',
                    extra: outlet,
                  );
                  if (updated != null) _notifier.load();
                } else if (v == 'delete') {
                  _deleteOutlet(outlet);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(s.outletEdit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.delete,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: outlet == null
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _notifier.load,
              color: cs.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _SummaryCard(outlet: outlet, currency: cur),
                  if (outlet.phones.isNotEmpty ||
                      (outlet.address?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (outlet.address?.isNotEmpty ?? false)
                          _InfoChip(
                            icon: Icons.place_outlined,
                            label: outlet.address!,
                          ),
                        for (final p in outlet.phones)
                          _InfoChip(
                            icon: Icons.call_outlined,
                            label: p,
                            onTap: () => _call(p),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  // ── Sana filtri ──
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickRange(st),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: st.isFiltered
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : cs.surfaceContainerHighest.withValues(
                                      alpha: 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: st.isFiltered
                                    ? AppColors.primary
                                    : cs.outline.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: st.isFiltered
                                      ? AppColors.primary
                                      : cs.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.isFiltered
                                        ? '${outletDateLabelOf(context, st.from!)} — ${outletDateLabelOf(context, st.to!)}'
                                        : s.outletFilterAll,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: st.isFiltered
                                          ? AppColors.primary
                                          : cs.onSurface,
                                    ),
                                  ),
                                ),
                                if (st.isFiltered)
                                  GestureDetector(
                                    onTap: () => _notifier.setRange(null, null),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (st.isLoading && st.entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppLoading(),
                    )
                  else if (st.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.outletLedgerEmpty,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._buildLedger(context, s, cs, st.entries, cur),
                ],
              ),
            ),
      bottomNavigationBar: outlet == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outline.withValues(alpha: 0.1)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: FilledButton.icon(
                          onPressed: () => _addEntry(OutletEntryType.delivery),
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                          ),
                          label: Text(s.outletActionDeliver),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: _TonalButton(
                          icon: Icons.undo_rounded,
                          label: s.outletActionReturn,
                          color: AppColors.warning,
                          onTap: () => _addEntry(OutletEntryType.returned),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: _TonalButton(
                          icon: Icons.payments_outlined,
                          label: s.outletActionPay,
                          color: AppColors.success,
                          onTap: () => _addEntry(OutletEntryType.payment),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Sana bo'yicha guruhlab chizadi.
  List<Widget> _buildLedger(
    BuildContext context,
    S s,
    ColorScheme cs,
    List<OutletEntryModel> entries,
    String cur,
  ) {
    final out = <Widget>[];
    String? lastDate;
    for (final e in entries) {
      if (e.date != lastDate) {
        lastDate = e.date;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              outletDateLabel(context, e.date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      }
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EntryTile(
            entry: e,
            currency: cur,
            onDelete: () => _deleteEntry(e),
          ),
        ),
      );
    }
    return out;
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.outlet, required this.currency});

  final OutletModel outlet;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = outlet.totals;
    final (_, label) = outletBalanceStyle(s, t);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cell(String title, double v, IconData icon) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              outletMoney(context, v),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? AppColors.cardGradientDark : AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.outletBalance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  outletMoney(context, t.balance.abs()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currency,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          Row(
            children: [
              cell(
                s.outletDelivered,
                t.delivered,
                Icons.local_shipping_outlined,
              ),
              cell(s.outletReturned, t.returned, Icons.undo_rounded),
              cell(s.outletPaid, t.paid, Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: onTap != null
                    ? AppColors.primary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: onTap != null
                        ? AppColors.primary
                        : cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TonalButton extends StatelessWidget {
  const _TonalButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar qatori: tur ikonkasi, mahsulotlar, summa; uzoq bosib o'chirish.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.currency,
    required this.onDelete,
  });

  final OutletEntryModel entry;
  final String currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final e = entry;

    final (title, color, icon, sign) = switch (e.type) {
      OutletEntryType.delivery => (
        s.outletEntryDelivery,
        AppColors.primary,
        Icons.local_shipping_outlined,
        '+',
      ),
      OutletEntryType.returned => (
        s.outletEntryReturn,
        AppColors.warning,
        Icons.undo_rounded,
        '−',
      ),
      OutletEntryType.payment => (
        e.isCashOnDelivery ? s.outletEntryCashOnDelivery : s.outletEntryPayment,
        AppColors.success,
        Icons.payments_outlined,
        '−',
      ),
    };

    final itemsLine = e.items
        .map((i) => '${i.name} × ${outletQty(context, i.quantity)}')
        .join(' · ');
    final sub = [itemsLine, e.note ?? ''].where((x) => x.isNotEmpty).join('\n');

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${outletMoney(context, e.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

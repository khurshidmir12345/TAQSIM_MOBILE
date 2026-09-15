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
        title: Text(
          outlet?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        scrolledUnderElevation: 0,
        actions: [
          if (outlet != null) ...[
            IconButton(
              tooltip: s.outletEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await context.push<OutletModel>(
                  '/outlets/${outlet.id}/edit',
                  extra: outlet,
                );
                if (updated != null) _notifier.load();
              },
            ),
            IconButton(
              tooltip: s.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _deleteOutlet(outlet),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: outlet == null
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _notifier.load,
              color: cs.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _HeaderCard(outlet: outlet, currency: cur, onCall: _call),
                  const SizedBox(height: 14),
                  _RangeBar(
                    state: st,
                    onPick: () => _pickRange(st),
                    onClear: () => _notifier.setRange(null, null),
                  ),
                  const SizedBox(height: 6),
                  if (st.isLoading && st.entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppLoading(),
                    )
                  else if (st.entries.isEmpty)
                    _LedgerEmpty(text: s.outletLedgerEmpty)
                  else
                    ..._buildLedger(context, cs, st.entries),
                ],
              ),
            ),
      bottomNavigationBar: outlet == null
          ? null
          : _ActionDock(
              onDeliver: () => _addEntry(OutletEntryType.delivery),
              onReturn: () => _addEntry(OutletEntryType.returned),
              onPay: () => _addEntry(OutletEntryType.payment),
            ),
    );
  }

  /// Sana bo'yicha guruhlab chizadi.
  List<Widget> _buildLedger(
    BuildContext context,
    ColorScheme cs,
    List<OutletEntryModel> entries,
  ) {
    final out = <Widget>[];
    String? lastDate;
    for (final e in entries) {
      if (e.date != lastDate) {
        lastDate = e.date;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
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
          child: _EntryTile(entry: e, onDelete: () => _deleteEntry(e)),
        ),
      );
    }
    return out;
  }
}

// ─── Sarlavha kartasi ───────────────────────────────────────────────────

/// Oq karta: do'kon, aloqa, qoldiq (ishora va rang bilan), uch ko'rsatkich.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.outlet,
    required this.currency,
    required this.onCall,
  });

  final OutletModel outlet;
  final String currency;
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = outlet.totals;
    final (color, label, sign) = outletBalanceStyle(context, s, t);
    final address = outlet.address?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutletAvatar(
                name: outlet.name,
                imageUrl: outlet.imageUrl,
                size: 52,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (outlet.phones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in outlet.phones)
                  _PhonePill(phone: p, onTap: () => onCall(p)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                s.outletBalance,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$sign${outletMoney(context, t.balance.abs())}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _StatCell(
                  label: s.outletDelivered,
                  value: outletMoney(context, t.delivered),
                  color: AppColors.primary,
                ),
                _StatDivider(cs: cs),
                _StatCell(
                  label: s.outletReturned,
                  value: outletMoney(context, t.returned),
                  color: AppColors.warning,
                ),
                _StatDivider(cs: cs),
                _StatCell(
                  label: s.outletPaid,
                  value: outletMoney(context, t.paid),
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: cs.outline.withValues(alpha: 0.15),
    );
  }
}

class _PhonePill extends StatelessWidget {
  const _PhonePill({required this.phone, required this.onTap});

  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.call_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sana filtri ─────────────────────────────────────────────────────────

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.state,
    required this.onPick,
    required this.onClear,
  });

  final OutletLedgerState state;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final active = state.isFiltered;
    final text = active
        ? '${outletDateLabelOf(context, state.from!)} — ${outletDateLabelOf(context, state.to!)}'
        : s.outletFilterAll;

    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.08)
          : cs.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: active
                    ? AppColors.primary
                    : cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primary : cs.onSurface,
                  ),
                ),
              ),
              if (active)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
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
    );
  }
}

class _LedgerEmpty extends StatelessWidget {
  const _LedgerEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: cs.onSurface.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pastki amallar ──────────────────────────────────────────────────────

/// Uchta bir xil o'lchamli amal: ikonka ustida, yorliq ostida. Asosiysi
/// (Berish) to'ldirilgan, qolgan ikkisi yumshoq fonda.
class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.onDeliver,
    required this.onReturn,
    required this.onPay,
  });

  final VoidCallback onDeliver;
  final VoidCallback onReturn;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
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
                child: _DockButton(
                  icon: Icons.local_shipping_outlined,
                  label: s.outletActionDeliver,
                  color: AppColors.primary,
                  filled: true,
                  onTap: onDeliver,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DockButton(
                  icon: Icons.undo_rounded,
                  label: s.outletActionReturn,
                  color: AppColors.warning,
                  onTap: onReturn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DockButton(
                  icon: Icons.payments_outlined,
                  label: s.outletActionPay,
                  color: AppColors.success,
                  onTap: onPay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Daftar qatori ───────────────────────────────────────────────────────

/// Tur ikonkasi, mahsulotlar, summa. Uzoq bosib o'chiriladi.
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});

  final OutletEntryModel entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final e = entry;

    final (title, color, icon) = switch (e.type) {
      OutletEntryType.delivery => (
        s.outletEntryDelivery,
        AppColors.primary,
        Icons.local_shipping_outlined,
      ),
      OutletEntryType.returned => (
        s.outletEntryReturn,
        AppColors.warning,
        Icons.undo_rounded,
      ),
      OutletEntryType.payment => (
        e.isCashOnDelivery ? s.outletEntryCashOnDelivery : s.outletEntryPayment,
        AppColors.success,
        Icons.payments_outlined,
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
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
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
                outletMoney(context, e.amount),
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

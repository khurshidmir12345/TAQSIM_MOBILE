import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';

enum PeriodType { daily, weekly, monthly }

class PeriodSelector extends StatefulWidget {
  const PeriodSelector({
    super.key,
    required this.onChanged,
    this.initialPeriod = PeriodType.daily,
  });

  final void Function(PeriodType period, DateTime from, DateTime to) onChanged;
  final PeriodType initialPeriod;

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late PeriodType _period;
  int _selectedIndex = 0;
  final ScrollController _scrollCtl = ScrollController();

  late final DateTime _today;
  late final List<DateTime> _days;
  late final List<DateTimeRange> _weeks;
  late final List<DateTimeRange> _months;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _generate();
    _selectedIndex = _lastIdx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTo(_selectedIndex, animate: false);
      _fire();
    });
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  void _generate() {
    _days = List.generate(
      30,
      (i) => _today.subtract(Duration(days: 29 - i)),
    );

    final anchor = DateTime(_today.year, _today.month - 2, _today.day);
    var mon = anchor.subtract(Duration(days: anchor.weekday - 1));
    _weeks = [];
    while (!mon.isAfter(_today)) {
      _weeks.add(DateTimeRange(
        start: mon,
        end: mon.add(const Duration(days: 6)),
      ));
      mon = mon.add(const Duration(days: 7));
    }

    _months = List.generate(12, (i) {
      final f = DateTime(_today.year, _today.month - 11 + i, 1);
      return DateTimeRange(start: f, end: DateTime(f.year, f.month + 1, 0));
    });
  }

  int get _lastIdx {
    switch (_period) {
      case PeriodType.daily:
        return _days.length - 1;
      case PeriodType.weekly:
        return _weeks.length - 1;
      case PeriodType.monthly:
        return _months.length - 1;
    }
  }

  int get _count {
    switch (_period) {
      case PeriodType.daily:
        return _days.length;
      case PeriodType.weekly:
        return _weeks.length;
      case PeriodType.monthly:
        return _months.length;
    }
  }

  double get _chipW {
    switch (_period) {
      case PeriodType.daily:
        return 52;
      case PeriodType.weekly:
        return 100;
      case PeriodType.monthly:
        return 76;
    }
  }

  void _switchPeriod(Set<PeriodType> s) {
    final t = s.first;
    if (_period == t) return;
    setState(() {
      _period = t;
      _selectedIndex = _lastIdx;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTo(_selectedIndex, animate: false);
      _fire();
    });
  }

  void _tap(int i) {
    if (_selectedIndex == i) return;
    setState(() => _selectedIndex = i);
    _fire();
    _scrollTo(i);
  }

  DateTime _clippedEnd(DateTime d) => d.isAfter(_today) ? _today : d;

  void _fire() {
    switch (_period) {
      case PeriodType.daily:
        final d = _days[_selectedIndex];
        widget.onChanged(PeriodType.daily, d, d);
      case PeriodType.weekly:
        final r = _weeks[_selectedIndex];
        widget.onChanged(PeriodType.weekly, r.start, _clippedEnd(r.end));
      case PeriodType.monthly:
        final r = _months[_selectedIndex];
        widget.onChanged(PeriodType.monthly, r.start, _clippedEnd(r.end));
    }
  }

  void _scrollTo(int i, {bool animate = true}) {
    if (!_scrollCtl.hasClients) return;
    final gap = AppSpacing.sm;
    final pos = i * (_chipW + gap);
    final vp = _scrollCtl.position.viewportDimension;
    final max = _scrollCtl.position.maxScrollExtent;
    final target = (pos - vp / 2 + _chipW / 2).clamp(0.0, max);
    if (animate) {
      _scrollCtl.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollCtl.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 10),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<PeriodType>(
              segments: [
                ButtonSegment(
                  value: PeriodType.daily,
                  label: Text(s.daily),
                ),
                ButtonSegment(
                  value: PeriodType.weekly,
                  label: Text(s.weekly),
                ),
                ButtonSegment(
                  value: PeriodType.monthly,
                  label: Text(s.monthly),
                ),
              ],
              selected: {_period},
              onSelectionChanged: _switchPeriod,
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            key: ValueKey(_period),
            controller: _scrollCtl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: pad),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemCount: _count,
            itemBuilder: _tile,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _tile(BuildContext context, int i) {
    final cs = Theme.of(context).colorScheme;
    final sel = i == _selectedIndex;
    final loc = Localizations.localeOf(context).toLanguageTag();

    switch (_period) {
      case PeriodType.daily:
        return _dailyTile(i, sel, cs, loc);
      case PeriodType.weekly:
        return _weeklyTile(i, sel, cs, loc);
      case PeriodType.monthly:
        return _monthlyTile(i, sel, cs, loc);
    }
  }

  Widget _dailyTile(int i, bool sel, ColorScheme cs, String loc) {
    final d = _days[i];
    final isToday = d == _today;

    return _Chip(
      width: _chipW,
      selected: sel,
      onTap: () => _tap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${d.day}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: sel ? cs.onPrimary : cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat.E(loc).format(d),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: sel
                  ? cs.onPrimary.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (isToday)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? cs.onPrimary : cs.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weeklyTile(int i, bool sel, ColorScheme cs, String loc) {
    final r = _weeks[i];
    final cross =
        r.start.month != r.end.month || r.start.year != r.end.year;
    final range = '${r.start.day} – ${r.end.day}';
    final month = cross
        ? '${DateFormat.MMM(loc).format(r.start)} – ${DateFormat.MMM(loc).format(r.end)}'
        : DateFormat.MMM(loc).format(r.start);

    return _Chip(
      width: _chipW,
      selected: sel,
      onTap: () => _tap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            range,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: sel ? cs.onPrimary : cs.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            month,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: sel
                  ? cs.onPrimary.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyTile(int i, bool sel, ColorScheme cs, String loc) {
    final r = _months[i];

    return _Chip(
      width: _chipW,
      selected: sel,
      onTap: () => _tap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.MMM(loc).format(r.start),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: sel ? cs.onPrimary : cs.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${r.start.year}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: sel
                  ? cs.onPrimary.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.width,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.surfaceContainerHighest
                  .withValues(alpha: isDark ? 0.5 : 0.7),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? null
              : Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: child,
      ),
    );
  }
}

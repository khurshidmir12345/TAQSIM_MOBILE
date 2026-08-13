import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/domain/providers/daily_provider.dart';
import '../models/statistics_model.dart';

/// Statistika sahifasidagi davr tanlovi — kassa sahifasidagi bilan bir xil.
enum StatsPeriod { all, month, day }

/// Tanlangan davr. Sahifadan alohida saqlanadi, chunki ma'lumot provideri
/// unga qarab qayta yuklanadi.
final statsPeriodProvider =
    NotifierProvider<StatsPeriodNotifier, StatsPeriod>(StatsPeriodNotifier.new);

class StatsPeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.month;

  void set(StatsPeriod period) => state = period;
}

final statisticsProvider =
    AsyncNotifierProvider<StatisticsNotifier, StatisticsModel>(
  StatisticsNotifier.new,
);

class StatisticsNotifier extends AsyncNotifier<StatisticsModel> {
  Future<StatisticsModel> _fetch() {
    final shopId = ref.watch(shopProvider).selected?.id;

    if (shopId == null) {
      return Future.value(const StatisticsModel());
    }

    final period = ref.watch(statsPeriodProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // "Barchasi" da boshlanish sanasini server o'zi aniqlaydi — ilova
    // do'kondagi birinchi yozuv qachonligini bilmaydi.
    final (from, to) = switch (period) {
      StatsPeriod.all => (null, null),
      StatsPeriod.month => (DateTime(now.year, now.month), today),
      StatsPeriod.day => (today, today),
    };

    return ref.read(dailyRepositoryProvider).getStatistics(
          shopId,
          from: from == null ? null : _ymd(from),
          to: to == null ? null : _ymd(to),
          period: period == StatsPeriod.all ? 'all' : null,
        );
  }

  static String _ymd(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<StatisticsModel> build() => _fetch();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/domain/providers/daily_provider.dart';
import '../models/statistics_model.dart';

/// Statistika sahifasi ma'lumotlari — oxirgi 30 kun.
///
/// Davr tanlagichi yo'q: sahifa ataylab sodda, grafikning o'zi sanalarni
/// ko'rsatadi. Do'kon almashtirilsa provider o'zi qayta yuklanadi.
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

    return ref.read(dailyRepositoryProvider).getStatistics(shopId);
  }

  @override
  Future<StatisticsModel> build() => _fetch();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

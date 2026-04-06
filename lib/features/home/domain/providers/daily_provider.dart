import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/daily_repository.dart';
import '../models/bread_return_model.dart';
import '../models/daily_report_model.dart';
import '../models/production_model.dart';

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.read(apiClientProvider));
});

String _shopId(Ref ref) => ref.read(shopProvider).selected!.id;

class DailyReportState {
  final DailyReportModel? report;
  final List<ProductionModel> productions;
  final List<BreadReturnModel> returns;
  final bool isLoading;
  final String? error;
  final String? selectedDate;

  const DailyReportState({
    this.report,
    this.productions = const [],
    this.returns = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
  });

  DailyReportState copyWith({
    DailyReportModel? report,
    List<ProductionModel>? productions,
    List<BreadReturnModel>? returns,
    bool? isLoading,
    String? error,
    String? selectedDate,
  }) {
    return DailyReportState(
      report: report ?? this.report,
      productions: productions ?? this.productions,
      returns: returns ?? this.returns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DailyReportNotifier extends Notifier<DailyReportState> {
  @override
  DailyReportState build() => const DailyReportState();

  DailyRepository get _repo => ref.read(dailyRepositoryProvider);

  Future<void> loadToday() async {
    final date = DateTime.now().toIso8601String().split('T').first;
    await loadDate(date);
  }

  Future<void> loadDate(String date) async {
    final shopId = _shopId(ref);
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);
    try {
      final results = await Future.wait([
        _repo.getDailyReport(shopId, date),
        _repo.getProductions(shopId, date),
        _repo.getReturns(shopId, date),
      ]);
      state = state.copyWith(
        report: results[0] as DailyReportModel,
        productions: results[1] as List<ProductionModel>,
        returns: results[2] as List<BreadReturnModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dailyReportProvider =
    NotifierProvider<DailyReportNotifier, DailyReportState>(DailyReportNotifier.new);

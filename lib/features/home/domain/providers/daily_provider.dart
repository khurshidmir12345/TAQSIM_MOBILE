import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/daily_repository.dart';
import '../models/bread_return_model.dart';
import '../models/daily_report_model.dart';
import '../models/expense_model.dart';
import '../models/production_model.dart';

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.read(apiClientProvider));
});

String _shopId(Ref ref) => ref.read(shopProvider).selected!.id;

class DailyReportState {
  final DailyReportModel? report;
  final List<ProductionModel> productions;
  final List<BreadReturnModel> returns;
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? error;
  final String? selectedDate;

  const DailyReportState({
    this.report,
    this.productions = const [],
    this.returns = const [],
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
  });

  DailyReportState copyWith({
    DailyReportModel? report,
    List<ProductionModel>? productions,
    List<BreadReturnModel>? returns,
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? error,
    String? selectedDate,
  }) {
    return DailyReportState(
      report: report ?? this.report,
      productions: productions ?? this.productions,
      returns: returns ?? this.returns,
      expenses: expenses ?? this.expenses,
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

  /// Removes an expense from local state immediately so the UI can show
  /// optimistic updates while a network call is in flight.
  void removeExpenseLocally(String expenseId) {
    final updated = state.expenses.where((e) => e.id != expenseId).toList();
    state = state.copyWith(expenses: updated);
  }

  /// Re-inserts an expense into local state (used when an optimistic delete
  /// is undone or when the server rejects the operation).
  void restoreExpenseLocally(ExpenseModel expense) {
    if (state.expenses.any((e) => e.id == expense.id)) return;
    final next = [...state.expenses, expense]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    state = state.copyWith(expenses: next);
  }

  /// Replaces an expense in local state after a successful update.
  void replaceExpenseLocally(ExpenseModel expense) {
    final next = state.expenses
        .map((e) => e.id == expense.id ? expense : e)
        .toList();
    state = state.copyWith(expenses: next);
  }

  Future<void> loadDate(String date) async {
    final shopId = _shopId(ref);
    final locale = ref.read(localeProvider).value?.code ?? AppLocale.uz.code;
    state = state.copyWith(isLoading: true, selectedDate: date);
    try {
      final results = await Future.wait([
        _repo.getDailyReport(shopId, date),
        _repo.getProductions(shopId, date),
        _repo.getReturns(shopId, date),
        _repo.getExpenses(shopId, date, locale: locale),
      ]);
      state = state.copyWith(
        report: results[0] as DailyReportModel,
        productions: results[1] as List<ProductionModel>,
        returns: results[2] as List<BreadReturnModel>,
        expenses: results[3] as List<ExpenseModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dailyReportProvider =
    NotifierProvider<DailyReportNotifier, DailyReportState>(DailyReportNotifier.new);

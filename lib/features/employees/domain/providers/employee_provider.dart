import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../../auth/domain/providers/shop_provider.dart';
import '../../data/employee_repository.dart';
import '../models/employee_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.read(apiClientProvider));
});

/// Joriy do'kon xodimlari. Faqat owner uchun ishlatiladi.
class EmployeesNotifier extends AsyncNotifier<List<EmployeeModel>> {
  EmployeeRepository get _repo => ref.read(employeeRepositoryProvider);

  String get _shopId {
    final id = ref.read(shopProvider).selected?.id;
    if (id == null) {
      throw StateError('No shop selected');
    }
    return id;
  }

  @override
  Future<List<EmployeeModel>> build() => _load();

  Future<List<EmployeeModel>> _load() => _repo.getEmployees(_shopId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> startInvite({
    required String name,
    required String phone,
    required String password,
  }) {
    return _repo.startInvite(_shopId, name: name, phone: phone, password: password);
  }

  Future<EmployeeModel> confirm({required String phone, required String code}) async {
    final employee = await _repo.confirm(_shopId, phone: phone, code: code);
    await refresh();
    return employee;
  }

  Future<EmployeeModel> updatePermissions(String employeeId, List<String> permissions) async {
    final updated = await _repo.updatePermissions(_shopId, employeeId, permissions);
    await refresh();
    return updated;
  }

  Future<void> remove(String employeeId) async {
    await _repo.remove(_shopId, employeeId);
    await refresh();
  }
}

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, List<EmployeeModel>>(EmployeesNotifier.new);

/// App ichidagi barcha modul ruxsatlari (UI toggle uchun tartibda).
const kShopPermissions = <String>[
  'view_reports',
  'manage_products',
  'manage_recipes',
  'manage_production',
  'manage_expenses',
  'manage_sales',
];

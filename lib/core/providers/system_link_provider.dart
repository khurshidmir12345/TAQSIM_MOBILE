import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_provider.dart';
import '../models/system_link_model.dart';

/// API dan system_links ni oladi va session davomida keshlab saqlaydi.
final systemLinksProvider =
    AsyncNotifierProvider<SystemLinksNotifier, List<SystemLinkModel>>(
  SystemLinksNotifier.new,
);

class SystemLinksNotifier extends AsyncNotifier<List<SystemLinkModel>> {
  @override
  Future<List<SystemLinkModel>> build() => _fetch();

  Future<List<SystemLinkModel>> _fetch() async {
    final client = ref.read(apiClientProvider);
    try {
      final response = await client.dio.get('/v1/system-links');
      final data = response.data as Map<String, dynamic>;
      final list = (data['data']?['links'] as List?) ?? [];
      return list
          .map((e) => SystemLinkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Berilgan type bo'yicha URL ni qaytaradi. Topilmasa null.
extension SystemLinksRef on WidgetRef {
  String? systemLinkUrl(String type) {
    final links = watch(systemLinksProvider).asData?.value ?? [];
    try {
      return links.firstWhere((l) => l.type == type).url;
    } catch (_) {
      return null;
    }
  }
}

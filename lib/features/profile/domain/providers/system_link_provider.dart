import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/system_link_repository.dart';
import '../models/system_link_model.dart';

final systemLinkRepositoryProvider = Provider<SystemLinkRepository>((ref) {
  return SystemLinkRepository(ref.read(apiClientProvider));
});

/// Profil ekrani "Aloqa" bo'limida ko'rsatiladigan tashqi havolalar.
///
/// Backend kamroq o'zgaradi — natijani 10 daqiqa keshlash kifoya. Foydalanuvchi
/// ekranga har kirganda invalidate qilinmasin: provider'ni AsyncNotifier emas,
/// oddiy `FutureProvider` qilamiz va orqali butun ilova davomida bir marta
/// olamiz. Xato bo'lsa AsyncValue.error qaytadi va UI uni jim o'tkazib yuboradi.
final systemLinksProvider =
    FutureProvider<List<SystemLinkModel>>((ref) async {
  return ref.read(systemLinkRepositoryProvider).getAll();
});

/// Berilgan turdagi (telegram/instagram/youtube/support/...) birinchi faol
/// havola; topilmasa null. UI bunga qarab tugmani ko'rsatadi yoki yashiradi.
SystemLinkModel? findSystemLink(
  List<SystemLinkModel> links,
  String type,
) {
  for (final l in links) {
    if (l.type == type && l.url.trim().isNotEmpty) return l;
  }
  return null;
}

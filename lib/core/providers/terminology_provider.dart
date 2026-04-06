import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/models/business_type_model.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../l10n/app_locale.dart';

/// Returns the BusinessTerminology for the currently selected shop.
/// Falls back to default if no shop is selected or shop has no business type.
final terminologyProvider = Provider<BusinessTerminology>((ref) {
  final shop   = ref.watch(shopProvider).selected;
  final locale = ref.watch(localeProvider).value ?? AppLocale.uz;
  return shop?.terminology(locale.code) ?? BusinessTerminology.defaultTerminology;
});

/// Shorthand: raw material name (e.g. "Un", "Go'sht")
final termRawMaterialProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).rawMaterial,
);

/// Shorthand: batch unit label (e.g. "qop", "partiya")
final termBatchUnitProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).batchUnit,
);

/// Shorthand: batch group label (e.g. "Qoplar", "Partiyalar")
final termBatchLabelProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).batchLabel,
);

/// Shorthand: product unit (e.g. "dona", "porsiya")
final termProductUnitProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).productUnit,
);

/// Shorthand: product label (e.g. "Mahsulot", "Taom")
final termProductLabelProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).productLabel,
);

/// Shorthand: production verb (e.g. "yopildi", "tayyorlandi")
final termProductionVerbProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).productionVerb,
);

/// Shorthand: category label (e.g. "Non turi", "Taom turi")
final termCategoryLabelProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).categoryLabel,
);

/// Shorthand: recipe label (e.g. "Retsept", "Tarkib")
final termRecipeLabelProvider = Provider<String>(
  (ref) => ref.watch(terminologyProvider).recipeLabel,
);

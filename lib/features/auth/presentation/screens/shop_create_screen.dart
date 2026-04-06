import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/business_type_model.dart';
import '../../domain/models/currency_model.dart';
import '../../domain/providers/auth_provider.dart';

enum _Step { category, details, location }

class ShopCreateScreen extends ConsumerStatefulWidget {
  const ShopCreateScreen({super.key});

  @override
  ConsumerState<ShopCreateScreen> createState() => _ShopCreateScreenState();
}

class _ShopCreateScreenState extends ConsumerState<ShopCreateScreen>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.category;

  BusinessTypeModel? _selectedType;
  final _customTypeCtl = TextEditingController();

  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _nameKey = GlobalKey<FormState>();

  String? _selectedCurrencyId;

  final _addressCtl = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;

  bool _isLoading = false;
  String? _error;

  late final AnimationController _animCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _customTypeCtl.dispose();
    _nameCtl.dispose();
    _descCtl.dispose();
    _addressCtl.dispose();
    _animCtl.dispose();
    super.dispose();
  }

  void _nextStep() {
    final steps = _Step.values;
    final idx = steps.indexOf(_step);
    if (idx < steps.length - 1) {
      _animCtl.reset();
      setState(() => _step = steps[idx + 1]);
      _animCtl.forward();
    }
  }

  void _prevStep() {
    final steps = _Step.values;
    final idx = steps.indexOf(_step);
    if (idx > 0) {
      _animCtl.reset();
      setState(() => _step = steps[idx - 1]);
      _animCtl.forward();
    } else {
      context.pop();
    }
  }

  String _stepTitle(S s) => switch (_step) {
        _Step.category => s.businessTypeStep,
        _Step.details => s.businessDetailsStep,
        _Step.location => s.businessLocationStep,
      };

  Future<void> _submit() async {
    if (_selectedType == null || _selectedCurrencyId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(shopProvider.notifier).createShop(
            businessTypeId: _selectedType!.id,
            currencyId: _selectedCurrencyId!,
            name: _nameCtl.text.trim(),
            customBusinessTypeName: _selectedType!.key == 'other'
                ? _customTypeCtl.text.trim()
                : null,
            description:
                _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
            address: _addressCtl.text.trim().isEmpty
                ? null
                : _addressCtl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
          );
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/shell');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _latitude = 41.2995;
        _longitude = 69.2401;
        _fetchingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = _Step.values;
    final stepIdx = steps.indexOf(_step);
    final progress = (stepIdx + 1) / steps.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(
              title: _stepTitle(s),
              stepIndex: stepIdx,
              totalSteps: steps.length,
              progress: progress,
              onBack: _prevStep,
            ),
            Expanded(
              child: FadeTransition(
                opacity: _animCtl,
                child: _buildStep(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(S s) {
    return switch (_step) {
      _Step.category => _CategoryStep(
          selected: _selectedType,
          customCtl: _customTypeCtl,
          onSelect: (t) => setState(() => _selectedType = t),
          onNext: () {
            if (_selectedType == null) return;
            _nextStep();
          },
        ),
      _Step.details => _DetailsStep(
          nameCtl: _nameCtl,
          descCtl: _descCtl,
          formKey: _nameKey,
          selectedCurrencyId: _selectedCurrencyId,
          onCurrencyChanged: (id) => setState(() => _selectedCurrencyId = id),
          onNext: () {
            if (!_nameKey.currentState!.validate()) return;
            final list = ref.read(currenciesProvider).when(
                  data: (d) => d,
                  loading: () => <CurrencyModel>[],
                  error: (_, _) => <CurrencyModel>[],
                );
            if (list.isEmpty) return;
            var id = _selectedCurrencyId;
            if (id == null) {
              for (final c in list) {
                if (c.code == 'UZS') {
                  id = c.id;
                  break;
                }
              }
              id ??= list.first.id;
              setState(() => _selectedCurrencyId = id);
            }
            _nextStep();
          },
        ),
      _Step.location => _LocationStep(
          addressCtl: _addressCtl,
          latitude: _latitude,
          longitude: _longitude,
          fetchingLocation: _fetchingLocation,
          isLoading: _isLoading,
          error: _error,
          onFetchLocation: _fetchLocation,
          onSubmit: _submit,
        ),
    };
  }
}

class _WizardHeader extends StatelessWidget {
  final String title;
  final int stepIndex;
  final int totalSteps;
  final double progress;
  final VoidCallback onBack;

  const _WizardHeader({
    required this.title,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient(brightness),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${stepIndex + 1}/$totalSteps',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor:
                    Colors.white.withValues(alpha: isDark ? 0.15 : 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStep extends ConsumerWidget {
  final BusinessTypeModel? selected;
  final TextEditingController customCtl;
  final ValueChanged<BusinessTypeModel> onSelect;
  final VoidCallback onNext;

  const _CategoryStep({
    required this.selected,
    required this.customCtl,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final typesAsync = ref.watch(businessTypesProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString()),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(businessTypesProvider),
              child: Text(s.tryAgain),
            ),
          ],
        ),
      ),
      data: (types) {
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _StepHint(
                    icon: '🏢',
                    title: s.selectBusinessType,
                    desc: s.selectBusinessTypeDesc,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: types.length,
                    itemBuilder: (context, i) {
                      final t = types[i];
                      final isSel = selected?.id == t.id;
                      final color = t.color;
                      final label = t.displayNameForLocale(locale);

                      return GestureDetector(
                        onTap: () => onSelect(t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSel
                                ? color.withValues(alpha: 0.12)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel
                                  ? color
                                  : cs.outline.withValues(alpha: 0.2),
                              width: isSel ? 2 : 1,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.icon, style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? color : cs.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSel)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: color,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (selected?.key == 'other') ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoBox(
                      text: s.customBusinessTypeInfo,
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: customCtl,
                      decoration: InputDecoration(
                        hintText: s.customBusinessTypeHint,
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            _BottomBar(
              label: s.continueWizard,
              enabled: selected != null,
              onTap: onNext,
            ),
          ],
        );
      },
    );
  }
}

class _DetailsStep extends ConsumerWidget {
  final TextEditingController nameCtl;
  final TextEditingController descCtl;
  final GlobalKey<FormState> formKey;
  final String? selectedCurrencyId;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onNext;

  const _DetailsStep({
    required this.nameCtl,
    required this.descCtl,
    required this.formKey,
    required this.selectedCurrencyId,
    required this.onCurrencyChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final currenciesAsync = ref.watch(currenciesProvider);

    return currenciesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString()),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(currenciesProvider),
              child: Text(s.tryAgain),
            ),
          ],
        ),
      ),
      data: (currencies) {
        String? defaultId;
        for (final c in currencies) {
          if (c.code == 'UZS') {
            defaultId = c.id;
            break;
          }
        }
        defaultId ??= currencies.isNotEmpty ? currencies.first.id : null;
        final effectiveId = selectedCurrencyId ?? defaultId;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _StepHint(
                    icon: '✏️',
                    title: s.businessDetailsTitle,
                    desc: s.businessDetailsDesc,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: nameCtl,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: '${s.businessName} *',
                            hintText: s.businessNameHint,
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerLowest,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return s.businessNameRequired;
                            }
                            if (v.trim().length < 2) {
                              return s.businessNameMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtl,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: s.description,
                            hintText: s.businessDescHint,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 48),
                              child: Icon(Icons.notes_rounded),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerLowest,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          s.selectCurrency,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.selectCurrencyDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: effectiveId,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerLowest,
                          ),
                          items: currencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.code} — ${c.name}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) onCurrencyChanged(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            _BottomBar(
              label: s.continueWizard,
              enabled: effectiveId != null,
              onTap: onNext,
            ),
          ],
        );
      },
    );
  }
}

class _LocationStep extends StatelessWidget {
  final TextEditingController addressCtl;
  final double? latitude;
  final double? longitude;
  final bool fetchingLocation;
  final bool isLoading;
  final String? error;
  final VoidCallback onFetchLocation;
  final VoidCallback onSubmit;

  const _LocationStep({
    required this.addressCtl,
    required this.latitude,
    required this.longitude,
    required this.fetchingLocation,
    required this.isLoading,
    required this.error,
    required this.onFetchLocation,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasGps = latitude != null && longitude != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StepHint(
                icon: '📍',
                title: s.businessLocationTitle,
                desc: s.businessLocationDesc,
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: fetchingLocation ? null : onFetchLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasGps
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasGps
                          ? AppColors.primary
                          : cs.outline.withValues(alpha: 0.2),
                      width: hasGps ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasGps
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: fetchingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                hasGps
                                    ? Icons.location_on_rounded
                                    : Icons.my_location_rounded,
                                color: hasGps
                                    ? AppColors.primary
                                    : cs.onSurfaceVariant,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasGps ? s.locationSaved : s.useGpsLocation,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color:
                                    hasGps ? AppColors.primary : cs.onSurface,
                              ),
                            ),
                            if (hasGps) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ] else
                              Text(
                                s.gpsAutoDetectSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasGps)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child:
                          Divider(color: cs.outline.withValues(alpha: 0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      s.orDivider,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                      child:
                          Divider(color: cs.outline.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.manualAddressLabel,
                  hintText: s.addressHint,
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style:
                              TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        _BottomBar(
          label: s.createBusinessSubmit,
          enabled: !isLoading,
          isLoading: isLoading,
          onTap: onSubmit,
          isPrimary: true,
        ),
      ],
    );
  }
}

class _StepHint extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const _StepHint({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoBox({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onTap;

  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        12,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (enabled && !isLoading) ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppColors.gold : AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

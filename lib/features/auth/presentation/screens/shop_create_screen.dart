import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/business_type_model.dart';
import '../../domain/providers/auth_provider.dart';

enum _Step { category, details }

// ─── Screen ────────────────────────────────────────────────────────────────────

class ShopCreateScreen extends ConsumerStatefulWidget {
  const ShopCreateScreen({super.key});

  @override
  ConsumerState<ShopCreateScreen> createState() => _ShopCreateScreenState();
}

class _ShopCreateScreenState extends ConsumerState<ShopCreateScreen> {
  _Step _step = _Step.category;

  // Step 1
  BusinessTypeModel? _selectedType;
  final _customCtl = TextEditingController();

  // Step 2
  final _nameCtl = TextEditingController();
  final _nameKey = GlobalKey<FormState>();
  final _addressCtl = TextEditingController();
  LatLng? _selectedLatLng;
  bool _fetchingGps = false;
  final _mapCtl = MapController();

  // Submit
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customCtl.addListener(_onCustomChanged);
  }

  void _onCustomChanged() => setState(() {});

  @override
  void dispose() {
    _customCtl
      ..removeListener(_onCustomChanged)
      ..dispose();
    _nameCtl.dispose();
    _addressCtl.dispose();
    _mapCtl.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _step = _Step.details);
  }

  void _back() {
    if (_step == _Step.details) {
      setState(() => _step = _Step.category);
    } else {
      context.pop();
    }
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchGps() async {
    setState(() => _fetchingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).locationPermDenied),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final latlng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _selectedLatLng = latlng);
        _mapCtl.move(latlng, 15);
        await _reverseGeocode(pos.latitude, pos.longitude);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).locationError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat.toString(),
          'lon': lng.toString(),
          'accept-language': 'uz',
        },
        options: Options(
          headers: {'User-Agent': 'TaqseemApp/1.0'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = response.data as Map<String, dynamic>?;
      final display = data?['display_name'] as String?;
      if (display != null && display.isNotEmpty && mounted) {
        _addressCtl.text = display;
      }
    } catch (_) {
      // foydalanuvchi qo'lda kiritadi
    }
  }

  void _onMapTap(LatLng latlng) {
    setState(() => _selectedLatLng = latlng);
    _reverseGeocode(latlng.latitude, latlng.longitude);
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedType == null) return;
    if (!(_nameKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(shopProvider.notifier).createShop(
            businessTypeId: _selectedType!.id,
            name: _nameCtl.text.trim(),
            customBusinessTypeName:
                _selectedType!.key == 'other' ? _customCtl.text.trim() : null,
            address: _addressCtl.text.trim().isEmpty
                ? null
                : _addressCtl.text.trim(),
            latitude: _selectedLatLng?.latitude,
            longitude: _selectedLatLng?.longitude,
          );
      if (mounted) {
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stepIdx = _Step.values.indexOf(_step);
    final total = _Step.values.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              stepIdx: stepIdx,
              totalSteps: total,
              onBack: _back,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    _Step.category => _CategoryStep(
                        selected: _selectedType,
                        customCtl: _customCtl,
                        onSelect: (t) => setState(() => _selectedType = t),
                        onNext: () {
                          if (_selectedType == null) return;
                          if (_selectedType!.key == 'other' &&
                              _customCtl.text.trim().isEmpty) {
                            return;
                          }
                          _next();
                        },
                      ),
                    _Step.details => _DetailsStep(
                        nameCtl: _nameCtl,
                        addressCtl: _addressCtl,
                        formKey: _nameKey,
                        selectedLatLng: _selectedLatLng,
                        fetchingGps: _fetchingGps,
                        mapCtl: _mapCtl,
                        isLoading: _isLoading,
                        error: _error,
                        onFetchGps: _fetchGps,
                        onMapTap: _onMapTap,
                        onSubmit: _submit,
                      ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.stepIdx,
    required this.totalSteps,
    required this.onBack,
  });

  final int stepIdx;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = (stepIdx + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: cs.onSurface,
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, val, child) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: val,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${stepIdx + 1}/$totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Kategoriyalar ────────────────────────────────────────────────────

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep({
    required this.selected,
    required this.customCtl,
    required this.onSelect,
    required this.onNext,
  });

  final BusinessTypeModel? selected;
  final TextEditingController customCtl;
  final ValueChanged<BusinessTypeModel> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ref.watch(businessTypesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 40, color: cs.outline),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(businessTypesProvider),
                  child: Text(s.tryAgain),
                ),
              ],
            ),
          ),
          data: (types) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sarlavha
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.selectBusinessType,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.selectBusinessTypeDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Ro'yxat
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: types.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = types[i];
                    final isSel = selected?.id == t.id;
                    final color = t.color;
                    final label = t.displayNameForLocale(locale);

                    return GestureDetector(
                      onTap: () => onSelect(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSel
                              ? color.withValues(alpha: 0.08)
                              : cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel
                                ? color
                                : cs.outline.withValues(alpha: 0.15),
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(t.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? color : cs.onSurface,
                                ),
                              ),
                            ),
                            if (isSel)
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── "Boshqa" input
              if (selected?.key == 'other')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextFormField(
                    controller: customCtl,
                    decoration: InputDecoration(
                      hintText: s.customBusinessTypeHint,
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

              _BottomBar(
                label: s.continueWizard,
                enabled: selected != null &&
                    (selected!.key != 'other' ||
                        customCtl.text.trim().isNotEmpty),
                onTap: onNext,
              ),
            ],
          ),
        );
  }
}

// ─── Step 2: Nom + Joylashuv ──────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.nameCtl,
    required this.addressCtl,
    required this.formKey,
    required this.selectedLatLng,
    required this.fetchingGps,
    required this.mapCtl,
    required this.isLoading,
    required this.error,
    required this.onFetchGps,
    required this.onMapTap,
    required this.onSubmit,
  });

  final TextEditingController nameCtl;
  final TextEditingController addressCtl;
  final GlobalKey<FormState> formKey;
  final LatLng? selectedLatLng;
  final bool fetchingGps;
  final MapController mapCtl;
  final bool isLoading;
  final String? error;
  final VoidCallback onFetchGps;
  final ValueChanged<LatLng> onMapTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(
            s.businessDetailsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                // ── Biznes nomi
                TextFormField(
                  controller: nameCtl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.businessName,
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
                const SizedBox(height: AppSpacing.md),

                // ── Joylashuv sarlavhasi + GPS tugma
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.businessLocationTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _GpsButton(
                      fetching: fetchingGps,
                      hasLocation: selectedLatLng != null,
                      onTap: onFetchGps,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Xarita
                _MapPicker(
                  mapCtl: mapCtl,
                  selectedLatLng: selectedLatLng,
                  onTap: onMapTap,
                ),
                const SizedBox(height: 10),

                // ── Manzil input
                TextFormField(
                  controller: addressCtl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
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

                // ── Xato
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.error),
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
        ),
        _BottomBar(
          label: s.createBusinessSubmit,
          enabled: !isLoading,
          isLoading: isLoading,
          isPrimary: true,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ─── Xarita ───────────────────────────────────────────────────────────────────

class _MapPicker extends StatelessWidget {
  const _MapPicker({
    required this.mapCtl,
    required this.selectedLatLng,
    required this.onTap,
  });

  final MapController mapCtl;
  final LatLng? selectedLatLng;
  final ValueChanged<LatLng> onTap;

  static const _default = LatLng(41.2995, 69.2401);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPin = selectedLatLng != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPin
                ? AppColors.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.2),
            width: hasPin ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapCtl,
              options: MapOptions(
                initialCenter: selectedLatLng ?? _default,
                initialZoom: 13,
                onTap: (_, latlng) => onTap(latlng),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'uz.taqseem.app',
                ),
                if (hasPin)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLatLng!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!hasPin)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      S.of(context).tapMapToSelect,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── GPS inline tugma ─────────────────────────────────────────────────────────

class _GpsButton extends StatelessWidget {
  const _GpsButton({
    required this.fetching,
    required this.hasLocation,
    required this.onTap,
  });

  final bool fetching;
  final bool hasLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: fetching ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasLocation
              ? AppColors.primary.withValues(alpha: 0.08)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasLocation
                ? AppColors.primary.withValues(alpha: 0.4)
                : cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            fetching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.8, color: AppColors.primary),
                  )
                : Icon(
                    hasLocation
                        ? Icons.location_on_rounded
                        : Icons.my_location_rounded,
                    size: 15,
                    color: hasLocation
                        ? AppColors.primary
                        : cs.onSurfaceVariant,
                  ),
            const SizedBox(width: 5),
            Text(
              hasLocation ? s.locationSaved : s.useGpsLocation,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasLocation ? AppColors.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
    this.isPrimary = false,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.45,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (enabled && !isLoading) ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary,
              disabledForegroundColor: Colors.white,
              elevation: enabled ? 2 : 0,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (!isPrimary) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

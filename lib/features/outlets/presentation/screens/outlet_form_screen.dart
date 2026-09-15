import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/models/outlet_model.dart';
import '../../domain/providers/outlet_provider.dart';
import '../widgets/outlet_avatar.dart';

/// Do'kon yaratish / tahrirlash: rasm, nom, manzil (qo'lda yoki joylashuvdan),
/// 3 tagacha telefon, izoh.
///
/// Rasm galereyadan tizim tanlagichi orqali olinadi (photo picker) —
/// mediaga ruxsat so'ralmaydi, profil rasmidagi kabi.
class OutletFormScreen extends ConsumerStatefulWidget {
  const OutletFormScreen({super.key, this.editing});

  final OutletModel? editing;

  @override
  ConsumerState<OutletFormScreen> createState() => _OutletFormScreenState();
}

class _OutletFormScreenState extends ConsumerState<OutletFormScreen> {
  static const _maxPhones = 3;

  late final _nameCtl = TextEditingController(text: widget.editing?.name ?? '');
  late final _addressCtl = TextEditingController(
    text: widget.editing?.address ?? '',
  );
  late final _noteCtl = TextEditingController(text: widget.editing?.note ?? '');
  late final List<TextEditingController> _phoneCtls = [
    for (final p in widget.editing?.phones ?? const <String>[])
      TextEditingController(text: p),
    if ((widget.editing?.phones ?? const []).isEmpty) TextEditingController(),
  ];

  double? _lat;
  double? _lng;
  String? _pickedImagePath;
  bool _removeImage = false;
  bool _fetchingGps = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.editing?.latitude;
    _lng = widget.editing?.longitude;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _addressCtl.dispose();
    _noteCtl.dispose();
    for (final c in _phoneCtls) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  // ─── Rasm ──────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (image == null || !mounted) return;
      setState(() {
        _pickedImagePath = image.path;
        _removeImage = false;
      });
    } catch (_) {
      if (mounted) _snack(S.of(context).photoUploadFailed, error: true);
    }
  }

  // ─── Joylashuv ─────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    final s = S.of(context);
    setState(() => _fetchingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) _snack(s.locationPermDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      HapticFeedback.lightImpact();
      _snack(s.outletLocationSaved);
      if (_addressCtl.text.trim().isEmpty) {
        await _reverseGeocode(pos.latitude, pos.longitude);
      }
    } catch (_) {
      if (mounted) _snack(s.locationError, error: true);
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  /// Manzil bo'sh bo'lsa — koordinatadan taxminiy manzil (OSM Nominatim).
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'format': 'json', 'lat': lat, 'lon': lng},
        options: Options(
          headers: {'User-Agent': 'TaqseemApp/1.0'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final display = res.data?['display_name'] as String?;
      if (display != null && display.isNotEmpty && mounted) {
        _addressCtl.text = display;
      }
    } catch (_) {
      // Foydalanuvchi qo'lda kiritadi.
    }
  }

  // ─── Saqlash ───────────────────────────────────────────────────────────

  Future<void> _save() async {
    final s = S.of(context);
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      _snack(s.snackbarFillAllFields, error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final notifier = ref.read(outletsProvider.notifier);
    final phones = _phoneCtls
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final address = _addressCtl.text.trim();
    final note = _noteCtl.text.trim();

    try {
      final editing = widget.editing;
      var outlet = editing == null
          ? await notifier.create(
              name: name,
              address: address.isEmpty ? null : address,
              latitude: _lat,
              longitude: _lng,
              phones: phones,
              note: note.isEmpty ? null : note,
            )
          : await notifier.update(
              editing.id,
              name: name,
              address: address.isEmpty ? null : address,
              latitude: _lat,
              longitude: _lng,
              phones: phones,
              note: note.isEmpty ? null : note,
            );

      if (_pickedImagePath != null) {
        outlet = await notifier.uploadImage(outlet.id, _pickedImagePath!);
      } else if (_removeImage && editing?.imageUrl != null) {
        outlet = await notifier.deleteImage(outlet.id);
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      _snack(s.outletSaved);
      context.pop(outlet);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        e is ApiException ? e.message : s.snackbarErrorGeneric,
        error: true,
      );
    }
  }

  InputDecoration _deco(
    ColorScheme cs, {
    String? label,
    String? hint,
    Widget? suffix,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      prefixIcon: prefix,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final editing = widget.editing;
    final showImage =
        !_removeImage &&
        (_pickedImagePath != null || (editing?.imageUrl?.isNotEmpty ?? false));

    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? s.outletNew : s.outletEdit),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _saving ? null : () => context.pop(),
        ),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    s.actionSave,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          // ── Rasm ──
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_pickedImagePath != null && !_removeImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(
                            File(_pickedImagePath!),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        OutletAvatar(
                          name: _nameCtl.text.isEmpty
                              ? (editing?.name ?? '')
                              : _nameCtl.text,
                          imageUrl: showImage ? editing?.imageUrl : null,
                          size: 96,
                          radius: 24,
                        ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _pickImage,
                      child: Text(s.outletPhotoPick),
                    ),
                    if (showImage)
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _pickedImagePath = null;
                                _removeImage = true;
                              }),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: Text(s.outletPhotoRemove),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Nom ──
          TextField(
            controller: _nameCtl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _deco(
              cs,
              label: s.outletNameLabel,
              hint: s.outletNameHint,
              prefix: const Icon(Icons.storefront_outlined),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // ── Manzil + joylashuv ──
          TextField(
            controller: _addressCtl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLines: 2,
            minLines: 1,
            decoration: _deco(
              cs,
              label: s.address,
              hint: s.outletAddressHint,
              prefix: const Icon(Icons.place_outlined),
              suffix: IconButton(
                tooltip: s.outletUseLocation,
                onPressed: _fetchingGps || _saving ? null : _fetchLocation,
                icon: _fetchingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _lat != null
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        color: _lat != null ? AppColors.primary : null,
                      ),
              ),
            ),
          ),
          if (_lat != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.outletLocationSaved,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() {
                      _lat = null;
                      _lng = null;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // ── Telefonlar ──
          Text(
            s.outletPhones,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _phoneCtls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _phoneCtls[i],
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
                ],
                decoration: _deco(
                  cs,
                  hint: '+998 90 123 45 67',
                  prefix: const Icon(Icons.phone_outlined),
                  suffix: _phoneCtls.length > 1
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          onPressed: () => setState(() {
                            _phoneCtls.removeAt(i).dispose();
                          }),
                        )
                      : null,
                ),
              ),
            ),
          if (_phoneCtls.length < _maxPhones)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _phoneCtls.add(TextEditingController())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(s.outletPhoneAdd),
              ),
            ),
          const SizedBox(height: 8),
          // ── Izoh ──
          TextField(
            controller: _noteCtl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 1,
            decoration: _deco(
              cs,
              label: s.outletNoteLabel,
              prefix: const Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

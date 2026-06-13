import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../subscription/domain/providers/subscription_provider.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _amountController = TextEditingController();
  File? _receipt;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = Responsive.horizontalPadding(context);
    final infoAsync = ref.watch(topupInfoProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(s.topUp, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: infoAsync.when(
        loading: () => const AppLoading(),
        error: (_, _) => ErrorRetryWidget(
          message: s.noInternet,
          onRetry: () => ref.invalidate(topupInfoProvider),
        ),
        data: (info) => ListView(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
          children: [
            _CardInfo(
              cardNumber: info.cardNumber ?? '—',
              cardHolder: info.cardHolder,
              onCopy: () => _copyCard(info.cardNumber),
            ),
            if (info.note?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _NoteCard(note: info.note!),
            ],
            const SizedBox(height: 24),
            _Label(s.topUpAmount),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '50 000',
                suffixText: 'UZS',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Label(s.uploadReceipt),
            const SizedBox(height: 8),
            _ReceiptPicker(
              file: _receipt,
              onPick: _pickReceipt,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(s.topUpSubmit,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyCard(String? number) {
    if (number == null || number.isEmpty) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: number.replaceAll(' ', '')));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(S.of(context).copiedMsg),
      ));
  }

  Future<void> _pickReceipt() async {
    // Faqat galereya — Photo Picker (media ruxsati so'ralmaydi).
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _receipt = File(image.path));
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final amount = double.tryParse(_amountController.text.replaceAll(' ', ''));

    if (amount == null || amount < 1000) {
      _snack(s.topUpAmountTooSmall, isError: true);
      return;
    }
    if (_receipt == null) {
      _snack(s.receiptRequired, isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .topup(amount, receiptPath: _receipt!.path);
      if (!mounted) return;
      ref.invalidate(ordersListProvider);
      HapticFeedback.lightImpact();
      _snack(s.topUpPendingMsg);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.message, isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : null,
        content: Text(message),
      ));
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String cardNumber;
  final String? cardHolder;
  final VoidCallback onCopy;

  const _CardInfo({
    required this.cardNumber,
    required this.cardHolder,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(s.topUpCardLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  cardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                      Text(s.copyAction,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (cardHolder?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Text(s.topUpCardHolderLabel,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 2),
            Text(cardHolder!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPicker extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;

  const _ReceiptPicker({required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    if (file != null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
            image: DecorationImage(
              image: FileImage(file!),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 5),
                Text(s.changeReceipt,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: cs.primary, size: 34),
            const SizedBox(height: 8),
            Text(s.uploadReceipt,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// SMS kodini kiritish maydoni.
///
/// Ichkarida bitta ko'rinmas [TextField] turadi, kataklar esa faqat chizma.
/// Avval har bir katak alohida maydon edi va ularga `LengthLimitingTextInput‑
/// Formatter(1)` osilgan edi — telefon klaviatura ustidan taklif qilgan
/// "1234" ni bitta belgigacha qirqib tashlardi, natijada faqat birinchi raqam
/// tushib qolardi. Yagona maydon bilan avtomatik to'ldirish ham, nusxa
/// ko'chirish ham, o'chirish ham to'g'ri ishlaydi.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const OtpInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
  });

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String _lastReported = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _code => _controller.text;

  void _onTextChanged() {
    final code = _code;

    if (code == _lastReported) return;

    _lastReported = code;
    setState(() {});
    widget.onChanged?.call(code);

    if (code.length == widget.length) {
      // Kod to'ldi — klaviatura yo'lda turmasin.
      _focusNode.unfocus();
      widget.onCompleted(code);
    }
  }

  /// Xato kodda tozalash uchun — tashqaridan chaqiriladi.
  void clear() {
    _controller.clear();
    _lastReported = '';
    _focusNode.requestFocus();
    setState(() {});
  }

  void focus() => _focusNode.requestFocus();

  @override
  Widget build(BuildContext context) {
    final code = _code;

    // AutofillGroup — Android'dagi avtomatik to'ldirish xizmati maydonni
    // shu guruh ichida ko'radi.
    return AutofillGroup(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kataklar — bosilganda yagona maydonga fokus beradi.
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _focusNode.requestFocus();
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _focusNode,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (i) {
                  final filled = i < code.length;

                  // Kursor keyingi bo'sh katakda turgandek ko'rinsin.
                  final active =
                      _focusNode.hasFocus &&
                      (i == code.length ||
                          (code.length == widget.length &&
                              i == widget.length - 1));

                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < widget.length - 1 ? 14 : 0,
                    ),
                    child: _OtpBox(
                      digit: filled ? code[i] : '',
                      active: active,
                      filled: filled,
                    ),
                  );
                }),
              ),
            ),
          ),

          // Haqiqiy maydon — ko'rinmaydi, lekin klaviatura va avtomatik
          // to'ldirish shu yerga bog'lanadi.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.filled,
  });

  final String digit;
  final bool active;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? AppColors.primary
              : filled
              ? AppColors.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: active ? 2 : 1,
        ),
      ),
      child: Text(
        digit,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

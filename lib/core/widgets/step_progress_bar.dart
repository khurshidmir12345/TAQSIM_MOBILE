import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Retsept / chiqim kabi ko‘p qadamli oqimlar uchun progress (dark/light mos).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
                final stepBefore = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: stepBefore < currentStep
                          ? AppColors.primary
                          : cs.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final step = i ~/ 2;
              final isCompleted = step < currentStep;
              final isCurrent = step == currentStep;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: isCurrent
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.primary
                                : cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Yengil ichkariga surish — chetlarga qattiq bosmasdan.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final isCurrent = i == currentStep;
                final isCompleted = i < currentStep;
                return Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent || isCompleted
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

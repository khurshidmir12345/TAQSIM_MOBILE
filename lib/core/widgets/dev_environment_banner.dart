import 'package:flutter/material.dart';

import '../constants/app_environment.dart';

/// Subtle DEV indicator — top-end, non-blocking; hidden in production builds.
class DevEnvironmentBanner extends StatelessWidget {
  const DevEnvironmentBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppEnvironment.isDev) return child;

    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: IgnorePointer(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppEnvironment.label,
                      style: TextStyle(
                        color: scheme.onTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

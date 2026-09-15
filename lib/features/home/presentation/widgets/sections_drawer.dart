import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';

/// Asosiy sahifada o'ng chetdan tortilganda ochiladigan bo'limlar paneli.
///
/// Orqa fon xiralashadi, o'ng tomonda bloklar chiqadi. Hozircha bitta blok —
/// «Do'konlar»; yangi bo'limlar shu ro'yxatga qo'shiladi.
class SectionsDrawer extends StatelessWidget {
  const SectionsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = (width * 0.72).clamp(260.0, 360.0);

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          // Xira fon — bosilsa yopiladi.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Scaffold.of(context).closeEndDrawer(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: cs.surface,
              elevation: 12,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.sectionsDrawerTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Scaffold.of(context).closeEndDrawer(),
                              icon: const Icon(Icons.close_rounded),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SectionBlock(
                          icon: Icons.storefront_rounded,
                          title: s.outletsTitle,
                          subtitle: s.outletsBlockSubtitle,
                          color: AppColors.primary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Scaffold.of(context).closeEndDrawer();
                            context.push('/outlets');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asosiy sahifaning o'ng chetidagi kichik "dastak": panel borligini
/// bildiradi, bosilsa ham ochiladi.
class SectionsEdgeHandle extends StatelessWidget {
  const SectionsEdgeHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: S.of(context).outletEdgeHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          // Shell'dagi eng tashqi Scaffold'da endDrawer bor.
          context.findRootAncestorStateOfType<ScaffoldState>()?.openEndDrawer();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 0, 12),
          child: Container(
            width: 5,
            height: 44,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.22),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

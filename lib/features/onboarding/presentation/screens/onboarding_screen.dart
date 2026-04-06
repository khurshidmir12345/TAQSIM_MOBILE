import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/translations.dart';
import '../../domain/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await completeOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    final pages = [
      _PageData(
        title: s.onboardingTitle1,
        description: s.onboardingDesc1,
        illustration: const _OnboardingIllustration(
          mainIcon: Icons.storefront_rounded,
          primaryColor: Color(0xFFB8941F),
          secondaryColor: Color(0xFFC8A951),
          topRightIcon: Icons.local_fire_department_rounded,
          topRightColor: Color(0xFFEF6C00),
          bottomLeftIcon: Icons.restaurant_rounded,
          bottomLeftColor: Color(0xFF2E7D32),
          extraIcon: Icons.cake_rounded,
          extraColor: Color(0xFFAD1457),
        ),
      ),
      _PageData(
        title: s.onboardingTitle2,
        description: s.onboardingDesc2,
        illustration: const _OnboardingIllustration(
          mainIcon: Icons.calculate_rounded,
          primaryColor: Color(0xFF00897B),
          secondaryColor: Color(0xFF26A69A),
          topRightIcon: Icons.trending_up_rounded,
          topRightColor: Color(0xFFF57C00),
          bottomLeftIcon: Icons.attach_money_rounded,
          bottomLeftColor: Color(0xFF1565C0),
          extraIcon: Icons.receipt_long_rounded,
          extraColor: Color(0xFF6A1B9A),
        ),
      ),
      _PageData(
        title: s.onboardingTitle3,
        description: s.onboardingDesc3,
        illustration: const _OnboardingIllustration(
          mainIcon: Icons.bar_chart_rounded,
          primaryColor: Color(0xFF1565C0),
          secondaryColor: Color(0xFF42A5F5),
          topRightIcon: Icons.point_of_sale_rounded,
          topRightColor: Color(0xFFEF6C00),
          bottomLeftIcon: Icons.inventory_2_rounded,
          bottomLeftColor: Color(0xFF2E7D32),
          extraIcon: Icons.notifications_active_rounded,
          extraColor: Color(0xFFAD1457),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    s.skip,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pageCount,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        page.illustration,
                        const Spacer(flex: 2),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildDotIndicators(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _currentPage < _pageCount - 1
                          ? s.next
                          : s.getStarted,
                      key: ValueKey(_currentPage == _pageCount - 1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _PageData {
  final String title;
  final String description;
  final Widget illustration;

  const _PageData({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class _OnboardingIllustration extends StatelessWidget {
  final IconData mainIcon;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData topRightIcon;
  final Color topRightColor;
  final IconData bottomLeftIcon;
  final Color bottomLeftColor;
  final IconData? extraIcon;
  final Color? extraColor;

  const _OnboardingIllustration({
    required this.mainIcon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.topRightIcon,
    required this.topRightColor,
    required this.bottomLeftIcon,
    required this.bottomLeftColor,
    this.extraIcon,
    this.extraColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(mainIcon, size: 72, color: Colors.white),
          ),
          Positioned(
            top: 18,
            right: 22,
            child: _FloatingBubble(
              icon: topRightIcon,
              color: topRightColor,
            ),
          ),
          Positioned(
            bottom: 22,
            left: 18,
            child: _FloatingBubble(
              icon: bottomLeftIcon,
              color: bottomLeftColor,
            ),
          ),
          if (extraIcon != null && extraColor != null)
            Positioned(
              bottom: 28,
              right: 16,
              child: _FloatingBubble(
                icon: extraIcon!,
                color: extraColor!,
                size: 40,
                iconSize: 18,
              ),
            ),
          Positioned(
            top: 55,
            left: 15,
            child: _AccentDot(color: primaryColor, size: 14),
          ),
          Positioned(
            bottom: 72,
            right: 12,
            child: _AccentDot(color: secondaryColor, size: 10),
          ),
          Positioned(
            top: 30,
            left: 55,
            child: _AccentDot(color: secondaryColor, size: 8),
          ),
        ],
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _FloatingBubble({
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final double size;

  const _AccentDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

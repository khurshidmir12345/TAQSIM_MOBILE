import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/taqsim_logo_asset.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import 'package:flutter/services.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _animCtl, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animCtl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _animCtl.forward();
    _init();
  }

  @override
  void dispose() {
    _animCtl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingDone) {
      if (mounted) context.go('/language-selection');
      return;
    }

    await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;

    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated) {
      await ref.read(shopProvider.notifier).loadShops();
      if (!mounted) return;
      final shops = ref.read(shopProvider).shops;
      context.go(shops.isEmpty ? '/shop-select' : '/shell');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Stack(
          children: [
            // Dekorativ halqa — orqa fon
            Positioned(
              top: -100,
              right: -100,
              child: _DecorativeCircle(
                size: 320,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _DecorativeCircle(
                size: 260,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            // Asosiy kontent
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TaqsimSplashLogo(
                      size: 140,
                      scaleAnim: _scaleAnim,
                    ),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [Colors.white, Color(0xFFE8CC6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              AppConstants.appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    fontSize: 42,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 15,
                                  color: AppColors.goldLight
                                      .withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kichik biznes uchun aqlli tizim',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.80),
                                        letterSpacing: 0.3,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}

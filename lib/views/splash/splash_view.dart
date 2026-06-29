import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../controllers/auth_controller.dart';
import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/customer_logo.dart';

/// Branded splash — purple gradient, centered logo, reference-style layout.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _ringCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );
    _enterCtrl.forward();

    Future.microtask(() {
      ref.read(locationResolverProvider).resolve();
      ref.read(discoveryControllerProvider.notifier).loadInitial();
    });

    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).refreshSession();
    if (!mounted) return;
    context.go(RoutePaths.discovery);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final basePurple = isDark ? AppColors.primaryDark : AppColors.primary;
    final logoAsset =
        isDark ? AppAssets.customerDark : AppAssets.customerLight;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.15),
            radius: 1.1,
            colors: isDark
                ? [
                    const Color(0xFF4A2F8C),
                    AppColors.primaryDark,
                    const Color(0xFF1A1030),
                  ]
                : [
                    AppColors.primaryLight,
                    basePurple,
                    AppColors.primaryDark,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ringCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(260, 260),
                  painter: _RingPainter(
                    progress: _ringCtrl.value,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: CustomerLogoSizes.splashIconBox,
                        height: CustomerLogoSizes.splashIconBox,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: CustomerLogo.splashIcon(asset: logoAsset),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'Foodeez',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          'Crave it. Tap it. Done.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXl),
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color;

    for (var i = 0; i < 3; i++) {
      final radius = 72.0 + i * 28 + progress * 6;
      paint.strokeWidth = 1.2 - i * 0.2;
      canvas.drawCircle(center, radius, paint);
    }

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final angle = progress * math.pi * 2;
    canvas.drawCircle(
      center + Offset(92 * math.cos(angle), 92 * math.sin(angle)),
      3,
      dotPaint,
    );
    canvas.drawCircle(
      center +
          Offset(
            118 * math.cos(angle + 1.2),
            118 * math.sin(angle + 1.2),
          ),
      2.5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _barCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _barWidth;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _barWidth = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);

    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _barCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      final auth = ref.read(authProvider);
      context.go(auth.isAuthenticated ? '/home' : '/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo
            ScaleTransition(
              scale: _logoScale,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Icon(Icons.school_rounded, size: 46, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                const Text(
                  'Student Diwan',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Parent Portal',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
            const SizedBox(height: 52),
            // Loading bar
            Container(
              width: 52, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _barWidth,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _barWidth.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}

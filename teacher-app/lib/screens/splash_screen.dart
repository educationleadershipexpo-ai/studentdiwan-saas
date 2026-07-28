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

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _glowOpacity;
  late Animation<double> _bookOpen;
  late Animation<double> _avatarFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _glowOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );

    _bookOpen = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    _avatarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => _checkAuthAndNavigate());
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (isAuth) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Glow Effect background
                Opacity(
                  opacity: _glowOpacity.value,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                // Main logo and book container
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2. Student Diwan Logo Scale
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 3. Opening Book Custom Paint
                    CustomPaint(
                      size: const Size(120, 60),
                      painter: BookPainter(progress: _bookOpen.value),
                    ),
                    const SizedBox(height: 16),
                    // Logo text
                    Text(
                      'STUDENT DIWAN',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: _avatarFade.value,
                      child: Text(
                        'Teacher Portal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
                // 4. Floating mini teacher avatar at the bottom
                Positioned(
                  bottom: 50,
                  child: Opacity(
                    opacity: _avatarFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Empowering Educators',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Custom book opening painter for neat premium visual effect
class BookPainter extends CustomPainter {
  final double progress;
  BookPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height;

    // Drawing opened pages based on progress
    // Left page curve
    path.moveTo(centerX, centerY);
    path.quadraticBezierTo(
      centerX - (size.width * 0.25 * progress),
      centerY - (size.height * 0.45 * progress),
      centerX - (size.width * 0.5 * progress),
      centerY - (size.height * 0.15 * progress),
    );

    // Right page curve
    path.moveTo(centerX, centerY);
    path.quadraticBezierTo(
      centerX + (size.width * 0.25 * progress),
      centerY - (size.height * 0.45 * progress),
      centerX + (size.width * 0.5 * progress),
      centerY - (size.height * 0.15 * progress),
    );

    // Spine line
    canvas.drawLine(Offset(centerX, centerY), Offset(centerX, centerY - (size.height * 0.6 * progress)), paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BookPainter oldDelegate) => oldDelegate.progress != progress;
}

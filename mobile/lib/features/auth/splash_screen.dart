import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../anchor/anchor_dashboard_screen.dart';
import '../dashboard/stagepilot_dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _initAppAndRoute();
  }

  Future<void> _initAppAndRoute() async {
    // Concurrently await branded splash timing and session restoration
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      AuthService().restoreSession(),
    ]);

    if (!mounted) return;

    final user = results[1] as AppUser?;
    Widget destination;

    if (user != null) {
      if (user.role.toLowerCase() == 'anchor') {
        debugPrint("🚀 [Splash] Session active: routing Anchor (${user.fullName}) to AnchorDashboardScreen");
        destination = const AnchorDashboardScreen();
      } else {
        debugPrint("🚀 [Splash] Session active: routing Organizer (${user.fullName}) to StagePilotDashboardScreen");
        destination = const StagePilotDashboardScreen();
      }
    } else {
      debugPrint("ℹ️ [Splash] No active session: opening LoginScreen");
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Existing App Logo
                Image.asset(
                  'assets/trans_icon.png',
                  width: 160,
                  height: 160,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sensors_rounded,
                    size: 100,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SMARTEVE',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mission-critical mobile co-pilot',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

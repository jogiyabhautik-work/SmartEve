import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../organizer/screens/organizer_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../attendee/attendee_screen.dart';
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

    // Check existing login session & transition
    Future.delayed(const Duration(milliseconds: 2200), () async {
      final user = await AuthService().restoreSession();
      if (!mounted) return;

      Widget destination;
      if (user != null) {
        final role = user.role.toLowerCase();
        if (role == 'anchor' || role == 'host') {
          destination = const AnchorTeleprompterScreen();
        } else if (role == 'admin') {
          destination = const AdminDashboardScreen();
        } else if (role == 'attendee') {
          destination = const AttendeeScreen();
        } else {
          destination = const OrganizerDashboardScreen();
        }
      } else {
        destination = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
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

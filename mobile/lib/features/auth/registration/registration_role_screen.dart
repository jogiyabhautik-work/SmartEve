import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/role_selection_card.dart';
import '../widgets/auth_button.dart';
import 'organizer_registration_screen.dart';
import 'anchor_registration_screen.dart';

class RegistrationRoleScreen extends StatefulWidget {
  const RegistrationRoleScreen({super.key});

  @override
  State<RegistrationRoleScreen> createState() => _RegistrationRoleScreenState();
}

class _RegistrationRoleScreenState extends State<RegistrationRoleScreen> {
  String? _selectedRole;

  void _handleContinue() {
    if (_selectedRole == 'organizer') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrganizerRegistrationScreen()),
      );
    } else if (_selectedRole == 'anchor') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AnchorRegistrationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How are you using SmartEve?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select your primary role to customize your setup experience.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              RoleSelectionCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Event Organizer',
                subtitle: 'Manage events, schedules, speakers, and coordinate the control room.',
                isSelected: _selectedRole == 'organizer',
                onTap: () {
                  setState(() => _selectedRole = 'organizer');
                },
              ),
              const SizedBox(height: 20),
              RoleSelectionCard(
                icon: Icons.mic_external_on_rounded,
                title: 'Anchor / Host',
                subtitle: 'Access teleprompters, live schedules, and AI-generated scripts on stage.',
                isSelected: _selectedRole == 'anchor',
                onTap: () {
                  setState(() => _selectedRole = 'anchor');
                },
              ),
              const Spacer(),
              AuthButton(
                text: 'CONTINUE',
                onPressed: _selectedRole != null ? _handleContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

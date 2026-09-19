import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../dashboard/stagepilot_dashboard_screen.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/auth_dropdown.dart';
import '../models/registration_data.dart';

class OrganizerRegistrationScreen extends StatefulWidget {
  const OrganizerRegistrationScreen({super.key});

  @override
  State<OrganizerRegistrationScreen> createState() => _OrganizerRegistrationScreenState();
}

class _OrganizerRegistrationScreenState extends State<OrganizerRegistrationScreen> {
  final PageController _pageController = PageController();
  final OrganizerRegistrationModel _data = OrganizerRegistrationModel();
  final _formKeys = List.generate(6, (_) => GlobalKey<FormState>());
  
  int _currentStep = 1;
  bool _isLoading = false;

  void _nextStep() {
    if (_formKeys[_currentStep - 1].currentState!.validate()) {
      if (_currentStep < 6) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _submitRegistration();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().registerOrganizer(data: _data);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Registration successful! Welcome to StagePilot Dashboard.'),
          backgroundColor: AppTheme.liveGreen,
          duration: Duration(seconds: 3),
        ),
      );

      // Redirect immediately to respective screen: StagePilot Dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const StagePilotDashboardScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: AppTheme.alertRed,
          duration: const Duration(seconds: 4),
        ),
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
          onPressed: _previousStep,
        ),
        title: const Text('Organizer Setup'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: StepIndicator(currentStep: _currentStep, totalSteps: 6),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      flex: 1,
                      child: AuthButton(
                        text: 'BACK',
                        isOutlined: true,
                        onPressed: _previousStep,
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AuthButton(
                      text: _currentStep == 6 ? 'CREATE ACCOUNT' : 'CONTINUE',
                      isLoading: _isLoading,
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Let\'s start with your contact details.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            AuthTextField(
              label: 'Full Name',
              hint: 'John Doe',
              onChanged: (v) => _data.fullName = v,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Email',
              hint: 'john@example.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => _data.email = v,
              validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Password',
              hint: 'Min 8 characters',
              isPassword: true,
              onChanged: (v) => _data.password = v,
              validator: (v) => v!.length < 8 ? 'Min 8 characters required' : null,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Confirm Password',
              hint: 'Re-enter password',
              isPassword: true,
              onChanged: (v) => _data.confirmPassword = v,
              validator: (v) => v != _data.password ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Phone Number',
              hint: '+1 234 567 8900',
              keyboardType: TextInputType.phone,
              onChanged: (v) => _data.phoneNumber = v,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            AuthDropdown<String>(
              label: 'Designation',
              value: _data.designation,
              items: ['Student', 'Faculty', 'Staff'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _data.designation = v!),
            ),
            const SizedBox(height: 20),
            if (_data.designation != 'Student')
              AuthTextField(
                label: 'Department',
                hint: 'Computer Science',
                onChanged: (v) => _data.department = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            if (_data.designation == 'Student')
              AuthTextField(
                label: 'Student ID',
                hint: 'e.g. 2023CS101',
                onChanged: (v) => _data.studentId = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'College Name',
              hint: 'University Name',
              onChanged: (v) => _data.collegeName = v,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile & Social', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            AuthTextField(
              label: 'Bio',
              hint: 'Tell us about yourself...',
              maxLines: 4,
              onChanged: (v) => _data.bio = v,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'LinkedIn URL (Optional)',
              hint: 'https://linkedin.com/in/...',
              onChanged: (v) => _data.linkedin = v,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Twitter URL (Optional)',
              hint: 'https://twitter.com/...',
              onChanged: (v) => _data.twitter = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Experience & Contact', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            AuthTextField(
              label: 'Events Organized (Optional)',
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) => _data.eventsOrganized = int.tryParse(v),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Years of Experience (Optional)',
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) => _data.yearsOfExperience = int.tryParse(v),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Emergency Contact Name',
              hint: 'Jane Doe',
              onChanged: (v) => _data.emergencyContactName = v,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Emergency Contact Phone',
              hint: '+1 234 567 8900',
              keyboardType: TextInputType.phone,
              onChanged: (v) => _data.emergencyContactPhone = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preferences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            AuthDropdown<String>(
              label: 'Language',
              value: _data.language,
              items: ['English', 'Spanish', 'French', 'Hindi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _data.language = v!),
            ),
            const SizedBox(height: 20),
            AuthDropdown<String>(
              label: 'Timezone',
              value: _data.timezone,
              items: ['Asia/Kolkata', 'America/New_York', 'Europe/London'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _data.timezone = v!),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text('Receive Notifications', style: TextStyle(color: AppTheme.textPrimary)),
              activeColor: AppTheme.cyan,
              value: _data.receiveNotifications,
              onChanged: (v) => setState(() => _data.receiveNotifications = v),
            ),
            SwitchListTile(
              title: const Text('Receive Emails', style: TextStyle(color: AppTheme.textPrimary)),
              activeColor: AppTheme.cyan,
              value: _data.receiveEmails,
              onChanged: (v) => setState(() => _data.receiveEmails = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Terms & Confirmation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Role: Organizer', style: const TextStyle(color: AppTheme.textPrimary)),
                  Text('Name: ${_data.fullName}', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('Email: ${_data.email}', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('College: ${_data.collegeName}', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CheckboxListTile(
              title: const Text('I agree to the Terms & Conditions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              activeColor: AppTheme.cyan,
              value: _data.termsAccepted,
              onChanged: (v) => setState(() => _data.termsAccepted = v!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_data.termsAccepted)
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text('Required to continue', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12)),
              ),
            CheckboxListTile(
              title: const Text('I agree to the Privacy Policy', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              activeColor: AppTheme.cyan,
              value: _data.privacyAccepted,
              onChanged: (v) => setState(() => _data.privacyAccepted = v!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_data.privacyAccepted)
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text('Required to continue', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

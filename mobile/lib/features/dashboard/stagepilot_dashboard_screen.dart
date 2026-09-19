import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../auth/role_selection_screen.dart';

class AppSlateColors {
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color rose400 = Color(0xFFFB7185);
}

class StagePilotDashboardScreen extends StatefulWidget {
  const StagePilotDashboardScreen({super.key});

  @override
  State<StagePilotDashboardScreen> createState() => _StagePilotDashboardScreenState();
}

class _StagePilotDashboardScreenState extends State<StagePilotDashboardScreen> {
  int _selectedIndex = 0;
  int _settingsTabIndex = 0;

  void _handleSignOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Mock Delay State for Interactive Preview
  int _delayMinutes = 15;
  bool _isDelayApplied = false;

  // Mock AI Assistant Prompt & Output
  final TextEditingController _aiPromptController = TextEditingController(
    text: "Generate a short introduction for Dr. Aayush Sharma about his session on Generative AI.",
  );
  String _aiGeneratedScript =
      "Please welcome Dr. Aayush Sharma, an AI Researcher at Google, who will be sharing his insights on Generative AI. With years of experience in building cutting-edge AI solutions, Dr. Sharma has worked on several groundbreaking projects in the field of machine learning and large language models. Let's give him a warm round of applause!";

  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isMobile
            ? Column(
                children: [
                  _buildMobileHeader(),
                  Expanded(child: _buildCurrentView()),
                  _buildMobileBottomNav(),
                ],
              )
            : Row(
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildCurrentView()),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // SIDEBAR NAVIGATION (Desktop / Tablet View)
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StagePilot AI',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Smart Anchor & Stage Flow',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppSlateColors.slate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Nav Items
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
          _buildNavItem(1, Icons.calendar_month_rounded, 'Agenda'),
          _buildNavItem(2, Icons.people_alt_rounded, 'Speakers'),
          _buildNavItem(3, Icons.auto_awesome_rounded, 'AI Assistant'),
          _buildNavItem(4, Icons.schedule_rounded, 'Schedule Update'),
          _buildNavItem(5, Icons.settings_rounded, 'Settings'),

          const Spacer(),

          // Bottom Event Tag
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GDG Hackathon 2026',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Build • Learn • Grow',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppSlateColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 16, color: AppSlateColors.rose400),
            label: const Text('Sign Out', style: TextStyle(color: AppSlateColors.rose400, fontSize: 13)),
            onPressed: _handleSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppSlateColors.slate400,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppSlateColors.slate300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE HEADER & BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'StagePilot AI',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppSlateColors.slate600),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'anchor') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()),
                );
              } else if (value == 'roles') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              } else if (value == 'logout') {
                _handleSignOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  AuthService().currentAppUser?.fullName ?? 'Organizer',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'anchor',
                child: Row(
                  children: [
                    Icon(Icons.mic_external_on_rounded, size: 18, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Anchor Teleprompter', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'roles',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text('Switch Role / Join Code', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                AuthService().currentAppUser?.fullName.isNotEmpty == true
                    ? AuthService().currentAppUser!.fullName.substring(0, 1).toUpperCase()
                    : 'SP',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
      onTap: (idx) => setState(() => _selectedIndex = idx),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: AppSlateColors.slate400,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Agenda'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Speakers'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Assistant'),
      ],
    );
  }

  // ==========================================
  // CURRENT VIEW ROUTER
  // ==========================================
  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildEventDashboardView();
      case 1:
        return _buildAgendaManagementView();
      case 2:
        return _buildSpeakerManagementView();
      case 3:
        return _buildAIAssistantView();
      case 4:
        return _buildScheduleUpdateView();
      case 5:
        return _buildEventSettingsView();
      default:
        return _buildEventDashboardView();
    }
  }

  // ==========================================
  // 1 & 5: EVENT DASHBOARD VIEW
  // ==========================================
  Widget _buildEventDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, Anchor! 👋',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening at the event today.",
                    style: GoogleFonts.inter(fontSize: 14, color: AppSlateColors.slate500),
                  ),
                ],
              ),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Romal Tandel\nAnchor',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Main Live Card (Gradient Hero)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Now Live',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Python Workshop',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '10:30 AM - 11:30 AM',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.code_rounded, color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Indicator Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '45 min left',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Up Next & Later Cards
          Row(
            children: [
              Expanded(
                child: _buildTimelineCard(
                  tag: 'Up Next',
                  title: 'Keynote by Dr. Sharma',
                  time: '11:30 AM - 12:00 PM',
                  icon: Icons.mic_rounded,
                  badgeColor: const Color(0xFFEFF6FF),
                  textColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimelineCard(
                  tag: 'Later',
                  title: 'Break & Networking',
                  time: '12:00 PM - 12:15 PM',
                  icon: Icons.coffee_rounded,
                  badgeColor: const Color(0xFFF8FAFC),
                  textColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Schedule Status Alert Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Status Alert',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        _isDelayApplied
                            ? 'Running $_delayMinutes minutes late. Dynamic reflow applied.'
                            : 'Running 10 minutes late. Action recommended.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Update Schedule'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required String tag,
    required String title,
    required String time,
    required IconData icon,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: AppSlateColors.slate400),
              const SizedBox(width: 6),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 12, color: AppSlateColors.slate500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2: AGENDA MANAGEMENT VIEW
  // ==========================================
  Widget _buildAgendaManagementView() {
    final sessions = [
      {'time': '09:00 AM', 'title': 'Welcome & Registration', 'duration': '15 min', 'status': 'done'},
      {'time': '09:15 AM', 'title': 'Opening Ceremony', 'duration': '45 min', 'status': 'done'},
      {'time': '10:00 AM', 'title': 'Keynote by Dr. Sharma', 'duration': '45 min', 'status': 'done'},
      {'time': '10:45 AM', 'title': 'Python Workshop', 'duration': '60 min', 'status': 'live'},
      {'time': '11:45 AM', 'title': 'Technical Session: Cloud Native', 'duration': '45 min', 'status': 'upcoming'},
      {'time': '12:30 PM', 'title': 'Networking & Lunch Break', 'duration': '45 min', 'status': 'upcoming'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Agenda',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage your event schedule and sessions.',
                    style: GoogleFonts.inter(color: AppSlateColors.slate500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = sessions[index];
                final isLive = item['status'] == 'live';

                return Container(
                  color: isLive ? const Color(0xFFECFDF5) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          item['time']!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item['title']!,
                          style: GoogleFonts.inter(
                            fontWeight: isLive ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLive ? 'Now Live' : item['duration']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLive ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppSlateColors.slate400),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppSlateColors.rose400),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3: SPEAKER MANAGEMENT VIEW
  // ==========================================
  Widget _buildSpeakerManagementView() {
    final speakers = [
      {
        'name': 'Dr. Aayush Sharma',
        'role': 'AI Researcher | Google',
        'topic': 'Topic: Generative AI & LLM Systems',
        'avatar': 'AS'
      },
      {
        'name': 'Priya Desai',
        'role': 'Tech Lead | Microsoft',
        'topic': 'Topic: Building Scalable Systems',
        'avatar': 'PD'
      },
      {
        'name': 'Rohan Mehta',
        'role': 'Founder | TechStart',
        'topic': 'Topic: Product & AI Innovation',
        'avatar': 'RM'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speakers',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage event speakers and generate introductions.',
                    style: GoogleFonts.inter(color: AppSlateColors.slate500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Speaker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search speakers...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppSlateColors.slate400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Speaker Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: speakers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final spk = speakers[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        spk['avatar']!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spk['name']!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            spk['role']!,
                            style: GoogleFonts.inter(fontSize: 13, color: AppSlateColors.slate500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            spk['topic']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: AppSlateColors.slate400),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Generate Intro Quick Action Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFF3E8FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Introduction',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF312E81),
                        ),
                      ),
                      Text(
                        'Use AI to create a compelling introduction for selected speakers.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4338CA)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Generate'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4: AI ASSISTANT VIEW
  // ==========================================
  Widget _buildAIAssistantView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Generate announcements, transitions and more.',
                    style: GoogleFonts.inter(color: AppSlateColors.slate500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Prompt Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _aiPromptController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Output Script Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF4F46E5),
                      child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Generated Teleprompter Script',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _aiGeneratedScript,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.6,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),

                // Script Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Script copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _aiGeneratedScript =
                              "Warm welcome to Dr. Aayush Sharma! As a leading Google AI researcher, Dr. Sharma will unveil breakthroughs in Generative AI. Let's put our hands together for an insightful session!";
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerate'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sent script to Stage Teleprompter!')),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Use as Script'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ask Anything Bottom Prompt Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiPromptController,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything or command AI...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                  onPressed: () {
                    setState(() {
                      _aiGeneratedScript =
                          "Generated intro based on: '${_aiPromptController.text}'. Ready for the anchor!";
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6: DYNAMIC SCHEDULE UPDATE VIEW
  // ==========================================
  Widget _buildScheduleUpdateView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Schedule',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            'Adjust the event flow based on real-time changes.',
            style: GoogleFonts.inter(color: AppSlateColors.slate500),
          ),
          const SizedBox(height: 24),

          // Duration Adjustment Picker Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delay Duration',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (_delayMinutes > 5) setState(() => _delayMinutes -= 5);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_delayMinutes min',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _delayMinutes += 5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'This will affect:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Keynote by Dr. Sharma (start time +$_delayMinutes min)'),
                _buildBulletPoint('Following sessions reflowed automatically'),
                _buildBulletPoint('Overall event end time adjusted'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _isDelayApplied = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied $_delayMinutes min schedule delay!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Updated Agenda Preview
          Text(
            'Updated Agenda Preview',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildPreviewItem('10:30 AM', 'Python Workshop', '1h 15m', true),
                const Divider(),
                _buildPreviewItem('11:45 AM', 'Keynote by Dr. Sharma', '45m', false),
                const Divider(),
                _buildPreviewItem('12:30 PM', 'Break & Networking', '15m', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String time, String title, String duration, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(time, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          const SizedBox(width: 20),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
          if (extended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Extended',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 12),
          Text(duration, style: GoogleFonts.inter(color: AppSlateColors.slate400, fontSize: 13)),
        ],
      ),
    );
  }

  // ==========================================
  // 7: EVENT SETTINGS / ADMIN PANEL
  // ==========================================
  Widget _buildEventSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Settings',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Configure your event details and AI preferences.',
                    style: GoogleFonts.inter(color: AppSlateColors.slate500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Settings Sub-Tabs
          Row(
            children: [
              _buildSettingsTab(0, 'General'),
              _buildSettingsTab(1, 'AI Preferences'),
              _buildSettingsTab(2, 'Notifications'),
            ],
          ),
          const SizedBox(height: 24),

          // Form Fields
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Details',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildTextField('Event Name', 'GDG Hackathon 2026', Icons.event_rounded),
                const SizedBox(height: 16),

                _buildTextField('Date', '19 - 20 Sep 2026', Icons.calendar_today_rounded),
                const SizedBox(height: 16),

                _buildTextField('Location', 'Auditorium, GDG Campus', Icons.location_on_rounded),
                const SizedBox(height: 24),

                Text(
                  'AI Features',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildToggleRow('Enable AI Assistant', true),
                _buildToggleRow('Auto-generate Introductions', true),
                _buildToggleRow('Smart Schedule Adjustment', true),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(int index, String title) {
    final isSelected = _settingsTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _settingsTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppSlateColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppSlateColors.slate400),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, bool initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155))),
          Switch(
            value: initialValue,
            onChanged: (val) {},
            activeThumbColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

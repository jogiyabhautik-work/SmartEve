import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/script_model.dart';
import '../../providers/scripts_provider.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import 'widgets/admin_analytics_sheet.dart';
import 'widgets/expanded_script_modal.dart';
import 'widgets/organizer_connection_sheet.dart';
import 'widgets/script_card.dart';

class ScriptsLibraryScreen extends StatefulWidget {
  const ScriptsLibraryScreen({super.key});

  @override
  State<ScriptsLibraryScreen> createState() => _ScriptsLibraryScreenState();
}

class _ScriptsLibraryScreenState extends State<ScriptsLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _filterTabs = const [
    {'key': 'all', 'label': 'All'},
    {'key': 'opening', 'label': 'Opening'},
    {'key': 'speaker_intro', 'label': 'Speaker Intro'},
    {'key': 'transition', 'label': 'Transition'},
    {'key': 'closing', 'label': 'Closing'},
    {'key': 'announcements', 'label': 'Announcements'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRealtimeToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScriptsProvider>(
      builder: (context, scriptsProvider, _) {
        // Handle incoming toast alerts from real-time events
        if (scriptsProvider.latestToastNotification != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRealtimeToast(scriptsProvider.latestToastNotification!);
            scriptsProvider.clearToast();
          });
        }

        final filteredScripts = scriptsProvider.filteredScripts;
        final nextScript = scriptsProvider.nextScript;

        return Scaffold(
          backgroundColor: AppTheme.lightBackground,
          appBar: _buildAppBar(scriptsProvider),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1000;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

              if (isDesktop) {
                return _buildDesktopLayout(scriptsProvider, filteredScripts, nextScript);
              } else {
                return _buildMobileTabletLayout(
                  scriptsProvider,
                  filteredScripts,
                  nextScript,
                  isTablet: isTablet,
                );
              }
            },
          ),
          // BOTTOM STICKY SECTION (When near event time)
          bottomNavigationBar: nextScript != null ? _buildBottomStickyBar(scriptsProvider, nextScript) : null,
        );
      },
    );
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar(ScriptsProvider provider) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SCRIPTS LIBRARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.liveGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: AppTheme.liveGreen),
                    SizedBox(width: 4),
                    Text(
                      'LIVE STAGE SYNC',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.liveGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Stage Scripts & Teleprompter Lineup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
        ],
      ),
      actions: [
        // Organizer Collaboration Hub shortcut
        Tooltip(
          message: 'Organizer Live Hub',
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.hub_rounded, size: 18, color: AppTheme.primaryBlue),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => OrganizerConnectionSheet.show(context, provider),
          ),
        ),

        // Admin Analytics & Override shortcut
        Tooltip(
          message: 'Admin Analytics & AI Override',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.analytics_rounded, size: 18, color: AppTheme.secondaryPurple),
            ),
            onPressed: () => AdminAnalyticsSheet.show(context, provider),
          ),
        ),

        // Teleprompter Direct Link
        Tooltip(
          message: 'Open Teleprompter HUD',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.speed_rounded, size: 18, color: AppTheme.textPrimary),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnchorTeleprompterScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- MOBILE & TABLET LAYOUT ---
  Widget _buildMobileTabletLayout(
    ScriptsProvider provider,
    List<ScriptModel> scripts,
    ScriptModel? nextScript, {
    required bool isTablet,
  }) {
    return RefreshIndicator(
      onRefresh: () => provider.loadScripts(),
      color: AppTheme.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // TOP SECTION: Search & Filter Bar
          SliverToBoxAdapter(
            child: _buildTopSearchAndFilterSection(provider),
          ),

          // SCRIPT CARDS or EMPTY STATE
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            )
          else if (scripts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(provider),
            )
          else if (isTablet)
            // Tablet 2-Column Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final script = scripts[index];
                    return ScriptCard(
                      script: script,
                      isCurrentOrNext: script.id == nextScript?.id,
                      onTap: () => ExpandedScriptModal.show(context, script: script, provider: provider),
                    );
                  },
                  childCount: scripts.length,
                ),
              ),
            )
          else
            // Mobile Vertical Stack
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final script = scripts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ScriptCard(
                        script: script,
                        isCurrentOrNext: script.id == nextScript?.id,
                        onTap: () => ExpandedScriptModal.show(context, script: script, provider: provider),
                      ),
                    );
                  },
                  childCount: scripts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DESKTOP 3-COLUMN LAYOUT WITH FIXED SIDEBAR ---
  Widget _buildDesktopLayout(
    ScriptsProvider provider,
    List<ScriptModel> scripts,
    ScriptModel? nextScript,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed Filter & Navigation Sidebar
        Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(right: BorderSide(color: AppTheme.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              ..._filterTabs.map((tab) {
                final isSelected = provider.selectedFilter == tab['key'];
                final count = provider.getCountForFilter(tab['key']!);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => provider.setFilter(tab['key']!),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tab['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 14),
              const Text(
                'Sort Strategy',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildSortDropdown(provider, isCompact: false),
              const Spacer(),
              // Quick action buttons in desktop sidebar
              ElevatedButton.icon(
                onPressed: () => OrganizerConnectionSheet.show(context, provider),
                icon: const Icon(Icons.hub_rounded, size: 16),
                label: const Text('Organizer Hub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),

        // Main 3-Column Grid Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Desktop Search Box
                _buildSearchInput(provider),
                const SizedBox(height: 20),
                Expanded(
                  child: scripts.isEmpty
                      ? _buildEmptyState(provider)
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: scripts.length,
                          itemBuilder: (context, index) {
                            final script = scripts[index];
                            return ScriptCard(
                              script: script,
                              isCurrentOrNext: script.id == nextScript?.id,
                              onTap: () => ExpandedScriptModal.show(context, script: script, provider: provider),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TOP SEARCH & FILTER BAR ---
  Widget _buildTopSearchAndFilterSection(ScriptsProvider provider) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Input: "Search scripts by type, speaker, or keyword..."
          _buildSearchInput(provider),

          const SizedBox(height: 12),

          // 2. Filter Buttons (horizontal scroll) & Sort dropdown row
          Row(
            children: [
              // Filter Buttons (horizontal scroll)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filterTabs.map((tab) {
                      final isSelected = provider.selectedFilter == tab['key'];
                      final count = provider.getCountForFilter(tab['key']!);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => provider.setFilter(tab['key']!),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tab['label']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : AppTheme.border.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Sort dropdown button
              _buildSortDropdown(provider, isCompact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(ScriptsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => provider.setSearchQuery(val),
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search scripts by type, speaker, or keyword...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(ScriptsProvider provider, {required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ScriptSortOption>(
          value: provider.sortOption,
          icon: const Icon(Icons.swap_vert_rounded, size: 18, color: AppTheme.textSecondary),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          onChanged: (opt) {
            if (opt != null) provider.setSortOption(opt);
          },
          items: const [
            DropdownMenuItem(
              value: ScriptSortOption.timeAsc,
              child: Text('Time (Earliest)'),
            ),
            DropdownMenuItem(
              value: ScriptSortOption.timeDesc,
              child: Text('Time (Latest)'),
            ),
            DropdownMenuItem(
              value: ScriptSortOption.byType,
              child: Text('By Type'),
            ),
            DropdownMenuItem(
              value: ScriptSortOption.recentlyUpdated,
              child: Text('Recently Updated'),
            ),
          ],
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState(ScriptsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No scripts available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Organizer will generate scripts soon, or try adjusting your search filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.clearSearch();
                provider.setFilter('all');
                provider.loadScripts();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM STICKY SECTION (When near event time) ---
  Widget _buildBottomStickyBar(ScriptsProvider provider, ScriptModel nextScript) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.deepNavy,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.cyan,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Next Script Display: "Next: Speaker Intro - John Doe | 10:35 AM"
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STAGE PROMPTER CUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppTheme.cyan,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Next: ${nextScript.typeLabel} — ${nextScript.title} | ${nextScript.timeSlot ?? "Next Up"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Floating "Open Full Script" button
            ElevatedButton(
              onPressed: () {
                ExpandedScriptModal.show(context, script: nextScript, provider: provider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Open Full Script',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

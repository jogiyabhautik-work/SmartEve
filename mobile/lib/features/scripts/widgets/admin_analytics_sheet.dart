import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/scripts_provider.dart';

class AdminAnalyticsSheet extends StatefulWidget {
  final ScriptsProvider provider;

  const AdminAnalyticsSheet({
    super.key,
    required this.provider,
  });

  static Future<void> show(BuildContext context, ScriptsProvider provider) {
    provider.fetchAdminAnalytics();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminAnalyticsSheet(provider: provider),
    );
  }

  @override
  State<AdminAnalyticsSheet> createState() => _AdminAnalyticsSheetState();
}

class _AdminAnalyticsSheetState extends State<AdminAnalyticsSheet> {
  String? _selectedScriptIdForOverride;
  final TextEditingController _overridePromptController = TextEditingController();
  bool _isRegenerating = false;
  String? _overrideResult;

  @override
  void initState() {
    super.initState();
    if (widget.provider.scripts.isNotEmpty) {
      _selectedScriptIdForOverride = widget.provider.scripts.first.id;
    }
  }

  @override
  void dispose() {
    _overridePromptController.dispose();
    super.dispose();
  }

  void _runAdminOverride() async {
    if (_selectedScriptIdForOverride == null) return;
    final prompt = _overridePromptController.text.trim();

    setState(() {
      _isRegenerating = true;
      _overrideResult = null;
    });

    final res = await widget.provider.generateAiAssistance(
      scriptId: _selectedScriptIdForOverride!,
      customPrompt: prompt.isEmpty
          ? 'Admin Override: Regenerate this script with authoritative, high-clarity keynote delivery instructions.'
          : prompt,
    );

    if (mounted) {
      setState(() {
        _isRegenerating = false;
        _overrideResult = res;
      });
    }
  }

  void _applyAdminOverride() {
    if (_overrideResult == null || _selectedScriptIdForOverride == null) return;
    widget.provider.applyRegeneratedScript(_selectedScriptIdForOverride!, _overrideResult!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin override applied to script successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scripts = widget.provider.scripts;
    final analytics = widget.provider.adminAnalytics ?? {};
    final totalScripts = analytics['totalScripts'] ?? scripts.length;
    final reviewRate = analytics['reviewRate'] ?? 0;
    final totalWords = analytics['totalWords'] ?? 0;
    final mostUsed = analytics['mostUsed'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppTheme.secondaryPurple, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Script Analytics & Override',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Teleprompter usage metrics & Quad-AI admin controls',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // KPI Stats
          Row(
            children: [
              _buildMetricCard('Total Scripts', '$totalScripts', AppTheme.primaryBlue, Icons.description_outlined),
              const SizedBox(width: 8),
              _buildMetricCard('Review Rate', '$reviewRate%', AppTheme.success, Icons.verified_rounded),
              const SizedBox(width: 8),
              _buildMetricCard('Total Words', '$totalWords', AppTheme.secondaryPurple, Icons.text_snippet_outlined),
            ],
          ),

          const SizedBox(height: 16),

          // Most Used Scripts Leaderboard
          const Text(
            'Most Utilized Scripts (Stage Practice & Views)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: mostUsed.isEmpty
                ? const Text('No usage events recorded yet.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                : Column(
                    children: mostUsed.map((item) {
                      final title = item['title'] ?? 'Script';
                      final count = item['count'] ?? 0;
                      final type = item['type'] ?? 'opening';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type.toString().toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '$count views',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // Admin Override Section Header
          const Text(
            'Admin Script Regeneration Override',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Force-regenerate any script using SmartEve Quad-AI Cascade.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),

          // Target Script Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedScriptIdForOverride,
            decoration: InputDecoration(
              labelText: 'Select Script to Override',
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: scripts.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text('${s.typeLabel}: ${s.title}', style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedScriptIdForOverride = val);
            },
          ),

          const SizedBox(height: 10),

          // Override prompt
          TextField(
            controller: _overridePromptController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Admin instruction (e.g. emphasize international VIPs, adjust for stage overtime)...',
              hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRegenerating ? null : _runAdminOverride,
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: Text(_isRegenerating ? 'Executing Quad-AI Cascade...' : 'Execute Admin Override'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          if (_overrideResult != null) ...[
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.secondaryPurple.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quad-AI Output Preview:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.secondaryPurple),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _overrideResult!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _applyAdminOverride,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Apply Script Override', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/script_model.dart';
import '../../../providers/scripts_provider.dart';
import 'script_modification_sheet.dart';

class ExpandedScriptModal extends StatefulWidget {
  final ScriptModel script;
  final ScriptsProvider provider;

  const ExpandedScriptModal({
    super.key,
    required this.script,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required ScriptModel script,
    required ScriptsProvider provider,
  }) {
    // Record that anchor viewed this script immediately
    provider.markScriptAsViewed(script.id);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpandedScriptModal(
        script: script,
        provider: provider,
      ),
    );
  }

  @override
  State<ExpandedScriptModal> createState() => _ExpandedScriptModalState();
}

class _ExpandedScriptModalState extends State<ExpandedScriptModal> {
  late ScriptModel _currentScript;
  final TextEditingController _aiPromptController = TextEditingController();

  bool _isAiSectionExpanded = false;
  bool _isGeneratingAi = false;
  String? _generatedAiResponse;
  String? _selectedQuickPrompt;

  @override
  void initState() {
    super.initState();
    _currentScript = widget.script;
  }

  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentScript.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Script copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareOptions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Share Stage Script',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
              ),
              title: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Send script to stage team or anchor group'),
              onTap: () {
                Navigator.of(ctx).pop();
                _copyToClipboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied script link ready for WhatsApp share!')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
              ),
              title: const Text('Share via Email', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Email agenda notes to production lead'),
              onTap: () {
                Navigator.of(ctx).pop();
                _copyToClipboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prepared email draft with stage script.')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _openModificationSheet() {
    ScriptModificationSheet.show(
      context,
      script: _currentScript,
      onSubmit: (notes, priority) async {
        await widget.provider.requestModification(
          scriptId: _currentScript.id,
          feedbackNote: notes,
          priority: priority,
        );
        setState(() {
          _currentScript = _currentScript.copyWith(
            status: 'revised',
            isUpdated: true,
          );
        });
      },
    );
  }

  void _toggleReviewed() async {
    await widget.provider.toggleScriptReviewed(_currentScript.id);
    setState(() {
      _currentScript = _currentScript.copyWith(
        isReviewedByAnchor: !_currentScript.isReviewedByAnchor,
      );
    });
  }

  void _triggerAiQuickAction(String action) async {
    setState(() {
      _selectedQuickPrompt = action;
      _isGeneratingAi = true;
      _generatedAiResponse = null;
      _isAiSectionExpanded = true;
    });

    final res = await widget.provider.generateAiAssistance(
      scriptId: _currentScript.id,
      customPrompt: action,
      quickAction: action,
    );

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        _generatedAiResponse = res;
      });
    }
  }

  void _triggerCustomAiPrompt() async {
    final text = _aiPromptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isGeneratingAi = true;
      _generatedAiResponse = null;
      _isAiSectionExpanded = true;
    });

    final res = await widget.provider.generateAiAssistance(
      scriptId: _currentScript.id,
      customPrompt: text,
    );

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        _generatedAiResponse = res;
      });
    }
  }

  void _applyAiScript() {
    if (_generatedAiResponse == null) return;
    widget.provider.applyRegeneratedScript(_currentScript.id, _generatedAiResponse!);
    setState(() {
      _currentScript = _currentScript.copyWith(
        text: _generatedAiResponse!,
        version: _currentScript.version + 1,
        isUpdated: true,
      );
      _generatedAiResponse = null;
      _selectedQuickPrompt = null;
      _aiPromptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeColor = _currentScript.badgeColor;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),

          // Modal Top Header
          _buildModalHeader(badgeColor),

          const Divider(height: 1, color: AppTheme.border),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Badges Row: Tone, Audience, Words, Reading Time
                  _buildMetaBadgesRow(),

                  const SizedBox(height: 18),

                  // Script Prose Box
                  _buildScriptContentBox(),

                  const SizedBox(height: 20),

                  // Action Buttons Bar
                  _buildActionButtonsBar(),

                  const SizedBox(height: 24),

                  // SmartEve AI Assistant Section
                  _buildSmartEveAiSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalHeader(Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded Title & Type Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        _currentScript.typeLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentScript.timeSlot ?? 'Time Slot TBD',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _currentScript.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Organizer approval line with avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Approved by ${_currentScript.organizerApprovedName ?? "Alex Rivera"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    const Text(
                      'Updated live',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textPrimary),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadgesRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Tone Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.graphic_eq_rounded, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 5),
              Text(
                'Tone: ${_currentScript.tone ?? "Motivational"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Target Audience
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined, size: 14, color: AppTheme.secondaryPurple),
              const SizedBox(width: 5),
              Text(
                'Audience: ${_currentScript.targetAudience ?? "All Attendees"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Word Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            '${_currentScript.wordCount} words',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // Reading Time estimate
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.cyan),
              const SizedBox(width: 5),
              Text(
                _currentScript.readingTimeFormatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cyan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScriptContentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: SelectableText(
        _currentScript.text,
        style: const TextStyle(
          fontSize: 17,
          height: 1.65,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildActionButtonsBar() {
    return Column(
      children: [
        // Primary action grid (Copy, Share, Request Mod, Review)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Copy to Clipboard
            OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy to Clipboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // Share (WhatsApp / Email)
            OutlinedButton.icon(
              onPressed: _showShareOptions,
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // Request Modification
            OutlinedButton.icon(
              onPressed: _openModificationSheet,
              icon: const Icon(Icons.edit_note_rounded, size: 17, color: AppTheme.warning),
              label: const Text('Request Change', style: TextStyle(color: AppTheme.warning)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.warning),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // SmartEve AI Assist trigger
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isAiSectionExpanded = !_isAiSectionExpanded);
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(_isAiSectionExpanded ? 'Hide AI Assist' : 'SmartEve AI Assist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Mark as Reviewed Checkbox Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _currentScript.isReviewedByAnchor
                ? AppTheme.success.withValues(alpha: 0.08)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentScript.isReviewedByAnchor ? AppTheme.success : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _currentScript.isReviewedByAnchor,
                activeColor: AppTheme.success,
                onChanged: (_) => _toggleReviewed(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentScript.isReviewedByAnchor
                          ? 'Marked as Reviewed ✓'
                          : 'Mark as Reviewed by Anchor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _currentScript.isReviewedByAnchor
                            ? AppTheme.success
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'Organizer can see your live review sign-off status',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartEveAiSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondaryPurple.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryPurple.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with AI banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask SmartEve AI for help',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Instant script alterations backed by Quad-Tier AI Cascade',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Suggestion Buttons
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionButton('Make it shorter'),
              _buildQuickActionButton('Make it more engaging'),
              _buildQuickActionButton('Add humor'),
              _buildQuickActionButton('Explain more'),
            ],
          ),

          const SizedBox(height: 14),

          // Custom prompt textfield
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiPromptController,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Custom request (e.g. mention sponsor, add stage cue)...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isGeneratingAi ? null : _triggerCustomAiPrompt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isGeneratingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
              ),
            ],
          ),

          // AI Response Preview & Apply Button
          if (_isGeneratingAi)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryPurple),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'SmartEve AI is crafting your stage script...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryPurple,
                    ),
                  ),
                ],
              ),
            ),

          if (_generatedAiResponse != null && !_isGeneratingAi) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.secondaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppTheme.secondaryPurple),
                      const SizedBox(width: 6),
                      Text(
                        'AI Suggestion (${_selectedQuickPrompt ?? "Custom"})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedAiResponse!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _generatedAiResponse = null),
                        child: const Text('Discard', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _applyAiScript,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Apply Regenerated Script'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label) {
    final isSelected = _selectedQuickPrompt == label;
    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.secondaryPurple,
      ),
      backgroundColor: isSelected ? AppTheme.secondaryPurple : AppTheme.secondaryPurple.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? AppTheme.secondaryPurple : AppTheme.secondaryPurple.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _triggerAiQuickAction(label),
    );
  }
}

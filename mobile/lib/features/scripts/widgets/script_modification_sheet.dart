import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/script_model.dart';

class ScriptModificationSheet extends StatefulWidget {
  final ScriptModel script;
  final Future<void> Function(String notes, String priority) onSubmit;

  const ScriptModificationSheet({
    super.key,
    required this.script,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required ScriptModel script,
    required Future<void> Function(String notes, String priority) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScriptModificationSheet(
        script: script,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ScriptModificationSheet> createState() => _ScriptModificationSheetState();
}

class _ScriptModificationSheetState extends State<ScriptModificationSheet> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedPriority = 'medium'; // 'low', 'medium', 'urgent'
  bool _isSubmitting = false;

  final List<String> _quickTags = [
    'Shorten by 30 seconds',
    'Pronounce name guide',
    'Speaker title updated',
    'Add sponsor acknowledgment',
    'More energetic opening',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _notesController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the requested modification.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.onSubmit(text, _selectedPriority);
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Script Modification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Script: ${widget.script.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
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

          // Priority Selector
          const Text(
            'Urgency Level',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityChip('low', 'Low', AppTheme.textSecondary),
              const SizedBox(width: 8),
              _buildPriorityChip('medium', 'Medium', AppTheme.warning),
              const SizedBox(width: 8),
              _buildPriorityChip('urgent', 'Urgent (Stage Live)', AppTheme.alertRed),
            ],
          ),

          const SizedBox(height: 16),

          // Quick tag pills
          const Text(
            'Quick Suggestions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickTags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppTheme.surfaceLight,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () {
                      if (_notesController.text.isEmpty) {
                        _notesController.text = tag;
                      } else {
                        _notesController.text += ' • $tag';
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Modification notes input
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe what adjustments are needed for the organizer...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send to Organizer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/scripts_provider.dart';
import '../../scripts/widgets/script_card.dart';
import '../../scripts/widgets/expanded_script_modal.dart';

class EventScriptsTab extends StatelessWidget {
  const EventScriptsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScriptsProvider>(
      builder: (context, provider, _) {
        final scripts = provider.filteredScripts;

        if (scripts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.description_outlined,
                    size: 40, color: AppTheme.textMuted),
                SizedBox(height: 12),
                Text('No scripts linked to this event',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'EVENT SCRIPTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scripts.length,
              itemBuilder: (context, index) {
                final script = scripts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScriptCard(
                    script: script,
                    isCurrentOrNext: false,
                    onTap: () => ExpandedScriptModal.show(context,
                        script: script, provider: provider),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

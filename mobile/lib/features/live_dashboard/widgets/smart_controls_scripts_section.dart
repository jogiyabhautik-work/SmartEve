import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';
import 'announcement_modal.dart';
import 'delay_handling_modal.dart';
import 'stage_messages_sheet.dart';

class SmartControlsScriptsSection extends StatefulWidget {
  final VoidCallback onOpenTeleprompter;
  const SmartControlsScriptsSection({super.key, required this.onOpenTeleprompter});

  @override
  State<SmartControlsScriptsSection> createState() => _SmartControlsScriptsSectionState();
}

class _SmartControlsScriptsSectionState extends State<SmartControlsScriptsSection> {
  bool _isNotesExpanded = false;
  bool _isNextScriptExpanded = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LiveDashboardProvider>();
    _notesController = TextEditingController(text: provider.anchorNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final script = provider.currentScript;
    final nextScript = provider.nextScript;
    final nextActivity = provider.nextActivity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Script Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_rounded, size: 14, color: Color(0xFF818CF8)),
                        const SizedBox(width: 6),
                        Text(
                          "ON-STAGE SCRIPT",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF818CF8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: widget.onOpenTeleprompter,
                      child: Text(
                        "Open Full Script →",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  script?.content != null && script!.content.isNotEmpty
                      ? script.content
                      : "Welcome everyone to SmartEve Live. We are thrilled to have industry innovators and thought leaders here today.",
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFE2E8F0),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Next Script (tap to expand) — next speaker intro
          InkWell(
            onTap: () {
              setState(() {
                _isNextScriptExpanded = !_isNextScriptExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.skip_next_rounded,
                          size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nextScript != null
                              ? "NEXT SCRIPT • ${nextScript.title.toUpperCase()}"
                              : "NEXT SCRIPT • ${nextActivity != null ? nextActivity.title.toUpperCase() : 'STANDBY'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFBBF24),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Icon(
                        _isNextScriptExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: const Color(0xFFFBBF24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextScript?.content.isNotEmpty == true
                        ? nextScript!.content
                        : nextActivity?.speaker != null
                            ? "Please welcome ${nextActivity!.speaker!.name} to the stage for '${nextActivity.title}'. A big round of applause!"
                            : "Next speaker intro will appear here once queued.",
                    maxLines: _isNextScriptExpanded ? 20 : 2,
                    overflow: _isNextScriptExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFFDE68A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Scratchpad / Notes Accordion
          InkWell(
            onTap: () {
              setState(() {
                _isNotesExpanded = !_isNotesExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    "Anchor Notes & Cues",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isNotesExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_isNotesExpanded) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              onChanged: provider.updateAnchorNotes,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type quick stage reminder...",
                hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF020617),
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Smart Action Buttons (Vertical Stack)

          // 1. Mark Complete / Auto-Advance button
          if (provider.isAutoAdvancing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Advancing in ${provider.autoAdvanceCountdown}s...",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: provider.cancelAutoAdvance,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text("CANCEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.startAutoAdvanceCountdown();
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: Text(
                  "Mark Complete",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // 2. Delay Activity Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const DelayHandlingModal(),
                  ),
                );
              },
              icon: const Icon(Icons.update_rounded, size: 16, color: Color(0xFFF59E0B)),
              label: Text(
                "Delay Activity",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFBBF24),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Make Announcement Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const AnnouncementModal(),
                  ),
                );
              },
              icon: const Icon(Icons.campaign_rounded, size: 16, color: Color(0xFF38BDF8)),
              label: Text(
                "Make Announcement",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF38BDF8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Row of SOS & Stage Messages
          Row(
            children: [
              // SOS / Get Help Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.postStageMessage("🚨 SOS ALERT: Anchor needs immediate backstage assistance!", isUrgent: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🚨 SOS Alert broadcast to all organizers & stage crew!"),
                          backgroundColor: Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning_rounded, size: 14, color: Colors.white),
                    label: Text(
                      "SOS Alert",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Stage Chat Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const StageMessagesSheet(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white70),
                    label: Text(
                      "Chat (${provider.stageMessages.length})",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

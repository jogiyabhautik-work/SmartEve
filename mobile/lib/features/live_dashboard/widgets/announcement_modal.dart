import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class AnnouncementModal extends StatefulWidget {
  const AnnouncementModal({super.key});

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal> {
  final TextEditingController _textController = TextEditingController();
  String _selectedType = "general";
  String _selectedPriority = "normal";
  bool _sendToOrganizerForApproval = false;
  bool _aiWorking = false;

  final List<Map<String, String>> _aiTemplates = [
    {
      "label": "Q&A Commencing",
      "text":
          "We are now commencing audience Q&A. Please submit your questions directly via the SmartEve app or signal the mic runner.",
    },
    {
      "label": "Brief 5m Intermission",
      "text":
          "Ladies and gentlemen, we are taking a brief 5-minute technical reset. Refreshments and networking are open in the foyer.",
    },
    {
      "label": "Speaker Announcement",
      "text":
          "Please give a warm round of applause as our keynote speaker takes the stage!",
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _applyAiSuggestion(String text) {
    setState(() {
      _textController.text = text;
    });
  }

  /// Simulated SmartEve AI polish (falls back gracefully offline).
  Future<void> _getAiHelp() async {
    setState(() => _aiWorking = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final raw = _textController.text.trim();
    final polished = raw.isEmpty
        ? "Ladies and gentlemen, a quick update from the stage — please stay with us for a brief moment. Exciting proceedings continue shortly. Thank you for your energy!"
        : "Ladies and gentlemen, $raw Thank you for your wonderful energy — please stay with us!";
    setState(() {
      _textController.text = polished;
      _aiWorking = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ SmartEve AI polished your announcement."),
          backgroundColor: Color(0xFF312E81),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Make Stage Announcement",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Real-time display on event screen + audience app",
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority & Type Selectors
            Row(
              children: [
                // Priority Pill (Standard / Urgent)
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPriority =
                          _selectedPriority == "normal" ? "urgent" : "normal";
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _selectedPriority == "urgent"
                          ? const Color(0xFFEF4444)
                              .withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedPriority == "urgent"
                            ? const Color(0xFFEF4444)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedPriority == "urgent"
                              ? Icons.priority_high_rounded
                              : Icons.notifications_none_rounded,
                          size: 14,
                          color: _selectedPriority == "urgent"
                              ? const Color(0xFFEF4444)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _selectedPriority == "urgent"
                              ? "URGENT / ALERT"
                              : "STANDARD",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedPriority == "urgent"
                                ? const Color(0xFFEF4444)
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Type dropdown
                DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: "general",
                        child: Text("General Announcement")),
                    DropdownMenuItem(
                        value: "qa", child: Text("Q&A Session")),
                    DropdownMenuItem(
                        value: "delay",
                        child: Text("Schedule Update")),
                    DropdownMenuItem(
                        value: "sponsor",
                        child: Text("Sponsor Mention")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Text Input Field
            TextField(
              controller: _textController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    "Enter stage announcement message to broadcast...",
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF020617),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Get AI Help button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _aiWorking ? null : _getAiHelp,
                icon: _aiWorking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF818CF8)),
                      )
                    : const Icon(Icons.auto_awesome_rounded,
                        size: 15, color: Color(0xFF818CF8)),
                label: Text(
                  _aiWorking
                      ? "SmartEve is drafting…"
                      : "Get AI Help",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA5B4FC),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // "Get AI Help" Chips
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Color(0xFF818CF8)),
                const SizedBox(width: 6),
                Text(
                  "Quick AI Templates:",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _aiTemplates.map((tpl) {
                return ActionChip(
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                  label: Text(
                    tpl['label']!,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFCBD5E1)),
                  ),
                  onPressed: () => _applyAiSuggestion(tpl['text']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Toggle: Send to Organizer for approval
            SwitchListTile(
              value: _sendToOrganizerForApproval,
              onChanged: (val) {
                setState(() {
                  _sendToOrganizerForApproval = val;
                });
              },
              title: Text(
                "Send to Organizer for approval",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              subtitle: Text(
                _sendToOrganizerForApproval
                    ? "Held for control-room approval before broadcast"
                    : "Broadcasts instantly to audience + event screen",
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
              activeThumbColor: const Color(0xFF38BDF8),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),

            // Send to Audience CTA
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = _textController.text.trim();
                  if (text.isEmpty) return;

                  provider.sendAnnouncement(
                    message: text,
                    type: _selectedType,
                    priority: _selectedPriority,
                    sendToOrganizerForApproval:
                        _sendToOrganizerForApproval,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_sendToOrganizerForApproval
                          ? "Sent to organizer for approval."
                          : "Announcement live on event screen + audience app!"),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _sendToOrganizerForApproval
                      ? "Send for Approval"
                      : "Send to Audience",
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

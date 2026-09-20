import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class UnplannedActivityModal extends StatefulWidget {
  const UnplannedActivityModal({super.key});

  @override
  State<UnplannedActivityModal> createState() => _UnplannedActivityModalState();
}

class _UnplannedActivityModalState extends State<UnplannedActivityModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  int _selectedDuration = 10;
  bool _insertNext = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();

    return Container(
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Unplanned Activity",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Injects new segment directly into the live stage schedule",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title Input
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              labelText: "Activity Title *",
              labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
              hintText: "e.g., Surprise Guest Q&A, Sponsor Giveaway",
              hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF020617),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Estimated Duration Presets
          Text(
            "ESTIMATED DURATION",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 15, 20].map((mins) {
              final isSelected = _selectedDuration == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDuration = mins;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${mins}m",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Description / Cue notes
          TextField(
            controller: _descController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              labelText: "Stage Notes & Cues (optional)",
              labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
              hintText: "Notes for teleprompter or stage manager...",
              hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF020617),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Insert Position Toggle
          SwitchListTile(
            value: _insertNext,
            onChanged: (val) {
              setState(() {
                _insertNext = val;
              });
            },
            title: Text(
              _insertNext ? "Insert as Next Activity" : "Append to end of queue",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            subtitle: Text(
              _insertNext ? "Will begin immediately after current session" : "Will play after all scheduled sessions",
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
            activeThumbColor: const Color(0xFF10B981),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Confirm CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;

                provider.addUnplannedActivity(
                  title: title,
                  durationMinutes: _selectedDuration,
                  description: _descController.text.trim(),
                  insertNext: _insertNext,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Added '$title' ($_selectedDuration min) to stage queue."),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text(
                "Insert Activity",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

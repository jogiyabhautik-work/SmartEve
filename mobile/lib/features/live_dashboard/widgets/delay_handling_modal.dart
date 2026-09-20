import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class DelayHandlingModal extends StatefulWidget {
  const DelayHandlingModal({super.key});

  @override
  State<DelayHandlingModal> createState() => _DelayHandlingModalState();
}

class _DelayHandlingModalState extends State<DelayHandlingModal> {
  int _selectedMinutes = 5;
  bool _notifyOrganizer = true;
  String? _selectedActivityId;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _customMinutesController =
      TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final current = provider.currentActivity;
    final allActivities = [
      if (current != null) current,
      if (provider.nextActivity != null) provider.nextActivity!,
      ...provider.upcomingQueue,
    ];
    _selectedActivityId ??= current?.id;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.update_rounded,
                      color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report Activity Delay",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Adjusts session duration and shifts remaining schedule",
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
            const SizedBox(height: 20),

            // Dropdown: Select activity
            Text(
              "SELECT ACTIVITY",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedActivityId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white),
                  items: allActivities
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              "${a.title} (${a.durationMinutes}m)",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedActivityId = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delay duration: presets + custom input
            Text(
              "DELAY DURATION (MINUTES)",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [5, 10, 15, 20].map((mins) {
                final isSelected = _selectedMinutes == mins;
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMinutes = mins;
                          _customMinutesController.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF59E0B)
                              : Colors.white
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF59E0B)
                                : Colors.white
                                    .withValues(alpha: 0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "+${mins}m",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v.trim());
                if (n != null && n > 0 && n <= 120) {
                  setState(() {
                    _selectedMinutes = n;
                  });
                }
              },
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                labelText: "Or enter custom minutes (1–120)",
                labelStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF020617),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reason (optional text)
            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                labelText: "Reason (optional)",
                labelStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 12),
                hintText: "e.g. Speaker running late, AV setup…",
                hintStyle: GoogleFonts.inter(
                    color: Colors.white30, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF020617),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Schedule Ripple Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFF59E0B)
                        .withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Subsequent ${provider.upcomingQueue.length} queue items will automatically shift by +$_selectedMinutes min.",
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFFDE68A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Toggle: Notify Organizer (auto on)
            SwitchListTile(
              value: _notifyOrganizer,
              onChanged: (val) {
                setState(() {
                  _notifyOrganizer = val;
                });
              },
              title: Text(
                "Notify Organizer",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              subtitle: Text(
                "Real-time push to control room + attendee banner",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8)),
              ),
              activeThumbColor: const Color(0xFFF59E0B),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),

            // Confirm & Continue
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.delayActivity(
                        minutes: _selectedMinutes,
                        notifyAll: _notifyOrganizer,
                        reason: _reasonController.text.trim(),
                        activityId: _selectedActivityId,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Confirmed: +$_selectedMinutes min delay applied. Organizer ${_notifyOrganizer ? 'notified in real time' : 'not notified'}."),
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      "Confirm & Continue",
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF0F172A),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

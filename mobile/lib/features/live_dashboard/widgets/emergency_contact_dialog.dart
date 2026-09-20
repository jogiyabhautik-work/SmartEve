import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class EmergencyContactDialog extends StatelessWidget {
  const EmergencyContactDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final organizer = provider.organizer;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emergency Header Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),

            Text(
              "Emergency Organizer Contact",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Direct priority communication line to event organizers",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),

            // Organizer Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      organizer.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizer.name,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          organizer.phone,
                          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: const Color(0xFF38BDF8)),
                        ),
                        Text(
                          organizer.email,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Direct Call CTA
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Initiating call to ${organizer.name} (${organizer.phone})..."),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.call_rounded, size: 20),
                label: Text(
                  "Call Organizer Now",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Stage Manager Broadcast Alert
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.postStageMessage("🚨 URGENT: Anchor requested immediate stage manager contact!", isUrgent: true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Emergency ping dispatched to backstage team."),
                      backgroundColor: Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.emergency_rounded, size: 18, color: Color(0xFFF59E0B)),
                label: Text(
                  "Page Backstage Crew",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFFBBF24)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Dismiss",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

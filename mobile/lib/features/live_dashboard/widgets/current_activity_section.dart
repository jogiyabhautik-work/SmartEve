import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class CurrentActivitySection extends StatelessWidget {
  const CurrentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final current = provider.currentActivity;
    final isOverdue = provider.isOverdue;
    final remainingSecs = provider.activityRemainingSeconds;
    final scheduleStatus = provider.scheduleStatus;

    if (current == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: Text(
            "No active stage session",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329), // Deep rich stage black/navy
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFEF4444).withValues(alpha: 0.6) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                : const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Current badge, Type, and Schedule Drift Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.co_present_rounded, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    Text(
                      "CURRENTLY ON STAGE",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF38BDF8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Activity Type Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  current.type.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),

              const Spacer(),

              // Schedule Drift Status Badge (On Track / Behind / Ahead)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheduleStatus.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheduleStatus.color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(scheduleStatus.icon, size: 13, color: scheduleStatus.color),
                    const SizedBox(width: 5),
                    Text(
                      provider.scheduleStatusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheduleStatus.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Activity Title (Large, Bold font 32px+)
          Text(
            current.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Speaker Row if available
          if (current.speaker != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF6366F1),
                    backgroundImage: current.speaker!.photoUrl != null && current.speaker!.photoUrl!.isNotEmpty
                        ? NetworkImage(current.speaker!.photoUrl!)
                        : null,
                    child: current.speaker!.photoUrl == null || current.speaker!.photoUrl!.isEmpty
                        ? Text(
                            current.speaker!.name.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.speaker!.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (current.speaker!.organization != null || current.speaker!.designation != null)
                          Text(
                            [
                              if (current.speaker!.designation != null) current.speaker!.designation,
                              if (current.speaker!.organization != null) current.speaker!.organization,
                            ].join(" • "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (current.speaker!.topic != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "KEYNOTE",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFA78BFA),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Dual Timers Grid: Elapsed vs Remaining
          Row(
            children: [
              // Elapsed Timer Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ELAPSED IN SESSION",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.formatDuration(provider.activityElapsedSeconds),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Countdown / Remaining Timer Card (Red alert if overdue)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOverdue ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOverdue ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isOverdue ? "OVERDUE BY" : "REMAINING TIME",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFF38BDF8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFEF4444)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (isOverdue ? "-" : "") + provider.formatDuration(remainingSecs),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (current.description != null && current.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              current.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
          ],

          const Spacer(),

          // Real-time Audience Engagement Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                // Attendees count
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      "${provider.metrics.activeAttendees}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Attendees",
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Questions count
                Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      "${provider.metrics.questionsCount}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Q&A",
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),

                const Spacer(),

                // Live Emoji Reactions: 👍 ❤️ 👏 🚀 🔥
                _buildReactionChip(context, "👍", provider.metrics.reactions['thumbsUp'] ?? 0, 'thumbsUp'),
                const SizedBox(width: 6),
                _buildReactionChip(context, "❤️", provider.metrics.reactions['heart'] ?? 0, 'heart'),
                const SizedBox(width: 6),
                _buildReactionChip(context, "👏", provider.metrics.reactions['applause'] ?? 0, 'applause'),
                const SizedBox(width: 6),
                _buildReactionChip(context, "🚀", provider.metrics.reactions['rocket'] ?? 0, 'rocket'),
                const SizedBox(width: 6),
                _buildReactionChip(context, "🔥", provider.metrics.reactions['fire'] ?? 0, 'fire'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionChip(BuildContext context, String emoji, int count, String key) {
    return InkWell(
      onTap: () {
        context.read<LiveDashboardProvider>().sendReaction(key);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              "$count",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

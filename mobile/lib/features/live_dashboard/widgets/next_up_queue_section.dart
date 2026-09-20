// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/live_dashboard_models.dart';
import '../providers/live_dashboard_provider.dart';
import 'unplanned_activity_modal.dart';

class NextUpQueueSection extends StatelessWidget {
  const NextUpQueueSection({super.key});

  void _previewActivity(
      BuildContext context, LiveActivityItem item, bool isNext) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isNext
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF38BDF8))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isNext ? "NEXT UP" : item.type.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isNext
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 18, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    "${item.durationMinutes} min • ${item.status}",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              if (item.speaker != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6366F1),
                      backgroundImage: item.speaker!.photoUrl != null &&
                              item.speaker!.photoUrl!.isNotEmpty
                          ? NetworkImage(item.speaker!.photoUrl!)
                          : null,
                      child: item.speaker!.photoUrl == null ||
                              item.speaker!.photoUrl!.isEmpty
                          ? Text(
                              item.speaker!.name.isNotEmpty
                                  ? item.speaker!.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : "?",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.speaker!.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (item.speaker!.designation != null ||
                              item.speaker!.organization != null)
                            Text(
                              [
                                if (item.speaker!.designation != null)
                                  item.speaker!.designation,
                                if (item.speaker!.organization != null)
                                  item.speaker!.organization,
                              ].join(" • "),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (item.description != null &&
                  item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description!,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFCBD5E1),
                      height: 1.4),
                ),
              ],
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Cue: ${item.notes!}",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFFFDE68A)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final next = provider.nextActivity;
    final queue = provider.upcomingQueue;

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
          // Header: NEXT UP & + Add Unplanned button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "NEXT UP & QUEUE",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: "Add Unplanned Activity",
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add,
                      size: 16, color: Color(0xFF38BDF8)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const UnplannedActivityModal(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // NEXT ACTIVITY Preview Card
          if (next != null) ...[
            InkWell(
              onTap: () => _previewActivity(context, next, true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "STARTS IN ${provider.formatDuration(provider.timeUntilNextSeconds)}",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${next.durationMinutes}m",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    if (next.speaker != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFF6366F1),
                            backgroundImage: next.speaker!.photoUrl !=
                                        null &&
                                    next.speaker!.photoUrl!.isNotEmpty
                                ? NetworkImage(next.speaker!.photoUrl!)
                                : null,
                            child: next.speaker!.photoUrl == null ||
                                    next.speaker!.photoUrl!.isEmpty
                                ? Text(
                                    next.speaker!.name.isNotEmpty
                                        ? next.speaker!.name
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : "?",
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  next.speaker!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (next.speaker!.organization != null)
                                  Text(
                                    next.speaker!.organization!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),

                    // "Prepare Now" Action Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final scriptTitle =
                              provider.nextScript?.title ?? "speaker intro";
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Prepare Now: '$scriptTitle' for '${next.title}' brought forward. Tap Scripts to rehearse."),
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        label: Text(
                          "Prepare Now",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Color(0xFFF59E0B)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Final activity on stage",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Upcoming Queue Header
          Text(
            "UPCOMING QUEUE (${queue.length}) • tap to preview",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Reorderable Upcoming List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Text(
                      "No further items in queue",
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white38),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: queue.length,
                    onReorder: provider.reorderUpcomingQueue,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      return InkWell(
                        key: ValueKey(item.id),
                        onTap: () =>
                            _previewActivity(context, item, false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 16,
                                  color: Colors.white24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (item.speaker != null)
                                      Text(
                                        item.speaker!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color:
                                              const Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${item.durationMinutes}m",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

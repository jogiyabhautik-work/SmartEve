import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/live_dashboard_provider.dart';

class StageMessagesSheet extends StatefulWidget {
  const StageMessagesSheet({super.key});

  @override
  State<StageMessagesSheet> createState() => _StageMessagesSheetState();
}

class _StageMessagesSheetState extends State<StageMessagesSheet> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDashboardProvider>();
    final messages = provider.stageMessages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.forum_rounded, color: Color(0xFF818CF8), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Backstage Live Comms",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Direct channel with stage manager and tech operators",
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
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
          const SizedBox(height: 14),

          // Message Stream
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      "No backstage messages yet",
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.isUrgent
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: msg.isUrgent
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  msg.senderName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: msg.isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "(${msg.senderRole})",
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('HH:mm:ss').format(msg.timestamp),
                                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white38),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              msg.message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),

          // Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Message backstage crew...",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF020617),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final text = _msgController.text.trim();
                  if (text.isEmpty) return;
                  provider.postStageMessage(text);
                  _msgController.clear();
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

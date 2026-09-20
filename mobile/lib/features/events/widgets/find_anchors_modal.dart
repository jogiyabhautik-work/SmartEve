import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/neon_database_service.dart';
import '../../../models/event_model.dart';

class FindAnchorsModal extends StatefulWidget {
  final EventModel event;

  const FindAnchorsModal({super.key, required this.event});

  static Future<void> show(BuildContext context, EventModel event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FindAnchorsModal(event: event),
    );
  }

  @override
  State<FindAnchorsModal> createState() => _FindAnchorsModalState();
}

class _FindAnchorsModalState extends State<FindAnchorsModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _anchors = [];
  List<Map<String, dynamic>> _filteredAnchors = [];
  final Set<String> _invitedAnchorIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnchors();
    _searchController.addListener(_filterAnchors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnchors() async {
    setState(() => _isLoading = true);
    try {
      final list = await NeonDatabaseService().getRegisteredAnchors();
      if (mounted) {
        setState(() {
          _anchors = list;
          _filteredAnchors = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAnchors() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredAnchors = _anchors);
    } else {
      setState(() {
        _filteredAnchors = _anchors.where((a) {
          final name = a['name'].toString().toLowerCase();
          final desig = a['designation'].toString().toLowerCase();
          final bio = a['bio'].toString().toLowerCase();
          final tags = (a['tags'] as List? ?? []).join(' ').toLowerCase();
          return name.contains(query) || desig.contains(query) || bio.contains(query) || tags.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _showInviteDialog(Map<String, dynamic> anchor) async {
    final noteController = TextEditingController(text: "Hi ${anchor['name']}, we would love for you to host our upcoming event '${widget.event.name}'.");
    final payController = TextEditingController(text: anchor['payRate']?.toString() ?? '₹15,000 / event');
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(anchor['photoUrl']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite ${anchor['name']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        anchor['designation'] ?? 'Stage Host',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EVENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      widget.event.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('COMPENSATION OFFER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: payController,
                    style: const TextStyle(color: AppTheme.liveGreen, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      hintText: 'e.g. ₹15,000',
                      prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.liveGreen),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('PERSONAL NOTE / CUES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      hintText: 'Add notes for the anchor…',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                icon: isSending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isSending ? 'Sending…' : 'SEND INVITATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.liveGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        setDialogState(() => isSending = true);
                        final success = await NeonDatabaseService().sendAnchorInvitation(
                          eventId: widget.event.id,
                          anchorId: anchor['id'].toString(),
                          anchorEmail: anchor['email']?.toString(),
                          notes: noteController.text.trim(),
                          payOffer: payController.text.trim(),
                        );
                        if (!dialogCtx.mounted || !mounted) return;
                        Navigator.pop(dialogCtx);
                        if (success) {
                          setState(() {
                            _invitedAnchorIds.add(anchor['id'].toString());
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Invitation sent to ${anchor['name']}! Saved in Neon DB.'),
                              backgroundColor: AppTheme.liveGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search_rounded, color: AppTheme.warningAmber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find & Invite Stage Anchors',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Explore registered hosts in Neon DB & invite to ${widget.event.name}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by anchor name, specialty, or keywords…',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Roster List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _filteredAnchors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 12),
                            Text('No anchors found matching your search.', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredAnchors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, idx) {
                          final anchor = _filteredAnchors[idx];
                          final id = anchor['id'].toString();
                          final isInvited = _invitedAnchorIds.contains(id);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isInvited ? AppTheme.liveGreen.withValues(alpha: 0.5) : AppTheme.border,
                                width: isInvited ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        anchor['photoUrl'],
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 54,
                                          height: 54,
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                          child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  anchor['name'],
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warningAmber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star_rounded, size: 12, color: AppTheme.warningAmber),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${anchor['rating']}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warningAmber),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            anchor['designation'],
                                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${anchor['experienceYears']} • ${anchor['eventsAnchored']} Events • ${anchor['payRate']}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  anchor['bio'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.35),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: (anchor['tags'] as List? ?? []).map<Widget>((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      isInvited ? Icons.check_circle_rounded : Icons.send_rounded,
                                      size: 16,
                                    ),
                                    label: Text(isInvited ? 'INVITED (PENDING)' : 'INVITE TO STAGE'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInvited ? AppTheme.liveGreen.withValues(alpha: 0.2) : AppTheme.liveGreen,
                                      foregroundColor: isInvited ? AppTheme.liveGreen : Colors.white,
                                      elevation: isInvited ? 0 : 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: isInvited ? null : () => _showInviteDialog(anchor),
                                  ),
                                ),
                              ],
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

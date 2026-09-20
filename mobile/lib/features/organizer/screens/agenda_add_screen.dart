import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/agenda_item_model.dart';
import '../../../providers/event_provider.dart';

class AgendaAddScreen extends StatefulWidget {
  final AgendaItemModel? itemToEdit;

  const AgendaAddScreen({super.key, this.itemToEdit});

  @override
  State<AgendaAddScreen> createState() => _AgendaAddScreenState();
}

class _AgendaAddScreenState extends State<AgendaAddScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _minDurationController;
  late TextEditingController _notesController;

  String _selectedType = 'talk';
  TimeOfDay _plannedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _absorbable = false;
  bool _hardStart = false;
  List<String> _selectedSpeakerIds = [];
  bool _isSaving = false;

  final Map<String, String> _typeLabels = {
    'opening': 'Opening Ceremony',
    'keynote': 'Keynote Speech',
    'talk': 'Tech Presentation / Talk',
    'panel': 'Panel Discussion',
    'break': 'Buffer / Tea Break',
    'workshop': 'Interactive Workshop',
    'announcement': 'Stage Announcement',
    'closing': 'Closing & Wrap-up',
  };

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _durationController = TextEditingController(text: (edit?.duration ?? 20).toString());
    _minDurationController = TextEditingController(text: (edit?.minDuration ?? 10).toString());
    _notesController = TextEditingController(text: edit?.notes ?? '');

    if (edit != null) {
      _selectedType = edit.type;
      _absorbable = edit.absorbable;
      _hardStart = edit.hardStart;
      _selectedSpeakerIds = List<String>.from(edit.speakerIds);
      if (edit.plannedStart.isNotEmpty) {
        final dt = DateTime.tryParse(edit.plannedStart);
        if (dt != null) {
          _plannedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _minDurationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _plannedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _plannedTime = picked;
      });
    }
  }

  Future<void> _submitAgendaItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<EventProvider>();

    final duration = int.tryParse(_durationController.text.trim()) ?? 15;
    final minDuration = _absorbable ? (int.tryParse(_minDurationController.text.trim()) ?? 10) : null;

    final now = DateTime.now();
    final plannedDt = DateTime(now.year, now.month, now.day, _plannedTime.hour, _plannedTime.minute);
    final plannedStartIso = plannedDt.toIso8601String();
    final endDt = plannedDt.add(Duration(minutes: duration));

    final newItem = AgendaItemModel(
      id: widget.itemToEdit?.id ?? 'item-${DateTime.now().millisecondsSinceEpoch}',
      order: widget.itemToEdit?.order ?? (provider.agenda.length + 1),
      title: _titleController.text.trim(),
      type: _selectedType,
      speakerIds: _selectedSpeakerIds,
      duration: duration,
      plannedStart: plannedStartIso,
      startTime: widget.itemToEdit?.startTime ?? plannedStartIso,
      endTime: widget.itemToEdit?.endTime ?? endDt.toIso8601String(),
      status: widget.itemToEdit?.status ?? 'upcoming',
      absorbable: _absorbable,
      minDuration: minDuration,
      hardStart: _hardStart,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final success = await provider.addAgendaItem(
      newItem,
      eventId: provider.event?.id,
      originalId: widget.itemToEdit?.id,
    );

    setState(() => _isSaving = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.itemToEdit != null
              ? '✅ Session "${newItem.title}" updated in Neon DB!'
              : '🚀 Session "${newItem.title}" added to Stage Timeline!'),
          backgroundColor: AppTheme.liveGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final speakers = provider.speakers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.itemToEdit != null ? 'Edit Agenda Session' : 'Add Agenda Session',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.view_timeline_rounded, color: AppTheme.primaryBlue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configure stage timing, linked speakers, and buffer settings stored in Neon DB.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Session Title
              const Text('SESSION TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Keynote: Future of Generative AI',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryBlue),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a session title' : null,
              ),
              const SizedBox(height: 18),

              // Session Type Dropdown
              const Text('SESSION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _typeLabels.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          if (val == 'break') {
                            _absorbable = true;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Planned Start Time & Duration Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 20, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  _plannedTime.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DURATION (MINS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '20',
                            prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.primaryBlue),
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                          ),
                          validator: (val) => (val == null || int.tryParse(val) == null) ? 'Enter mins' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Speaker Selection (if speakers exist)
              const Text('LINKED SPEAKERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              if (speakers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Text('No speakers registered for this event yet. You can link speakers later.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: speakers.map((spk) {
                    final isSelected = _selectedSpeakerIds.contains(spk.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(spk.name),
                      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryBlue,
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(color: isSelected ? AppTheme.primaryBlue : AppTheme.border),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSpeakerIds.add(spk.id);
                          } else {
                            _selectedSpeakerIds.remove(spk.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // Absorbable Break Switch
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Absorbable Buffer Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              SizedBox(height: 2),
                              Text('Can be shortened if earlier sessions run overtime', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _absorbable,
                          activeThumbColor: AppTheme.primaryBlue,
                          onChanged: (val) => setState(() => _absorbable = val),
                        ),
                      ],
                    ),
                    if (_absorbable) ...[
                      const Divider(height: 16, color: AppTheme.border),
                      Row(
                        children: [
                          const Text('MINIMUM DURATION (MINS):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: TextFormField(
                              controller: _minDurationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: AppTheme.surfaceLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hard Start Switch
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hard Start Time (Fixed)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          SizedBox(height: 2),
                          Text('Must start at exact scheduled time regardless of prior delays', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hardStart,
                      activeThumbColor: AppTheme.primaryPurple,
                      onChanged: (val) => setState(() => _hardStart = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Notes & Teleprompter Remarks
              const Text('ANCHOR & SPEAKER NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Introduce speaker with emphasis on AI safety research.',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitAgendaItem,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? 'SAVING TO NEON DB...' : (widget.itemToEdit != null ? 'UPDATE SESSION' : 'SAVE AGENDA SESSION'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

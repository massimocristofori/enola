import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/riddle.dart';
import '../../models/riddle_map.dart';
import '../../providers/map_providers.dart';
import '../../services/map_repository.dart';
import '../../theme/enola_theme.dart';
import '../../widgets/fantasy_widgets.dart';
import '../scan/scan_screen.dart';

class CreateMapScreen extends ConsumerStatefulWidget {
  final int? existingMapId;
  const CreateMapScreen({super.key, this.existingMapId});

  @override
  ConsumerState<CreateMapScreen> createState() => _CreateMapScreenState();
}

class _CreateMapScreenState extends ConsumerState<CreateMapScreen> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  RiddleMap? _existingMap;
  List<Riddle> _riddles = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMapId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    _existingMap = await MapRepository.instance.getMap(widget.existingMapId!);
    _riddles = await MapRepository.instance
        .getRiddlesForMap(widget.existingMapId!);
    if (_existingMap != null) {
      _titleCtrl.text = _existingMap!.title;
      _subjectCtrl.text = _existingMap!.subject ?? '';
      _descCtrl.text = _existingMap!.description ?? '';
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final map = _existingMap ?? RiddleMap(title: _titleCtrl.text.trim());
      map.title = _titleCtrl.text.trim();
      map.subject = _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim();
      map.description = _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim();

      final id = await MapRepository.instance.saveMap(map);
      await MapRepository.instance.saveRiddles(id, _riddles);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addRiddleManually() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRiddleSheet(
        onAdd: (riddle) {
          setState(() => _riddles.add(riddle));
        },
      ),
    );
  }

  Future<void> _openScan() async {
    final generated = await Navigator.push<List<Riddle>>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (generated != null && generated.isNotEmpty) {
      setState(() => _riddles.addAll(generated));
    }
  }

  void _removeRiddle(int index) {
    setState(() => _riddles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: EnolaTheme.accent))
              : Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMapInfoSection(),
                              const SizedBox(height: 28),
                              const RuneDivider(),
                              const SizedBox(height: 24),
                              _buildRiddlesSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: EnolaTheme.accent,
        foregroundColor: EnolaTheme.background,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: EnolaTheme.background))
            : const Icon(Icons.save_rounded),
        label: const Text('Save Map',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EnolaTheme.accent),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            widget.existingMapId == null ? 'New Quest Map' : 'Edit Map',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: EnolaTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Map Details'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleCtrl,
          style: const TextStyle(color: EnolaTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Map Title *',
            hintText: 'e.g. The Roman Empire',
            prefixIcon: Icon(Icons.auto_stories_rounded, color: EnolaTheme.accent),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _subjectCtrl,
          style: const TextStyle(color: EnolaTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Subject (optional)',
            hintText: 'e.g. History, Science…',
            prefixIcon: Icon(Icons.school_rounded, color: EnolaTheme.accent),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descCtrl,
          style: const TextStyle(color: EnolaTheme.textPrimary),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'What is this quest about?',
            prefixIcon: Icon(Icons.notes_rounded, color: EnolaTheme.accent),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRiddlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel('Riddles (${_riddles.length})'),
            const Spacer(),
            _SmallButton(
              icon: Icons.document_scanner_rounded,
              label: 'Scan Pages',
              onTap: _openScan,
              accent: true,
            ),
            const SizedBox(width: 8),
            _SmallButton(
              icon: Icons.add_rounded,
              label: 'Manual',
              onTap: _addRiddleManually,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_riddles.isEmpty)
          _EmptyRiddles(
            onScan: _openScan,
            onManual: _addRiddleManually,
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _riddles.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final r = _riddles.removeAt(oldIndex);
                _riddles.insert(newIndex, r);
              });
            },
            itemBuilder: (context, i) {
              return _RiddleTile(
                key: ValueKey('riddle_$i'),
                riddle: _riddles[i],
                index: i,
                onDelete: () => _removeRiddle(i),
              );
            },
          ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: EnolaTheme.accent,
        letterSpacing: 2,
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent ? EnolaTheme.accentSoft : const Color(0xFF1E1A10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent ? EnolaTheme.accent : const Color(0xFF4A3F22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: EnolaTheme.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: EnolaTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Riddle tile in list ───────────────────────────────────────────────────────

class _RiddleTile extends StatelessWidget {
  final Riddle riddle;
  final int index;
  final VoidCallback onDelete;

  const _RiddleTile({
    super.key,
    required this.riddle,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = riddle.type == RiddleType.multipleChoice
        ? 'Multiple Choice'
        : 'Ordering';
    final typeIcon = riddle.type == RiddleType.multipleChoice
        ? Icons.help_outline_rounded
        : Icons.sort_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ParchmentCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EnolaTheme.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: EnolaTheme.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riddle.question,
                    style: const TextStyle(
                        color: EnolaTheme.textPrimary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                        color: EnolaTheme.textSecond, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.drag_handle_rounded,
                color: EnolaTheme.textSecond, size: 20),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded,
                  color: EnolaTheme.wrong, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty riddles state ───────────────────────────────────────────────────────

class _EmptyRiddles extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onManual;

  const _EmptyRiddles({required this.onScan, required this.onManual});

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 36, color: EnolaTheme.accent),
          const SizedBox(height: 12),
          const Text(
            'No riddles yet',
            style: TextStyle(
                color: EnolaTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan book pages to auto-generate riddles with AI,\nor add them manually.',
            textAlign: TextAlign.center,
            style: TextStyle(color: EnolaTheme.textSecond, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.document_scanner_rounded, size: 16),
                  label: const Text('Scan Pages'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.add_rounded, size: 16,
                      color: EnolaTheme.accent),
                  label: const Text('Manual',
                      style: TextStyle(color: EnolaTheme.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: EnolaTheme.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

// ── Add Riddle Sheet ──────────────────────────────────────────────────────────

class _AddRiddleSheet extends StatefulWidget {
  final void Function(Riddle) onAdd;
  const _AddRiddleSheet({required this.onAdd});

  @override
  State<_AddRiddleSheet> createState() => _AddRiddleSheetState();
}

class _AddRiddleSheetState extends State<_AddRiddleSheet> {
  RiddleType _type = RiddleType.multipleChoice;
  final _questionCtrl = TextEditingController();

  // Multiple choice
  final _choiceCtrls = List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  // Ordering
  final _itemCtrls = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _choiceCtrls) c.dispose();
    for (final c in _itemCtrls) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_questionCtrl.text.trim().isEmpty) return;

    final riddle = Riddle()..question = _questionCtrl.text.trim();

    if (_type == RiddleType.multipleChoice) {
      final choices =
          _choiceCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      if (choices.length < 2) return;
      riddle.type = RiddleType.multipleChoice;
      riddle.mcChoicesJson = jsonEncode(choices);
      riddle.mcCorrectIndex = _correctIndex.clamp(0, choices.length - 1);
    } else {
      final items =
          _itemCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      if (items.length < 2) return;
      riddle.type = RiddleType.ordering;
      riddle.orderItemsJson = jsonEncode(items);
    }

    widget.onAdd(riddle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1508),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF4A3F22))),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3F22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Riddle',
                style: TextStyle(
                  color: EnolaTheme.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              // Type selector
              Row(
                children: [
                  _TypeChip(
                    label: 'Multiple Choice',
                    icon: Icons.help_outline_rounded,
                    selected: _type == RiddleType.multipleChoice,
                    onTap: () =>
                        setState(() => _type = RiddleType.multipleChoice),
                  ),
                  const SizedBox(width: 10),
                  _TypeChip(
                    label: 'Ordering',
                    icon: Icons.sort_rounded,
                    selected: _type == RiddleType.ordering,
                    onTap: () =>
                        setState(() => _type = RiddleType.ordering),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionCtrl,
                style: const TextStyle(color: EnolaTheme.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question *',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_type == RiddleType.multipleChoice)
                _buildMultipleChoiceFields()
              else
                _buildOrderingFields(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Riddle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHOICES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: EnolaTheme.accent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 4; i++) ...[
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _correctIndex = i),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _correctIndex == i
                        ? EnolaTheme.correct
                        : Colors.transparent,
                    border: Border.all(
                      color: _correctIndex == i
                          ? EnolaTheme.correct
                          : const Color(0xFF4A3F22),
                      width: 2,
                    ),
                  ),
                  child: _correctIndex == i
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _choiceCtrls[i],
                  style: const TextStyle(color: EnolaTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Choice ${i + 1}',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Tap the circle to mark the correct answer',
          style: TextStyle(fontSize: 11, color: EnolaTheme.textSecond),
        ),
      ],
    );
  }

  Widget _buildOrderingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ITEMS (in correct order)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: EnolaTheme.accent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 4; i++) ...[
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A3F22), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: EnolaTheme.accent,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _itemCtrls[i],
                  style: const TextStyle(color: EnolaTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Item ${i + 1}',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? EnolaTheme.accentSoft : const Color(0xFF1E1A10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? EnolaTheme.accent : const Color(0xFF4A3F22),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? EnolaTheme.accent : EnolaTheme.textSecond),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? EnolaTheme.accent : EnolaTheme.textSecond,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

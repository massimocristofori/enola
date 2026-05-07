import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';

import 'package:enola/services/map_repository.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/scan_screen.dart';

class CreateMapScreen extends ConsumerStatefulWidget {
  final String? existingMapId;

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
    final id = widget.existingMapId!;
    _existingMap = await MapRepository.instance.getMap(id);
    _riddles = await MapRepository.instance.getRiddlesForMap(id);

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

  // ── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: EnolaTheme.textSecond),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.existingMapId == null ? 'Forge New Map' : 'Edit Map',
            style: const TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── MAP INFO ───────────────────────────────────────────────────────────────

  Widget _buildMapInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MAP DETAILS", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 16),
        FantasyTextField(
          controller: _titleCtrl,
          label: 'Map Title',
          hint: 'e.g., The Lost Kingdom',
          validator: (v) => v!.isEmpty ? 'Give your map a name' : null,
        ),
        const SizedBox(height: 16),
        FantasyTextField(
          controller: _subjectCtrl,
          label: 'Subject',
          hint: 'e.g., History, Math, Lore',
        ),
        const SizedBox(height: 16),
        FantasyTextField(
          controller: _descCtrl,
          label: 'Description',
          hint: 'The story of this journey...',
          maxLines: 3,
        ),
      ],
    );
  }

  // ── RIDDLES SECTION ────────────────────────────────────────────────────────

  Widget _buildRiddlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("RIDDLES & TRIALS", style: EnolaTheme.sectionHeader),
            Row(
              children: [
                IconButton(
                  onPressed: _openScan,
                  icon: const Icon(Icons.auto_fix_high_rounded, color: EnolaTheme.accent),
                  tooltip: 'Scan text with AI',
                ),
                IconButton(
                  onPressed: _addRiddleManually,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: EnolaTheme.accent),
                  tooltip: 'Add manual riddle',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_riddles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No riddles added yet.\nUse the wand or the plus to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EnolaTheme.textSecond.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _riddles.length,
            itemBuilder: (context, index) {
              final riddle = _riddles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ParchmentCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      riddle.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      riddle.type == RiddleType.multipleChoice ? 'Multiple Choice' : 'Ordering',
                      style: const TextStyle(color: EnolaTheme.accent, fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: EnolaTheme.wrong),
                      onPressed: () => _removeRiddle(index),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ── LOGIC ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final map = _existingMap ?? RiddleMap(title: _titleCtrl.text.trim());
      map.title = _titleCtrl.text.trim();
      map.subject = _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim();
      map.description = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

      final mapId = await MapRepository.instance.saveMap(map);
      await MapRepository.instance.saveRiddles(mapId, _riddles);

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
        onAdd: (riddle) => setState(() => _riddles.add(riddle)),
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
              ? const Center(child: CircularProgressIndicator(color: EnolaTheme.accent))
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
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: EnolaTheme.background))
            : const Icon(Icons.save_rounded),
        label: const Text('Save Map', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── ADD RIDDLE SHEET ─────────────────────────────────────────────────────────

class _AddRiddleSheet extends StatefulWidget {
  final Function(Riddle) onAdd;
  const _AddRiddleSheet({required this.onAdd});

  @override
  State<_AddRiddleSheet> createState() => _AddRiddleSheetState();
}

class _AddRiddleSheetState extends State<_AddRiddleSheet> {
  final _qCtrl = TextEditingController();
  final _choiceCtrl = TextEditingController();
  final List<String> _choices = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EnolaTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("New Riddle", style: EnolaTheme.sectionHeader),
          const SizedBox(height: 20),
          FantasyTextField(controller: _qCtrl, label: 'The Question'),
          const SizedBox(height: 20),
          // Simple Multiple Choice UI for manual adding
          Row(
            children: [
              Expanded(child: FantasyTextField(controller: _choiceCtrl, label: 'Add Choice')),
              IconButton(
                icon: const Icon(Icons.add, color: EnolaTheme.accent),
                onPressed: () {
                  if (_choiceCtrl.text.isNotEmpty) {
                    setState(() {
                      _choices.add(_choiceCtrl.text);
                      _choiceCtrl.clear();
                    });
                  }
                },
              ),
            ],
          ),
          Wrap(
            children: _choices.map((c) => Chip(label: Text(c), onDeleted: () => setState(() => _choices.remove(c)))).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_qCtrl.text.isEmpty) return;
              final riddle = Riddle(
                mapId: 'temp', // Reassigned on save
                typeIndex: RiddleType.multipleChoice.index,
                question: _qCtrl.text,
                orderInMap: 0,
                mcChoicesJson: jsonEncode(_choices),
                mcCorrectIndex: 0,
              );
              widget.onAdd(riddle);
              Navigator.pop(context);
            },
            child: const Text('Add to Map'),
          ),
        ],
      ),
    );
  }
}

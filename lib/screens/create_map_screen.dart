import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart'; // Ensure your RiddleType enum is here
import 'package:enola/services/drift_service.dart';
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
    final db = DriftService.instance.db;

    // Fetch map
    _existingMap = await (db.select(db.riddleMaps)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    // Fetch riddles
    _riddles = await (db.select(db.riddles)..where((t) => t.mapId.equals(id))).get();

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

  // ── LOGIC ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final db = DriftService.instance.db;
      // Use existing ID or generate a new one
      final mapId = _existingMap?.id ?? const Uuid().v4();

      // 1. Save the Map (Upsert)
      await DriftService.instance.saveMap(
        mapId,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
      );

      // 2. Save the Riddles
      // We delete old ones first if editing, or just overwrite
      await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();
      
      await db.batch((batch) {
        batch.insertAll(db.riddles, [
          for (int i = 0; i < _riddles.length; i++)
            RiddlesCompanion.insert(
              mapId: mapId,
              question: _riddles[i].question,
              typeIndex: _riddles[i].typeIndex,
              orderInMap: i,
              choicesJson: drift.Value(_riddles[i].choicesJson),
              correctIndex: drift.Value(_riddles[i].correctIndex),
            ),
        ]);
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Save failed: $e");
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

  // ── UI COMPONENTS ──────────────────────────────────────────────────────────

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
                style: TextStyle(color: EnolaTheme.textSecond.withAlpha(128)),
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
                      RiddleType.values[riddle.typeIndex] == RiddleType.multipleChoice 
                          ? 'Multiple Choice' 
                          : 'Ordering',
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
            spacing: 8,
            children: _choices.map((c) => Chip(
              label: Text(c), 
              onDeleted: () => setState(() => _choices.remove(c))
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_qCtrl.text.isEmpty) return;
              
              // Create a Drift Riddle object (mocking ID and mapId as they are set on save)
              final riddle = Riddle(
                id: 0, 
                mapId: 'temp', 
                typeIndex: RiddleType.multipleChoice.index,
                question: _qCtrl.text,
                orderInMap: 0,
                choicesJson: jsonEncode(_choices),
                correctIndex: 0,
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

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/providers/map_providers.dart';
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
  final _formKey = GlobalKey<FormState>();

  RiddleMap? _existingMap;
  List<Riddle> _riddles = [];
  Uint8List? _imageBytes;

  bool _loading = false;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMapId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final id = widget.existingMapId!;
    final db = DriftService.instance.db;

    _existingMap = await (db.select(db.riddleMaps)..where((t) => t.id.equals(id))).getSingleOrNull();
    _riddles = await (db.select(db.riddles)..where((t) => t.mapId.equals(id))).get();

    if (_existingMap != null) {
      _titleCtrl.text = _existingMap!.title;
      _subjectCtrl.text = _existingMap!.subject ?? '';
      // Load existing image if present
      if (_existingMap!.imageBytes != null) {
        _imageBytes = Uint8List.fromList(_existingMap!.imageBytes!);
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  // ── IMAGE ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final rawBytes = await picked.readAsBytes();
      final resized = await _resizeTo200(rawBytes);
      setState(() => _imageBytes = resized);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e'), backgroundColor: EnolaTheme.wrong),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  /// Decodes raw image bytes, draws them into a 200×200 canvas, returns PNG bytes.
  Future<Uint8List> _resizeTo200(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 200,
      targetHeight: 200,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 200, 200),
      Paint(),
    );
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(200, 200);
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ── LOGIC ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final db = DriftService.instance.db;
      final mapId = _existingMap?.id ?? const Uuid().v4();

      await DriftService.instance.saveMap(
        mapId,
        _titleCtrl.text.trim(),
        null, // description removed from UI but kept in DB for compatibility
        _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        imageBytes: _imageBytes,
      );

      await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();

      await db.batch((batch) {
        batch.insertAll(db.riddles, [
          for (int i = 0; i < _riddles.length; i++)
            _riddleToCompanion(_riddles[i], mapId, i),
        ]);
      });

      ref.invalidate(allMapsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint("Save failed: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: EnolaTheme.wrong),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  RiddlesCompanion _riddleToCompanion(Riddle riddle, String mapId, int order) {
    final type = RiddleType.values[riddle.typeIndex];

    switch (type) {
      case RiddleType.multipleChoice:
      case RiddleType.trueFalse:
        final mc = riddle.asMultipleChoice;
        final choices = mc?.choices ?? riddle.choices;
        final correct = mc?.correctIndex ?? riddle.correctIndex ?? 0;
        final payload = MultipleChoicePayload(choices: choices, correctIndex: correct);
        return RiddlesCompanion.insert(
          mapId: mapId,
          question: riddle.question,
          typeIndex: riddle.typeIndex,
          orderInMap: order,
          payloadJson: drift.Value(jsonEncode(payload.toJson())),
          choicesJson: drift.Value(jsonEncode(choices)),
          correctIndex: drift.Value(correct),
        );

      case RiddleType.ordering:
        final ord = riddle.asOrdering;
        final items = ord?.items ?? riddle.choices;
        final payload = OrderingPayload(items: items);
        return RiddlesCompanion.insert(
          mapId: mapId,
          question: riddle.question,
          typeIndex: riddle.typeIndex,
          orderInMap: order,
          payloadJson: drift.Value(jsonEncode(payload.toJson())),
          choicesJson: drift.Value(jsonEncode(items)),
          correctIndex: const drift.Value(null),
        );
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

  // ── UI HELPERS ─────────────────────────────────────────────────────────────

  String _riddleTypeLabel(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice: return 'Multiple Choice';
      case RiddleType.trueFalse:      return 'True / False';
      case RiddleType.ordering:       return 'Ordering';
    }
  }

  IconData _riddleTypeIcon(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice: return Icons.list_alt_rounded;
      case RiddleType.trueFalse:      return Icons.thumbs_up_down_rounded;
      case RiddleType.ordering:       return Icons.sort_rounded;
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

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
        // ── Image picker ──
        Center(
          child: GestureDetector(
            onTap: _pickingImage ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: EnolaTheme.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EnolaTheme.accent.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _pickingImage
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: EnolaTheme.accent,
                          strokeWidth: 2,
                        ),
                      )
                    : _imageBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: EnolaTheme.background.withAlpha(180),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: EnolaTheme.accent,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/0.jpeg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: TextStyle(
                                  color: EnolaTheme.accent.withAlpha(180),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
              final type = RiddleType.values[riddle.typeIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ParchmentCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_riddleTypeIcon(type), color: EnolaTheme.accent, size: 20),
                    title: Text(
                      riddle.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _riddleTypeLabel(type),
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
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: EnolaTheme.background),
              )
            : const Icon(Icons.save_rounded),
        label: const Text('Save Map', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── ADD RIDDLE SHEET ──────────────────────────────────────────────────────────

class _AddRiddleSheet extends StatefulWidget {
  final Function(Riddle) onAdd;
  const _AddRiddleSheet({required this.onAdd});

  @override
  State<_AddRiddleSheet> createState() => _AddRiddleSheetState();
}

class _AddRiddleSheetState extends State<_AddRiddleSheet> {
  final _qCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();

  RiddleType _selectedType = RiddleType.multipleChoice;

  final List<String> _choices = [];
  int _correctIndex = 0;

  int _tfCorrectIndex = 0;

  final List<String> _orderItems = [];

  @override
  void dispose() {
    _qCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_qCtrl.text.trim().isEmpty) return;

    final String? payloadJson;
    final String? legacyChoicesJson;
    final int? legacyCorrectIndex;

    switch (_selectedType) {
      case RiddleType.multipleChoice:
        if (_choices.length < 2) return;
        final payload = MultipleChoicePayload(choices: _choices, correctIndex: _correctIndex);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(_choices);
        legacyCorrectIndex = _correctIndex;

      case RiddleType.trueFalse:
        final choices = ['True', 'False'];
        final payload = MultipleChoicePayload(choices: choices, correctIndex: _tfCorrectIndex);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(choices);
        legacyCorrectIndex = _tfCorrectIndex;

      case RiddleType.ordering:
        if (_orderItems.length < 2) return;
        final payload = OrderingPayload(items: _orderItems);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(_orderItems);
        legacyCorrectIndex = null;
    }

    final riddle = Riddle(
      id: 0,
      mapId: 'temp',
      typeIndex: _selectedType.index,
      question: _qCtrl.text.trim(),
      orderInMap: 0,
      payloadJson: payloadJson,
      choicesJson: legacyChoicesJson,
      correctIndex: legacyCorrectIndex,
    );

    widget.onAdd(riddle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EnolaTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("New Riddle", style: EnolaTheme.sectionHeader)),
            const SizedBox(height: 20),

            const Text("TYPE", style: EnolaTheme.sectionHeader),
            const SizedBox(height: 10),
            Row(
              children: RiddleType.values.map((type) {
                final selected = _selectedType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = type;
                        _choices.clear();
                        _orderItems.clear();
                        _correctIndex = 0;
                        _tfCorrectIndex = 0;
                        _itemCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? EnolaTheme.accent : EnolaTheme.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? EnolaTheme.accent : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _typeIcon(type),
                              color: selected ? EnolaTheme.background : EnolaTheme.accent,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _typeShortLabel(type),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: selected ? EnolaTheme.background : EnolaTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            FantasyTextField(controller: _qCtrl, label: 'The Question'),
            const SizedBox(height: 20),

            if (_selectedType == RiddleType.multipleChoice) ...[
              _buildMultipleChoiceForm(),
            ] else if (_selectedType == RiddleType.trueFalse) ...[
              _buildTrueFalseForm(),
            ] else if (_selectedType == RiddleType.ordering) ...[
              _buildOrderingForm(),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EnolaTheme.accent,
                  foregroundColor: EnolaTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add to Map', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHOICES", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: FantasyTextField(controller: _itemCtrl, label: 'Add a choice')),
            IconButton(
              icon: const Icon(Icons.add, color: EnolaTheme.accent),
              onPressed: () {
                final text = _itemCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _choices.add(text);
                    _itemCtrl.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_choices.isNotEmpty) ...[
          const Text("TAP A CHOICE TO MARK IT CORRECT", style: EnolaTheme.sectionHeader),
          const SizedBox(height: 8),
          ...List.generate(_choices.length, (i) {
            final isCorrect = i == _correctIndex;
            return GestureDetector(
              onTap: () => setState(() => _correctIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCorrect ? EnolaTheme.accent.withAlpha(40) : EnolaTheme.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect ? EnolaTheme.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: EnolaTheme.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_choices[i], style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () => setState(() {
                        _choices.removeAt(i);
                        if (_correctIndex >= _choices.length) _correctIndex = 0;
                      }),
                      child: const Icon(Icons.close_rounded, color: EnolaTheme.wrong, size: 18),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTrueFalseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CORRECT ANSWER", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _tfOption(0, 'True', Icons.check_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _tfOption(1, 'False', Icons.close_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _tfOption(int index, String label, IconData icon) {
    final selected = _tfCorrectIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tfCorrectIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? EnolaTheme.accent.withAlpha(40) : EnolaTheme.accent.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? EnolaTheme.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: EnolaTheme.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? EnolaTheme.accent : EnolaTheme.textSecond,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ITEMS IN CORRECT ORDER", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: FantasyTextField(controller: _itemCtrl, label: 'Add an item')),
            IconButton(
              icon: const Icon(Icons.add, color: EnolaTheme.accent),
              onPressed: () {
                final text = _itemCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _orderItems.add(text);
                    _itemCtrl.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_orderItems.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                _orderItems.insert(newIndex, _orderItems.removeAt(oldIndex));
              });
            },
            children: List.generate(_orderItems.length, (i) {
              return Container(
                key: ValueKey(_orderItems[i] + i.toString()),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: EnolaTheme.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EnolaTheme.accent.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        color: EnolaTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_orderItems[i], style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () => setState(() => _orderItems.removeAt(i)),
                      child: const Icon(Icons.close_rounded, color: EnolaTheme.wrong, size: 18),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_handle_rounded, color: EnolaTheme.textSecond, size: 18),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  String _typeShortLabel(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice: return 'Multiple\nChoice';
      case RiddleType.trueFalse:      return 'True /\nFalse';
      case RiddleType.ordering:       return 'Order';
    }
  }

  IconData _typeIcon(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice: return Icons.list_alt_rounded;
      case RiddleType.trueFalse:      return Icons.thumbs_up_down_rounded;
      case RiddleType.ordering:       return Icons.sort_rounded;
    }
  }
}

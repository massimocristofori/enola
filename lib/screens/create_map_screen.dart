import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/services/gemini_service.dart'; // Assuming this is your AI service

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
  final _pageCtrl = PageController();

  RiddleMap? _existingMap;
  List<Riddle> _riddles = [];
  Uint8List? _imageBytes;

  bool _loading = false;
  bool _saving = false;
  bool _isGeneratingAI = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    if (widget.existingMapId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final id = widget.existingMapId!;
      final db = DriftService.instance.db;
      _existingMap = await (db.select(db.riddleMaps)..where((t) => t.id.equals(id))).getSingleOrNull();
      _riddles = await (db.select(db.riddles)..where((t) => t.mapId.equals(id))).get();

      if (_existingMap != null) {
        _titleCtrl.text = _existingMap!.title;
        _subjectCtrl.text = _existingMap!.subject ?? '';
        _imageBytes = _existingMap!.imageBytes;
      }
    } catch (e) {
      _showError("Load Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _generateWithAI() async {
    if (_subjectCtrl.text.isEmpty) {
      _showError("Please enter a subject first");
      return;
    }
    setState(() => _isGeneratingAI = true);
    try {
      // Restore your specific Gemini logic here
      final result = await GeminiService.instance.generateRiddles(_subjectCtrl.text);
      setState(() => _riddles.addAll(result));
    } catch (e) {
      _showError("AI Error: $e");
    } finally {
      setState(() => _isGeneratingAI = false);
    }
  }

  Future<void> _deleteMap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Map?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && _existingMap != null) {
      await DriftService.instance.db.delete(DriftService.instance.db.riddleMaps)
          .where((t) => t.id.equals(_existingMap!.id)).go();
      ref.invalidate(allMapsProvider);
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    setState(() => _lastError = msg);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = DriftService.instance.db;
      final mapId = _existingMap?.id ?? const Uuid().v4();

      await DriftService.instance.saveMap(
        mapId, _titleCtrl.text.trim(), null, 
        _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        imageBytes: _imageBytes,
      );

      await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();
      
      await db.batch((batch) {
        for (int i = 0; i < _riddles.length; i++) {
          final r = _riddles[i];
          batch.insert(db.riddles, RiddlesCompanion.insert(
            mapId: mapId,
            question: r.question,
            typeIndex: r.typeIndex,
            orderInMap: i,
            choicesJson: drift.Value(r.choicesJson),
            correctIndex: drift.Value(r.correctIndex),
          ));
        }
      });

      ref.invalidate(allMapsProvider);
      Navigator.pop(context);
    } catch (e) {
      _showError("Save Error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Map"),
        actions: [
          if (_existingMap != null) IconButton(icon: const Icon(Icons.delete_forever), onPressed: _deleteMap),
          IconButton(icon: const Icon(Icons.save), onPressed: _saving ? null : _save)
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isGeneratingAI) const LinearProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: 1 + _riddles.length,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildMapDetails();
                  return _RiddleEditorPage(
                    key: ValueKey('riddle_${index - 1}'),
                    riddle: _riddles[index - 1],
                    onChanged: (u) => setState(() => _riddles[index - 1] = u),
                    onDelete: () {
                      setState(() => _riddles.removeAt(index - 1));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(heroTag: 'ai', onPressed: _generateWithAI, child: const Icon(Icons.auto_awesome)),
          const SizedBox(height: 10),
          FloatingActionButton(heroTag: 'add', onPressed: () => setState(() => _riddles.add(Riddle(id: 0, mapId: '', typeIndex: 0, question: '', orderInMap: _riddles.length))), child: const Icon(Icons.add)),
        ],
      ),
    );
  }

  Widget _buildMapDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_imageBytes != null) Image.memory(_imageBytes!, height: 150),
        ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text("Set Cover Image")),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Map Title")),
        TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subject (for AI)")),
      ],
    );
  }
}

class _RiddleEditorPage extends StatelessWidget {
  final Riddle riddle;
  final ValueChanged<Riddle> onChanged;
  final VoidCallback onDelete;

  const _RiddleEditorPage({super.key, required this.riddle, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final List<String> choices = riddle.choices;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Riddle #${riddle.orderInMap + 1}"),
              IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            ],
          ),
          TextField(
            controller: TextEditingController(text: riddle.question)..selection = TextSelection.collapsed(offset: riddle.question.length),
            onChanged: (v) => onChanged(riddle.copyWith(question: v)),
            decoration: const InputDecoration(labelText: "Question"),
          ),
          const SizedBox(height: 20),
          ...List.generate(choices.length, (i) {
            return Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: riddle.correctIndex,
                  onChanged: (val) => onChanged(riddle.copyWith(correctIndex: drift.Value(val))),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: choices[i])..selection = TextSelection.collapsed(offset: choices[i].length),
                    onChanged: (v) {
                      final list = List<String>.from(choices);
                      list[i] = v;
                      onChanged(riddle.copyWith(choicesJson: drift.Value(jsonEncode(list))));
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

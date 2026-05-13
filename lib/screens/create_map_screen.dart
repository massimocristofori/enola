import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/providers/map_providers.dart';

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
        if (_existingMap!.imageBytes != null) _imageBytes = _existingMap!.imageBytes;
      }
    } catch (e) {
      _showError("Load Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    setState(() => _lastError = msg);
  }

  void _addRiddle() {
    final newRiddle = Riddle(
      id: 0,
      mapId: 'temp',
      typeIndex: 0,
      question: '',
      orderInMap: _riddles.length,
      choicesJson: jsonEncode([]),
      correctIndex: 0,
    );
    
    setState(() => _riddles.add(newRiddle));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(_riddles.length, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = DriftService.instance.db;
      final mapId = _existingMap?.id ?? const Uuid().v4();

      // Ensure your DriftService.saveMap handles these types correctly
      await DriftService.instance.saveMap(
        mapId, 
        _titleCtrl.text.trim(), 
        null, 
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
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saving ? null : _save)],
      ),
      body: Form(
        key: _formKey,
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: 1 + _riddles.length,
          itemBuilder: (context, index) {
            if (index == 0) return _buildMapDetails();
            return _RiddleEditorPage(
              key: ValueKey('riddle_page_${index - 1}'),
              riddle: _riddles[index - 1],
              onChanged: (u) => setState(() => _riddles[index - 1] = u),
              onDelete: () {
                setState(() => _riddles.removeAt(index - 1));
                _pageCtrl.jumpToPage(0);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addRiddle, child: const Icon(Icons.add)),
    );
  }

  Widget _buildMapDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Map Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Title")),
        TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subject")),
      ],
    );
  }
}

class _RiddleEditorPage extends StatefulWidget {
  final Riddle riddle;
  final ValueChanged<Riddle> onChanged;
  final VoidCallback onDelete;

  const _RiddleEditorPage({super.key, required this.riddle, required this.onChanged, required this.onDelete});

  @override
  State<_RiddleEditorPage> createState() => _RiddleEditorPageState();
}

class _RiddleEditorPageState extends State<_RiddleEditorPage> {
  late TextEditingController _qCtrl;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.riddle.question);
  }

  @override
  void didUpdateWidget(_RiddleEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riddle.question != _qCtrl.text) {
      _qCtrl.text = widget.riddle.question;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using the extension method from your database.dart
    final List<String> currentChoices = widget.riddle.choices;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Riddle Editor", style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: widget.onDelete),
            ],
          ),
          TextField(
            controller: _qCtrl,
            decoration: const InputDecoration(labelText: "Question"),
            maxLines: 2,
            onChanged: (v) => widget.onChanged(widget.riddle.copyWith(question: v)),
          ),
          const SizedBox(height: 20),
          ...List.generate(currentChoices.length, (i) {
            return Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: widget.riddle.correctIndex,
                  onChanged: (val) => widget.onChanged(
                    widget.riddle.copyWith(correctIndex: drift.Value(val))
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: currentChoices[i],
                    onChanged: (v) {
                      final newChoices = List<String>.from(currentChoices);
                      newChoices[i] = v;
                      widget.onChanged(
                        widget.riddle.copyWith(choicesJson: drift.Value(jsonEncode(newChoices)))
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final newChoices = List<String>.from(currentChoices)..removeAt(i);
                    widget.onChanged(
                      widget.riddle.copyWith(choicesJson: drift.Value(jsonEncode(newChoices)))
                    );
                  },
                )
              ],
            );
          }),
          TextButton(
            onPressed: () {
              final newChoices = List<String>.from(currentChoices)..add("");
              widget.onChanged(
                widget.riddle.copyWith(choicesJson: drift.Value(jsonEncode(newChoices)))
              );
            },
            child: const Text("Add Choice"),
          ),
        ],
      ),
    );
  }
}

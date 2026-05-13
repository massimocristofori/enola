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
  int _currentPage = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    debugPrint("🚨 LOG: Init CreateMapScreen");
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
        if (_existingMap!.imageBytes != null) _imageBytes = Uint8List.fromList(_existingMap!.imageBytes!);
      }
      debugPrint("🚨 LOG: Loaded ${_riddles.length} riddles.");
    } catch (e) {
      _showError("Load Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    debugPrint("🚨 ERROR: $msg");
    setState(() => _lastError = msg);
  }

  void _addRiddle() {
    debugPrint("🚨 LOG: Adding riddle button pressed");
    try {
      final newRiddle = Riddle(
        id: 0,
        mapId: 'temp',
        typeIndex: 0,
        question: '',
        orderInMap: _riddles.length,
        choicesJson: jsonEncode([]), // Ensure it's never null
        correctIndex: 0,
      );
      
      setState(() {
        _riddles.add(newRiddle);
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pageCtrl.hasClients) {
          _pageCtrl.animateToPage(_riddles.length, 
              duration: const Duration(milliseconds: 300), 
              curve: Curves.easeOut);
        }
      });
    } catch (e) {
      _showError("Add Riddle Crash: $e");
    }
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
            choicesJson: drift.Value(jsonEncode(r.choices ?? [])),
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
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: 1 + _riddles.length,
                    itemBuilder: (context, index) {
                      try {
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
                      } catch (e) {
                        return Center(child: Text("Page Build Error: $e"));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_lastError != null)
            Container(
              color: Colors.red.withOpacity(0.9),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🚨 APP ERROR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(_lastError!, style: const TextStyle(color: Colors.white)),
                  ElevatedButton(onPressed: () => setState(() => _lastError = null), child: const Text("Dismiss"))
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addRiddle, child: const Icon(Icons.add)),
    );
  }

  Widget _buildMapDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Step 1: Map Identity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Title")),
        TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subject")),
        const SizedBox(height: 20),
        const Text("Tap [+] to add your first riddle.", style: TextStyle(color: Colors.grey)),
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

  List<String> _getSafeChoices() {
    final raw = widget.riddle.choices;
    if (raw == null) return [];
    try {
      // Direct cast to dynamic list to bypass minified type mismatch
      final List<dynamic> list = raw as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("🚨 Choices Casting Error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = _getSafeChoices();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Riddle Editor", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: widget.onDelete),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _qCtrl,
            decoration: const InputDecoration(labelText: "Riddle Question", border: OutlineInputBorder()),
            maxLines: 2,
            onChanged: (v) => widget.onChanged(widget.riddle.copyWith(question: v)),
          ),
          const SizedBox(height: 20),
          const Text("Multiple Choice Options:", style: TextStyle(fontWeight: FontWeight.w500)),
          const Text("Select the radio button for the correct answer", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          ...List.generate(choices.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: widget.riddle.correctIndex,
                    onChanged: (val) => widget.onChanged(widget.riddle.copyWith(correctIndex: val)),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: choices[i],
                      decoration: InputDecoration(hintText: "Option ${i + 1}"),
                      onChanged: (v) {
                        final newChoices = List<String>.from(choices);
                        newChoices[i] = v;
                        widget.onChanged(widget.riddle.copyWith(choicesJson: jsonEncode(newChoices)));
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final newChoices = List<String>.from(choices)..removeAt(i);
                      widget.onChanged(widget.riddle.copyWith(choicesJson: jsonEncode(newChoices)));
                    },
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final newChoices = List<String>.from(choices)..add("");
              widget.onChanged(widget.riddle.copyWith(choicesJson: jsonEncode(newChoices)));
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Option"),
          ),
        ],
      ),
    );
  }
}

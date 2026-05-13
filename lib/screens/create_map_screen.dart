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
  final _pageCtrl = PageController();

  RiddleMap? _existingMap;
  List<Riddle> _riddles = [];
  Uint8List? _imageBytes;

  bool _loading = false;
  bool _saving = false;
  int _currentPage = 0;

  int get _totalPages => 1 + _riddles.length;
  bool get _onMapPage => _currentPage == 0;

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
        if (_existingMap!.imageBytes != null) {
          _imageBytes = Uint8List.fromList(_existingMap!.imageBytes!);
        }
      }
      debugPrint("DEBUG: Loaded ${_riddles.length} riddles.");
    } catch (e) {
      debugPrint("DEBUG ERROR: _loadExisting failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final rawBytes = await picked.readAsBytes();
      
      // Resize logic
      final codec = await ui.instantiateImageCodec(rawBytes, targetWidth: 200, targetHeight: 200);
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
      
      setState(() => _imageBytes = byteData!.buffer.asUint8List());
    } catch (e) {
      debugPrint("DEBUG ERROR: Image resize failed: $e");
    }
  }

  void _addRiddle() {
    final blank = Riddle(
      id: 0,
      mapId: 'temp',
      typeIndex: RiddleType.multipleChoice.index,
      question: '',
      orderInMap: _riddles.length,
      payloadJson: jsonEncode({'choices': [], 'correctIndex': 0}),
      choicesJson: jsonEncode([]),
      correctIndex: 0,
    );
    setState(() => _riddles.add(blank));
    _pageCtrl.animateToPage(_riddles.length, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = DriftService.instance.db;
      final mapId = _existingMap?.id ?? const Uuid().v4();

      await DriftService.instance.saveMap(
        mapId,
        _titleCtrl.text.trim(),
        null,
        _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        imageBytes: _imageBytes,
      );

      await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();

      await db.batch((batch) {
        batch.insertAll(db.riddles, [
          for (int i = 0; i < _riddles.length; i++) _riddleToCompanion(_riddles[i], mapId, i),
        ]);
      });

      ref.invalidate(allMapsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('DEBUG ERROR: Save failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  RiddlesCompanion _riddleToCompanion(Riddle riddle, String mapId, int order) {
    final choices = riddle.choices ?? [];
    final correct = riddle.correctIndex;
    
    return RiddlesCompanion.insert(
      mapId: mapId,
      question: riddle.question,
      typeIndex: riddle.typeIndex,
      orderInMap: order,
      payloadJson: drift.Value(jsonEncode({'choices': choices, 'correctIndex': correct ?? 0})),
      choicesJson: drift.Value(jsonEncode(choices)),
      correctIndex: drift.Value(correct),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMapId == null ? 'Create Map' : 'Edit Map'),
        actions: [
          if (_saving) const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white)))
          else IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(value: (_currentPage + 1) / _totalPages),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildMapDetails();
                  return _RiddleEditorPage(
                    key: ValueKey('riddle_${index - 1}'),
                    riddle: _riddles[index - 1],
                    onChanged: (u) => setState(() => _riddles[index - 1] = u),
                    onDelete: () {
                      setState(() => _riddles.removeAt(index - 1));
                      _pageCtrl.jumpToPage(index - 1);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'ai',
            mini: true,
            onPressed: () async {
              final res = await Navigator.push<List<Riddle>>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              if (res != null) setState(() => _riddles.addAll(res));
            },
            child: const Icon(Icons.auto_fix_high),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addRiddle,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildMapDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120, width: 120,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              child: _imageBytes == null 
                ? const Icon(Icons.add_a_photo, size: 40) 
                : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Map Title', border: OutlineInputBorder()),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(labelText: 'Subject (Optional)', border: OutlineInputBorder()),
          ),
        ],
      ),
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
  late List<String> _items;
  late int _correctIdx;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.riddle.question);
    
    // Safety Casting for Web
    try {
      final raw = widget.riddle.choices ?? [];
      _items = List<String>.from(raw.map((e) => e.toString()));
      _correctIdx = widget.riddle.correctIndex ?? 0;
    } catch (e) {
      debugPrint("DEBUG ERROR: Failed to parse riddle data: $e");
      _items = [];
      _correctIdx = 0;
    }
    _qCtrl.addListener(_emit);
  }

  void _emit() {
    widget.onChanged(Riddle(
      id: widget.riddle.id,
      mapId: widget.riddle.mapId,
      typeIndex: widget.riddle.typeIndex,
      question: _qCtrl.text,
      orderInMap: widget.riddle.orderInMap,
      payloadJson: jsonEncode({'choices': _items, 'correctIndex': _correctIdx}),
      choicesJson: jsonEncode(_items),
      correctIndex: _correctIdx,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Edit Riddle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: widget.onDelete),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("Choices", style: TextStyle(fontWeight: FontWeight.bold)),
          ...List.generate(_items.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<int>(
                  value: i, 
                  groupValue: _correctIdx, 
                  onChanged: (v) { setState(() => _correctIdx = v!); _emit(); }
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _items[i],
                    onChanged: (v) { _items[i] = v; _emit(); },
                    decoration: InputDecoration(hintText: 'Choice ${i + 1}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline), 
                  onPressed: () { setState(() => _items.removeAt(i)); _emit(); }
                ),
              ],
            ),
          )),
          TextButton.icon(
            onPressed: () { setState(() => _items.add('')); _emit(); },
            icon: const Icon(Icons.add),
            label: const Text("Add Choice"),
          ),
        ],
      ),
    );
  }
}

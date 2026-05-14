import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/scan_screen.dart';
import 'package:enola/screens/riddles_pager_screen.dart';

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

  RiddleMap? _savedMap;
  int _riddleCount = 0;
  Uint8List? _imageBytes;

  bool _loading = false;
  bool _saving = false;
  bool _pickingImage = false;

  bool get _isSaved => _savedMap != null;

  // ── INIT ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.existingMapId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final id = widget.existingMapId!;
    final db = DriftService.instance.db;

    _savedMap = await (db.select(db.riddleMaps)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    final riddles = await (db.select(db.riddles)
          ..where((t) => t.mapId.equals(id)))
        .get();
    _riddleCount = riddles.length;

    if (_savedMap != null) {
      _titleCtrl.text = _savedMap!.title;
      _subjectCtrl.text = _savedMap!.subject ?? '';
      if (_savedMap!.imageBytes != null) {
        _imageBytes = Uint8List.fromList(_savedMap!.imageBytes!);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load image: $e'),
          backgroundColor: EnolaTheme.wrong,
        ));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<Uint8List> _resizeTo200(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: 200, targetHeight: 200);
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
    final byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final mapId = _savedMap?.id ?? const Uuid().v4();
      await DriftService.instance.saveMap(
        mapId,
        _titleCtrl.text.trim(),
        null,
        _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        imageBytes: _imageBytes,
      );
      // reload so _savedMap is populated
      final db = DriftService.instance.db;
      _savedMap = await (db.select(db.riddleMaps)
            ..where((t) => t.id.equals(mapId)))
          .getSingleOrNull();

      ref.invalidate(allMapsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Map saved!'),
          backgroundColor: EnolaTheme.correct,
          duration: Duration(seconds: 1),
        ));
        setState(() {});
      }
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: EnolaTheme.wrong,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── NAVIGATION ─────────────────────────────────────────────────────────────

  Future<void> _openRiddles() async {
    if (!_isSaved) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiddlesPagerScreen(mapId: _savedMap!.id),
      ),
    );
    // refresh riddle count on return
    final db = DriftService.instance.db;
    final riddles = await (db.select(db.riddles)
          ..where((t) => t.mapId.equals(_savedMap!.id)))
        .get();
    if (mounted) setState(() => _riddleCount = riddles.length);
  }

  Future<void> _openScan() async {
    if (!_isSaved) return;
    final generated = await Navigator.push<List<Riddle>>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (generated != null && generated.isNotEmpty && _savedMap != null) {
      // save generated riddles straight to DB
      final db = DriftService.instance.db;
      final existing = await (db.select(db.riddles)
            ..where((t) => t.mapId.equals(_savedMap!.id)))
          .get();
      int order = existing.length;
      await db.batch((batch) {
        batch.insertAll(db.riddles, [
          for (final r in generated)
            _riddleToCompanion(r, _savedMap!.id, order++),
        ]);
      });
      final updated = await (db.select(db.riddles)
            ..where((t) => t.mapId.equals(_savedMap!.id)))
          .get();
      if (mounted) setState(() => _riddleCount = updated.length);
    }
  }

  RiddlesCompanion _riddleToCompanion(Riddle riddle, String mapId, int order) {
    // reuse schema_utils helpers via riddle itself
    return RiddlesCompanion.insert(
      mapId: mapId,
      question: riddle.question,
      typeIndex: riddle.typeIndex,
      orderInMap: order,
      payloadJson: drift.Value(riddle.payloadJson),
      choicesJson: drift.Value(riddle.choicesJson),
      correctIndex: drift.Value(riddle.correctIndex),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: EnolaTheme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: EnolaTheme.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _titleCtrl,
                        label: 'Map Title',
                        hint: 'e.g., The Solar System',
                        validator: (v) =>
                            v!.isEmpty ? 'Give your map a name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _subjectCtrl,
                        label: 'Subject',
                        hint: 'e.g., Science, History, Math',
                      ),
                      const SizedBox(height: 32),
                      _buildRiddlesSection(),
                      const SizedBox(height: 16),
                      _buildAiButton(),
                    ],
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
        foregroundColor: Colors.white,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded),
        label: const Text('Save Map',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EnolaTheme.textSecond),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.existingMapId == null ? 'New Map' : 'Edit Map',
            style: const TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── IMAGE PICKER ───────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickingImage ? null : _pickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: EnolaTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EnolaTheme.border, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _pickingImage
                ? const Center(
                    child: CircularProgressIndicator(
                        color: EnolaTheme.accent, strokeWidth: 2))
                : _imageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(220),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: EnolaTheme.accent, size: 14),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              color: EnolaTheme.accent.withAlpha(180),
                              size: 32),
                          const SizedBox(height: 6),
                          Text(
                            'Add cover',
                            style: TextStyle(
                              color: EnolaTheme.textSecond.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  // ── TEXT FIELD ─────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: EnolaTheme.textSecond.withAlpha(120), fontSize: 15),
            filled: true,
            fillColor: EnolaTheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: EnolaTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: EnolaTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: EnolaTheme.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: EnolaTheme.wrong),
            ),
          ),
        ),
      ],
    );
  }

  // ── RIDDLES SECTION ────────────────────────────────────────────────────────

  Widget _buildRiddlesSection() {
    final locked = !_isSaved;
    return GestureDetector(
      onTap: locked ? null : _openRiddles,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EnolaTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EnolaTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: EnolaTheme.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_rounded,
                    color: EnolaTheme.accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riddles',
                      style: TextStyle(
                        color: EnolaTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked
                          ? 'Save the map first'
                          : _riddleCount == 0
                              ? 'Tap to add your first riddle'
                              : '$_riddleCount riddle${_riddleCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: EnolaTheme.textSecond, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: EnolaTheme.textSecond),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI BUTTON ─────────────────────────────────────────────────────────────

  Widget _buildAiButton() {
    final locked = !_isSaved;
    return GestureDetector(
      onTap: locked ? null : _openScan,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: locked
                ? null
                : const LinearGradient(
                    colors: [EnolaTheme.accent, EnolaTheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: locked ? EnolaTheme.surface : null,
            borderRadius: BorderRadius.circular(20),
            border: locked ? Border.all(color: EnolaTheme.border) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: locked
                      ? EnolaTheme.accent.withAlpha(20)
                      : Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_fix_high_rounded,
                    color: locked ? EnolaTheme.accent : Colors.white,
                    size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Riddle Generator',
                      style: TextStyle(
                        color: locked ? EnolaTheme.textPrimary : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked
                          ? 'Save the map first'
                          : 'Scan text and generate riddles instantly',
                      style: TextStyle(
                        color: locked
                            ? EnolaTheme.textSecond
                            : Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: locked ? EnolaTheme.textSecond : Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

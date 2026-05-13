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
  final _pageCtrl = PageController();

  RiddleMap? _existingMap;
  List<Riddle> _riddles = [];
  Uint8List? _imageBytes;

  bool _loading = false;
  bool _saving = false;
  bool _pickingImage = false;

  int _currentPage = 0;

  // -- page 0 = map details, pages 1..n = riddles
  int get _totalPages => 1 + _riddles.length;
  bool get _onMapPage => _currentPage == 0;
  bool get _onRiddlePage => _currentPage > 0;
  int get _riddleIndex => _currentPage - 1;

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

    _existingMap = await (db.select(db.riddleMaps)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    _riddles = await (db.select(db.riddles)
          ..where((t) => t.mapId.equals(id)))
        .get();

    if (_existingMap != null) {
      _titleCtrl.text = _existingMap!.title;
      _subjectCtrl.text = _existingMap!.subject ?? '';
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
    _pageCtrl.dispose();
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
          SnackBar(
              content: Text('Could not load image: $e'),
              backgroundColor: EnolaTheme.wrong),
        );
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

  // ── RIDDLE MUTATIONS ───────────────────────────────────────────────────────

  void _insertRiddleAfterCurrent() {
    final insertAt = _onMapPage ? 0 : _riddleIndex + 1;
    final blank = _blankRiddle();
    setState(() => _riddles.insert(insertAt, blank));
    final targetPage = insertAt + 1;
    // animate after the frame so PageView has rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageCtrl.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _deleteRiddle(int riddleIndex) {
    setState(() => _riddles.removeAt(riddleIndex));
    // if we deleted the last riddle, move back one page
    final newPage = (_currentPage > _riddles.length) ? _riddles.length : _currentPage;
    if (newPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.jumpToPage(newPage);
      });
    }
  }

  void _moveRiddleLeft(int riddleIndex) {
    if (riddleIndex <= 0) return;
    setState(() {
      final r = _riddles.removeAt(riddleIndex);
      _riddles.insert(riddleIndex - 1, r);
    });
    _pageCtrl.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _moveRiddleRight(int riddleIndex) {
    if (riddleIndex >= _riddles.length - 1) return;
    setState(() {
      final r = _riddles.removeAt(riddleIndex);
      _riddles.insert(riddleIndex + 1, r);
    });
    _pageCtrl.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateRiddle(int riddleIndex, Riddle updated) {
    setState(() => _riddles[riddleIndex] = updated);
  }

  Riddle _blankRiddle() => Riddle(
        id: 0,
        mapId: 'temp',
        typeIndex: RiddleType.multipleChoice.index,
        question: '',
        orderInMap: 0,
        payloadJson: null,
        choicesJson: null,
        correctIndex: null,
      );

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      // snap to map page so user sees the validation error
      _pageCtrl.animateToPage(0,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      return;
    }
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
          for (int i = 0; i < _riddles.length; i++)
            _riddleToCompanion(_riddles[i], mapId, i),
        ]);
      });

      ref.invalidate(allMapsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: EnolaTheme.wrong),
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
        final payload =
            MultipleChoicePayload(choices: choices, correctIndex: correct);
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

  // ── SCAN ───────────────────────────────────────────────────────────────────

  Future<void> _openScan() async {
    final generated = await Navigator.push<List<Riddle>>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (generated != null && generated.isNotEmpty) {
      final insertAt = _onMapPage ? 0 : _riddleIndex + 1;
      setState(() => _riddles.insertAll(insertAt, generated));
      final targetPage = insertAt + 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.animateToPage(targetPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut);
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
      );
    }

    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                // ── Main pager ──
                Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: _totalPages,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildMapDetailsPage();
                          return _buildRiddlePage(index - 1);
                        },
                      ),
                    ),
                    _buildPageIndicator(),
                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),

                // ── FAB area ──
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // small + button — always visible
                      _SmallFab(
                        icon: Icons.auto_fix_high_rounded,
                        tooltip: 'Scan with AI',
                        onTap: _openScan,
                      ),
                      const SizedBox(height: 10),
                      _SmallFab(
                        icon: Icons.add_rounded,
                        tooltip: 'Add riddle after this',
                        onTap: _insertRiddleAfterCurrent,
                      ),
                      const SizedBox(height: 10),
                      // main save FAB
                      FloatingActionButton.extended(
                        heroTag: 'save_fab',
                        onPressed: _saving ? null : _save,
                        backgroundColor: EnolaTheme.accent,
                        foregroundColor: EnolaTheme.background,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: EnolaTheme.background),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Save Map',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EnolaTheme.textSecond),
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

  // ── PAGE 0 — MAP DETAILS ───────────────────────────────────────────────────

  Widget _buildMapDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MAP DETAILS", style: EnolaTheme.sectionHeader),
          const SizedBox(height: 16),
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
                              color: EnolaTheme.accent, strokeWidth: 2))
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
                                    child: const Icon(Icons.edit_rounded,
                                        color: EnolaTheme.accent, size: 14),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/0.jpeg',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain),
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
      ),
    );
  }

  // ── PAGES 1..n — RIDDLE EDITOR ─────────────────────────────────────────────

  Widget _buildRiddlePage(int riddleIndex) {
    final riddle = _riddles[riddleIndex];
    return _RiddleEditorPage(
      key: ValueKey('riddle_$riddleIndex'),
      riddle: riddle,
      riddleIndex: riddleIndex,
      totalRiddles: _riddles.length,
      onChanged: (updated) => _updateRiddle(riddleIndex, updated),
      onDelete: () => _deleteRiddle(riddleIndex),
      onMoveLeft: riddleIndex > 0 ? () => _moveRiddleLeft(riddleIndex) : null,
      onMoveRight: riddleIndex < _riddles.length - 1
          ? () => _moveRiddleRight(riddleIndex)
          : null,
    );
  }

  // ── PAGE INDICATOR ─────────────────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalPages, (i) {
            final isActive = i == _currentPage;
            final isMapPage = i == 0;

            return GestureDetector(
              onTap: () => _pageCtrl.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive
                      ? EnolaTheme.accent
                      : EnolaTheme.accent.withAlpha(60),
                  borderRadius: isMapPage
                      ? BorderRadius.circular(5) // pill/circle for map page
                      : BorderRadius.circular(3), // square for riddle pages
                  border: isMapPage
                      ? Border.all(color: EnolaTheme.accent, width: 1.5)
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── SMALL FAB ─────────────────────────────────────────────────────────────────

class _SmallFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallFab(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: EnolaTheme.accent.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: EnolaTheme.background, size: 20),
        ),
      ),
    );
  }
}

// ── RIDDLE EDITOR PAGE ────────────────────────────────────────────────────────

class _RiddleEditorPage extends StatefulWidget {
  final Riddle riddle;
  final int riddleIndex;
  final int totalRiddles;
  final ValueChanged<Riddle> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;

  const _RiddleEditorPage({
    super.key,
    required this.riddle,
    required this.riddleIndex,
    required this.totalRiddles,
    required this.onChanged,
    required this.onDelete,
    this.onMoveLeft,
    this.onMoveRight,
  });

  @override
  State<_RiddleEditorPage> createState() => _RiddleEditorPageState();
}

class _RiddleEditorPageState extends State<_RiddleEditorPage> {
  late final TextEditingController _qCtrl;
  late final TextEditingController _itemCtrl;
  late RiddleType _selectedType;
  late List<String> _choices;
  late int _correctIndex;
  late int _tfCorrectIndex;
  late List<String> _orderItems;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.riddle.question);
    _itemCtrl = TextEditingController();
    _selectedType = RiddleType.values[widget.riddle.typeIndex];

    final mc = widget.riddle.asMultipleChoice;
    final ord = widget.riddle.asOrdering;

    switch (_selectedType) {
      case RiddleType.multipleChoice:
        _choices = List<String>.from(mc?.choices ?? widget.riddle.choices ?? []);
        _correctIndex = mc?.correctIndex ?? widget.riddle.correctIndex ?? 0;
        _tfCorrectIndex = 0;
        _orderItems = [];
      case RiddleType.trueFalse:
        _choices = ['True', 'False'];
        _tfCorrectIndex = mc?.correctIndex ?? widget.riddle.correctIndex ?? 0;
        _correctIndex = 0;
        _orderItems = [];
      case RiddleType.ordering:
        _orderItems = List<String>.from(ord?.items ?? widget.riddle.choices ?? []);
        _choices = [];
        _correctIndex = 0;
        _tfCorrectIndex = 0;
    }

    _qCtrl.addListener(_emit);
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  // ── EMIT changes up to parent ──────────────────────────────────────────────

  void _emit() {
    final String? payloadJson;
    final String? legacyChoicesJson;
    final int? legacyCorrectIndex;

    switch (_selectedType) {
      case RiddleType.multipleChoice:
        final payload =
            MultipleChoicePayload(choices: _choices, correctIndex: _correctIndex);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(_choices);
        legacyCorrectIndex = _correctIndex;

      case RiddleType.trueFalse:
        final choices = ['True', 'False'];
        final payload = MultipleChoicePayload(
            choices: choices, correctIndex: _tfCorrectIndex);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(choices);
        legacyCorrectIndex = _tfCorrectIndex;

      case RiddleType.ordering:
        final payload = OrderingPayload(items: _orderItems);
        payloadJson = jsonEncode(payload.toJson());
        legacyChoicesJson = jsonEncode(_orderItems);
        legacyCorrectIndex = null;
    }

    widget.onChanged(Riddle(
      id: widget.riddle.id,
      mapId: widget.riddle.mapId,
      typeIndex: _selectedType.index,
      question: _qCtrl.text.trim(),
      orderInMap: widget.riddle.orderInMap,
      payloadJson: payloadJson,
      choicesJson: legacyChoicesJson,
      correctIndex: legacyCorrectIndex,
    ));
  }

  void _changeType(RiddleType type) {
    setState(() {
      _selectedType = type;
      _choices.clear();
      _orderItems.clear();
      _correctIndex = 0;
      _tfCorrectIndex = 0;
      _itemCtrl.clear();
    });
    _emit();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Text(
                'Riddle ${widget.riddleIndex + 1} of ${widget.totalRiddles}',
                style: EnolaTheme.sectionHeader,
              ),
              const Spacer(),
              // move left
              IconButton(
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: widget.onMoveLeft != null
                      ? EnolaTheme.accent
                      : EnolaTheme.textSecond.withAlpha(60),
                ),
                onPressed: widget.onMoveLeft,
              ),
              // move right
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: widget.onMoveRight != null
                      ? EnolaTheme.accent
                      : EnolaTheme.textSecond.withAlpha(60),
                ),
                onPressed: widget.onMoveRight,
              ),
              // delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: EnolaTheme.wrong),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Type selector ──
          const Text("TYPE", style: EnolaTheme.sectionHeader),
          const SizedBox(height: 10),
          Row(
            children: RiddleType.values.map((type) {
              final selected = _selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _changeType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? EnolaTheme.accent
                            : EnolaTheme.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? EnolaTheme.accent : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _typeIcon(type),
                            color: selected
                                ? EnolaTheme.background
                                : EnolaTheme.accent,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _typeShortLabel(type),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? EnolaTheme.background
                                  : EnolaTheme.accent,
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

          // ── Question ──
          FantasyTextField(controller: _qCtrl, label: 'The Question'),
          const SizedBox(height: 20),

          // ── Type-specific form ──
          if (_selectedType == RiddleType.multipleChoice)
            _buildMultipleChoiceForm()
          else if (_selectedType == RiddleType.trueFalse)
            _buildTrueFalseForm()
          else if (_selectedType == RiddleType.ordering)
            _buildOrderingForm(),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EnolaTheme.background,
        title: const Text('Delete Riddle?',
            style: TextStyle(color: EnolaTheme.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: EnolaTheme.textSecond)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: EnolaTheme.textSecond)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: EnolaTheme.wrong)),
          ),
        ],
      ),
    );
  }

  // ── MULTIPLE CHOICE ────────────────────────────────────────────────────────

  Widget _buildMultipleChoiceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHOICES", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: FantasyTextField(controller: _itemCtrl, label: 'Add a choice')),
            IconButton(
              icon: const Icon(Icons.add, color: EnolaTheme.accent),
              onPressed: () {
                final text = _itemCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _choices.add(text);
                    _itemCtrl.clear();
                  });
                  _emit();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_choices.isNotEmpty) ...[
          const Text("TAP A CHOICE TO MARK IT CORRECT",
              style: EnolaTheme.sectionHeader),
          const SizedBox(height: 8),
          ...List.generate(_choices.length, (i) {
            final isCorrect = i == _correctIndex;
            return GestureDetector(
              onTap: () {
                setState(() => _correctIndex = i);
                _emit();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? EnolaTheme.accent.withAlpha(40)
                      : EnolaTheme.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect ? EnolaTheme.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: EnolaTheme.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_choices[i],
                            style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _choices.removeAt(i);
                          if (_correctIndex >= _choices.length)
                            _correctIndex = 0;
                        });
                        _emit();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: EnolaTheme.wrong, size: 18),
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

  // ── TRUE / FALSE ───────────────────────────────────────────────────────────

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
      onTap: () {
        setState(() => _tfCorrectIndex = index);
        _emit();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? EnolaTheme.accent.withAlpha(40)
              : EnolaTheme.accent.withAlpha(15),
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

  // ── ORDERING ───────────────────────────────────────────────────────────────

  Widget _buildOrderingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ITEMS IN CORRECT ORDER", style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: FantasyTextField(controller: _itemCtrl, label: 'Add an item')),
            IconButton(
              icon: const Icon(Icons.add, color: EnolaTheme.accent),
              onPressed: () {
                final text = _itemCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _orderItems.add(text);
                    _itemCtrl.clear();
                  });
                  _emit();
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
              _emit();
            },
            children: List.generate(_orderItems.length, (i) {
              return Container(
                key: ValueKey(_orderItems[i] + i.toString()),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: EnolaTheme.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: EnolaTheme.accent.withAlpha(60)),
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
                    Expanded(
                        child: Text(_orderItems[i],
                            style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () {
                        setState(() => _orderItems.removeAt(i));
                        _emit();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: EnolaTheme.wrong, size: 18),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_handle_rounded,
                        color: EnolaTheme.textSecond, size: 18),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

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

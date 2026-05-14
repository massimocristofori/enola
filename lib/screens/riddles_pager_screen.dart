
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/theme/enola_theme.dart';

class RiddlesPagerScreen extends StatefulWidget {
  final String mapId;

  const RiddlesPagerScreen({super.key, required this.mapId});

  @override
  State<RiddlesPagerScreen> createState() => _RiddlesPagerScreenState();
}

class _RiddlesPagerScreenState extends State<RiddlesPagerScreen> {
  final _pageCtrl = PageController();
  List<Riddle> _riddles = [];
  bool _loading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadRiddles();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ───────────────────────────────────────────────────────────────────

  Future<void> _loadRiddles() async {
    final db = DriftService.instance.db;
    final riddles = await (db.select(db.riddles)
          ..where((t) => t.mapId.equals(widget.mapId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.orderInMap)]))
        .get();
    setState(() {
      _riddles = riddles;
      _loading = false;
    });
    if (_riddles.isEmpty) {
      await _insertBlankRiddle(atIndex: 0, navigate: true);
    }
  }

  // ── MUTATIONS ──────────────────────────────────────────────────────────────

  Future<void> _insertBlankRiddle(
      {required int atIndex, bool navigate = false}) async {
    // shift orderInMap of riddles at and after insertion point
    final db = DriftService.instance.db;
    for (int i = atIndex; i < _riddles.length; i++) {
      await (db.update(db.riddles)
            ..where((t) => t.id.equals(_riddles[i].id)))
          .write(RiddlesCompanion(orderInMap: drift.Value(i + 1)));
    }

    final newId = await DriftService.instance.insertBlankRiddle(
      mapId: widget.mapId,
      orderInMap: atIndex,
    );

    final inserted = await (db.select(db.riddles)
          ..where((t) => t.id.equals(newId)))
        .getSingle();

    setState(() => _riddles.insert(atIndex, inserted));

    if (navigate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.animateToPage(
          atIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _deleteRiddle(int riddleIndex) async {
    final riddle = _riddles[riddleIndex];
    await DriftService.instance.deleteRiddle(riddle.id);
    setState(() => _riddles.removeAt(riddleIndex));
    await DriftService.instance.reorderRiddles(_riddles);

    final newPage =
        (_currentPage >= _riddles.length && _riddles.isNotEmpty)
            ? _riddles.length - 1
            : _currentPage;
    if (newPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.jumpToPage(newPage);
      });
    }
  }

  Future<void> _moveLeft(int riddleIndex) async {
    if (riddleIndex <= 0) return;
    setState(() {
      final r = _riddles.removeAt(riddleIndex);
      _riddles.insert(riddleIndex - 1, r);
    });
    await DriftService.instance.reorderRiddles(_riddles);
    _pageCtrl.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _moveRight(int riddleIndex) async {
    if (riddleIndex >= _riddles.length - 1) return;
    setState(() {
      final r = _riddles.removeAt(riddleIndex);
      _riddles.insert(riddleIndex + 1, r);
    });
    await DriftService.instance.reorderRiddles(_riddles);
    _pageCtrl.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onRiddleSaved(int riddleIndex, Riddle updated) {
    setState(() => _riddles[riddleIndex] = updated);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

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
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _riddles.isEmpty
                  ? _buildEmptyState()
                  : PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      itemCount: _riddles.length,
                      itemBuilder: (context, index) => _RiddleEditorPage(
                        key: ValueKey(_riddles[index].id),
                        riddle: _riddles[index],
                        riddleIndex: index,
                        totalRiddles: _riddles.length,
                        onSaved: (updated) =>
                            _onRiddleSaved(index, updated),
                        onDelete: () => _deleteRiddle(index),
                        onMoveLeft:
                            index > 0 ? () => _moveLeft(index) : null,
                        onMoveRight: index < _riddles.length - 1
                            ? () => _moveRight(index)
                            : null,
                      ),
                    ),
            ),
            if (_riddles.isNotEmpty) _buildBottomBar(),
          ],
        ),
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
          const Text(
            'Riddles',
            style: TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _insertBlankRiddle(
              atIndex:
                  _riddles.isEmpty ? 0 : _currentPage + 1,
              navigate: true,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EnolaTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined,
              size: 64, color: EnolaTheme.textSecond.withAlpha(80)),
          const SizedBox(height: 16),
          const Text('No riddles yet',
              style: TextStyle(
                  color: EnolaTheme.textSecond,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                _insertBlankRiddle(atIndex: 0, navigate: true),
            icon: const Icon(Icons.add_rounded, color: EnolaTheme.accent),
            label: const Text('Add first riddle',
                style: TextStyle(color: EnolaTheme.accent)),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM INDICATOR ───────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EnolaTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_riddles.length, (i) {
            final isActive = i == _currentPage;
            return GestureDetector(
              onTap: () => _pageCtrl.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? EnolaTheme.accent
                      : EnolaTheme.accent.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
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
  final ValueChanged<Riddle> onSaved;
  final VoidCallback onDelete;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;

  const _RiddleEditorPage({
    super.key,
    required this.riddle,
    required this.riddleIndex,
    required this.totalRiddles,
    required this.onSaved,
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
  bool _saving = false;

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

				_choices = List<String>.from(mc?.choices ?? (widget.riddle.choices as List<String>?) ?? []);

        _correctIndex =
            mc?.correctIndex ?? widget.riddle.correctIndex ?? 0;
        _tfCorrectIndex = 0;
        _orderItems = [];
      case RiddleType.trueFalse:
        _choices = ['True', 'False'];
        _tfCorrectIndex =
            mc?.correctIndex ?? widget.riddle.correctIndex ?? 0;
        _correctIndex = 0;
        _orderItems = [];
      case RiddleType.ordering:
				_orderItems = List<String>.from(ord?.items ?? (widget.riddle.choices as List<String>?) ?? []);
        _choices = [];
        _correctIndex = 0;
        _tfCorrectIndex = 0;
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final RiddlePayload payload;

      switch (_selectedType) {
        case RiddleType.multipleChoice:
          payload = MultipleChoicePayload(
              choices: _choices, correctIndex: _correctIndex);
        case RiddleType.trueFalse:
          payload = MultipleChoicePayload(
              choices: ['True', 'False'], correctIndex: _tfCorrectIndex);
        case RiddleType.ordering:
          payload = OrderingPayload(items: _orderItems);
      }

      await DriftService.instance.saveRiddle(
        mapId: widget.riddle.mapId,
        question: _qCtrl.text.trim(),
        orderInMap: widget.riddle.orderInMap,
        payload: payload,
        existingId: widget.riddle.id,
      );

      final db = DriftService.instance.db;
      final updated = await (db.select(db.riddles)
            ..where((t) => t.id.equals(widget.riddle.id)))
          .getSingle();

      widget.onSaved(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Riddle saved!'),
          backgroundColor: EnolaTheme.correct,
          duration: Duration(seconds: 1),
        ));
      }
    } catch (e) {
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

  void _changeType(RiddleType type) {
    setState(() {
      _selectedType = type;
      _choices.clear();
      _orderItems.clear();
      _correctIndex = 0;
      _tfCorrectIndex = 0;
      _itemCtrl.clear();
    });
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTypeSelector(),
          const SizedBox(height: 20),
          _buildQuestionField(),
          const SizedBox(height: 20),
          if (_selectedType == RiddleType.multipleChoice)
            _buildMultipleChoiceForm()
          else if (_selectedType == RiddleType.trueFalse)
            _buildTrueFalseForm()
          else if (_selectedType == RiddleType.ordering)
            _buildOrderingForm(),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Riddle ${widget.riddleIndex + 1} of ${widget.totalRiddles}',
          style: EnolaTheme.sectionHeader,
        ),
        const Spacer(),
        _iconBtn(
          icon: Icons.chevron_left_rounded,
          color: widget.onMoveLeft != null
              ? EnolaTheme.accent
              : EnolaTheme.border,
          onTap: widget.onMoveLeft,
        ),
        _iconBtn(
          icon: Icons.chevron_right_rounded,
          color: widget.onMoveRight != null
              ? EnolaTheme.accent
              : EnolaTheme.border,
          onTap: widget.onMoveRight,
        ),
        _iconBtn(
          icon: Icons.delete_outline_rounded,
          color: EnolaTheme.wrong,
          onTap: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // ── TYPE SELECTOR ──────────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TYPE', style: EnolaTheme.sectionHeader),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? EnolaTheme.accent
                          : EnolaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? EnolaTheme.accent
                            : EnolaTheme.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(_typeIcon(type),
                            color: selected
                                ? Colors.white
                                : EnolaTheme.accent,
                            size: 20),
                        const SizedBox(height: 4),
                        Text(
                          _typeShortLabel(type),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : EnolaTheme.textSecond,
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
      ],
    );
  }

  // ── QUESTION ───────────────────────────────────────────────────────────────

  Widget _buildQuestionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUESTION', style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        TextField(
          controller: _qCtrl,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Type your question here...',
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
          ),
        ),
      ],
    );
  }

  // ── MULTIPLE CHOICE ────────────────────────────────────────────────────────

  Widget _buildMultipleChoiceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CHOICES', style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _addItemField('Add a choice')),
            const SizedBox(width: 8),
            _addItemButton(() {
              final text = _itemCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _choices.add(text);
                  _itemCtrl.clear();
                });
              }
            }),
          ],
        ),
        if (_choices.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('TAP TO MARK CORRECT', style: EnolaTheme.sectionHeader),
          const SizedBox(height: 8),
          ...List.generate(_choices.length, (i) {
            final isCorrect = i == _correctIndex;
            return GestureDetector(
              onTap: () => setState(() => _correctIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? EnolaTheme.correct.withAlpha(20)
                      : EnolaTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? EnolaTheme.correct
                        : EnolaTheme.border,
                    width: isCorrect ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isCorrect
                          ? EnolaTheme.correct
                          : EnolaTheme.textSecond,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_choices[i],
                            style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () => setState(() {
                        _choices.removeAt(i);
                        if (_correctIndex >= _choices.length) {
                          _correctIndex = 0;
                        }
                      }),
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
        const Text('CORRECT ANSWER', style: EnolaTheme.sectionHeader),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? EnolaTheme.correct.withAlpha(20)
              : EnolaTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? EnolaTheme.correct : EnolaTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? EnolaTheme.correct
                    : EnolaTheme.textSecond,
                size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected
                    ? EnolaTheme.correct
                    : EnolaTheme.textSecond,
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
        const Text('ITEMS IN CORRECT ORDER', style: EnolaTheme.sectionHeader),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _addItemField('Add an item')),
            const SizedBox(width: 8),
            _addItemButton(() {
              final text = _itemCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _orderItems.add(text);
                  _itemCtrl.clear();
                });
              }
            }),
          ],
        ),
        if (_orderItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                _orderItems.insert(
                    newIndex, _orderItems.removeAt(oldIndex));
              });
            },
            children: List.generate(_orderItems.length, (i) {
              return Container(
                key: ValueKey('${_orderItems[i]}_$i'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: EnolaTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EnolaTheme.border),
                ),
                child: Row(
                  children: [
                    Text('${i + 1}.',
                        style: const TextStyle(
                          color: EnolaTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_orderItems[i],
                            style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _orderItems.removeAt(i)),
                      child: const Icon(Icons.close_rounded,
                          color: EnolaTheme.wrong, size: 18),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.drag_handle_rounded,
                        color: EnolaTheme.textSecond, size: 18),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ── SAVE BUTTON ────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: EnolaTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: const Text('Save Riddle',
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _addItemField(String hint) {
    return TextField(
      controller: _itemCtrl,
      style:
          const TextStyle(fontSize: 14, color: EnolaTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: EnolaTheme.textSecond.withAlpha(120), fontSize: 14),
        filled: true,
        fillColor: EnolaTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EnolaTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EnolaTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: EnolaTheme.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _addItemButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: EnolaTheme.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EnolaTheme.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Riddle?',
            style: TextStyle(
                color: EnolaTheme.textPrimary,
                fontWeight: FontWeight.w700)),
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
                style: TextStyle(
                    color: EnolaTheme.wrong,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _typeShortLabel(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice:
        return 'Multiple\nChoice';
      case RiddleType.trueFalse:
        return 'True /\nFalse';
      case RiddleType.ordering:
        return 'Order';
    }
  }

  IconData _typeIcon(RiddleType type) {
    switch (type) {
      case RiddleType.multipleChoice:
        return Icons.list_alt_rounded;
      case RiddleType.trueFalse:
        return Icons.thumbs_up_down_rounded;
      case RiddleType.ordering:
        return Icons.sort_rounded;
    }
  }
}

import 'dart:convert';
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/models/riddle.dart';
import 'package:enola/models/riddle_map.dart';

import 'package:enola/services/map_repository.dart';
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

    _existingMap = await MapRepository.instance.getMap(id);
    _riddles = await MapRepository.instance.getRiddlesForMap(id);

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final map = _existingMap ??
          RiddleMap(
            title: _titleCtrl.text.trim(),
          );

      map.title = _titleCtrl.text.trim();
      map.subject = _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim();
      map.description = _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim();

      final mapId = await MapRepository.instance.saveMap(map);

      await MapRepository.instance.saveRiddles(mapId, _riddles);

      if (mounted) Navigator.pop(context);
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
        onAdd: (riddle) {
          setState(() => _riddles.add(riddle));
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: EnolaTheme.accent,
                  ),
                )
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EnolaTheme.background,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: const Text(
          'Save Map',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

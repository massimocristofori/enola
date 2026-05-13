import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import 'package:enola/services/gemini_service.dart';
import 'package:enola/services/riddle_generation_service.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final List<File> _pages = [];
  int _riddleCount = 5;
  bool _generating = false;
  String? _error;
  String _status = '';

  // Timer-related state for handling Quota/Rate limits
  int _retrySeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _addPage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pages.add(File(picked.path)));
    }
  }

  Future<void> _addFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _pages.addAll(picked.map((x) => File(x.path))));
    }
  }

  void _removePage(int index) {
    setState(() => _pages.removeAt(index));
  }

  Future<void> _generate() async {
    if (_pages.isEmpty || _retrySeconds > 0) return;

    if (GeminiService.instance.apiKey == null ||
        GeminiService.instance.apiKey!.isEmpty) {
      setState(() => _error =
          'Gemini API key not configured. Set GEMINI_API_KEY at build time.');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _status = 'Reading pages…';
    });

    try {
      setState(() => _status = 'Extracting text and consulting the Oracle…');

      final riddles = await RiddleGenerationService.instance.generateFromImages(
        imagePaths: _pages.map((file) => file.path).toList(),
        mapId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (riddles.isEmpty) {
          setState(() {
            _generating = false;
            _error = 'The Oracle returned no riddles. Try clearer images.';
          });
        } else {
          Navigator.pop(context, riddles);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        
        // Handle the Quota Exceeded error from image.png
        if (errorStr.contains('Quota exceeded') || errorStr.contains('429')) {
          final match = RegExp(r'retry in ([\d.]+)s').firstMatch(errorStr);
          final seconds = double.tryParse(match?.group(1) ?? '30')?.ceil() ?? 30;

          setState(() {
            _generating = false;
            _retrySeconds = seconds;
            _error = "The Oracle is exhausted and needs to rest.";
          });

          _startCountdown();
        } else {
          setState(() {
            _error = 'Generation failed: $e';
            _generating = false;
            _status = '';
          });
        }
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_retrySeconds > 0) {
            _retrySeconds--;
          } else {
            _error = null;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _generating
                    ? _buildGenerating()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInstructions(),
                            const SizedBox(height: 24),
                            _buildPageGrid(),
                            const SizedBox(height: 24),
                            const RuneDivider(),
                            const SizedBox(height: 20),
                            _buildOptions(),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              _buildError(),
                            ],
                            const SizedBox(height: 24),
                            _buildGenerateButton(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EnolaTheme.accent),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'Scan Pages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: EnolaTheme.textPrimary,
            ),
          ),
          const Spacer(),
          const TorchFlame(size: 20),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return ParchmentCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EnolaTheme.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_fix_high_rounded,
                color: EnolaTheme.accent),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Riddle Generator',
                  style: TextStyle(
                    color: EnolaTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Photograph your book pages and Enola will read the text and craft riddles automatically.',
                  style: TextStyle(
                    color: EnolaTheme.textSecond,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'PAGES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: EnolaTheme.accent,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            if (_pages.isNotEmpty)
              Text(
                '${_pages.length} added',
                style: const TextStyle(
                    fontSize: 12, color: EnolaTheme.textSecond),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: _pages.length + 2,
          itemBuilder: (context, i) {
            if (i == _pages.length) return _AddPageTile(onTap: _addPage, icon: Icons.camera_alt_rounded, label: 'Camera');
            if (i == _pages.length + 1) return _AddPageTile(onTap: _addFromGallery, icon: Icons.photo_library_rounded, label: 'Gallery');
            return _PageTile(
              file: _pages[i],
              index: i,
              onRemove: () => _removePage(i),
            ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
          },
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RIDDLES TO GENERATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: EnolaTheme.accent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final count in [3, 5, 8, 10])
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _riddleCount = count),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _riddleCount == count
                          ? EnolaTheme.accentSoft
                          : EnolaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _riddleCount == count
                            ? EnolaTheme.accent
                            : EnolaTheme.border,
                        width: _riddleCount == count ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _riddleCount == count
                              ? EnolaTheme.accent
                              : EnolaTheme.textSecond,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    final isQuota = _retrySeconds > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isQuota 
            ? EnolaTheme.accent.withValues(alpha: 0.1) 
            : EnolaTheme.wrong.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isQuota 
                ? EnolaTheme.accent.withValues(alpha: 0.5) 
                : EnolaTheme.wrong.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isQuota ? Icons.hourglass_empty_rounded : Icons.error_outline_rounded,
            color: isQuota ? EnolaTheme.accent : EnolaTheme.wrong,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isQuota 
                  ? "The Oracle is resting. Please wait $_retrySeconds seconds..." 
                  : _error!,
              style: TextStyle(
                color: isQuota ? EnolaTheme.textPrimary : EnolaTheme.wrong, 
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final bool canGenerate = _pages.isNotEmpty && _retrySeconds == 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generate : null,
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: Text(
          _pages.isEmpty
              ? 'Add pages first'
              : _retrySeconds > 0 
                  ? 'Oracle cooling down...' 
                  : 'Generate $_riddleCount Riddles',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: EnolaTheme.surfaceHigh,
          disabledForegroundColor: EnolaTheme.textSecond,
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildGenerating() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TorchFlame(size: 60)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                ),
            const SizedBox(height: 32),
            const Text(
              'Consulting the oracle…',
              style: TextStyle(
                color: EnolaTheme.accent,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EnolaTheme.textSecond,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            const LinearProgressIndicator(
              backgroundColor: EnolaTheme.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(EnolaTheme.accent),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _PageTile extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;

  const _PageTile({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'p.${index + 1}',
              style: const TextStyle(
                  color: EnolaTheme.accent, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: EnolaTheme.wrong, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPageTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _AddPageTile({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: EnolaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EnolaTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: EnolaTheme.accent, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                  color: EnolaTheme.textSecond, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

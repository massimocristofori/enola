import 'package:flutter/material.dart';

import '../services/drift_service.dart';
import '../services/supabase_service.dart';
import '../theme/enola_theme.dart';

class DownloadPackScreen extends StatefulWidget {
  final String? initialCode;
  const DownloadPackScreen({super.key, this.initialCode});

  @override
  State<DownloadPackScreen> createState() => _DownloadPackScreenState();
}

class _DownloadPackScreenState extends State<DownloadPackScreen> {
  late final TextEditingController _codeCtrl;
  _Phase _phase = _Phase.idle;
  RemotePackSummary? _found;
  double _progress = 0;
  String? _error;
  bool _alreadyOwned = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null) _lookup();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _phase = _Phase.looking;
      _error = null;
      _found = null;
    });
    try {
      final summary = await SupabaseService.instance.fetchPackByCode(code);
      if (summary == null) {
        setState(() {
          _error = 'No pack found for "$code".';
          _phase = _Phase.idle;
        });
        return;
      }
      final owned =
          await DriftService.instance.isPackDownloaded(summary.id);
      setState(() {
        _found = summary;
        _alreadyOwned = owned;
        _phase = _Phase.found;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _Phase.idle;
      });
    }
  }

  Future<void> _download() async {
    final summary = _found!;
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
    });
    try {
      await SupabaseService.instance.downloadPack(
        packId: summary.id,
        shareCode: summary.shareCode,
        creatorId: summary.creatorId,
        onProgress: (p) => setState(() => _progress = p),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _Phase.found;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnolaTheme.background,
      appBar: AppBar(title: const Text('Download a Pack')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Code entry ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: EnolaTheme.textPrimary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. WOLF-42',
                      hintStyle: TextStyle(
                        color: EnolaTheme.textSecond.withOpacity(0.5),
                        letterSpacing: 1,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: EnolaTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: EnolaTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: EnolaTheme.border),
                      ),
                    ),
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed:
                        _phase == _Phase.looking ? null : _lookup,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _phase == _Phase.looking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                ),
              ]),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: EnolaTheme.wrong, fontSize: 13),
                ),
              ],

              // ── Found ────────────────────────────────────────────────────
              if (_phase == _Phase.found && _found != null) ...[
                const SizedBox(height: 32),
                _PackPreviewCard(
                    summary: _found!, alreadyOwned: _alreadyOwned),
                const Spacer(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: EnolaTheme.wrong, fontSize: 13),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _alreadyOwned ? null : _download,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(_alreadyOwned
                        ? 'Already in your library'
                        : 'Download Pack'),
                  ),
                ),
              ],

              // ── Downloading ──────────────────────────────────────────────
              if (_phase == _Phase.downloading) ...[
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_rounded,
                          size: 56, color: EnolaTheme.accent),
                      const SizedBox(height: 32),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: EnolaTheme.border,
                        color: EnolaTheme.accent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}% downloaded',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PackPreviewCard extends StatelessWidget {
  final RemotePackSummary summary;
  final bool alreadyOwned;

  const _PackPreviewCard({
    required this.summary,
    required this.alreadyOwned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EnolaTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EnolaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_outlined,
                color: EnolaTheme.accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (alreadyOwned)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EnolaTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Owned',
                  style: TextStyle(
                    color: EnolaTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.download_outlined,
                size: 15, color: EnolaTheme.textSecond),
            const SizedBox(width: 4),
            Text(
              '${summary.downloadCount} downloads',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]),
        ],
      ),
    );
  }
}

enum _Phase { idle, looking, found, downloading }

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../database/database.dart';
import '../services/drift_service.dart';
import '../services/supabase_service.dart';
import '../theme/enola_theme.dart';

class SharePackScreen extends StatefulWidget {
  final Folder folder;
  const SharePackScreen({super.key, required this.folder});

  @override
  State<SharePackScreen> createState() => _SharePackScreenState();
}

class _SharePackScreenState extends State<SharePackScreen> {
  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _shareCode;
  String? _error;

  bool _checkingExisting = true;
  String? _existingPackId;
  bool _isOwner = false;

  // Email linking
  bool _showEmailPrompt = false;
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;
  bool _emailLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final existing =
        await SupabaseService.instance.lookupPackForFolder(widget.folder.id);
    if (!mounted) return;
    setState(() {
      _existingPackId = existing?.packId;
      _shareCode = existing?.shareCode;
      _isOwner = existing?.isOwner ?? false;
      _checkingExisting = false;
      if (existing != null) {
        _phase = _Phase.done;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (_existingPackId != null && !_isOwner) return; // guard, shouldn't be reachable from UI

    setState(() {
      _phase = _Phase.uploading;
      _progress = 0;
      _error = null;
    });

    try {
      final db = DriftService.instance;
      final maps = await (db.db.select(db.db.riddleMaps)
            ..where((t) => t.folderId.equals(widget.folder.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

      final riddlesByMapId = <String, List<Riddle>>{};
      for (final m in maps) {
        riddlesByMapId[m.id] = await db.db.getRiddlesForMap(m.id);
      }

      String code;
      if (_existingPackId != null && _shareCode != null) {
        code = await SupabaseService.instance.updatePack(
          packId: _existingPackId!,
          shareCode: _shareCode!,
          folder: widget.folder,
          maps: maps,
          riddlesByMapId: riddlesByMapId,
          onProgress: (p) => setState(() => _progress = p),
        );
      } else {
        code = await SupabaseService.instance.uploadFolder(
          folder: widget.folder,
          maps: maps,
          riddlesByMapId: riddlesByMapId,
          onProgress: (p) => setState(() => _progress = p),
        );
      }

      final wasFirstShare = _existingPackId == null;

      setState(() {
        _shareCode = code;
        _phase = _Phase.done;
        _showEmailPrompt = wasFirstShare && SupabaseService.instance.isAnonymous;
      });

      if (wasFirstShare) {
        // Refresh ownership/pack-id now that this folder is a pack.
        final refreshed = await SupabaseService.instance
            .lookupPackForFolder(widget.folder.id);
        if (mounted && refreshed != null) {
          setState(() {
            _existingPackId = refreshed.packId;
            _isOwner = refreshed.isOwner;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _Phase.idle;
      });
    }
  }

  Future<void> _linkEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _emailLoading = true);
    try {
      await SupabaseService.instance.linkEmail(email);
      setState(() {
        _emailSent = true;
        _emailLoading = false;
      });
    } catch (e) {
      setState(() => _emailLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send link: $e')),
        );
      }
    }
  }

  String get _shareLink => 'https://enola.app/pack/$_shareCode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnolaTheme.background,
      appBar: AppBar(
        title: const Text('Share Pack'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _checkingExisting
              ? const Center(child: CircularProgressIndicator())
              : switch (_phase) {
                  _Phase.idle => _IdleView(
                      folder: widget.folder,
                      onShare: _upload,
                      error: _error,
                      isUpdate: _existingPackId != null,
                    ),
                  _Phase.uploading => _UploadingView(
                      progress: _progress,
                      isUpdate: _existingPackId != null,
                    ),
                  _Phase.done => _DoneView(
                      code: _shareCode!,
                      link: _shareLink,
                      isOwner: _isOwner,
                      onPushUpdate: _upload,
                      showEmailPrompt: _showEmailPrompt,
                      emailCtrl: _emailCtrl,
                      emailSent: _emailSent,
                      emailLoading: _emailLoading,
                      onLinkEmail: _linkEmail,
                      onDismissEmailPrompt: () =>
                          setState(() => _showEmailPrompt = false),
                    ),
                },
        ),
      ),
    );
  }
}

enum _Phase { idle, uploading, done }

// ── Idle ──────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final Folder folder;
  final VoidCallback onShare;
  final String? error;
  final bool isUpdate;

  const _IdleView({
    required this.folder,
    required this.onShare,
    required this.isUpdate,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          folder.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          isUpdate
              ? 'This pack is already shared. Updating will push your latest changes to everyone with the code.'
              : 'Upload this folder as a shareable Pack. Anyone with the code can download and play it.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: EnolaTheme.textSecond),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EnolaTheme.wrong.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EnolaTheme.wrong.withOpacity(0.3)),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: EnolaTheme.wrong, fontSize: 13),
            ),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShare,
            icon: Icon(isUpdate
                ? Icons.cloud_sync_outlined
                : Icons.cloud_upload_outlined),
            label: Text(isUpdate ? 'Update Pack' : 'Upload & Generate Code'),
          ),
        ),
      ],
    );
  }
}

// ── Uploading ─────────────────────────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  final double progress;
  final bool isUpdate;
  const _UploadingView({required this.progress, required this.isUpdate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUpdate ? Icons.cloud_sync_outlined : Icons.cloud_upload_outlined,
            size: 56,
            color: EnolaTheme.accent,
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: EnolaTheme.border,
            color: EnolaTheme.accent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          Text(
            isUpdate
                ? '${(progress * 100).toStringAsFixed(0)}% updated'
                : '${(progress * 100).toStringAsFixed(0)}% uploaded',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final String code;
  final String link;
  final bool isOwner;
  final VoidCallback onPushUpdate;
  final bool showEmailPrompt;
  final TextEditingController emailCtrl;
  final bool emailSent;
  final bool emailLoading;
  final VoidCallback onLinkEmail;
  final VoidCallback onDismissEmailPrompt;

  const _DoneView({
    required this.code,
    required this.link,
    required this.isOwner,
    required this.onPushUpdate,
    required this.showEmailPrompt,
    required this.emailCtrl,
    required this.emailSent,
    required this.emailLoading,
    required this.onLinkEmail,
    required this.onDismissEmailPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isOwner ? EnolaTheme.correct : EnolaTheme.textSecond)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isOwner ? EnolaTheme.correct : EnolaTheme.textSecond)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOwner ? Icons.check_circle_outline : Icons.lock_outline,
                  size: 16,
                  color: isOwner ? EnolaTheme.correct : EnolaTheme.textSecond,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOwner
                        ? 'This pack is shared. Push local changes anytime.'
                        : 'You downloaded this pack. Only its creator can update it — you can still share the code below.',
                    style: TextStyle(
                      color:
                          isOwner ? EnolaTheme.correct : EnolaTheme.textSecond,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EnolaTheme.border),
            ),
            child: QrImageView(
              data: link,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Share Code',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: EnolaTheme.textSecond),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: EnolaTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EnolaTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: EnolaTheme.textPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy_rounded,
                      color: EnolaTheme.textSecond, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!')),
              );
            },
            icon: const Icon(Icons.link_rounded,
                color: EnolaTheme.textSecond, size: 18),
            label: const Text(
              'Copy link',
              style: TextStyle(color: EnolaTheme.textSecond),
            ),
          ),

          if (isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPushUpdate,
                icon: const Icon(Icons.cloud_sync_outlined),
                label: const Text('Push Update'),
              ),
            ),
          ],

          if (isOwner && showEmailPrompt) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EnolaTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EnolaTheme.border),
              ),
              child: emailSent
                  ? Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: EnolaTheme.correct, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Magic link sent! Tap it from any device to keep access to your packs.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: EnolaTheme.correct),
                        ),
                      ),
                    ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: EnolaTheme.textSecond),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Save your access — if you lose this device you won\'t be able to update this pack.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: EnolaTheme.textSecond,
                                      fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: onDismissEmailPrompt,
                            child: const Icon(Icons.close,
                                size: 16, color: EnolaTheme.textSecond),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'your@email.com',
                                hintStyle: TextStyle(
                                    color: EnolaTheme.textSecond
                                        .withOpacity(0.5)),
                                filled: true,
                                fillColor: EnolaTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: EnolaTheme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: EnolaTheme.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          emailLoading
                              ? const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: EnolaTheme.accent,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: onLinkEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: EnolaTheme.accent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Save'),
                                ),
                        ]),
                      ],
                    ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

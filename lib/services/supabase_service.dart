import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import 'drift_service.dart';

// ── DTOs ──────────────────────────────────────────────────────────────────────

class RemotePackSummary {
  final String id;
  final String title;
  final String shareCode;
  final int downloadCount;
  final DateTime createdAt;
  final String creatorId;

  const RemotePackSummary({
    required this.id,
    required this.title,
    required this.shareCode,
    required this.downloadCount,
    required this.createdAt,
    required this.creatorId,
  });

  factory RemotePackSummary.fromJson(Map<String, dynamic> j) =>
      RemotePackSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        shareCode: j['share_code'] as String,
        downloadCount: j['download_count'] as int,
        createdAt: DateTime.parse(j['created_at'] as String),
        creatorId: j['creator_id'] as String,
      );
}

class StaleMapInfo {
  final String packMapId;
  final String localMapId;
  final String packId;
  final DateTime remoteUpdatedAt;

  const StaleMapInfo({
    required this.packMapId,
    required this.localMapId,
    required this.packId,
    required this.remoteUpdatedAt,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Signs in anonymously if not already signed in.
  /// Called once on app start — completely invisible to the user.
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentUser != null) return;
    await _client.auth.signInAnonymously();
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isAnonymous =>
      _client.auth.currentUser?.isAnonymous ?? true;

  /// Links an email to the current anonymous account.
  /// Supabase sends a magic link — after clicking it the account is upgraded
  /// and the same creator_id is preserved on all their packs.
  Future<void> linkEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  /// True if this device owns (created) the given pack.
  bool isPackOwner(String creatorId) => currentUserId == creatorId;

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Uploads [folder] and all its maps + riddles.
  /// Returns the generated share code.
  Future<String> uploadFolder({
    required Folder folder,
    required List<RiddleMap> maps,
    required Map<String, List<Riddle>> riddlesByMapId,
    void Function(double progress)? onProgress,
  }) async {
    await ensureSignedIn();
    final uid = currentUserId!;

    // 1. Generate share code
    final shareCode = await _client.rpc('generate_share_code') as String;

    // 2. Insert pack row — creator_id = current anon/real uid
    final packInsert = await _client.from('packs').insert({
      'title': folder.title,
      'share_code': shareCode,
      'creator_id': uid,
    }).select('id').single();
    final packId = packInsert['id'] as String;

    // 3. Record locally so this device knows it owns the pack
    await DriftService.instance.db
        .into(DriftService.instance.db.downloadedPacks)
        .insertOnConflictUpdate(
          DownloadedPacksCompanion.insert(
            id: packId,
            title: folder.title,
            shareCode: shareCode,
            // creatorId null = "I am the creator"
            creatorId: const Value(null),
            downloadedAt: Value(DateTime.now()),
          ),
        );

    final total = maps.length;
    int done = 0;

    // 4. Upload each map
    for (final map in maps) {
      final imageBase64 =
          map.imageBytes != null ? base64Encode(map.imageBytes!) : null;

      final mapInsert = await _client.from('pack_maps').insert({
        'pack_id': packId,
        'local_map_id': map.id,
        'title': map.title,
        'description': map.description,
        'subject': map.subject,
        'image_base64': imageBase64,
        'order_index': maps.indexOf(map),
      }).select('id').single();
      final packMapId = mapInsert['id'] as String;

      // Record the map mapping locally
      await DriftService.instance.db
          .into(DriftService.instance.db.downloadedPackMaps)
          .insertOnConflictUpdate(
            DownloadedPackMapsCompanion.insert(
              id: packMapId,
              packId: packId,
              localMapId: map.id,
              remoteUpdatedAt: DateTime.now(),
            ),
          );

      final riddles = riddlesByMapId[map.id] ?? [];
      if (riddles.isNotEmpty) {
        await _client.from('pack_riddles').insert(
          riddles
              .map((r) => {
                    'pack_map_id': packMapId,
                    'question': r.question,
                    'type_index': r.typeIndex,
                    'order_in_map': r.orderInMap,
                    'payload_json': r.payloadJson,
                    'source_excerpt': r.sourceExcerpt,
                  })
              .toList(),
        );
      }

      done++;
      onProgress?.call(done / total);
    }

    return shareCode;
  }

  // ── Sync a single map after local edit ────────────────────────────────────

  /// Called when a teacher edits a map that was already shared.
  /// RLS ensures only the original creator_id can do this.
  Future<void> syncMapUpdate({
    required String packMapId,
    required RiddleMap map,
    required List<Riddle> riddles,
  }) async {
    await ensureSignedIn();

    final imageBase64 =
        map.imageBytes != null ? base64Encode(map.imageBytes!) : null;

    await _client.from('pack_maps').update({
      'title': map.title,
      'description': map.description,
      'subject': map.subject,
      'image_base64': imageBase64,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', packMapId);

    await _client
        .from('pack_riddles')
        .delete()
        .eq('pack_map_id', packMapId);

    if (riddles.isNotEmpty) {
      await _client.from('pack_riddles').insert(
        riddles
            .map((r) => {
                  'pack_map_id': packMapId,
                  'question': r.question,
                  'type_index': r.typeIndex,
                  'order_in_map': r.orderInMap,
                  'payload_json': r.payloadJson,
                  'source_excerpt': r.sourceExcerpt,
                })
            .toList(),
      );
    }

    // Update local staleness timestamp
    await (DriftService.instance.db
            .update(DriftService.instance.db.downloadedPackMaps)
          ..where((t) => t.id.equals(packMapId)))
        .write(DownloadedPackMapsCompanion(
      remoteUpdatedAt: Value(DateTime.now()),
    ));
  }

  // ── Download ──────────────────────────────────────────────────────────────

  Future<RemotePackSummary?> fetchPackByCode(String code) async {
    final rows = await _client
        .from('packs')
        .select('id, title, share_code, download_count, created_at, creator_id')
        .eq('share_code', code.toUpperCase().trim())
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return RemotePackSummary.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Downloads a full pack and inserts it into the local Drift DB.
  /// Returns the local Folder id created.
  Future<int> downloadPack({
    required String packId,
    required String shareCode,
    required String creatorId,
    void Function(double progress)? onProgress,
  }) async {
    await ensureSignedIn();
    final db = DriftService.instance;

    // 1. Pack title
    final packRow = await _client
        .from('packs')
        .select('title')
        .eq('id', packId)
        .single();
    final packTitle = packRow['title'] as String;

    // 2. All maps
    final mapRows = await _client
        .from('pack_maps')
        .select(
            'id, local_map_id, title, description, subject, image_base64, updated_at, order_index')
        .eq('pack_id', packId)
        .order('order_index');

    // 3. Local folder
    final folderId = await db.saveFolder(packTitle);

    // 4. Record downloaded pack
    await db.db.into(db.db.downloadedPacks).insertOnConflictUpdate(
          DownloadedPacksCompanion.insert(
            id: packId,
            title: packTitle,
            shareCode: shareCode,
            creatorId: Value(creatorId),
            downloadedAt: Value(DateTime.now()),
          ),
        );

    final total = (mapRows as List).length;
    int done = 0;

    for (final mapRow in mapRows) {
      final packMapId = mapRow['id'] as String;
      final localMapId = const Uuid().v4();
      final imageBase64 = mapRow['image_base64'] as String?;
      final imageBytes =
          imageBase64 != null ? base64Decode(imageBase64) : null;

      await db.saveMap(
        localMapId,
        mapRow['title'] as String,
        mapRow['description'] as String?,
        mapRow['subject'] as String?,
        imageBytes: imageBytes,
      );
      await db.setMapFolder(localMapId, folderId);

      final riddleRows = await _client
          .from('pack_riddles')
          .select(
              'question, type_index, order_in_map, payload_json, source_excerpt')
          .eq('pack_map_id', packMapId)
          .order('order_in_map');

      for (final r in (riddleRows as List)) {
        await db.db.into(db.db.riddles).insert(
              RiddlesCompanion.insert(
                mapId: localMapId,
                question: r['question'] as String,
                typeIndex: r['type_index'] as int,
                orderInMap: r['order_in_map'] as int,
                payloadJson: Value(r['payload_json'] as String?),
                sourceExcerpt: Value(r['source_excerpt'] as String?),
              ),
            );
      }

      await db.db.into(db.db.downloadedPackMaps).insertOnConflictUpdate(
            DownloadedPackMapsCompanion.insert(
              id: packMapId,
              packId: packId,
              localMapId: localMapId,
              remoteUpdatedAt:
                  DateTime.parse(mapRow['updated_at'] as String),
            ),
          );

      done++;
      onProgress?.call(done / total);
    }

    // Increment download counter (fire & forget)
    _client
        .rpc('increment_download_count', params: {'pack_id': packId})
        .then((_) {})
        .catchError((_) {});

    return folderId;
  }

  // ── Staleness check ───────────────────────────────────────────────────────

  Future<List<StaleMapInfo>> checkForUpdates() async {
    final db = DriftService.instance.db;
    final localMaps = await db.select(db.downloadedPackMaps).get();
    if (localMaps.isEmpty) return [];

    final packMapIds = localMaps.map((m) => m.id).toList();
    final remoteRows = await _client
        .from('pack_maps')
        .select('id, updated_at')
        .inFilter('id', packMapIds);

    final stale = <StaleMapInfo>[];
    for (final row in (remoteRows as List)) {
      final remoteUpdatedAt =
          DateTime.parse(row['updated_at'] as String);
      final local = localMaps.firstWhere((m) => m.id == row['id']);
      if (remoteUpdatedAt.isAfter(local.remoteUpdatedAt)) {
        stale.add(StaleMapInfo(
          packMapId: local.id,
          localMapId: local.localMapId,
          packId: local.packId,
          remoteUpdatedAt: remoteUpdatedAt,
        ));
      }
    }
    return stale;
  }

  Future<void> applyMapUpdate(StaleMapInfo info) async {
    final db = DriftService.instance;

    final mapRow = await _client
        .from('pack_maps')
        .select('title, description, subject, image_base64, updated_at')
        .eq('id', info.packMapId)
        .single();

    final imageBase64 = mapRow['image_base64'] as String?;
    final imageBytes =
        imageBase64 != null ? base64Decode(imageBase64) : null;

    await db.saveMap(
      info.localMapId,
      mapRow['title'] as String,
      mapRow['description'] as String?,
      mapRow['subject'] as String?,
      imageBytes: imageBytes,
    );

    await db.deleteRiddlesForMap(info.localMapId);
    await (db.db.delete(db.db.playSessions)
          ..where((t) => t.mapId.equals(info.localMapId)))
        .go();

    final riddleRows = await _client
        .from('pack_riddles')
        .select(
            'question, type_index, order_in_map, payload_json, source_excerpt')
        .eq('pack_map_id', info.packMapId)
        .order('order_in_map');

    for (final r in (riddleRows as List)) {
      await db.db.into(db.db.riddles).insert(
            RiddlesCompanion.insert(
              mapId: info.localMapId,
              question: r['question'] as String,
              typeIndex: r['type_index'] as int,
              orderInMap: r['order_in_map'] as int,
              payloadJson: Value(r['payload_json'] as String?),
              sourceExcerpt: Value(r['source_excerpt'] as String?),
            ),
          );
    }

    await (db.db.update(db.db.downloadedPackMaps)
          ..where((t) => t.id.equals(info.packMapId)))
        .write(DownloadedPackMapsCompanion(
      remoteUpdatedAt: Value(info.remoteUpdatedAt),
    ));
  }

  // ── Popular packs feed ────────────────────────────────────────────────────

  Future<List<RemotePackSummary>> fetchPopularPacks({int limit = 10}) async {
    final rows = await _client
        .from('packs')
        .select('id, title, share_code, download_count, created_at, creator_id')
        .order('download_count', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => RemotePackSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/notification_service.dart';

// ── Scheduled slot model ──────────────────────────────────────────────────────

class TrainingSlot {
  final int riddleId;
  final DateTime scheduledAt;
  final int notificationId;

  const TrainingSlot({
    required this.riddleId,
    required this.scheduledAt,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'riddleId': riddleId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'notificationId': notificationId,
      };

  factory TrainingSlot.fromJson(Map<String, dynamic> json) => TrainingSlot(
        riddleId: json['riddleId'] as int,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        notificationId: json['notificationId'] as int,
      );
}

// ── Training service ──────────────────────────────────────────────────────────

class TrainingService {
  static final TrainingService instance = TrainingService._internal();
  TrainingService._internal();

  // Minimum gap between notifications
  static const _minGapMinutes = 30;

  // Called by main.dart warm-start listener — navigates to riddle screen
  void Function(String mapId, int riddleId)? onTrainingNotificationTap;

  // ── Init ──────────────────────────────────────────────────────────────────

  void init() {
    NotificationService.instance.onNotificationTap = (payload) {
      _handleNotificationTap(payload);
    };
  }

  void _handleNotificationTap(String payload) {
    // Payload format: "mapId:riddleId"
    final parts = payload.split(':');
    if (parts.length != 2) return;
    final mapId = parts[0];
    final riddleId = int.tryParse(parts[1]);
    if (riddleId == null) return;
    onTrainingNotificationTap?.call(mapId, riddleId);
  }

  // ── Active session check ──────────────────────────────────────────────────

  Future<TrainingSession?> getActiveSession(String mapId) async {
    final db = DriftService.instance.db;
    return await (db.select(db.trainingSessions)
          ..where((t) => t.mapId.equals(mapId))
          ..where((t) => t.completedAt.isNull())
          ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> isTrainingActive(String mapId) async {
    final session = await getActiveSession(mapId);
    if (session == null) return false;
    // Auto-expire if past end time
    if (DateTime.now().isAfter(session.endsAt)) {
      await _completeSession(session.id);
      return false;
    }
    return true;
  }

  // ── Start training ────────────────────────────────────────────────────────

  Future<void> startTraining({
    required String mapId,
    required List<Riddle> riddles,
    required int durationHours,
  }) async {
    // Cancel any existing active session for this map
    await stopTraining(mapId);

    final db = DriftService.instance.db;
    final now = DateTime.now();
    final endsAt = now.add(Duration(hours: durationHours));

    // Pool starts as all riddle IDs
    final pool = riddles.map((r) => r.id).toList();

    // Schedule slots upfront
    final slots = _buildSlots(
      mapId: mapId,
      pool: pool,
      from: now,
      to: endsAt,
    );

    // Persist session
    await db.into(db.trainingSessions).insert(
          TrainingSessionsCompanion.insert(
            mapId: mapId,
            endsAt: endsAt,
            poolJson: drift.Value(jsonEncode(pool)),
            scheduledJson: drift.Value(
              jsonEncode(slots.map((s) => s.toJson()).toList()),
            ),
          ),
        );

    // Schedule notifications
    await _scheduleNotifications(mapId, riddles, slots);
  }

  // ── Stop training ─────────────────────────────────────────────────────────

  Future<void> stopTraining(String mapId) async {
    final session = await getActiveSession(mapId);
    if (session == null) return;

    // Cancel all pending notifications for this session
    final slots = _parseSlotsJson(session.scheduledJson);
    for (final slot in slots) {
      await NotificationService.instance.cancelNotification(slot.notificationId);
    }

    await _completeSession(session.id);
  }

  // ── On riddle answered in training ────────────────────────────────────────

  Future<void> onRiddleAnswered({
    required String mapId,
    required int riddleId,
    required bool correct,
    required List<Riddle> riddles,
  }) async {
    final session = await getActiveSession(mapId);
    if (session == null) return;

    final now = DateTime.now();
    if (now.isAfter(session.endsAt)) {
      await _completeSession(session.id);
      return;
    }

    final db = DriftService.instance.db;
    List<int> pool = _parsePoolJson(session.poolJson);
    List<TrainingSlot> slots = _parseSlotsJson(session.scheduledJson);

    if (correct) {
      // Remove from pool permanently
      pool.remove(riddleId);

      // Cancel any future notifications for this riddle
      final toCancel = slots.where((s) =>
          s.riddleId == riddleId && s.scheduledAt.isAfter(now));
      for (final slot in toCancel) {
        await NotificationService.instance.cancelNotification(slot.notificationId);
      }
      slots.removeWhere((s) =>
          s.riddleId == riddleId && s.scheduledAt.isAfter(now));
    }
    // If wrong: riddle stays in pool, already has future slots scheduled.
    // Nothing to do — it will appear again naturally.

    // Check if pool is empty → training complete
    if (pool.isEmpty) {
      await _scheduleCompletionNotification();
      await _completeSession(session.id);
      return;
    }

    // Persist updated state
    await (db.update(db.trainingSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(TrainingSessionsCompanion(
      poolJson: drift.Value(jsonEncode(pool)),
      scheduledJson: drift.Value(
        jsonEncode(slots.map((s) => s.toJson()).toList()),
      ),
    ));
  }

  // ── Build slots ───────────────────────────────────────────────────────────

  List<TrainingSlot> _buildSlots({
    required String mapId,
    required List<int> pool,
    required DateTime from,
    required DateTime to,
  }) {
    final totalMinutes = to.difference(from).inMinutes;
    final count = pool.length;

    // Interval between notifications, respecting minimum gap
    final intervalMinutes =
        max(_minGapMinutes, totalMinutes ~/ count);

    final slots = <TrainingSlot>[];
    final shuffled = List<int>.from(pool)..shuffle(Random());

    for (int i = 0; i < shuffled.length; i++) {
      final scheduledAt = from.add(Duration(minutes: intervalMinutes * (i + 1)));
      if (scheduledAt.isAfter(to)) break;

      slots.add(TrainingSlot(
        riddleId: shuffled[i],
        scheduledAt: scheduledAt,
        notificationId: _notificationId(shuffled[i], scheduledAt),
      ));
    }

    return slots;
  }

  // ── Schedule notifications ────────────────────────────────────────────────

  Future<void> _scheduleNotifications(
    String mapId,
    List<Riddle> riddles,
    List<TrainingSlot> slots,
  ) async {
    final riddleMap = {for (final r in riddles) r.id: r};

    for (final slot in slots) {
      final riddle = riddleMap[slot.riddleId];
      if (riddle == null) continue;

      // Skip slots in the past (safety check)
      if (slot.scheduledAt.isBefore(DateTime.now())) continue;

      await NotificationService.instance.scheduleRiddleNotification(
        id: slot.notificationId,
        title: '🧠 Training time!',
        body: riddle.question.length > 80
            ? '${riddle.question.substring(0, 80)}…'
            : riddle.question,
        scheduledAt: slot.scheduledAt,
        payload: '$mapId:${slot.riddleId}',
      );
    }
  }

  Future<void> _scheduleCompletionNotification() async {
    await NotificationService.instance.scheduleRiddleNotification(
      id: 999999,
      title: '🎉 You\'re ready!',
      body: 'You\'ve mastered all the riddles in this training session.',
      scheduledAt: DateTime.now().add(const Duration(seconds: 2)),
      payload: '',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _completeSession(int sessionId) async {
    final db = DriftService.instance.db;
    await (db.update(db.trainingSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(TrainingSessionsCompanion(
      completedAt: drift.Value(DateTime.now()),
    ));
  }

  List<int> _parsePoolJson(String json) {
    try {
      return (jsonDecode(json) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }

  List<TrainingSlot> _parseSlotsJson(String json) {
    try {
      return (jsonDecode(json) as List)
          .map((e) => TrainingSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Deterministic notification ID from riddle ID + scheduled time
  // Stays within Flutter local notifications int range
  int _notificationId(int riddleId, DateTime scheduledAt) =>
      (riddleId * 1000 + scheduledAt.millisecondsSinceEpoch ~/ 60000) %
      2147483647;
}

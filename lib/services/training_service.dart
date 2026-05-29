import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/notification_service.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const int kTrainingMinGapMinutes = 3;

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

  void Function(String mapId, int riddleId)? onTrainingNotificationTap;

  // ── Init ──────────────────────────────────────────────────────────────────

  void init() {
    NotificationService.instance.onNotificationTap = (payload) {
      _handleNotificationTap(payload);
    };
  }

  void _handleNotificationTap(String payload) {
    if (payload.isEmpty) return;
    final parts = payload.split(':');
    if (parts.length != 2) return;
    final mapId = parts[0];
    final riddleId = int.tryParse(parts[1]);
    if (riddleId == null) return;
    onTrainingNotificationTap?.call(mapId, riddleId);
  }

  // ── Active session ────────────────────────────────────────────────────────

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
    if (DateTime.now().isAfter(session.endsAt)) {
      await _completeSession(session.id);
      return false;
    }
    return true;
  }

  // ── Start ─────────────────────────────────────────────────────────────────

  Future<void> startTraining({
    required String mapId,
    required List<Riddle> riddles,
    required int durationMinutes,
  }) async {
    await stopTraining(mapId);

    final db = DriftService.instance.db;
    final now = DateTime.now();
    final endsAt = now.add(Duration(minutes: durationMinutes));

    final pool = riddles.map((r) => r.id).toList();

    final firstHalfEnd = now.add(Duration(minutes: durationMinutes ~/ 2));
    final slots = _buildInitialSlots(
      mapId: mapId,
      pool: pool,
      from: now,
      to: firstHalfEnd,
    );

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

    await _scheduleNotifications(mapId, riddles, slots);
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  Future<void> stopTraining(String mapId) async {
    final session = await getActiveSession(mapId);
    if (session == null) return;

    final slots = _parseSlotsJson(session.scheduledJson);
    for (final slot in slots) {
      await NotificationService.instance
          .cancelNotification(slot.notificationId);
    }

    await _completeSession(session.id);
  }

  // ── On riddle answered ────────────────────────────────────────────────────

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
    List<TrainingSlot> slotsToCancel = [];
    TrainingSlot? newSlot;

    // ── Record attempt ────────────────────────────────────────────────────
    await DriftService.instance.insertTrainingAttempt(
      sessionId: session.id,
      riddleId: riddleId,
      correct: correct,
    );

    if (correct) {
      pool.remove(riddleId);

      slotsToCancel = slots
          .where((s) =>
              s.riddleId == riddleId && s.scheduledAt.isAfter(now))
          .toList();

      slots.removeWhere(
          (s) => s.riddleId == riddleId && s.scheduledAt.isAfter(now));

      // ── Remove from notified queue ──────────────────────────────────────
      await DriftService.instance.removeNotifiedRiddle(
        sessionId: session.id,
        riddleId: riddleId,
      );

      if (pool.isEmpty) {
        await (db.update(db.trainingSessions)
              ..where((t) => t.id.equals(session.id)))
            .write(TrainingSessionsCompanion(
          poolJson: drift.Value(jsonEncode(pool)),
          scheduledJson: drift.Value(
              jsonEncode(slots.map((s) => s.toJson()).toList())),
          completedAt: drift.Value(DateTime.now()),
        ));

        await _scheduleCompletionNotification();
        for (final slot in slotsToCancel) {
          await NotificationService.instance
              .cancelNotification(slot.notificationId);
        }
        return;
      }
    } else {
      newSlot = _scheduleFailureSlot(
        mapId: mapId,
        riddleId: riddleId,
        existingSlots: slots,
        sessionEndsAt: session.endsAt,
        now: now,
      );

      if (newSlot != null) {
        slots.add(newSlot);
      }
    }

    // Update DB state
    await (db.update(db.trainingSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(TrainingSessionsCompanion(
      poolJson: drift.Value(jsonEncode(pool)),
      scheduledJson: drift.Value(
        jsonEncode(slots.map((s) => s.toJson()).toList()),
      ),
    ));

    // Notify mutations
    if (correct) {
      for (final slot in slotsToCancel) {
        await NotificationService.instance
            .cancelNotification(slot.notificationId);
      }
    } else if (newSlot != null) {
      final riddle = riddles.firstWhere((r) => r.id == riddleId);
      await NotificationService.instance.scheduleRiddleNotification(
        id: newSlot.notificationId,
        title: '🧠 Training time!',
        body: riddle.question.length > 80
            ? '${riddle.question.substring(0, 80)}…'
            : riddle.question,
        scheduledAt: newSlot.scheduledAt,
        payload: '$mapId:$riddleId',
      );
      // ── Mark as notified for the new failure slot ─────────────────────
      await DriftService.instance.insertNotifiedRiddle(
        sessionId: session.id,
        mapId: mapId,
        riddleId: riddleId,
      );
    }
  }

  // ── Build initial slots ───────────────────────────────────────────────────

  List<TrainingSlot> _buildInitialSlots({
    required String mapId,
    required List<int> pool,
    required DateTime from,
    required DateTime to,
  }) {
    final totalMinutes = to.difference(from).inMinutes;
    final count = pool.length;
    if (count == 0) return [];

    final intervalMinutes = max(
      kTrainingMinGapMinutes,
      totalMinutes ~/ count,
    );

    final slots = <TrainingSlot>[];
    final shuffled = List<int>.from(pool)..shuffle(Random());

    final baseTime = from.add(const Duration(seconds: 10));

    for (int i = 0; i < shuffled.length; i++) {
      final scheduledAt =
          baseTime.add(Duration(minutes: intervalMinutes * (i + 1)));
      if (scheduledAt.isAfter(to)) break;

      slots.add(TrainingSlot(
        riddleId: shuffled[i],
        scheduledAt: scheduledAt,
        notificationId: _notificationId(shuffled[i], scheduledAt),
      ));
    }

    return slots;
  }

  // ── Schedule failure slot ─────────────────────────────────────────────────

  TrainingSlot? _scheduleFailureSlot({
    required String mapId,
    required int riddleId,
    required List<TrainingSlot> existingSlots,
    required DateTime sessionEndsAt,
    required DateTime now,
  }) {
    final futureSlots = existingSlots
        .where((s) => s.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    DateTime candidate;
    if (futureSlots.isEmpty) {
      candidate = now.add(Duration(minutes: kTrainingMinGapMinutes));
    } else {
      candidate = futureSlots.last.scheduledAt
          .add(Duration(minutes: kTrainingMinGapMinutes));
    }

    if (candidate.isAfter(sessionEndsAt)) return null;

    return TrainingSlot(
      riddleId: riddleId,
      scheduledAt: candidate,
      notificationId: _notificationId(riddleId, candidate),
    );
  }

  // ── Schedule notifications ────────────────────────────────────────────────

  Future<void> _scheduleNotifications(
    String mapId,
    List<Riddle> riddles,
    List<TrainingSlot> slots,
  ) async {
    // Fetch the session we just created so we have its id
    final session = await getActiveSession(mapId);
    final riddleMap = {for (final r in riddles) r.id: r};

    for (final slot in slots) {
      final riddle = riddleMap[slot.riddleId];
      if (riddle == null) continue;
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

      // ── Mark as notified ──────────────────────────────────────────────
      if (session != null) {
        await DriftService.instance.insertNotifiedRiddle(
          sessionId: session.id,
          mapId: mapId,
          riddleId: slot.riddleId,
        );
      }
    }
  }

  Future<void> _scheduleCompletionNotification() async {
    await NotificationService.instance.scheduleRiddleNotification(
      id: 999999,
      title: '🎉 You\'re ready!',
      body: 'You\'ve mastered all the riddles. Training complete!',
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

  int _notificationId(int riddleId, DateTime scheduledAt) =>
      (riddleId * 1000 + scheduledAt.millisecondsSinceEpoch ~/ 60000) %
      2147483647;
}

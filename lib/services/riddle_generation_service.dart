import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:enola/database/database.dart';
import 'package:enola/services/gemini_service.dart';
import 'package:enola/services/ocr_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:enola/database/schema_utils.dart';


// ---

class RiddleGenerationService {
  static final RiddleGenerationService instance = RiddleGenerationService._();
  RiddleGenerationService._();

  /// Bridge for ScanScreen — converts image paths → extracted text → riddles.
  Future<List<Riddle>> generateFromImages({
    required List<String> imagePaths,
    required String mapId,
    int count = 5,
  }) async {
    final files = imagePaths.map((path) => File(path)).toList();
    final extractedText = await OCRService.instance.extractTextFromImages(files);
    return generateRiddlesFromText(text: extractedText, mapId: mapId, count: count);
  }

  // ---

  /// Calls GeminiService.generateRiddles and maps raw JSON → typed Riddle objects.
  Future<List<Riddle>> generateRiddlesFromText({
    required String text,
    required String mapId,
    int count = 5,
  }) async {
    try {
      final List<Map<String, dynamic>> rawRiddles =
          await GeminiService.instance.generateRiddles(text, count: count);

      return rawRiddles.asMap().entries.map<Riddle>((entry) {
        final index = entry.key;
        final data = entry.value;
        final isOrdering = data['type'] == 'ordering';

        // sourceExcerpt: may be null if Gemini omitted it — that's fine
        final String? sourceExcerpt = data['sourceExcerpt'] as String?;

        final RiddlePayload payload;
        final String legacyChoicesJson;
        final int? legacyCorrectIndex;

        if (isOrdering) {
          final items = (data['items'] as List? ?? []).cast<String>();
          payload = OrderingPayload(items: items);
          legacyChoicesJson = jsonEncode(items);
          legacyCorrectIndex = null;
        } else {
          final choices = (data['choices'] as List? ?? []).cast<String>();
          final correctIndex = (data['correctIndex'] as int?) ?? 0;
          payload = MultipleChoicePayload(choices: choices, correctIndex: correctIndex);
          legacyChoicesJson = jsonEncode(choices);
          legacyCorrectIndex = correctIndex;
        }

        // We build a RiddlesCompanion so drift.Value handles the nullable
        // sourceExcerpt correctly, then convert to a Riddle via toInsertable.
        final companion = RiddlesCompanion.insert(
          mapId: mapId,
          question: (data['question'] as String?) ?? 'Unnamed Trial',
          typeIndex: isOrdering
              ? RiddleType.ordering.index
              : RiddleType.multipleChoice.index,
          orderInMap: index,
          payloadJson: drift.Value(jsonEncode(payload.toJson())),
          choicesJson: drift.Value(legacyChoicesJson),
          correctIndex: drift.Value(legacyCorrectIndex),
          sourceExcerpt: drift.Value(sourceExcerpt),
        );

        // Drift's Insertable → DataClass conversion gives us a proper Riddle.
        // id is autoIncrement so we use 0 as placeholder (same as before).
        return Riddle(
          id: 0,
          mapId: companion.mapId.value,
          question: companion.question.value,
          typeIndex: companion.typeIndex.value,
          orderInMap: companion.orderInMap.value,
          payloadJson: companion.payloadJson.value,
          choicesJson: companion.choicesJson.value,
          correctIndex: companion.correctIndex.value,
          sourceExcerpt: companion.sourceExcerpt.value,
        );
      }).toList();
    } catch (e) {
      debugPrint('Generation failed: $e');
      rethrow;
    }
  }
}

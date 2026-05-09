import 'dart:convert';
import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/services/gemini_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RiddleGenerationService {
  static final RiddleGenerationService instance = RiddleGenerationService._();
  RiddleGenerationService._();

  /// Bridge for ScanScreen — converts image paths → extracted text → riddles.
  Future<List<Riddle>> generateFromImages({
    required List<String> imagePaths,
    required String mapId,
  }) async {
    final files = imagePaths.map((path) => File(path)).toList();
    final extractedText = await GeminiService.instance.extractTextFromImages(files);
    return generateRiddlesFromText(text: extractedText, mapId: mapId);
  }

  /// Calls GeminiService.generateRiddles and maps raw JSON → typed Riddle objects.
  Future<List<Riddle>> generateRiddlesFromText({
    required String text,
    required String mapId,
  }) async {
    try {
      final List<Map<String, dynamic>> rawRiddles =
          await GeminiService.instance.generateRiddles(text, count: 5);

      return rawRiddles.asMap().entries.map<Riddle>((entry) {
        final index = entry.key;
        final data = entry.value;
        final isOrdering = data['type'] == 'ordering';

        // Build the typed payload so payloadJson is always populated.
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

        return Riddle(
          id: 0,
          mapId: mapId,
          question: (data['question'] as String?) ?? 'Unnamed Trial',
          typeIndex: isOrdering
              ? RiddleType.ordering.index
              : RiddleType.multipleChoice.index,
          orderInMap: index,
          payloadJson: jsonEncode(payload.toJson()),
          choicesJson: legacyChoicesJson,   // legacy fallback
          correctIndex: legacyCorrectIndex, // legacy fallback
        );
      }).toList();
    } catch (e) {
      debugPrint('Generation failed: $e');
      return [];
    }
  }
}

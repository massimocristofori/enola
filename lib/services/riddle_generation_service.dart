import 'dart:convert';
import 'dart:io';

import '../models/riddle.dart';
import 'gemini_service.dart';
import 'ocr_service.dart';

class RiddleGenerationService {
  RiddleGenerationService._();
  static final RiddleGenerationService instance =
      RiddleGenerationService._();

  /// Full pipeline: images → OCR → text → Gemini
  Future<List<Riddle>> generateFromImages(
    List<File> images, {
    int riddleCount = 5,
    int mapId = 0,
  }) async {
    final text =
        await OCRService.instance.extractTextFromImages(images);

    return generateFromText(
      text,
      riddleCount: riddleCount,
      mapId: mapId,
    );
  }

  /// Text → riddles (pure LLM step)
  Future<List<Riddle>> generateFromText(
    String sourceText, {
    int riddleCount = 5,
    int mapId = 0,
  }) async {
    final rawList = await GeminiService.instance.generateRiddles(
      sourceText,
      count: riddleCount,
    );

    final riddles = <Riddle>[];

    for (var i = 0; i < rawList.length; i++) {
      final r = _parseRiddle(rawList[i], order: i, mapId: mapId);
      if (r != null) riddles.add(r);
    }

    return riddles;
  }

  Riddle? _parseRiddle(
    Map<String, dynamic> raw, {
    required int order,
    required int mapId,
  }) {
    try {
      final type = raw['type'] as String;
      final question = raw['question'] as String;

      final riddle = Riddle()
        ..mapId = mapId
        ..question = question
        ..orderInMap = order;

      switch (type) {
        case 'multipleChoice':
          riddle.type = RiddleType.multipleChoice;
          riddle.mcChoicesJson = jsonEncode(raw['choices']);
          riddle.mcCorrectIndex = raw['correctIndex'];
          break;

        case 'ordering':
          riddle.type = RiddleType.ordering;
          riddle.orderItemsJson = jsonEncode(raw['items']);
          break;

        default:
          return null;
      }

      return riddle;
    } catch (_) {
      return null;
    }
  }
}

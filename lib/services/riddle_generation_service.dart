import 'dart:convert';
import 'dart:io';

import '../models/riddle.dart';
import 'gemini_service.dart';

class RiddleGenerationService {
  RiddleGenerationService._();
  static final RiddleGenerationService instance = RiddleGenerationService._();

  /// Full pipeline: images → text → riddles
  Future<List<Riddle>> generateFromImages(
    List<File> images, {
    int riddleCount = 5,
    int mapId = 0, // will be set after map is saved
  }) async {
    final text = await GeminiService.instance.extractTextFromImages(images);
    return generateFromText(text, riddleCount: riddleCount, mapId: mapId);
  }

  /// Text-only pipeline (useful when user already has the text)
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
      final raw = rawList[i];
      final riddle = _parseRiddle(raw, order: i, mapId: mapId);
      if (riddle != null) riddles.add(riddle);
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
          riddle.mcChoicesJson =
              jsonEncode((raw['choices'] as List).cast<String>());
          riddle.mcCorrectIndex = raw['correctIndex'] as int;

        case 'ordering':
          riddle.type = RiddleType.ordering;
          riddle.orderItemsJson =
              jsonEncode((raw['items'] as List).cast<String>());

        default:
          return null; // unknown type — skip gracefully
      }

      return riddle;
    } catch (_) {
      return null;
    }
  }
}

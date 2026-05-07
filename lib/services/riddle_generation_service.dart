import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/database/database.dart';

import 'gemini_service.dart';
import 'ocr_service.dart';
import '../utils/text_cleaner.dart';

class RiddleGenerationService {
  RiddleGenerationService._();
  static final RiddleGenerationService instance =
      RiddleGenerationService._();

  final _uuid = const Uuid();

  /// Full pipeline: images → OCR → text → Gemini
  Future<List<Riddle>> generateFromImages(
    List<File> images, {
    int riddleCount = 5,
    String? mapId,
  }) async {
    final text =
        await OCRService.instance.extractTextFromImages(images);

    final cleanedText = cleanOcrText(text);

    return generateFromText(
      cleanedText,
      riddleCount: riddleCount,
      mapId: mapId ?? _uuid.v4(),
    );
  }

  /// Text → riddles (pure LLM step)
  Future<List<Riddle>> generateFromText(
    String sourceText, {
    int riddleCount = 5,
    required String mapId,
  }) async {
    final rawList = await GeminiService.instance.generateRiddles(
      sourceText,
      count: riddleCount,
    );

    final riddles = <Riddle>[];

    for (var i = 0; i < rawList.length; i++) {
      final r = _parseRiddle(
        rawList[i],
        order: i,
        mapId: mapId,
      );

      if (r != null) riddles.add(r);
    }

    return riddles;
  }

  Riddle? _parseRiddle(
    Map<String, dynamic> raw, {
    required int order,
    required String mapId,
  }) {
    try {
      final type = raw['type'] as String;
      final question = raw['question'] as String;

      final isMC = type == 'multipleChoice';

final riddle = Riddle(
  id: 0, // Drift classes require an ID; use 0 as a placeholder for autoincrement
  mapId: 'temp', 
  question: generatedQuestion,
  typeIndex: type.index,
  orderInMap: index,
  // Use the actual column names from your Drift table:
  choicesJson: jsonEncode(generatedChoices), 
  correctIndex: generatedCorrectIndex,
);


      if (isMC) {
        riddle.mcChoicesJson = jsonEncode(raw['choices']);
        riddle.mcCorrectIndex = raw['correctIndex'];
      } else {
        riddle.orderItemsJson = jsonEncode(raw['items']);
      }

      return riddle;
    } catch (_) {
      return null;
    }
  }
}

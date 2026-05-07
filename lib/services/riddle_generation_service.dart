import 'dart:convert';
import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/services/gemini_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RiddleGenerationService {
  static final RiddleGenerationService instance = RiddleGenerationService._();
  RiddleGenerationService._();

  /// 1. The bridge for ScanScreen (Fixes the generateFromImages error)
  Future<List<Riddle>> generateFromImages({
    required List<String> imagePaths,
    required String mapId,
  }) async {
    // Convert paths to File objects for Gemini
    final files = imagePaths.map((path) => File(path)).toList();
    
    // Step A: Extract text using your existing service
    final extractedText = await GeminiService.instance.extractTextFromImages(files);
    
    // Step B: Generate riddles from that text
    return generateRiddlesFromText(text: extractedText, mapId: mapId);
  }

  /// 2. The logic that calls your existing GeminiService.generateRiddles
  Future<List<Riddle>> generateRiddlesFromText({
    required String text,
    required String mapId,
  }) async {
    try {
      // Calls your working method: generateRiddles
      final List<Map<String, dynamic>> rawRiddles = 
          await GeminiService.instance.generateRiddles(text, count: 5);

      return rawRiddles.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        final isOrdering = data['type'] == 'ordering';

        return Riddle(
          id: 0, 
          mapId: mapId,
          question: data['question'] ?? 'Unnamed Trial',
          typeIndex: isOrdering ? RiddleType.ordering.index : RiddleType.multipleChoice.index,
          orderInMap: index,
          // We store both 'choices' and 'items' in the same JSON column
          choicesJson: jsonEncode(isOrdering ? data['items'] : data['choices']),
          correctIndex: data['correctIndex'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Generation failed: $e');
      return [];
    }
  }
}

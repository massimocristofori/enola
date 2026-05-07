import 'dart:convert';
import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/services/gemini_service.dart';

class RiddleGenerationService {
  static final RiddleGenerationService instance = RiddleGenerationService._();
  RiddleGenerationService._();

  /// Analyzes scanned text and generates a list of Drift Riddle objects.
  Future<List<Riddle>> generateRiddlesFromText({
    required String text,
    required String mapId,
  }) async {
    // 1. Prepare the prompt for Gemini
    final prompt = '''
      You are a fantasy quest builder. Analyze the following text and create 3 riddles.
      Text: "$text"
      
      Return ONLY a JSON array of objects with this structure:
      [
        {
          "question": "The riddle text",
          "choices": ["Choice A", "Choice B", "Choice C", "Choice D"],
          "correctIndex": 0,
          "type": "multipleChoice"
        }
      ]
    ''';

    try {
      // 2. Call Gemini
      final response = await GeminiService.instance.generateContent(prompt);
      final String cleanJson = _stripMarkdown(response);
      final List<dynamic> decoded = jsonDecode(cleanJson);

      // 3. Map JSON to Drift Riddle objects
      return decoded.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        // Determine the type index from the Enum
        int typeIdx = RiddleType.multipleChoice.index;
        if (data['type'] == 'ordering') {
          typeIdx = RiddleType.ordering.index;
        }

        // Drift objects must be created via constructor (Immutable)
        return Riddle(
          id: 0, // Placeholder, autoincremented by DB
          mapId: mapId,
          question: data['question'] ?? 'Unknown Trial',
          typeIndex: typeIdx,
          orderInMap: index,
          choicesJson: jsonEncode(data['choices'] ?? []),
          correctIndex: data['correctIndex'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('AI Generation Error: $e');
      return [];
    }
  }

  /// Helper to clean Gemini's markdown code blocks if present
  String _stripMarkdown(String text) {
    if (text.contains('```json')) {
      return text.split('```json')[1].split('```')[0].trim();
    } else if (text.contains('```')) {
      return text.split('```')[1].split('```')[0].trim();
    }
    return text.trim();
  }
}

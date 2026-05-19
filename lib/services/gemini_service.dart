import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Thrown when the Gemini API returns an unexpected / unparsable response.
class GeminiParseException implements Exception {
  final String message;
  GeminiParseException(this.message);
  @override
  String toString() => 'GeminiParseException: $message';
}

// ---

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Must be set before calling any method.
  String? apiKey;

  GenerativeModel get _model {
    assert(apiKey != null && apiKey!.isNotEmpty, 'GeminiService: apiKey not set');

    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  // ---

  /// Asks Gemini to generate [count] riddles from [sourceText].
  ///
  /// Returns a list of raw riddle maps ready to be parsed into Riddle objects.
  /// Each map has at minimum: { "type", "question", "sourceExcerpt", ... type-specific fields }
  Future<List<Map<String, dynamic>>> generateRiddles(
    String sourceText, {
    int count = 5,
  }) async {
    final prompt = '''
You are a quiz-generation assistant for students.
IMPORTANT: You must respond in the SAME LANGUAGE as the provided text.

Given the following text, generate exactly $count riddles to test comprehension.

Use ONLY these riddle types:
- "multipleChoice": a question with 4 answer options, one correct.
- "ordering": a list of 4-6 items the student must arrange in the correct order.

Mix the types. Respond ONLY with a valid JSON array. No markdown, no explanation.

Each element must be one of:
{
  "type": "multipleChoice",
  "question": "...",
  "choices": ["A", "B", "C", "D"],
  "correctIndex": 0,
  "sourceExcerpt": "copy here the exact sentence(s) from the text above that this riddle is based on, word for word, no paraphrasing"
}
or
{
  "type": "ordering",
  "question": "...",
  "items": ["first", "second", "third", "fourth"],
  "sourceExcerpt": "copy here the exact sentence(s) from the text above that this riddle is based on, word for word, no paraphrasing"
}

Text:
"""
$sourceText
"""
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    final raw = response.text ?? '';
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) throw const FormatException('Expected JSON array');
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      throw GeminiParseException('Could not parse Gemini response: $e\n\n$raw');
    }
  }
}

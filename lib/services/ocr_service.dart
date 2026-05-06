import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  OCRService._();
  static final OCRService instance = OCRService._();

  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from a single image
  Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final RecognizedText result =
        await _recognizer.processImage(inputImage);

    return _formatRecognizedText(result);
  }

  /// Extract text from multiple images (pages)
  Future<String> extractTextFromImages(List<File> images) async {
    final buffer = StringBuffer();

    for (int i = 0; i < images.length; i++) {
      final text = await extractTextFromImage(images[i]);

      buffer.writeln('--- Page ${i + 1} ---');
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// Converts ML Kit blocks → clean readable text
  String _formatRecognizedText(RecognizedText result) {
    final buffer = StringBuffer();

    for (final block in result.blocks) {
      for (final line in block.lines) {
        buffer.writeln(line.text);
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// Always dispose when app shuts down
  void dispose() {
    _recognizer.close();
  }
}

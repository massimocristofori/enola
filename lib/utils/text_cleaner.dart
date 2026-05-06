String cleanOcrText(String text) {
  return text
      // Fix hyphenated line breaks (common OCR issue)
      .replaceAll(RegExp(r'-\n'), '')

      // Merge broken lines
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')

      // Remove weird excessive spaces
      .replaceAll(RegExp(r'[ \t]+'), ' ')

      // Trim each line
      .split('\n')
      .map((line) => line.trim())
      .join('\n')

      .trim();
}

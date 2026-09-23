import 'dart:io';
import 'dart:math';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final int pageHint;

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.pageHint,
  });
}

/// Builds comprehension MCQs from real PDF page text (on-device).
class ReadingQuizService {
  ReadingQuizService._();
  static final instance = ReadingQuizService._();

  /// Extract plain text for 1-based [pageNumbers].
  Future<Map<int, String>> extractPageTexts(
    String pdfPath,
    Iterable<int> pageNumbers,
  ) async {
    final bytes = await File(pdfPath).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final out = <int, String>{};
    try {
      for (final p in pageNumbers) {
        if (p < 1 || p > doc.pages.count) continue;
        final text = extractor.extractText(
          startPageIndex: p - 1,
          endPageIndex: p - 1,
        );
        out[p] = _normalize(text);
      }
    } finally {
      doc.dispose();
    }
    return out;
  }

  String _normalize(String t) =>
      t.replaceAll(RegExp(r'\s+'), ' ').trim();

  List<String> _sentences(String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 6 && s.length < 220)
        .toList();
    return parts;
  }

  List<String> _keywords(String text) {
    final stop = {
      'the', 'and', 'for', 'that', 'with', 'this', 'from', 'have', 'were',
      'been', 'they', 'their', 'what', 'when', 'where', 'which', 'while',
      'about', 'would', 'could', 'should', 'there', 'these', 'those', 'into',
      'your', 'more', 'some', 'than', 'then', 'them', 'only', 'also', 'just',
    };
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 5 && !stop.contains(w))
        .toSet()
        .toList();
    words.shuffle(Random(text.hashCode));
    return words;
  }

  /// Generate up to [count] questions from extracted page texts.
  List<QuizQuestion> generate(
    Map<int, String> pageTexts, {
    int count = 3,
  }) {
    final rng = Random(pageTexts.values.join().hashCode);
    final questions = <QuizQuestion>[];
    final pages = pageTexts.keys.toList()..sort();

    for (final page in pages) {
      if (questions.length >= count) break;
      final text = pageTexts[page] ?? '';
      if (text.length < 40) continue;

      final sentences = _sentences(text);
      final keys = _keywords(text);
      if (keys.length < 4) continue;

      // Q type A: which word appeared on this page?
      final correct = keys.first;
      final distractors = keys.skip(1).take(3).toList();
      while (distractors.length < 3) {
        distractors.add('option${distractors.length}');
      }
      final options = [...distractors, correct]..shuffle(rng);
      questions.add(
        QuizQuestion(
          prompt:
              'Which word or name appears on page $page of what you just read?',
          options: options,
          correctIndex: options.indexOf(correct),
          pageHint: page,
        ),
      );

      if (questions.length >= count) break;

      // Q type B: sentence completion / true statement
      if (sentences.isNotEmpty) {
        final s = sentences[rng.nextInt(sentences.length)];
        final words = s.split(' ');
        if (words.length >= 8) {
          final blankAt = words.length ~/ 2;
          final answer = words[blankAt].replaceAll(RegExp(r'[^a-zA-Z]'), '');
          if (answer.length >= 4) {
            final promptWords = List<String>.from(words);
            promptWords[blankAt] = '______';
            final wrong = keys
                .where((k) => k.toLowerCase() != answer.toLowerCase())
                .take(3)
                .toList();
            while (wrong.length < 3) {
              wrong.add('word${wrong.length}');
            }
            final opts = [...wrong, answer]..shuffle(rng);
            questions.add(
              QuizQuestion(
                prompt:
                    'Fill the blank from page $page:\n"${promptWords.join(' ')}"',
                options: opts,
                correctIndex: opts.indexOf(answer),
                pageHint: page,
              ),
            );
          }
        }
      }
    }

    // Fallback if PDF has little extractable text
    while (questions.length < count) {
      final page = pages.isEmpty ? 1 : pages[questions.length % pages.length];
      final text = pageTexts[page] ?? '';
      final snippet = text.length > 12
          ? text.substring(0, min(24, text.length))
          : 'reading';
      questions.add(
        QuizQuestion(
          prompt:
              'You opened page $page. Which best matches text near the start of that page?',
          options: [
            snippet,
            'Unrelated placeholder alpha',
            'Unrelated placeholder beta',
            'Unrelated placeholder gamma',
          ],
          correctIndex: 0,
          pageHint: page,
        ),
      );
    }

    return questions.take(count).toList();
  }
}

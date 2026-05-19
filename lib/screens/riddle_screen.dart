import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/theme/enola_theme.dart';

class RiddleScreen extends StatefulWidget {
  final Riddle riddle;
  final int riddleIndex;

  const RiddleScreen({
    super.key,
    required this.riddle,
    required this.riddleIndex,
  });

  @override
  State<RiddleScreen> createState() => _RiddleScreenState();
}

class _RiddleScreenState extends State<RiddleScreen> {
  bool _solvedCorrectly = false;
  int? _selectedAnswer;
  bool? _lastAnswerCorrect;
  bool _showingFeedback = false;
  int _errorCount = 0;
  List<String> _orderedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.riddle.type == RiddleType.ordering) {
      final items = widget.riddle.asOrdering?.items ?? widget.riddle.choices;
      _orderedItems = List.from(items)..shuffle(math.Random());
    }
  }

  bool get _canShowHint =>
      widget.riddle.sourceExcerpt != null &&
      widget.riddle.sourceExcerpt!.isNotEmpty &&
      (_solvedCorrectly || _errorCount >= 3);

  bool get _hasHint =>
      widget.riddle.sourceExcerpt != null &&
      widget.riddle.sourceExcerpt!.isNotEmpty;

  void _onMultipleChoiceAnswer(int index, int correctIndex) {
    if (_solvedCorrectly || _showingFeedback) return;
    final correct = index == correctIndex;
    setState(() {
      _selectedAnswer = index;
      _lastAnswerCorrect = correct;
      _showingFeedback = true;
      if (correct) {
        _solvedCorrectly = true;
      } else {
        _errorCount++;
      }
    });
  }

  void _retryAfterWrong() {
    setState(() {
      _selectedAnswer = null;
      _lastAnswerCorrect = null;
      _showingFeedback = false;
    });
  }

  void _confirm() {
    if (_solvedCorrectly) {
      Navigator.pop(context, _errorCount);
    } else {
      Navigator.pop(context, null);
    }
  }

  void _onOrderingSubmit(List<String> correctOrder) {
    if (_solvedCorrectly || _showingFeedback) return;
    final correct = _orderedItems.join('|') == correctOrder.join('|');
    setState(() {
      _lastAnswerCorrect = correct;
      _showingFeedback = true;
      if (correct) {
        _solvedCorrectly = true;
      } else {
        _errorCount++;
      }
    });
  }

  // ── HINT BOTTOM SHEET ──────────────────────────────────────────────────────

  void _showHint() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EnolaTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EnolaTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: EnolaTheme.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Source Passage',
                  style: TextStyle(
                    color: EnolaTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'The original passage this riddle was taken from.',
              style: TextStyle(
                color: EnolaTheme.textSecond,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EnolaTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EnolaTheme.border),
              ),
              child: Text(
                widget.riddle.sourceExcerpt!,
                style: const TextStyle(
                  color: EnolaTheme.textPrimary,
                  fontSize: 14,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final riddle = widget.riddle;

    return Scaffold(
      backgroundColor: EnolaTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: EnolaTheme.textSecond),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Text(
                        'Riddle #${widget.riddleIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: EnolaTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_hasHint)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: _canShowHint ? _showHint : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _canShowHint
                                    ? const LinearGradient(
                                        colors: [
                                          EnolaTheme.accent,
                                          EnolaTheme.secondary,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: _canShowHint
                                    ? null
                                    : EnolaTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: _canShowHint
                                    ? null
                                    : Border.all(color: EnolaTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 15,
                                    color: _canShowHint
                                        ? Colors.white
                                        : EnolaTheme.textSecond,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hint',
                                    style: TextStyle(
                                      color: _canShowHint
                                          ? Colors.white
                                          : EnolaTheme.textSecond,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Card(
                          elevation: _solvedCorrectly ? 4 : 0,
                          shadowColor: _solvedCorrectly
                              ? EnolaTheme.accent.withValues(alpha: 0.3)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _solvedCorrectly
                                  ? EnolaTheme.accent
                                  : EnolaTheme.border,
                              width: _solvedCorrectly ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('Riddle #${widget.riddleIndex + 1}',
                                    style: EnolaTheme.sectionHeader),
                                const SizedBox(height: 16),
                                Text(
                                  riddle.question,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn().scale(delay: 100.ms),
                        const SizedBox(height: 32),

                        if (riddle.type == RiddleType.multipleChoice ||
                            riddle.type == RiddleType.trueFalse)
                          _buildMultipleChoice(riddle)
                        else
                          _buildOrdering(riddle),
                      ],
                    ),
                  ),
                ),

                // ── Feedback bar ──
if (_showingFeedback)
  _AnswerFeedback(
    isCorrect: _lastAnswerCorrect ?? false,
    errorCount: _errorCount,
    onSkip: () => Navigator.pop(context, 0),
    onContinue: (_lastAnswerCorrect ?? false)
        ? _confirm
        : _retryAfterWrong,
  ).animate().slideY(begin: 1, end: 0).fadeIn(),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── MULTIPLE CHOICE ────────────────────────────────────────────────────────

  Widget _buildMultipleChoice(Riddle riddle) {
    final choices = [
      riddle.choiceA,
      riddle.choiceB,
      riddle.choiceC,
      riddle.choiceD,
    ].where((c) => c != null && c.isNotEmpty).cast<String>().toList();

    return Column(
      children: List.generate(choices.length, (i) {
        final isSelected = _selectedAnswer == i;
        final isCorrectChoice = i == riddle.correctChoiceIndex;

        Color borderColor = EnolaTheme.border;
        Color bgColor = Colors.white;

        if (_showingFeedback) {
          if (isCorrectChoice && _solvedCorrectly) {
            borderColor = EnolaTheme.correct;
            bgColor = EnolaTheme.correct.withAlpha(25);
          } else if (isSelected && !(_lastAnswerCorrect ?? false)) {
            borderColor = EnolaTheme.wrong;
            bgColor = EnolaTheme.wrong.withAlpha(25);
          }
        } else if (isSelected) {
          borderColor = EnolaTheme.accent;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () =>
                _onMultipleChoiceAnswer(i, riddle.correctChoiceIndex ?? 0),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ||
                          (_showingFeedback &&
                              isCorrectChoice &&
                              _solvedCorrectly)
                      ? 2
                      : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? EnolaTheme.accent
                        : EnolaTheme.surfaceHigh,
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected ? Colors.white : EnolaTheme.textSecond,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(choices[i],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  if (_showingFeedback && isCorrectChoice && _solvedCorrectly)
                    const Icon(Icons.check_circle, color: EnolaTheme.correct),
                  if (_showingFeedback &&
                      isSelected &&
                      !(_lastAnswerCorrect ?? false))
                    const Icon(Icons.cancel, color: EnolaTheme.wrong),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── ORDERING ───────────────────────────────────────────────────────────────

  Widget _buildOrdering(Riddle riddle) {
    final correctOrder = riddle.asOrdering?.items ?? riddle.choices;

    return Column(
      children: [
        const Text(
          'Drag to reorder the items correctly',
          style: TextStyle(
              fontStyle: FontStyle.italic, color: EnolaTheme.textSecond),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (_solvedCorrectly || _showingFeedback) return;
            if (newIndex > oldIndex) newIndex -= 1;
            setState(() {
              final item = _orderedItems.removeAt(oldIndex);
              _orderedItems.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < _orderedItems.length; i++)
              Container(
                key: ValueKey(_orderedItems[i]),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EnolaTheme.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.drag_indicator,
                      color: EnolaTheme.border),
                  title: Text(_orderedItems[i],
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_solvedCorrectly && !_showingFeedback)
          ElevatedButton(
            onPressed: () => _onOrderingSubmit(correctOrder),
            child: const Text('Submit Order'),
          ),
        if (_showingFeedback && !_solvedCorrectly)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Not quite — try reordering again!',
              style: TextStyle(
                color: EnolaTheme.wrong,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Feedback bar ──────────────────────────────────────────────────────────────

class _AnswerFeedback extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;
  final int errorCount;
  final VoidCallback? onSkip;

  const _AnswerFeedback({
    required this.isCorrect,
    required this.onContinue,
    this.errorCount = 0,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final canSkip = !isCorrect && errorCount >= 3 && onSkip != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isCorrect
            ? EnolaTheme.correct.withAlpha(20)
            : EnolaTheme.wrong.withAlpha(20),
        border: Border(
          top: BorderSide(
            color: isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct! Well done.' : 'Not quite — try again!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? EnolaTheme.correct : EnolaTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isCorrect ? 'Continue' : 'Try Again',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (canSkip) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'Skip this riddle (0 stars)',
                style: TextStyle(
                  fontSize: 13,
                  color: EnolaTheme.textSecond.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: EnolaTheme.textSecond.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


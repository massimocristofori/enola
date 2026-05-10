import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';

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
  bool _answered = false;
  int? _selectedAnswer;
  bool? _isCorrect;
  List<String> _orderedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.riddle.type == RiddleType.ordering) {
      final items = widget.riddle.asOrdering?.items ?? widget.riddle.choices;
      _orderedItems = List.from(items)..shuffle(math.Random());
    }
  }

  void _onMultipleChoiceAnswer(int index, int correctIndex) {
    if (_answered) return;
    final correct = index == correctIndex;
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      _isCorrect = correct;
    });
  }

  void _onOrderingSubmit(List<String> correctOrder) {
    if (_answered) return;
    final correct = _orderedItems.join('|') == correctOrder.join('|');
    setState(() {
      _answered = true;
      _isCorrect = correct;
    });
  }

  void _confirm() {
    Navigator.pop(context, _isCorrect ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final riddle = widget.riddle;

    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
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
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    Text(
                      'Riddle #${widget.riddleIndex + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: EnolaTheme.textPrimary,
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
                      ParchmentCard(
                        glowing: _answered && (_isCorrect ?? false),
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

              // ── Feedback + continue button ──
              if (_answered)
                _AnswerFeedback(
                  isCorrect: _isCorrect ?? false,
                  onContinue: _confirm,
                ).animate().slideY(begin: 1, end: 0).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Multiple choice ────────────────────────────────────────────────────────

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

        if (_answered) {
          if (isCorrectChoice) {
            borderColor = EnolaTheme.correct;
            bgColor = EnolaTheme.correct.withAlpha(25);
          } else if (isSelected && !isCorrectChoice) {
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
                  width:
                      isSelected || (_answered && isCorrectChoice) ? 2 : 1,
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
                        color: isSelected ? Colors.white : EnolaTheme.textSecond,
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
                  if (_answered && isCorrectChoice)
                    const Icon(Icons.check_circle, color: EnolaTheme.correct),
                  if (_answered && isSelected && !isCorrectChoice)
                    const Icon(Icons.cancel, color: EnolaTheme.wrong),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Ordering ───────────────────────────────────────────────────────────────

  Widget _buildOrdering(Riddle riddle) {
    final correctOrder =
        riddle.asOrdering?.items ?? riddle.choices;

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
            if (_answered) return;
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
        if (!_answered)
          ElevatedButton(
            onPressed: () => _onOrderingSubmit(correctOrder),
            child: const Text('Submit Order'),
          ),
      ],
    );
  }
}

// ── Feedback bar ──────────────────────────────────────────────────────────────

class _AnswerFeedback extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;

  const _AnswerFeedback({required this.isCorrect, required this.onContinue});

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'Correct! Well done.' : 'Not quite — keep going!',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

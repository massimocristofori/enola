import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/models/riddle.dart';
import 'package:enola/models/riddle_map.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/result_screen.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final int mapId;
  const PlayScreen({super.key, required this.mapId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  int _currentIndex = 0;
  int _correct = 0;
  bool _answered = false;
  int? _selectedAnswer;
  bool? _isCorrect;

  // Ordering state
  List<String> _orderedItems = [];

  void _onMultipleChoiceAnswer(int index, int correctIndex) {
    if (_answered) return;
    final correct = index == correctIndex;
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      _isCorrect = correct;
      if (correct) _correct++;
    });
  }

  void _onOrderingSubmit(List<String> correctOrder) {
    if (_answered) return;
    final correct = _orderedItems.join('|') == correctOrder.join('|');
    setState(() {
      _answered = true;
      _isCorrect = correct;
      if (correct) _correct++;
    });
  }

  void _nextRiddle(List<Riddle> riddles) {
    if (_currentIndex < riddles.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedAnswer = null;
        _isCorrect = null;
        _orderedItems = [];
      });
    } else {
      // Done — go to result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            mapId: widget.mapId,
            correct: _correct,
            total: riddles.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapProvider(widget.mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(widget.mapId));

    return Scaffold(
      body: FantasyBackground(
        child: mapAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
          error: (e, _) => Center(child: Text('$e')),
          data: (map) => riddlesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
            error: (e, _) => Center(child: Text('$e')),
            data: (riddles) {
              if (riddles.isEmpty) {
                return const Center(
                  child: Text('No riddles in this map.',
                      style: TextStyle(color: EnolaTheme.textSecond)),
                );
              }
              // Init ordering items
              if (_orderedItems.isEmpty &&
                  riddles[_currentIndex].type == RiddleType.ordering) {
                final items = (jsonDecode(
                        riddles[_currentIndex].orderItemsJson ?? '[]') as List)
                    .cast<String>();
                _orderedItems = List.from(items)..shuffle(math.Random());
              }
              return _PlayBody(
                map: map!,
                riddles: riddles,
                currentIndex: _currentIndex,
                correct: _correct,
                answered: _answered,
                selectedAnswer: _selectedAnswer,
                isCorrect: _isCorrect,
                orderedItems: _orderedItems,
                onMultipleChoiceAnswer: _onMultipleChoiceAnswer,
                onOrderingItemsChanged: (items) =>
                    setState(() => _orderedItems = items),
                onOrderingSubmit: _onOrderingSubmit,
                onNext: () => _nextRiddle(riddles),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Play Body ─────────────────────────────────────────────────────────────────

class _PlayBody extends StatelessWidget {
  final RiddleMap map;
  final List<Riddle> riddles;
  final int currentIndex;
  final int correct;
  final bool answered;
  final int? selectedAnswer;
  final bool? isCorrect;
  final List<String> orderedItems;
  final void Function(int index, int correctIndex) onMultipleChoiceAnswer;
  final void Function(List<String>) onOrderingItemsChanged;
  final void Function(List<String> correctOrder) onOrderingSubmit;
  final VoidCallback onNext;

  const _PlayBody({
    required this.map,
    required this.riddles,
    required this.currentIndex,
    required this.correct,
    required this.answered,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.orderedItems,
    required this.onMultipleChoiceAnswer,
    required this.onOrderingItemsChanged,
    required this.onOrderingSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final riddle = riddles[currentIndex];
    final total = riddles.length;
    final progress = (currentIndex + (answered ? 1 : 0)) / total;

    return SafeArea(
      child: Column(
        children: [
          _PlayHeader(
            mapTitle: map.title,
            currentIndex: currentIndex,
            total: total,
            correct: correct,
            progress: progress,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  _RiddleCard(riddle: riddle, index: currentIndex),
                  const SizedBox(height: 24),
                  if (riddle.type == RiddleType.multipleChoice)
                    _MultipleChoiceWidget(
                      riddle: riddle,
                      answered: answered,
                      selectedAnswer: selectedAnswer,
                      onAnswer: onMultipleChoiceAnswer,
                    )
                  else
                    _OrderingWidget(
                      riddle: riddle,
                      answered: answered,
                      isCorrect: isCorrect,
                      orderedItems: orderedItems,
                      onItemsChanged: onOrderingItemsChanged,
                      onSubmit: onOrderingSubmit,
                    ),
                  if (answered) ...[
                    const SizedBox(height: 20),
                    _FeedbackBanner(isCorrect: isCorrect!),
                    const SizedBox(height: 20),
                    _NextButton(
                      isLast: currentIndex == total - 1,
                      onNext: onNext,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header with progress ──────────────────────────────────────────────────────

class _PlayHeader extends StatelessWidget {
  final String mapTitle;
  final int currentIndex;
  final int total;
  final int correct;
  final double progress;

  const _PlayHeader({
    required this.mapTitle,
    required this.currentIndex,
    required this.total,
    required this.correct,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2416))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    color: EnolaTheme.textSecond, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mapTitle,
                  style: const TextStyle(
                    color: EnolaTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EnolaTheme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentIndex + 1} / $total',
                  style: const TextStyle(
                    color: EnolaTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF2A2416),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(EnolaTheme.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Riddle card ───────────────────────────────────────────────────────────────

class _RiddleCard extends StatelessWidget {
  final Riddle riddle;
  final int index;

  const _RiddleCard({required this.riddle, required this.index});

  @override
  Widget build(BuildContext context) {
    final typeLabel = riddle.type == RiddleType.multipleChoice
        ? 'Multiple Choice'
        : 'Put in Order';
    final typeIcon = riddle.type == RiddleType.multipleChoice
        ? Icons.help_outline_rounded
        : Icons.sort_rounded;

    return ParchmentCard(
      glowing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 14, color: EnolaTheme.accent),
              const SizedBox(width: 6),
              Text(
                typeLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: EnolaTheme.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            riddle.question,
            style: const TextStyle(
              color: EnolaTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(index)).fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ── Multiple choice widget ────────────────────────────────────────────────────

class _MultipleChoiceWidget extends StatelessWidget {
  final Riddle riddle;
  final bool answered;
  final int? selectedAnswer;
  final void Function(int index, int correctIndex) onAnswer;

  const _MultipleChoiceWidget({
    required this.riddle,
    required this.answered,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final choices = (jsonDecode(riddle.mcChoicesJson ?? '[]') as List).cast<String>();
    final correctIndex = riddle.mcCorrectIndex ?? 0;

    return Column(
      children: [
        for (var i = 0; i < choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceTile(
              label: choices[i],
              index: i,
              answered: answered,
              isSelected: selectedAnswer == i,
              isCorrect: i == correctIndex,
              onTap: () => onAnswer(i, correctIndex),
            ),
          ).animate(delay: (i * 80).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final int index;
  final bool answered;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.index,
    required this.answered,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF4A3F22);
    Color bgColor = const Color(0xFF1E1A10);
    Color textColor = EnolaTheme.textPrimary;

    if (answered) {
      if (isCorrect) {
        borderColor = EnolaTheme.correct;
        bgColor = EnolaTheme.correct.withValues(alpha: 0.15);
        textColor = EnolaTheme.correct;
      } else if (isSelected) {
        borderColor = EnolaTheme.wrong;
        bgColor = EnolaTheme.wrong.withValues(alpha: 0.12);
        textColor = EnolaTheme.wrong;
      }
    } else if (isSelected) {
      borderColor = EnolaTheme.accent;
      bgColor = EnolaTheme.accentSoft;
    }

    final letters = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 250.ms,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: answered && isCorrect
                    ? EnolaTheme.correct
                    : answered && isSelected
                        ? EnolaTheme.wrong
                        : const Color(0xFF2A2416),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: answered && (isCorrect || isSelected)
                    ? Icon(
                        isCorrect ? Icons.check : Icons.close,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        letters[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ordering widget ───────────────────────────────────────────────────────────

class _OrderingWidget extends StatelessWidget {
  final Riddle riddle;
  final bool answered;
  final bool? isCorrect;
  final List<String> orderedItems;
  final void Function(List<String>) onItemsChanged;
  final void Function(List<String> correctOrder) onSubmit;

  const _OrderingWidget({
    required this.riddle,
    required this.answered,
    required this.isCorrect,
    required this.orderedItems,
    required this.onItemsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final correctOrder =
        (jsonDecode(riddle.orderItemsJson ?? '[]') as List).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DRAG TO REORDER',
          style: TextStyle(
            fontSize: 10,
            color: EnolaTheme.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderedItems.length,
          onReorder: answered
              ? (_, __) {}
              : (oldIndex, newIndex) {
                  final list = List<String>.from(orderedItems);
                  if (newIndex > oldIndex) newIndex--;
                  final item = list.removeAt(oldIndex);
                  list.insert(newIndex, item);
                  onItemsChanged(list);
                },
          itemBuilder: (context, i) {
            final isRight = answered && orderedItems[i] == correctOrder[i];
            final isWrong = answered && orderedItems[i] != correctOrder[i];

            return Padding(
              key: ValueKey(orderedItems[i]),
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: 250.ms,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isRight
                      ? EnolaTheme.correct.withValues(alpha: 0.12)
                      : isWrong
                          ? EnolaTheme.wrong.withValues(alpha: 0.1)
                          : const Color(0xFF1E1A10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRight
                        ? EnolaTheme.correct
                        : isWrong
                            ? EnolaTheme.wrong
                            : const Color(0xFF4A3F22),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2A2416),
                        border: Border.all(color: const Color(0xFF4A3F22)),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: EnolaTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        orderedItems[i],
                        style: TextStyle(
                          color: isRight
                              ? EnolaTheme.correct
                              : isWrong
                                  ? EnolaTheme.wrong
                                  : EnolaTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!answered)
                      const Icon(Icons.drag_handle_rounded,
                          color: EnolaTheme.textSecond, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
        if (!answered) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onSubmit(correctOrder),
              child: const Text('Confirm Order'),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Feedback banner ───────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  const _FeedbackBanner({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isCorrect
            ? EnolaTheme.correct.withValues(alpha: 0.15)
            : EnolaTheme.wrong.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            isCorrect ? '🏆' : '💀',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect ? 'Correct!' : 'Wrong!',
                style: TextStyle(
                  color: isCorrect ? EnolaTheme.correct : EnolaTheme.wrong,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                isCorrect
                    ? 'The path forward is revealed.'
                    : 'The darkness claims this point.',
                style: const TextStyle(
                    color: EnolaTheme.textSecond, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0)
        .scale(begin: const Offset(0.9, 0.9));
  }
}

// ── Next button ───────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onNext;

  const _NextButton({required this.isLast, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onNext,
        icon: Icon(isLast
            ? Icons.emoji_events_rounded
            : Icons.arrow_forward_rounded),
        label: Text(isLast ? 'See Results' : 'Next Riddle'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

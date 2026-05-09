import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/database/schema_utils.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/result_screen.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String mapId;
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
          loading: () => const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
          error: (e, _) => Center(child: Text('$e')),
          data: (map) => riddlesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
            error: (e, _) => Center(child: Text('$e')),
            data: (riddles) {
              if (riddles.isEmpty) {
                return const Center(
                  child: Text('No riddles in this map.',
                      style: TextStyle(color: EnolaTheme.textSecond)),
                );
              }

              // Only ordering riddles need the shuffled list initialised.
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
                onOrderingItemsChanged: (items) => setState(() => _orderedItems = items),
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

// ── Private Body Widget ──────────────────────────────────────────────────────

class _PlayBody extends StatelessWidget {
  final RiddleMap map;
  final List<Riddle> riddles;
  final int currentIndex;
  final int correct;
  final bool answered;
  final int? selectedAnswer;
  final bool? isCorrect;
  final List<String> orderedItems;
  final Function(int, int) onMultipleChoiceAnswer;
  final Function(List<String>) onOrderingItemsChanged;
  final Function(List<String>) onOrderingSubmit;
  final VoidCallback onNext;

  const _PlayBody({
    required this.map,
    required this.riddles,
    required this.currentIndex,
    required this.correct,
    required this.answered,
    this.selectedAnswer,
    this.isCorrect,
    required this.orderedItems,
    required this.onMultipleChoiceAnswer,
    required this.onOrderingItemsChanged,
    required this.onOrderingSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final riddle = riddles[currentIndex];
    final progress = (currentIndex + 1) / riddles.length;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, progress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ParchmentCard(
                    glowing: answered && (isCorrect ?? false),
                    child: Column(
                      children: [
                        Text(
                          'Riddle #${currentIndex + 1}',
                          style: EnolaTheme.sectionHeader,
                        ),
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
                  // trueFalse shares the same widget as multipleChoice —
                  // both use MultipleChoicePayload under the hood.
                  if (riddle.type == RiddleType.multipleChoice ||
                      riddle.type == RiddleType.trueFalse)
                    _buildMultipleChoice(riddle)
                  else
                    _buildOrdering(riddle),
                ],
              ),
            ),
          ),
          if (answered)
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor:
                      isCorrect == true ? EnolaTheme.correct : EnolaTheme.accent,
                ),
                child: Text(
                    currentIndex == riddles.length - 1 ? 'See Results' : 'Next Riddle'),
              ).animate().slideY(begin: 0.5, end: 0).fadeIn(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: EnolaTheme.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation(EnolaTheme.accent),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${currentIndex + 1}/${riddles.length}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: EnolaTheme.textSecond),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoice(Riddle riddle) {
    final choices = [riddle.choiceA, riddle.choiceB, riddle.choiceC, riddle.choiceD]
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();

    return Column(
      children: List.generate(choices.length, (i) {
        final isSelected = selectedAnswer == i;
        final isCorrectChoice = i == riddle.correctChoiceIndex;

        Color borderColor = EnolaTheme.border;
        Color bgColor = Colors.white;

        if (answered) {
          if (isCorrectChoice) {
            borderColor = EnolaTheme.correct;
            bgColor = EnolaTheme.correct.withValues(alpha: 0.1);
          } else if (isSelected && !isCorrectChoice) {
            borderColor = EnolaTheme.wrong;
            bgColor = EnolaTheme.wrong.withValues(alpha: 0.1);
          }
        } else if (isSelected) {
          borderColor = EnolaTheme.accent;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onMultipleChoiceAnswer(i, riddle.correctChoiceIndex ?? 0),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: 300.ms,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: borderColor,
                    width: isSelected || (answered && isCorrectChoice) ? 2 : 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isSelected ? EnolaTheme.accent : EnolaTheme.surfaceHigh,
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
                    child: Text(
                      choices[i],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (answered && isCorrectChoice)
                    const Icon(Icons.check_circle, color: EnolaTheme.correct),
                  if (answered && isSelected && !isCorrectChoice)
                    const Icon(Icons.cancel, color: EnolaTheme.wrong),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrdering(Riddle riddle) {
    final correctOrder =
        (jsonDecode(riddle.orderItemsJson ?? '[]') as List).cast<String>();

    return Column(
      children: [
        const Text(
          'Drag to reorder the items correctly',
          style: TextStyle(fontStyle: FontStyle.italic, color: EnolaTheme.textSecond),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (answered) return;
            if (newIndex > oldIndex) newIndex -= 1;
            final items = List<String>.from(orderedItems);
            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
            onOrderingItemsChanged(items);
          },
          children: [
            for (int i = 0; i < orderedItems.length; i++)
              Container(
                key: ValueKey(orderedItems[i]),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EnolaTheme.border),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.drag_indicator, color: EnolaTheme.border),
                  title: Text(orderedItems[i],
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (!answered)
          ElevatedButton(
            onPressed: () => onOrderingSubmit(correctOrder),
            child: const Text('Submit Order'),
          ),
      ],
    );
  }
}

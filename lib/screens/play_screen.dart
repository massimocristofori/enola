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
  // ✅ Changed to String to support web-safe UUIDs
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
            mapId: widget.mapId, // ✅ Passing String ID
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
              
              // ✅ Correctly using the enum getter from our Riddle model
              if (_orderedItems.isEmpty &&
                  riddles[_currentIndex].type == RiddleType.ordering) {
                final items = (jsonDecode(riddles[_currentIndex].orderItemsJson ?? '[]') as List)
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

// ... Rest of your UI components (_PlayBody, _PlayHeader, etc.) 
// stay exactly as they were, but they will now recognize RiddleType 
// because we fixed the Riddle model!

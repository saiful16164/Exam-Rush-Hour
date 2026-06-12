import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

part 'mcq_state_provider.g.dart';

@riverpod
class McqAnswers extends _$McqAnswers {
  @override
  Map<String, String> build() {
    return {};
  }

  void selectAnswer(String questionId, String option) {
    final newState = Map<String, String>.from(state);
    if (newState[questionId] == option) {
      newState.remove(questionId);
    } else {
      newState[questionId] = option;
    }
    state = newState;
  }
}

@riverpod
class McqTimer extends _$McqTimer {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return 0;
  }

  void startTimer(int totalMinutes) {
    state = totalMinutes * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';
import 'dart:async';

part 'written_state_provider.g.dart';

@riverpod
class WrittenAnswers extends _$WrittenAnswers {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void addImages(List<Map<String, dynamic>> files) {
    state = [...state, ...files];
  }

  void removeImage(int index) {
    final newState = List<Map<String, dynamic>>.from(state);
    newState.removeAt(index);
    state = newState;
  }
}

@riverpod
class WrittenTimer extends _$WrittenTimer {
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

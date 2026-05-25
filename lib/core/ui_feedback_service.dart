import 'package:flutter_riverpod/flutter_riverpod.dart';

class UIFeedbackMessage {
  final String message;
  final bool isError;
  UIFeedbackMessage(this.message, {this.isError = false});
}

class UIFeedbackNotifier extends StateNotifier<UIFeedbackMessage?> {
  UIFeedbackNotifier() : super(null);

  void showMessage(String message, {bool isError = false}) {
    state = UIFeedbackMessage(message, isError: isError);
  }

  void clear() {
    state = null;
  }
}

final uiFeedbackProvider = StateNotifierProvider<UIFeedbackNotifier, UIFeedbackMessage?>((ref) {
  return UIFeedbackNotifier();
});

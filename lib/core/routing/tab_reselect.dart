import 'dart:async';

/// Tapping the tab you are already on. A tab that can scroll listens for its
/// own index and goes back to the top.
class TabReselect {
  TabReselect._();

  /// The tab indexes in the main shell.
  static const int home = 0;

  static final StreamController<int> _controller =
      StreamController<int>.broadcast();

  static Stream<int> get stream => _controller.stream;

  static void notify(int index) => _controller.add(index);
}

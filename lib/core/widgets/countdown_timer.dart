import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';

/// "Ends in 05 : 32 : 10" pill for time-boxed promotions.
///
/// UI only: it counts down to [deadline] on the device clock. When the backend
/// exists, pass the server-provided end time. The ticker only runs while the
/// widget is mounted and is cancelled on dispose.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.deadline,
    this.onDark = false,
  });

  /// Counts down to the next local midnight.
  factory CountdownTimer.untilEndOfDay({Key? key, bool onDark = false}) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return CountdownTimer(key: key, deadline: midnight, onDark: onDark);
  }

  final DateTime deadline;
  final bool onDark;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _ticker;
  late Duration _remaining = _compute();

  Duration _compute() {
    final d = widget.deadline.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _compute());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    final colors = context.colors;
    final text = context.textTheme;

    Widget cell(int v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: widget.onDark ? Colors.white : colors.onSurface,
            borderRadius: AppRadius.rSm,
          ),
          child: Text(
            _two(v),
            style: text.labelMedium?.copyWith(
              color: widget.onDark ? const Color(0xFF12141A) : colors.surface,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ':',
        style: text.labelMedium?.copyWith(
          color: widget.onDark ? Colors.white : colors.onSurface,
        ),
      ),
    );

    return Semantics(
      label: context.l10n.endsInSemantics(h, m),
      excludeSemantics: true,
      child: Directionality(
        // Clock digits always read left-to-right.
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [cell(h), sep, cell(m), sep, cell(s)],
        ),
      ),
    );
  }
}

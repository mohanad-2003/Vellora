import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Reusable boxed OTP input. Renders [length] digit fields with auto-advance,
/// backspace-to-previous, and paste support. Reports the joined code via
/// [onChanged] and fires [onCompleted] when all boxes are filled.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    this.length = 4,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length && !code.contains(' ')) {
      widget.onCompleted?.call(code);
    }
  }

  void _onChanged(int index, String value) {
    // Paste of a full code into any box.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final target = digits.length >= widget.length
          ? widget.length - 1
          : digits.length;
      _focusNodes[target].requestFocus();
      _notify();
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notify();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Digits always run left to right, even in an RTL layout.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: SizedBox(
              width: 60,
              height: 64,
              child: Focus(
                onKeyEvent: (_, event) => _onKey(index, event),
                child: ListenableBuilder(
                  listenable: _controllers[index],
                  builder: (context, _) {
                    final filled = _controllers[index].text.isNotEmpty;
                    final borderColor = widget.hasError
                        ? colors.error
                        : filled
                        ? colors.primary
                        : colors.outline;
                    return TextField(
                      controller: _controllers[index],
                      autofocus: index == 0,
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: context.textTheme.headlineMedium,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: filled
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rMd,
                          borderSide: BorderSide(
                            color: borderColor,
                            width: filled || widget.hasError ? 1.6 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rMd,
                          borderSide: BorderSide(
                            color: context.colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onChanged(index, value),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int verificationCodeLength = 6;

/// Six boxes for the code received by SMS or email. One hidden field takes the digits, so the keyboard
/// and the autofill of the phone work as in a normal field.
class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.code, required this.onChanged, required this.isError});

  final String code;
  final ValueChanged<String> onChanged;
  final bool isError;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late final TextEditingController _controller = TextEditingController(text: widget.code);
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          // The real field: invisible, it only receives the digits.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(verificationCodeLength),
              ],
              onChanged: widget.onChanged,
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < verificationCodeLength; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.85,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          width: i == widget.code.length ? 2 : 1,
                          color: widget.isError
                              ? colors.error
                              : i == widget.code.length
                                  ? colors.primary
                                  : colors.outline,
                        ),
                      ),
                      child: Text(
                        i < widget.code.length ? widget.code[i] : '',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "Reenviar código en 0:42", and the button once the time is over.
class ResendCode extends StatelessWidget {
  const ResendCode({super.key, required this.secondsToResend, required this.enabled, required this.onResend});

  final int secondsToResend;
  final bool enabled;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (secondsToResend > 0) {
      final minutes = secondsToResend ~/ 60;
      final seconds = (secondsToResend % 60).toString().padLeft(2, '0');
      return Text(
        'Reenviar código en $minutes:$seconds',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Center(child: TextButton(onPressed: enabled ? onResend : null, child: const Text('Reenviar código')));
  }
}

/// Counts down the seconds until another code can be requested.
class ResendCountdown {
  ResendCountdown(this.onTick);

  final void Function(int seconds) onTick;
  Timer? _timer;

  void start(DateTime until) {
    cancel();
    onTick(_secondsTo(until));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final seconds = _secondsTo(until);
      onTick(seconds);
      if (seconds == 0) timer.cancel();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  static int _secondsTo(DateTime until) {
    final seconds = until.difference(DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}

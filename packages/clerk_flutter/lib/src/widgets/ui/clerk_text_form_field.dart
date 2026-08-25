import 'dart:async';

import 'package:clerk_flutter/src/widgets/control/clerk_auth.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:clerk_flutter/src/widgets/ui/input_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable and Clerk styled [TextFormField].
///
class ClerkTextFormField extends StatelessWidget {
  /// Constructs a new [ClerkTextFormField].
  const ClerkTextFormField({
    super.key,
    this.label,
    this.isOptional,
    this.obscureText,
    this.autofocus = false,
    this.isMissing = false,
    this.inputFormatter,
    this.focusNode,
    this.onChanged,
    this.onSubmit,
    this.initial,
    this.onObscure,
    this.validator,
    this.trailing,
    this.hint,
    this.keyboardType,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  /// The keyboard to present for this field.
  final TextInputType? keyboardType;

  /// Whether to enable platform autocorrection. Must be `false` for anything
  /// that is not prose — an email address or username is corrupted by it.
  final bool autocorrect;

  /// Whether the platform should capitalise input for this field.
  final TextCapitalization textCapitalization;

  /// Autofill hints, so the platform can offer saved credentials.
  final List<String>? autofillHints;

  /// Report changes back to calling widget
  final ValueChanged<String>? onChanged;

  /// Callback for when field submitted
  final ValueChanged<String>? onSubmit;

  /// Optional label.
  final String? label;

  /// Is this field optional?
  final bool? isOptional;

  /// can we see the text or not?
  final bool? obscureText;

  /// Should the input box immediately take focus?
  final bool autofocus;

  /// Do we need to mark this field as required?
  final bool isMissing;

  /// A [TextInputFormatter] to normalise input text
  final TextInputFormatter? inputFormatter;

  /// An optional focus node
  final FocusNode? focusNode;

  /// function to change obscurity
  final VoidCallback? onObscure;

  /// Is the string valid yet?
  /// NB: NOT a [FormFieldValidator], just returns a boolean
  final bool Function(String?)? validator;

  /// initial value
  final String? initial;

  /// A widget for the end of the label
  final Widget? trailing;

  /// Hint text
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InputLabel(
          label: label,
          isRequired: isMissing,
          isOptional: isOptional,
          trailing: trailing,
        ),
        verticalMargin4,
        _TextField(
          obscureText: obscureText,
          onChanged: onChanged,
          onSubmit: onSubmit,
          initial: initial,
          onObscure: onObscure,
          validator: validator,
          autofocus: autofocus,
          focusNode: focusNode,
          inputFormatter: inputFormatter,
          hint: hint,
          keyboardType: keyboardType,
          autocorrect: autocorrect,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
        ),
      ],
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.obscureText,
    required this.onChanged,
    required this.onSubmit,
    required this.initial,
    required this.onObscure,
    required this.validator,
    required this.autofocus,
    this.inputFormatter,
    this.focusNode,
    this.hint,
    this.keyboardType,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final bool? obscureText;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onObscure;
  final bool Function(String?)? validator;
  final TextInputFormatter? inputFormatter;
  final String? initial;
  final String? hint;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final List<String>? autofillHints;

  List<TextInputFormatter>? get inputFormatters => switch (inputFormatter) {
        TextInputFormatter formatter => [formatter],
        _ => null,
      };

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late bool _obscure = widget.obscureText ?? false;
  bool _valid = true;

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscure = widget.obscureText ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return TextFormField(
      initialValue: widget.initial,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      style: themeExtension.styles.inputText.copyWith(
        color:
            _valid ? themeExtension.colors.text : themeExtension.colors.error,
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmit,
      keyboardType: widget.keyboardType,
      autocorrect: widget.autocorrect,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      obscureText: _obscure,
      obscuringCharacter: '\u25CF' /* Unicode: Black Circle */,
      validator: (text) {
        if (widget.validator?.call(text) case bool valid when valid != _valid) {
          scheduleMicrotask(() => setState(() => _valid = valid));
        }
        return null;
      },
      inputFormatters: widget.inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isCollapsed: true,
        hintText: widget.hint,
        hintStyle: themeExtension.styles.inputText,
        border: outlineInputBorder(context),
        enabledBorder: outlineInputBorder(context),
        focusedBorder: outlineInputBorder(context),
        contentPadding: allPadding8,
        errorStyle: const TextStyle(fontSize: 0),
        suffixIconConstraints: const BoxConstraints(maxHeight: 16),
        suffixIcon: _obscureTextIcon(),
      ),
    );
  }

  Widget? _obscureTextIcon() {
    if (widget.obscureText is bool) {
      return Padding(
        padding: rightPadding8,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.onObscure case VoidCallback onObscure) {
              onObscure();
            } else {
              setState(() => _obscure = !_obscure);
            }
          },
          child: Icon(
            _obscure ? Icons.visibility : Icons.visibility_off,
            size: 16,
          ),
        ),
      );
    }
    return null;
  }
}

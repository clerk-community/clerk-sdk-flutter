import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/input_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/test_support.dart';

void main() {
  group('ClerkTextFormField', () {
    late ClerkAuthState authState;

    setUp(() async {
      authState = await createSignedOutAuthState();
    });

    tearDown(() {
      authState.terminate();
    });

    test('stores onChanged callback', () {
      void onChanged(String value) {}
      final widget = ClerkTextFormField(onChanged: onChanged);
      expect(widget.onChanged, onChanged);
    });

    test('stores onSubmit callback', () {
      void onSubmit(String value) {}
      final widget = ClerkTextFormField(onSubmit: onSubmit);
      expect(widget.onSubmit, onSubmit);
    });

    test('stores label parameter', () {
      const widget = ClerkTextFormField(label: 'Test Label');
      expect(widget.label, 'Test Label');
    });

    test('stores isOptional parameter', () {
      const widget = ClerkTextFormField(isOptional: true);
      expect(widget.isOptional, isTrue);
    });

    test('stores obscureText parameter', () {
      const widget = ClerkTextFormField(obscureText: true);
      expect(widget.obscureText, isTrue);
    });

    test('stores autofocus parameter', () {
      const widget = ClerkTextFormField(autofocus: true);
      expect(widget.autofocus, isTrue);
    });

    test('defaults autofocus to false', () {
      const widget = ClerkTextFormField();
      expect(widget.autofocus, isFalse);
    });

    test('stores isMissing parameter', () {
      const widget = ClerkTextFormField(isMissing: true);
      expect(widget.isMissing, isTrue);
    });

    test('defaults isMissing to false', () {
      const widget = ClerkTextFormField();
      expect(widget.isMissing, isFalse);
    });

    test('stores inputFormatter parameter', () {
      final formatter = TextInputFormatter.withFunction((_, value) => value);
      final widget = ClerkTextFormField(inputFormatter: formatter);
      expect(widget.inputFormatter, formatter);
    });

    test('stores focusNode parameter', () {
      final focusNode = FocusNode();
      final widget = ClerkTextFormField(focusNode: focusNode);
      expect(widget.focusNode, focusNode);
    });

    test('stores onObscure callback', () {
      void onObscure() {}
      final widget = ClerkTextFormField(onObscure: onObscure);
      expect(widget.onObscure, onObscure);
    });

    test('stores validator callback', () {
      bool validator(String? value) => true;
      final widget = ClerkTextFormField(validator: validator);
      expect(widget.validator, isNotNull);
      expect(identical(widget.validator, validator), isTrue);
    });

    test('stores initial parameter', () {
      const widget = ClerkTextFormField(initial: 'Initial Value');
      expect(widget.initial, 'Initial Value');
    });

    test('stores trailing widget', () {
      const trailing = Icon(Icons.check);
      const widget = ClerkTextFormField(trailing: trailing);
      expect(widget.trailing, trailing);
    });

    test('stores hint parameter', () {
      const widget = ClerkTextFormField(hint: 'Hint Text');
      expect(widget.hint, 'Hint Text');
    });

    test('stores autofillHints parameter', () {
      const widget = ClerkTextFormField(
        autofillHints: [AutofillHints.email],
      );
      expect(widget.autofillHints, [AutofillHints.email]);
    });

    test('stores keyboardType parameter', () {
      const widget = ClerkTextFormField(
        keyboardType: TextInputType.emailAddress,
      );
      expect(widget.keyboardType, TextInputType.emailAddress);
    });

    test('stores textInputAction parameter', () {
      const widget = ClerkTextFormField(
        textInputAction: TextInputAction.next,
      );
      expect(widget.textInputAction, TextInputAction.next);
    });

    testWidgets('renders Column', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkTextFormField(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders InputLabel', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkTextFormField(label: 'Test'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InputLabel), findsOneWidget);
    });

    testWidgets('renders TextFormField', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkTextFormField(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets(
        'passes autofillHints, keyboardType, and textInputAction to TextFormField',
        (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkTextFormField(
                autofillHints: [AutofillHints.password],
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofillHints, [AutofillHints.password]);
      expect(textField.keyboardType, TextInputType.visiblePassword);
      expect(textField.textInputAction, TextInputAction.done);
    });
  });
}

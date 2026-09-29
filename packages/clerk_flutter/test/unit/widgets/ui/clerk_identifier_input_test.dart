import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/identifier.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_identifier_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/test_support.dart';

void main() {
  group('ClerkIdentifierInput', () {
    late ClerkAuthState authState;

    setUp(() async {
      authState = await createSignedOutAuthState();
    });

    tearDown(() {
      authState.terminate();
    });

    test('stores onChanged callback', () {
      void onChanged(Identifier id) {}
      final widget = ClerkIdentifierInput(
        onChanged: onChanged,
        strategies: const [],
      );
      expect(widget.onChanged, onChanged);
    });

    test('stores onSubmit callback', () {
      void onSubmit(Identifier? id) {}
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: const [],
        onSubmit: onSubmit,
      );
      expect(widget.onSubmit, onSubmit);
    });

    test('stores strategies parameter', () {
      const strategies = [clerk.Strategy.emailCode];
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: strategies,
      );
      expect(widget.strategies, strategies);
    });

    test('stores identifierType parameter', () {
      final identifierType = ValueNotifier(clerk.IdentifierType.emailAddress);
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: const [],
        identifierType: identifierType,
      );
      expect(widget.identifierType, identifierType);
    });

    test('stores initialValue parameter', () {
      const initialValue = Identifier('test@example.com');
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: const [],
        initialValue: initialValue,
      );
      expect(widget.initialValue, initialValue);
    });

    test('stores autofillHints parameter', () {
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: const [],
        autofillHints: const [AutofillHints.email],
      );
      expect(widget.autofillHints, [AutofillHints.email]);
    });

    test('stores keyboardType parameter', () {
      final widget = ClerkIdentifierInput(
        onChanged: (id) {},
        strategies: const [],
        keyboardType: TextInputType.emailAddress,
      );
      expect(widget.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('creates state', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClerkIdentifierInput(
                onChanged: (id) {},
                strategies: const [clerk.Strategy.emailCode],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkIdentifierInput), findsOneWidget);
    });

    testWidgets('renders with email strategies', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClerkIdentifierInput(
                onChanged: (id) {},
                strategies: const [clerk.Strategy.emailCode],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkIdentifierInput), findsOneWidget);
    });

    testWidgets('renders with phone strategies', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClerkIdentifierInput(
                onChanged: (id) {},
                strategies: const [clerk.Strategy.phoneCode],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkIdentifierInput), findsOneWidget);
    });

    testWidgets('renders with mixed strategies', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClerkIdentifierInput(
                onChanged: (id) {},
                strategies: const [
                  clerk.Strategy.emailCode,
                  clerk.Strategy.phoneCode,
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkIdentifierInput), findsOneWidget);
    });

    testWidgets('renders Column', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClerkIdentifierInput(
                onChanged: (id) {},
                strategies: const [clerk.Strategy.emailCode],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });
  });
}

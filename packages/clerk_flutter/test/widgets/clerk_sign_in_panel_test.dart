import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_in_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/strategy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/test_support.dart';

void main() {
  group('ClerkSignInPanel', () {
    testWidgets('renders password field when password is the only first factor',
        (tester) async {
      final signIn = createTestSignIn(
        status: Status.needsFirstFactor,
        identifier: 'test@example.com',
        supportedFirstFactors: [
          createTestFactor(strategy: Strategy.password),
        ],
      );
      final client = createTestClient(signIn: signIn);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          identificationStrategies: [Strategy.emailAddress],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignInPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
      expect(find.byType(ClerkTextFormField), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      authState.terminate();
    });

    testWidgets(
        'renders strategy button when email code is the only first factor',
        (tester) async {
      final signIn = createTestSignIn(
        status: Status.needsFirstFactor,
        identifier: 'test@example.com',
        supportedFirstFactors: [
          createTestFactor(strategy: Strategy.emailCode),
        ],
      );
      final client = createTestClient(signIn: signIn);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          identificationStrategies: [Strategy.emailAddress],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignInPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
      expect(find.byType(StrategyButton), findsOneWidget);
      expect(find.byType(ClerkTextFormField), findsNothing);

      authState.terminate();
    });

    testWidgets(
        'renders password field and strategy button when both are '
        'supported first factors', (tester) async {
      final signIn = createTestSignIn(
        status: Status.needsFirstFactor,
        supportedFirstFactors: [
          createTestFactor(strategy: Strategy.password),
          createTestFactor(strategy: Strategy.emailCode),
        ],
      );
      final client = createTestClient(signIn: signIn);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          identificationStrategies: [Strategy.emailAddress],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignInPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
      expect(find.byType(ClerkTextFormField), findsOneWidget);
      expect(find.byType(StrategyButton), findsOneWidget);

      authState.terminate();
    });

    testWidgets(
        'renders strategy button when phone code is the only first factor',
        (tester) async {
      final signIn = createTestSignIn(
        status: Status.needsFirstFactor,
        supportedFirstFactors: [
          createTestFactor(strategy: Strategy.phoneCode),
        ],
      );
      final client = createTestClient(signIn: signIn);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          identificationStrategies: [Strategy.phoneNumber],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignInPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
      expect(find.byType(StrategyButton), findsOneWidget);

      authState.terminate();
    });

    testWidgets('renders strategy buttons when a second factor is required',
        (tester) async {
      final signIn = createTestSignIn(
        status: Status.needsSecondFactor,
        supportedSecondFactors: [
          createTestFactor(strategy: Strategy.totp),
          createTestFactor(strategy: Strategy.backupCode),
        ],
      );
      final client = createTestClient(signIn: signIn);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          identificationStrategies: [Strategy.emailAddress],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignInPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);

      // One button each for authenticator app and backup code
      expect(find.byType(StrategyButton), findsNWidgets(2));

      authState.terminate();
    });
  });
}

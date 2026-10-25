import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_in_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_control_buttons.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_identifier_input.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/test_support.dart';

void main() {
  group('ClerkSignInPanel', () {
    late ClerkAuthState authState;

    setUp(() async {
      // Create an environment with identification strategies
      const environment = clerk.Environment(
        config: clerk.Config(
          identificationStrategies: [
            clerk.Strategy.emailAddress,
            clerk.Strategy.username,
          ],
          firstFactors: [
            clerk.Strategy.password,
            clerk.Strategy.emailCode,
          ],
        ),
      );

      // Create a client without a sign-in
      final client = createSignedOutClient();

      authState = await createTestAuthState(
        config: TestClerkAuthConfig(
          initialClient: client,
          httpService: const TestHttpService(
            environment: environment,
          ),
        ),
      );
    });

    tearDown(() {
      authState.terminate();
    });

    testWidgets('creates state', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
    });

    testWidgets('renders Column', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders AutofillGroup', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(ClerkSignInPanel),
          matching: find.byType(AutofillGroup),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders when environment has identification strategies',
        (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Should render the panel
      expect(find.byType(ClerkSignInPanel), findsOneWidget);
    });

    testWidgets('renders Closeable widget', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Closeable), findsWidgets);
    });

    testWidgets('renders when signed out', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignInPanel), findsOneWidget);
    });

    testWidgets('renders with default state', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Should render without errors
      expect(find.byType(ClerkSignInPanel), findsOneWidget);
    });

    testWidgets('renders control buttons', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkControlButtons), findsOneWidget);
    });

    testWidgets('renders identifier input', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignInPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkIdentifierInput), findsOneWidget);
    });

    group('with SignIn state', () {
      testWidgets('renders with needs identifier status', (tester) async {
        const environment = clerk.Environment(
          config: clerk.Config(
            identificationStrategies: [
              clerk.Strategy.emailAddress,
              clerk.Strategy.username,
            ],
            firstFactors: [
              clerk.Strategy.password,
              clerk.Strategy.emailCode,
            ],
          ),
        );

        final signIn = createTestSignIn(
          status: clerk.Status.needsIdentifier,
          supportedIdentifiers: ['email_address'],
        );
        final client = createTestClient(signIn: signIn);
        final authStateWithSignIn = await createTestAuthState(
          config: TestClerkAuthConfig(
            initialClient: client,
            httpService: const TestHttpService(
              environment: environment,
            ),
          ),
        );

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignIn,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignInPanel), findsOneWidget);
        expect(find.byType(ClerkControlButtons), findsOneWidget);

        authStateWithSignIn.terminate();
      });

      testWidgets('renders with identifier set', (tester) async {
        final signIn = createTestSignIn(
          status: clerk.Status.needsFirstFactor,
          identifier: 'test@example.com',
          supportedFirstFactors: [
            createTestFactor(strategy: clerk.Strategy.password),
          ],
        );
        final client = createTestClient(signIn: signIn);
        final authStateWithSignIn = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignIn,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignInPanel), findsOneWidget);

        authStateWithSignIn.terminate();
      });

      testWidgets('renders with first factor verification', (tester) async {
        final signIn = createTestSignIn(
          status: clerk.Status.needsFirstFactor,
          identifier: 'test@example.com',
          firstFactorVerification: createTestVerification(
            status: clerk.Status.unverified,
            strategy: clerk.Strategy.emailCode,
          ),
        );
        final client = createTestClient(signIn: signIn);
        final authStateWithSignIn = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignIn,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignInPanel), findsOneWidget);

        authStateWithSignIn.terminate();
      });

      testWidgets('renders factor list and heading for needs_client_trust',
          (tester) async {
        const environment = clerk.Environment(
          config: clerk.Config(
            identificationStrategies: [clerk.Strategy.emailAddress],
            firstFactors: [clerk.Strategy.password],
          ),
        );
        final signIn = createTestSignIn(
          status: clerk.Status.needsClientTrust,
          identifier: 'test@example.com',
          supportedSecondFactors: [
            createTestFactor(
              strategy: clerk.Strategy.emailCode,
              safeIdentifier: 'test@example.com',
              emailAddressId: 'email_123',
            ),
          ],
          firstFactorVerification: createTestVerification(
            status: clerk.Status.verified,
            strategy: clerk.Strategy.password,
          ),
        );
        final client = createTestClient(signIn: signIn);
        final authStateWithSignIn = await createTestAuthState(
          config: TestClerkAuthConfig(
            initialClient: client,
            initialEnvironment: environment,
          ),
        );

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignIn,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ClerkSignInPanel), findsOneWidget);
        expect(find.text('Verify this device'), findsOneWidget);

        authStateWithSignIn.terminate();
      });

      testWidgets('renders with multiple first factors', (tester) async {
        final signIn = createTestSignIn(
          status: clerk.Status.needsFirstFactor,
          identifier: 'test@example.com',
          supportedFirstFactors: [
            createTestFactor(strategy: clerk.Strategy.password),
            createTestFactor(strategy: clerk.Strategy.emailCode),
          ],
        );
        final client = createTestClient(signIn: signIn);
        final authStateWithSignIn = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignIn,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignInPanel), findsOneWidget);

        authStateWithSignIn.terminate();
      });
    });
  });
}

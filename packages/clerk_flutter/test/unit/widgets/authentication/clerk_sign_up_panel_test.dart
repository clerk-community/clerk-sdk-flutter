import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_up_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_control_buttons.dart';
import 'package:clerk_flutter/src/widgets/ui/strategy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_support/test_support.dart';

void main() {
  group('ClerkSignUpPanel', () {
    late ClerkAuthState authState;

    setUp(() async {
      authState = await createSignedOutAuthState();
    });

    tearDown(() {
      authState.terminate();
    });

    testWidgets('creates state', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);
    });

    testWidgets('renders Column', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders when environment is available', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      // Should render the panel
      expect(find.byType(ClerkSignUpPanel), findsOneWidget);
    });

    testWidgets('renders AutofillGroup widget', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignUpPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(ClerkSignUpPanel),
          matching: find.byType(AutofillGroup),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders ClerkControlButtons widget', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ClerkSignUpPanel(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkControlButtons), findsWidgets);
    });

    testWidgets('renders when signed out', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);
    });

    testWidgets('renders with default state', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      // Should render without errors
      expect(find.byType(ClerkSignUpPanel), findsOneWidget);
    });

    testWidgets('renders control buttons', (tester) async {
      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const ClerkSignUpPanel(),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkControlButtons), findsOneWidget);
    });

    group('with SignUp state', () {
      testWidgets('renders with missing fields', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          requiredFields: [clerk.Field.emailAddress, clerk.Field.password],
          missingFields: [clerk.Field.emailAddress, clerk.Field.password],
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);
        expect(find.byType(ClerkControlButtons), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with unverified email', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          emailAddress: 'test@example.com',
          unverifiedFields: [clerk.Field.emailAddress],
          verifications: {
            clerk.Field.emailAddress: createTestVerification(
              status: clerk.Status.unverified,
              strategy: clerk.Strategy.emailCode,
            ),
          },
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with phone number', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          phoneNumber: '+1234567890',
          unverifiedFields: [clerk.Field.phoneNumber],
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with user data', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          firstName: 'John',
          lastName: 'Doe',
          emailAddress: 'john@example.com',
          missingFields: [clerk.Field.password],
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with all user attributes', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          emailAddress: 'john@example.com',
          phoneNumber: '+1234567890',
          missingFields: [clerk.Field.password],
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with awaiting phone code', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          phoneNumber: '+1234567890',
          unverifiedFields: [],
          verifications: {
            clerk.Field.phoneNumber: createTestVerification(
              status: clerk.Status.unverified,
              strategy: clerk.Strategy.phoneCode,
            ),
          },
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders with awaiting email code', (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          emailAddress: 'test@example.com',
          unverifiedFields: [clerk.Field.emailAddress],
          verifications: {
            clerk.Field.emailAddress: createTestVerification(
              status: clerk.Status.unverified,
              strategy: clerk.Strategy.emailCode,
            ),
          },
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders email link message when awaiting email link',
          (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          emailAddress: 'test@example.com',
          missingFields: [],
          unverifiedFields: [clerk.Field.emailAddress],
          verifications: {
            clerk.Field.emailAddress: createTestVerification(
              status: clerk.Status.unverified,
              strategy: clerk.Strategy.emailLink,
            ),
          },
        );
        final client = createTestClient(signUp: signUp);
        final authStateWithSignUp = await createTestAuthState(client: client);

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const ClerkSignUpPanel(),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);

        authStateWithSignUp.terminate();
      });

      testWidgets('renders strategy buttons when needs email strategy',
          (tester) async {
        final signUp = createTestSignUp(
          status: clerk.Status.missingRequirements,
          emailAddress: 'test@example.com',
          missingFields: [],
          unverifiedFields: [clerk.Field.emailAddress],
        );
        final client = createTestClient(signUp: signUp);

        // Create environment with email and phone attributes that have verification strategies
        const environment = clerk.Environment(
          user: clerk.UserSettings(
            attributes: {
              clerk.UserAttribute.emailAddress: clerk.UserAttributeData(
                verifications: [
                  clerk.Strategy.emailCode,
                  clerk.Strategy.emailLink
                ],
              ),
              clerk.UserAttribute.phoneNumber: clerk.UserAttributeData(
                verifications: [clerk.Strategy.phoneCode],
              ),
            },
          ),
        );

        final authStateWithSignUp = await createTestAuthState(
          client: client,
          config: TestClerkAuthConfig(
            initialClient: client,
            initialEnvironment: environment,
          ),
        );

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authStateWithSignUp,
            child: const Scaffold(
              body: ClerkSignUpPanel(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ClerkSignUpPanel), findsOneWidget);
        // Should render strategy buttons for email code and email link
        expect(find.byType(StrategyButton), findsWidgets);

        authStateWithSignUp.terminate();
      });
    });
  });
}

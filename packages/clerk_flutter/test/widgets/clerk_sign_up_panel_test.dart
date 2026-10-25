import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_up_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_phone_number_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/strategy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/test_support.dart';

void main() {
  group('ClerkSignUpPanel', () {
    testWidgets('renders email and password fields when they are missing',
        (tester) async {
      final signUp = createTestSignUp(
        status: Status.missingRequirements,
        requiredFields: [Field.emailAddress, Field.password],
        missingFields: [Field.emailAddress, Field.password],
      );
      final client = createTestClient(signUp: signUp);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          requiredAttributes: [
            UserAttribute.emailAddress,
            UserAttribute.password,
          ],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignUpPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);

      // Email, password and password confirmation fields
      expect(find.byType(ClerkTextFormField), findsNWidgets(3));
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      authState.terminate();
    });

    testWidgets('renders phone number field when phone number is missing',
        (tester) async {
      final signUp = createTestSignUp(
        status: Status.missingRequirements,
        requiredFields: [Field.phoneNumber],
        missingFields: [Field.phoneNumber],
      );
      final client = createTestClient(signUp: signUp);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          requiredAttributes: [UserAttribute.phoneNumber],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignUpPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);
      expect(find.byType(ClerkPhoneNumberFormField), findsOneWidget);

      authState.terminate();
    });

    testWidgets('renders optional name fields alongside required email field',
        (tester) async {
      final signUp = createTestSignUp(
        status: Status.missingRequirements,
        requiredFields: [Field.emailAddress],
        optionalFields: [Field.firstName, Field.lastName],
      );
      final client = createTestClient(signUp: signUp);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          requiredAttributes: [UserAttribute.emailAddress],
          optionalAttributes: [
            UserAttribute.firstName,
            UserAttribute.lastName,
          ],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignUpPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);

      // First name, last name and email fields
      expect(find.byType(ClerkTextFormField), findsNWidgets(3));

      authState.terminate();
    });

    testWidgets('renders strategy button when email verification is required',
        (tester) async {
      final verification = createTestVerification(
        status: Status.unverified,
        strategy: Strategy.emailCode,
      );
      final signUp = createTestSignUp(
        status: Status.missingRequirements,
        emailAddress: 'test@example.com',
        unverifiedFields: [Field.emailAddress],
        verifications: {Field.emailAddress: verification},
      );
      final client = createTestClient(signUp: signUp);
      final authState = await createTestAuthState(
        client: client,
        environment: createTestEnvironment(
          requiredAttributes: [UserAttribute.emailAddress],
        ),
      );

      await tester.pumpWidget(
        TestClerkAuthWrapper(
          authState: authState,
          child: const Scaffold(body: ClerkSignUpPanel()),
        ),
      );
      await tester.pump();

      expect(find.byType(ClerkSignUpPanel), findsOneWidget);

      // Email code is the only supported strategy for verification
      expect(find.byType(StrategyButton), findsOneWidget);

      authState.terminate();
    });
  });
}

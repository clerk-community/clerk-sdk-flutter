import 'package:clerk_auth/clerk_auth.dart';

import '../../test_helpers.dart';

void main() {
  group('attemptSignIn identifier comparison', () {
    late MockHttpService mockHttp;
    late Auth auth;

    // The back end normalises an email identifier to lower case; the sign-in UI
    // sends back whatever the user typed. These two therefore routinely differ.
    const typedIdentifier = 'Person@example.com';
    const storedIdentifier = 'person@example.com';

    Map<String, dynamic> signInWithPreparedFirstFactor({
      String status = 'needs_first_factor',
    }) {
      return {
        'object': 'sign_in',
        'id': 'signin_123',
        'status': status,
        'identifier': storedIdentifier,
        'supported_identifiers': ['email_address'],
        'supported_first_factors': [
          {'strategy': 'email_code', 'email_address_id': 'idn_123'},
        ],
        'supported_second_factors': [],
        'first_factor_verification': {
          'object': 'verification',
          'status': 'unverified',
          'strategy': 'email_code',
          'attempts': 0,
          'expire_at': DateTime.now()
              .add(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        },
        'second_factor_verification': null,
        'created_session_id': null,
        'abandon_at':
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      };
    }

    bool isSignInCreation(MockHttpCall call) =>
        call.uri.path.endsWith('/client/sign_ins');

    setUp(() async {
      mockHttp = MockHttpService();
      auth = Auth(
        config: TestAuthConfig(
          publishableKey: TestAuthConfig.kPublishableKey,
          httpService: mockHttp,
        ),
      );
      mockHttp.addClientResponse();
      mockHttp.addEnvironmentResponse();
      await auth.initialize();

      // A sign-in is under way and its first factor has been prepared, i.e. a
      // code has been emailed to the user.
      mockHttp.addClientResponse(signIn: signInWithPreparedFirstFactor());
      await auth.attemptSignIn(
        strategy: Strategy.emailCode,
        identifier: typedIdentifier,
      );
    });

    tearDown(() {
      auth.terminate();
    });

    test('the back end has normalised the identifier we sent', () {
      expect(auth.client.signIn?.identifier, equals(storedIdentifier));
    });

    test(
      'submitting a code does not discard a sign-in whose identifier differs '
      'only by case',
      () async {
        final callsBefore = mockHttp.calls.length;

        mockHttp.addClientResponse(
          signIn: signInWithPreparedFirstFactor(status: 'complete'),
        );
        await auth.attemptSignIn(
          strategy: Strategy.emailCode,
          identifier: typedIdentifier,
          code: '424242',
        );

        // Creating a second SignIn here re-prepares the first factor, which
        // invalidates the code already sent to the user, and then checks the
        // code they typed against a verification it does not belong to. The
        // sign-in fails with form_code_incorrect, and because every retry
        // repeats the cycle it can never succeed.
        final creations =
            mockHttp.calls.skip(callsBefore).where(isSignInCreation);
        expect(creations, isEmpty);
      },
    );
  });
}

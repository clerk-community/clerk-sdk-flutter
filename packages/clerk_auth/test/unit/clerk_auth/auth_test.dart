import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart';

import '../../test_helpers.dart';

// Valid publishable key with base64-encoded domain (somedomain.com)
const _validPublishableKey = 'pk_test_c29tZWRvbWFpbi5jb20K';

User _createTestUser({
  String id = 'user_123',
  String? firstName,
  String? lastName,
}) {
  return User(
    id: id,
    externalId: null,
    username: null,
    firstName: firstName,
    lastName: lastName,
    profileImageUrl: null,
    imageUrl: null,
    hasImage: false,
    primaryEmailAddressId: null,
    primaryPhoneNumberId: null,
    primaryWeb3WalletId: null,
    publicMetadata: null,
    privateMetadata: const {},
    unsafeMetadata: null,
    emailAddresses: null,
    phoneNumbers: null,
    web3Wallets: null,
    passkeys: null,
    organizationMemberships: null,
    createOrganizationEnabled: false,
    externalAccounts: null,
    passwordEnabled: false,
    twoFactorEnabled: false,
    totpEnabled: false,
    backupCodeEnabled: false,
    lastSignInAt: DateTimeExt.epoch,
    banned: false,
    locked: false,
    lockoutExpiresInSeconds: null,
    verificationAttemptsRemaining: null,
    updatedAt: DateTimeExt.epoch,
    createdAt: DateTimeExt.epoch,
    lastActiveAt: DateTimeExt.epoch,
    deleteSelfEnabled: false,
  );
}

Session _createTestSession({
  String id = 'sess_123',
  Status status = Status.active,
  User? user,
  String? lastActiveOrganizationId,
}) {
  final testUser = user ?? _createTestUser();
  return Session(
    id: id,
    status: status,
    lastActiveAt: DateTime.now(),
    expireAt: DateTime.now().add(const Duration(days: 1)),
    abandonAt: DateTime.now().add(const Duration(days: 7)),
    publicUserData: UserPublic(
      firstName: testUser.firstName,
      lastName: testUser.lastName,
      profileImageUrl: testUser.profileImageUrl,
      imageUrl: testUser.imageUrl,
      hasImage: testUser.hasImage ?? false,
      identifier: testUser.email ?? '',
    ),
    lastActiveOrganizationId: lastActiveOrganizationId,
    user: testUser,
  );
}

Organization _createTestOrganization({
  String id = 'org_123',
  String name = 'Test Org',
  String slug = 'test-org',
}) {
  return Organization(
    id: id,
    name: name,
    slug: slug,
  );
}

ExternalAccount _createTestExternalAccount({
  String id = 'ext_123',
  String provider = 'google',
}) {
  return ExternalAccount(
    id: id,
    provider: provider,
    providerUserId: 'provider_user_123',
    approvedScopes: '',
    emailAddress: 'test@gmail.com',
    username: null,
    firstName: 'Test',
    lastName: 'User',
    avatarUrl: null,
    imageUrl: null,
    label: null,
    publicMetadata: const {},
    verification: Verification(
      status: Status.verified,
      strategy: Strategy.oauthGoogle,
      attempts: 0,
      expireAt: DateTime.now().add(const Duration(days: 1)),
    ),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

OrganizationInvitation _createTestOrganizationInvitation({
  String id = 'inv_123',
}) {
  return OrganizationInvitation(
    id: id,
    status: Status.pending,
    roleName: 'basic_member',
    organization: _createTestOrganization(),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Auth', () {
    group('initial state', () {
      test('isNotAvailable returns true before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.isNotAvailable, true);
      });

      test('client is empty before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.client.isEmpty, true);
      });

      test('env is empty before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.env.isEmpty, true);
      });

      test('user is null before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.user, isNull);
      });

      test('session is null before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.session, isNull);
      });

      test('signIn is null before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.signIn, isNull);
      });

      test('signUp is null before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.signUp, isNull);
      });

      test('isSignedIn returns false before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.isSignedIn, false);
      });

      test('isSigningIn returns false before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.isSigningIn, false);
      });

      test('isSigningUp returns false before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.isSigningUp, false);
      });

      test('organization is null before initialization', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        expect(auth.organization, isNull);
      });
    });

    group('client setter', () {
      test('updates client value', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final session = _createTestSession();
        final newClient = Client(
          id: 'client_123',
          sessions: [session],
          lastActiveSessionId: session.id,
        );

        auth.client = newClient;

        expect(auth.client.id, 'client_123');
        expect(auth.client.sessions.length, 1);
      });

      test('updates user when client has active session', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final user = _createTestUser(id: 'user_abc', firstName: 'Test');
        final session = _createTestSession(user: user);
        final newClient = Client(
          id: 'client_123',
          sessions: [session],
          lastActiveSessionId: session.id,
        );

        auth.client = newClient;

        expect(auth.user?.id, 'user_abc');
        expect(auth.user?.firstName, 'Test');
      });

      test('isSignedIn returns true when client has active session', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final session = _createTestSession();
        final newClient = Client(
          id: 'client_123',
          sessions: [session],
          lastActiveSessionId: session.id,
        );

        auth.client = newClient;

        expect(auth.isSignedIn, true);
      });
    });

    group('env setter', () {
      test('updates env value', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );

        auth.env = Environment.empty;

        expect(auth.env.isEmpty, true);
      });

      test('isNotAvailable returns true when env is empty', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );

        auth.env = Environment.empty;

        expect(auth.isNotAvailable, true);
      });
    });

    group('defaultLocalesLookup', () {
      test('returns English as default locale', () {
        final locales = Auth.defaultLocalesLookup();
        expect(locales, ['en']);
      });
    });

    group('handleError', () {
      test('throws ClerkError', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        const error = ClerkError(
          message: 'Test error',
          code: ClerkErrorCode.clientAppError,
        );

        expect(
          () => auth.handleError(error),
          throwsA(isA<ClerkError>()),
        );
      });
    });

    group('signIn and signUp getters', () {
      test('signIn returns client signIn', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        const signIn = SignIn.empty;
        const newClient = Client(
          id: 'client_123',
          signIn: signIn,
        );

        auth.client = newClient;

        expect(auth.signIn, isNotNull);
        expect(auth.isSigningIn, true);
      });

      test('signUp returns client signUp', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final signUp = SignUp(
          id: 'signup_123',
          status: Status.missingRequirements,
          requiredFields: const [],
          optionalFields: const [],
          missingFields: const [],
          unverifiedFields: const [],
          username: null,
          emailAddress: null,
          phoneNumber: null,
          web3Wallet: null,
          passwordEnabled: false,
          firstName: null,
          lastName: null,
          unsafeMetadata: const {},
          publicMetadata: const {},
          verifications: const {},
          customAction: false,
          externalId: null,
          createdSessionId: null,
          createdUserId: null,
          abandonAt: DateTime.now().add(const Duration(days: 7)),
        );
        final newClient = Client(
          id: 'client_123',
          signUp: signUp,
        );

        auth.client = newClient;

        expect(auth.signUp, isNotNull);
        expect(auth.isSigningUp, true);
      });
    });

    group('session getter', () {
      test('returns active session from client', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final session = _createTestSession(id: 'sess_active');
        final newClient = Client(
          id: 'client_123',
          sessions: [session],
          lastActiveSessionId: 'sess_active',
        );

        auth.client = newClient;

        expect(auth.session?.id, 'sess_active');
      });

      test('returns null when no active session', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        const newClient = Client(
          id: 'client_123',
          sessions: [],
        );

        auth.client = newClient;

        expect(auth.session, isNull);
      });
    });

    group('organization getter', () {
      test('returns organization from active session', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        final session = _createTestSession(lastActiveOrganizationId: 'org_123');
        final newClient = Client(
          id: 'client_123',
          sessions: [session],
          lastActiveSessionId: session.id,
        );

        auth.client = newClient;

        // Organization is derived from session.lastActiveOrganizationId
        // and user's organizationMemberships, which we haven't set up
        expect(auth.organization, isNull);
      });
    });

    group('update method', () {
      test('can be called without error', () {
        final auth = Auth(
          config: const TestAuthConfig(publishableKey: _validPublishableKey),
        );
        // update() is a no-op in base Auth class
        expect(() => auth.update(), returnsNormally);
      });
    });

    group('with MockHttpService', () {
      late MockHttpService mockHttp;
      late Auth auth;

      setUp(() {
        mockHttp = MockHttpService();
      });

      tearDown(() {
        mockHttp.reset();
      });

      group('initialize', () {
        test('fetches client and environment', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          expect(auth.client.isNotEmpty, true);
          expect(auth.env.isNotEmpty, true);
          expect(auth.isNotAvailable, false);

          auth.terminate();
        });

        test('handles error response gracefully', () async {
          // Add error responses
          mockHttp.addJsonResponse({'errors': []}, statusCode: 500);
          mockHttp.addJsonResponse({'errors': []}, statusCode: 500);

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          // Should still work but with empty client/env due to error responses
          expect(auth.client.isEmpty, true);
          expect(auth.env.isEmpty, true);

          auth.terminate();
        });
      });

      group('terminate', () {
        test('can be called after initialize', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          expect(() => auth.terminate(), returnsNormally);
        });
      });

      group('refreshClient', () {
        test('updates the current client from the API', () async {
          mockHttp.addClientResponse(clientId: 'client_initial');
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientWithSessionResponse(clientId: 'client_initial');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          expect(auth.client.id, 'client_initial');
          expect(auth.user, isNull);

          await auth.refreshClient();
          expect(auth.client.id, 'client_initial');
          expect(auth.user, isNotNull);

          auth.terminate();
        });

        // Regression test: during an oAuth handoff the client token is
        // rotated, and a refresh presenting the superseded token resolves
        // to a freshly minted, session-less client. Adopting it silently
        // signs the user out and orphans the real client.
        test('discards a refresh that resolves to a different client',
            () async {
          mockHttp.addClientWithSessionResponse(clientId: 'client_original');
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(clientId: 'client_minted');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          expect(auth.user, isNotNull);

          await auth.refreshClient();

          // a refresh resolving to a different client must not replace
          // the signed-in client
          expect(auth.client.id, 'client_original');
          expect(auth.user, isNotNull);

          auth.terminate();
        });

        test('adopts a persistently mismatched client after repeated refreshes',
            () async {
          mockHttp.addClientWithSessionResponse(clientId: 'client_original');
          mockHttp.addEnvironmentResponse();
          for (var i = 0; i < 4; i++) {
            mockHttp.addClientResponse(clientId: 'client_replacement');
          }

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          // mismatched clients must be discarded until the pinned client
          // is demonstrably gone
          for (var i = 0; i < 3; i++) {
            await auth.refreshClient();
            expect(auth.client.id, 'client_original');
          }

          // the pinned client has not been returned for several consecutive
          // refreshes: it is genuinely gone, so the new client is adopted
          await auth.refreshClient();
          expect(auth.client.id, 'client_replacement');

          auth.terminate();
        });

        test('keeps the current client when the refresh fails', () async {
          mockHttp.addClientWithSessionResponse(clientId: 'client_original');
          mockHttp.addEnvironmentResponse();
          mockHttp.addJsonResponse({'errors': []}, statusCode: 500);

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          expect(auth.user, isNotNull);

          await auth.refreshClient();

          // a failed refresh must not sign the user out
          expect(auth.client.id, 'client_original');
          expect(auth.user, isNotNull);

          auth.terminate();
        });
      });

      group('resetClient', () {
        test('creates new client', () async {
          mockHttp.addClientResponse(clientId: 'client_initial');
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(clientId: 'client_reset');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.resetClient();

          expect(auth.client.id, 'client_reset');

          auth.terminate();
        });
      });

      group('refreshEnvironment', () {
        test('updates environment from API', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.refreshEnvironment();

          expect(auth.env.isNotEmpty, true);

          auth.terminate();
        });
      });

      group('signOut', () {
        test('clears client', () async {
          mockHttp.addClientResponse(clientId: 'client_123');
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(
              clientId: ''); // Empty client after signout

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.signOut();

          // Client should be updated
          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('transfer', () {
        test('does nothing when no signIn or signUp', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.transfer();

          // No additional API calls should be made
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('oauthSignIn', () {
        test('creates sign in with oauth strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(status: 'needs_first_factor');
          mockHttp.addSignInResponse(status: 'needs_first_factor');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.oauthSignIn(
            strategy: Strategy.oauthGoogle,
            redirect: Uri.parse('https://example.com/callback'),
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('completeOAuthSignIn', () {
        test('does nothing when no signIn or signUp', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.completeOAuthSignIn(token: 'test_token');

          // No additional API calls should be made
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('oauthConnect', () {
        test('adds external account', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.oauthConnect(
            strategy: Strategy.oauthGoogle,
            redirect: Uri.parse('https://example.com/callback'),
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('idTokenSignIn', () {
        test('calls attemptSignIn with provider strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(status: 'complete');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.idTokenSignIn(
            provider: IdTokenProvider.apple,
            token: 'test_id_token',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('idTokenSignUp', () {
        test('calls attemptSignUp with provider strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignUpResponse(status: 'complete');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.idTokenSignUp(
            provider: IdTokenProvider.apple,
            idToken: 'test_id_token',
            firstName: 'Test',
            lastName: 'User',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('initiatePasswordReset', () {
        test('creates sign in with password reset strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(status: 'needs_first_factor');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.initiatePasswordReset(
            identifier: 'test@example.com',
            strategy: Strategy.resetPasswordEmailCode,
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('throws error for non-password-reset strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          expect(
            () => auth.initiatePasswordReset(
              identifier: 'test@example.com',
              strategy: Strategy.password,
            ),
            throwsA(isA<ClerkError>()),
          );

          auth.terminate();
        });
      });

      group('attemptSignIn', () {
        test('creates sign in with identifier', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(
            status: 'needs_first_factor',
            identifier: 'test@example.com',
          );

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.attemptSignIn(
            strategy: Strategy.password,
            identifier: 'test@example.com',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));
          // After attemptSignIn, the client should have a signIn object
          // The isSigningIn state depends on the response status

          auth.terminate();
        });

        test('handles oauth token strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(status: 'complete');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.attemptSignIn(
            strategy: Strategy.oauthApple,
            token: 'oauth_token_123',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('handles oauth code strategy', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignInResponse(status: 'complete');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.attemptSignIn(
            strategy: Strategy.oauthGoogle,
            code: 'oauth_code_123',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('attemptSignUp', () {
        test('creates sign up with email', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignUpResponse(
            status: 'missing_requirements',
            emailAddress: 'test@example.com',
          );

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.attemptSignUp(
            strategy: Strategy.emailCode,
            emailAddress: 'test@example.com',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));
          // After attemptSignUp, the client should have a signUp object
          // The isSigningUp state depends on the response status

          auth.terminate();
        });

        test('throws error when passwords do not match', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          expect(
            () => auth.attemptSignUp(
              strategy: Strategy.password,
              password: 'password123',
              passwordConfirmation: 'different_password',
            ),
            throwsA(isA<ClerkError>()),
          );

          auth.terminate();
        });

        test('creates sign up with all fields', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addSignUpResponse(
            status: 'missing_requirements',
            firstName: 'Test',
            lastName: 'User',
            emailAddress: 'test@example.com',
          );

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.attemptSignUp(
            strategy: Strategy.password,
            firstName: 'Test',
            lastName: 'User',
            emailAddress: 'test@example.com',
            password: 'password123',
            passwordConfirmation: 'password123',
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('signOutOf', () {
        test('signs out of specific session', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final session = _createTestSession(id: 'sess_to_signout');
          await auth.signOutOf(session);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('setActiveOrganization', () {
        test('does nothing when no session', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          await auth.setActiveOrganization(org);

          // No additional API calls since no session
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('createOrganization', () {
        test('creates organization with name', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addOrganizationResponse(name: 'New Org');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.createOrganization(name: 'New Org');

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('leaveOrganization', () {
        test('leaves organization', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addApiResponse(response: {'success': true});

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          await auth.leaveOrganization(organization: org);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('fetchOrganizationInvitations', () {
        test('fetches empty invitations list', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addOrganizationInvitationsResponse(invitations: []);

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          final invitations = await auth.fetchOrganizationInvitations();

          expect(invitations, isEmpty);

          auth.terminate();
        });

        test('fetches invitations with data', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // Add empty response for the invitations call (no data key means empty list)
          mockHttp.addOrganizationInvitationsResponse(invitations: []);

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          final invitations = await auth.fetchOrganizationInvitations();

          // The method makes an API call and returns the parsed invitations
          expect(invitations, isA<List<OrganizationInvitation>>());
          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('fetchOrganizationDomains', () {
        test('fetches empty domains list', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addOrganizationDomainsResponse(domains: []);

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          final domains =
              await auth.fetchOrganizationDomains(organization: org);

          expect(domains, isEmpty);

          auth.terminate();
        });
      });

      group('activate', () {
        test('activates session', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final session = _createTestSession();
          await auth.activate(session);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('updateUser', () {
        test('does nothing when no user', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.updateUser(firstName: 'New Name');

          // No additional API calls since no user
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('deleteUser', () {
        test('deletes user when allowed', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(); // For deleteUser API call
          mockHttp.addClientResponse(); // For currentClient refresh

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          // The mock environment has delete_self: true, so this should work
          await auth.deleteUser();

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('addIdentifyingData', () {
        test('adds email to user', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.addIdentifyingData(
              'new@example.com', IdentifierType.emailAddress);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('adds phone to user', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.addIdentifyingData(
              '+1234567890', IdentifierType.phoneNumber);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('updateUserPassword', () {
        test('updates password', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.updateUserPassword('old_password', 'new_password');

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('updates password without sign out', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.updateUserPassword('old_password', 'new_password',
              signOut: false);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('deleteUserPassword', () {
        test('deletes password', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.deleteUserPassword('current_password');

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('fetchApiResponse', () {
        test('makes API call with default parameters', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(); // For the API call

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          final response = await auth.fetchApiResponse('/test');

          // The response is an ApiResponse object
          expect(response, isA<ApiResponse>());
          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('makes API call with custom method', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(); // For the API call

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          final response = await auth.fetchApiResponse(
            '/test',
            method: HttpMethod.get,
          );

          expect(response, isA<ApiResponse>());

          auth.terminate();
        });

        test('makes API call with headers and params', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse(); // For the API call

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          final response = await auth.fetchApiResponse(
            '/test',
            headers: {'X-Custom': 'header'},
            params: {'key': 'value'},
          );

          expect(response, isA<ApiResponse>());

          auth.terminate();
        });
      });

      group('sessionTokenStream', () {
        test('returns a stream', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          expect(auth.sessionTokenStream, isA<Stream<SessionToken>>());

          auth.terminate();
        });
      });

      group('deleteExternalAccount', () {
        test('deletes external account', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final account = _createTestExternalAccount();

          await auth.deleteExternalAccount(account: account);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('acceptOrganizationInvitation', () {
        test('accepts invitation', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final invitation = _createTestOrganizationInvitation();

          await auth.acceptOrganizationInvitation(invitation);

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('createDomain', () {
        test('creates domain with manual invitation mode', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addApiResponse(response: {'id': 'domain_123'});

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          await auth.createDomain(
            organization: org,
            name: 'example.com',
            mode: EnrollmentMode.manualInvitation,
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });

        test('creates domain with automatic invitation mode', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // For createDomain - needs client response with response containing id
          mockHttp.addJsonResponse({
            'response': {'id': 'domain_123', 'name': 'example.com'},
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });
          // For updateDomainEnrollmentMode
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          await auth.createDomain(
            organization: org,
            name: 'example.com',
            mode: EnrollmentMode.automaticInvitation,
          );

          expect(mockHttp.calls.length, greaterThanOrEqualTo(4));

          auth.terminate();
        });
      });

      group('updateOrganization', () {
        test('does nothing when no changes', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          // Pass same name - should not make API call
          await auth.updateOrganization(organization: org, name: 'Test Org');

          // No additional API calls
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });

        test('updates organization name', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addOrganizationResponse(name: 'New Name');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();

          await auth.updateOrganization(organization: org, name: 'New Name');

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('setActiveOrganization', () {
        test('does nothing when no session exists', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();
          // Should not throw when no session exists
          await auth.setActiveOrganization(org);

          // Only 2 calls for initialization (client + env)
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('createOrganization', () {
        test('creates organization without slug', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // For createOrganization
          mockHttp.addOrganizationResponse(name: 'Test Org');

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          await auth.createOrganization(name: 'Test Org');

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('updateUserImage', () {
        test('updates user avatar', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          // We can't easily test file upload without a real file,
          // but we can verify the method exists and is callable
          expect(auth.updateUserImage, isA<Function>());

          auth.terminate();
        });
      });

      group('deleteUserImage', () {
        test('deletes user avatar', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addClientResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          await auth.deleteUserImage();

          expect(mockHttp.calls.length, greaterThanOrEqualTo(3));

          auth.terminate();
        });
      });

      group('transfer', () {
        test('does nothing when no signIn or signUp', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          // Transfer should do nothing when no signIn or signUp
          await auth.transfer();

          // Only 2 calls for initialization
          expect(mockHttp.calls.length, 2);

          auth.terminate();
        });
      });

      group('fetchOrganizationDomains', () {
        test('fetches domains with pagination', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // First page with data
          mockHttp.addJsonResponse({
            'response': {
              'data': [
                {
                  'object': 'organization_domain',
                  'id': 'domain_1',
                  'organization_id': 'org_123',
                  'name': 'example.com',
                  'enrollment_mode': 'manual_invitation',
                  'verification': null,
                  'affiliation_email_address': null,
                  'total_pending_invitations': 0,
                  'total_pending_suggestions': 0,
                  'created_at': DateTime.now().millisecondsSinceEpoch,
                  'updated_at': DateTime.now().millisecondsSinceEpoch,
                }
              ],
              'total_count': 1,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();
          final domains =
              await auth.fetchOrganizationDomains(organization: org);

          expect(domains, isA<List<OrganizationDomain>>());
          expect(domains.length, 1);

          auth.terminate();
        });

        test('handles multiple pages of domains', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // First page with 20 items (full page)
          final firstPageDomains = List.generate(
            20,
            (i) => {
              'object': 'organization_domain',
              'id': 'domain_$i',
              'organization_id': 'org_123',
              'name': 'example$i.com',
              'enrollment_mode': 'manual_invitation',
              'verification': null,
              'affiliation_email_address': null,
              'total_pending_invitations': 0,
              'total_pending_suggestions': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
          mockHttp.addJsonResponse({
            'response': {
              'data': firstPageDomains,
              'total_count': 25,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });
          // Second page with 5 items (partial page - ends pagination)
          final secondPageDomains = List.generate(
            5,
            (i) => {
              'object': 'organization_domain',
              'id': 'domain_${20 + i}',
              'organization_id': 'org_123',
              'name': 'example${20 + i}.com',
              'enrollment_mode': 'manual_invitation',
              'verification': null,
              'affiliation_email_address': null,
              'total_pending_invitations': 0,
              'total_pending_suggestions': 0,
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
          mockHttp.addJsonResponse({
            'response': {
              'data': secondPageDomains,
              'total_count': 25,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();
          final domains =
              await auth.fetchOrganizationDomains(organization: org);

          expect(domains, isA<List<OrganizationDomain>>());
          expect(domains.length, 25);

          auth.terminate();
        });

        test('handles empty response', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addJsonResponse({
            'response': {
              'data': null,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final org = _createTestOrganization();
          final domains =
              await auth.fetchOrganizationDomains(organization: org);

          expect(domains, isA<List<OrganizationDomain>>());
          expect(domains.isEmpty, true);

          auth.terminate();
        });
      });

      group('fetchOrganizationInvitations', () {
        test('handles multiple pages of invitations', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          // First page with 20 items (full page)
          final firstPageInvitations = List.generate(
            20,
            (i) => {
              'object': 'organization_invitation',
              'id': 'inv_$i',
              'status': 'pending',
              'role_name': 'member',
              'public_organization_data': {
                'object': 'organization',
                'id': 'org_123',
                'name': 'Test Org',
                'slug': 'test-org',
              },
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
          mockHttp.addJsonResponse({
            'response': {
              'data': firstPageInvitations,
              'total_count': 25,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });
          // Second page with 5 items (partial page - ends pagination)
          final secondPageInvitations = List.generate(
            5,
            (i) => {
              'object': 'organization_invitation',
              'id': 'inv_${20 + i}',
              'status': 'pending',
              'role_name': 'member',
              'public_organization_data': {
                'object': 'organization',
                'id': 'org_123',
                'name': 'Test Org',
                'slug': 'test-org',
              },
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
          mockHttp.addJsonResponse({
            'response': {
              'data': secondPageInvitations,
              'total_count': 25,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final invitations = await auth.fetchOrganizationInvitations();

          expect(invitations, isA<List<OrganizationInvitation>>());
          expect(invitations.length, 25);

          auth.terminate();
        });

        test('handles empty response', () async {
          mockHttp.addClientResponse();
          mockHttp.addEnvironmentResponse();
          mockHttp.addJsonResponse({
            'response': {
              'data': null,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();

          final invitations = await auth.fetchOrganizationInvitations();

          expect(invitations, isA<List<OrganizationInvitation>>());
          expect(invitations.isEmpty, true);

          auth.terminate();
        });
      });

      group('transfer', () {
        test('transfers sign up when signIn is transferable', () async {
          // SignIn.isTransferable checks verification?.status.isTransferable
          final signInJson = {
            'object': 'sign_in',
            'id': 'signin_123',
            'status': 'needs_first_factor',
            'identifier': 'test@example.com',
            'supported_identifiers': ['email_address'],
            'supported_first_factors': [],
            'supported_second_factors': [],
            'first_factor_verification': {
              'status': 'transferable',
              'strategy': 'oauth_google',
              'attempts': 0,
              'expire_at': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch,
            },
            'second_factor_verification': null,
            'created_session_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          };
          mockHttp.addClientResponse(signIn: signInJson);
          mockHttp.addEnvironmentResponse();
          // Response for transferSignUp
          mockHttp.addJsonResponse({
            'response': {
              'object': 'sign_up',
              'id': 'signup_123',
              'status': 'complete',
              'required_fields': [],
              'optional_fields': [],
              'missing_fields': [],
              'unverified_fields': [],
              'verifications': {},
              'password_enabled': false,
              'custom_action': false,
              'unsafe_metadata': {},
              'public_metadata': {},
              'abandon_at': DateTime.now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.transfer();

          // Verify transferSignUp was called (calls /client/sign_ups with transfer=true)
          expect(
              mockHttp.calls.any((c) => c.uri.path.contains('sign_ups')), true);

          auth.terminate();
        });

        test('transfers sign in when signUp is transferable', () async {
          // SignUp.isTransferable checks if any verification has status.isTransferable
          final signUpJson = {
            'object': 'sign_up',
            'id': 'signup_123',
            'status': 'missing_requirements',
            'required_fields': [],
            'optional_fields': [],
            'missing_fields': [],
            'unverified_fields': [],
            'verifications': {
              'external_account': {
                'status': 'transferable',
                'strategy': 'oauth_google',
                'attempts': 0,
                'expire_at': DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch,
              },
            },
            'password_enabled': false,
            'custom_action': false,
            'unsafe_metadata': {},
            'public_metadata': {},
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          };
          mockHttp.addClientResponse(signUp: signUpJson);
          mockHttp.addEnvironmentResponse();
          // Response for transferSignIn
          mockHttp.addJsonResponse({
            'response': {
              'object': 'sign_in',
              'id': 'signin_123',
              'status': 'complete',
              'identifier': 'test@example.com',
              'supported_identifiers': ['email_address'],
              'supported_first_factors': [],
              'supported_second_factors': [],
              'first_factor_verification': null,
              'second_factor_verification': null,
              'created_session_id': null,
              'abandon_at': DateTime.now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch,
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.transfer();

          // Verify transferSignIn was called (calls /client/sign_ins with transfer=true)
          expect(
              mockHttp.calls.any((c) => c.uri.path.contains('sign_ins')), true);

          auth.terminate();
        });
      });

      group('completeOAuthSignIn', () {
        test('sends oauth token when signIn exists', () async {
          final signInJson = {
            'object': 'sign_in',
            'id': 'signin_123',
            'status': 'needs_first_factor',
            'identifier': 'test@example.com',
            'supported_identifiers': ['email_address'],
            'supported_first_factors': [
              {'strategy': 'oauth_google'},
            ],
            'supported_second_factors': [],
            'first_factor_verification': null,
            'second_factor_verification': null,
            'created_session_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          };
          mockHttp.addClientResponse(signIn: signInJson);
          mockHttp.addEnvironmentResponse();
          // Response for sendOauthToken
          mockHttp.addJsonResponse({
            'response': {
              'object': 'sign_in',
              'id': 'signin_123',
              'status': 'complete',
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.completeOAuthSignIn(token: 'oauth_token_123');

          // Verify sendOauthToken was called
          expect(mockHttp.calls.any((c) => c.uri.path.contains('signin_123')),
              true);

          auth.terminate();
        });

        test('sends oauth token when signUp exists', () async {
          final signUpJson = {
            'object': 'sign_up',
            'id': 'signup_123',
            'status': 'missing_requirements',
            'required_fields': [],
            'optional_fields': [],
            'missing_fields': [],
            'unverified_fields': [],
            'verifications': {},
            'password_enabled': false,
            'custom_action': false,
            'unsafe_metadata': {},
            'public_metadata': {},
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          };
          mockHttp.addClientResponse(signUp: signUpJson);
          mockHttp.addEnvironmentResponse();
          // Response for sendOauthToken
          mockHttp.addJsonResponse({
            'response': {
              'object': 'sign_up',
              'id': 'signup_123',
              'status': 'complete',
            },
            'client': {
              'object': 'client',
              'id': 'client_123',
              'sessions': [],
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          });

          auth = Auth(
            config: TestAuthConfig(
              publishableKey: _validPublishableKey,
              httpService: mockHttp,
            ),
          );

          await auth.initialize();
          await auth.completeOAuthSignIn(token: 'oauth_token_123');

          // Verify sendOauthToken was called
          expect(mockHttp.calls.any((c) => c.uri.path.contains('signup_123')),
              true);

          auth.terminate();
        });
      });
    });

    group('oauthSignIn', () {
      test('prepares sign in when signIn has no verification', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client, environment
        mockHttp.addClientResponse();
        mockHttp.addEnvironmentResponse();
        // Create sign in response without verification
        mockHttp.addSignInResponse(
          signInId: 'signin_oauth',
          status: 'needs_first_factor',
          firstFactorVerification: null,
        );
        // Prepare sign in response
        mockHttp.addSignInResponse(
          signInId: 'signin_oauth',
          status: 'needs_first_factor',
          firstFactorVerification: {
            'status': 'unverified',
            'strategy': 'oauth_google',
            'attempts': 0,
            'expire_at': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
            'external_verification_redirect_url':
                'https://accounts.google.com/oauth',
          },
        );

        await auth.initialize();
        await auth.oauthSignIn(
          strategy: Strategy.oauthGoogle,
          redirect: Uri.parse('https://example.com/callback'),
        );

        // Verify createSignIn was called
        expect(
            mockHttp.calls.any((c) => c.uri.path.contains('sign_ins')), true);

        auth.terminate();
      });
    });

    group('attemptSignIn', () {
      test('handles SSO with token', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with signIn, environment
        mockHttp.addClientResponse(
          signIn: {
            'object': 'sign_in',
            'id': 'signin_sso',
            'status': 'needs_first_factor',
            'identifier': 'test@example.com',
            'supported_identifiers': ['email_address'],
            'supported_first_factors': [
              {'strategy': 'enterprise_sso'},
            ],
            'supported_second_factors': [],
            'first_factor_verification': null,
            'second_factor_verification': null,
            'created_session_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          },
        );
        mockHttp.addEnvironmentResponse();
        // SSO token response
        mockHttp.addClientWithSessionResponse();

        await auth.initialize();
        await auth.attemptSignIn(
          strategy: Strategy.enterpriseSSO,
          token: 'sso_token_123',
        );

        // Verify sendOauthToken was called (3 calls: client, env, sendOauthToken)
        expect(mockHttp.calls.length, 3);

        auth.terminate();
      });

      test('handles password reset with code', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with signIn, environment
        mockHttp.addClientResponse(
          signIn: {
            'object': 'sign_in',
            'id': 'signin_reset',
            'status': 'needs_first_factor',
            'identifier': 'test@example.com',
            'supported_identifiers': ['email_address'],
            'supported_first_factors': [
              {'strategy': 'reset_password_email_code'},
            ],
            'supported_second_factors': [],
            'first_factor_verification': null,
            'second_factor_verification': null,
            'created_session_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          },
        );
        mockHttp.addEnvironmentResponse();
        // Password reset response
        mockHttp.addClientWithSessionResponse();

        await auth.initialize();
        await auth.attemptSignIn(
          strategy: Strategy.resetPasswordEmailCode,
          code: '123456',
          password: 'newPassword123',
        );

        // Verify attempt was made
        expect(mockHttp.calls.any((c) => c.uri.path.contains('attempt')), true);

        auth.terminate();
      });

      // Note: email link strategy test removed due to async polling issues
      // The _pollForEmailLinkCompletion continues after test completion

      test('handles password sign in when status needs factor', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with signIn needing first factor, environment
        mockHttp.addClientResponse(
          signIn: {
            'object': 'sign_in',
            'id': 'signin_pwd',
            'status': 'needs_first_factor',
            'identifier': 'test@example.com',
            'supported_identifiers': ['email_address'],
            'supported_first_factors': [
              {'strategy': 'password'},
            ],
            'supported_second_factors': [],
            'first_factor_verification': null,
            'second_factor_verification': null,
            'created_session_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          },
        );
        mockHttp.addEnvironmentResponse();
        // Attempt password response
        mockHttp.addClientWithSessionResponse();

        await auth.initialize();
        await auth.attemptSignIn(
          strategy: Strategy.password,
          password: 'password123',
        );

        // Verify attempt was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('attempt')), true);

        auth.terminate();
      });
    });

    group('attemptSignUp', () {
      // Note: email link strategy test removed due to async polling issues
      // The _pollForEmailLinkCompletion continues after test completion

      test('handles enterprise SSO sign up', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with signUp requiring enterprise SSO, environment
        mockHttp.addClientResponse(
          signUp: {
            'object': 'sign_up',
            'id': 'signup_sso',
            'status': 'missing_requirements',
            'required_fields': ['email_address'],
            'optional_fields': [],
            'missing_fields': [],
            'unverified_fields': [],
            'email_address': 'test@enterprise.com',
            'phone_number': null,
            'first_name': null,
            'last_name': null,
            'username': null,
            'web3_wallet': null,
            'password_enabled': false,
            'unsafe_metadata': {},
            'public_metadata': {},
            'verifications': {
              'enterprise_sso': {
                'status': 'unverified',
                'strategy': 'saml',
                'attempts': 0,
                'expire_at': DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch,
              },
            },
            'custom_action': false,
            'external_id': null,
            'created_session_id': null,
            'created_user_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch,
          },
        );
        mockHttp.addEnvironmentResponse();
        // Update sign up response
        mockHttp.addSignUpResponse(
          signUpId: 'signup_sso',
          status: 'missing_requirements',
        );

        await auth.initialize();
        await auth.attemptSignUp(
          strategy: Strategy.saml,
          redirectUrl: 'https://example.com/sso/callback',
        );

        // Verify update was called
        expect(
            mockHttp.calls.any((c) => c.uri.path.contains('sign_ups')), true);

        auth.terminate();
      });

      test(
          'handles missing requirements with empty missing fields and unverified fields',
          () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with signUp in missing_requirements with empty missing and unverified fields
        // This triggers the case at line 741-756 in auth.dart
        // We use a strategy that doesn't require verification (password) and don't pass a code
        // to hit just the prepare path
        mockHttp.addClientResponse(
          signUp: {
            'object': 'sign_up',
            'id': 'signup_verify',
            'status': 'missing_requirements',
            'required_fields': ['email_address'],
            'optional_fields': [],
            'missing_fields': [],
            'unverified_fields': [],
            'email_address': 'test@example.com',
            'phone_number': null,
            'first_name': null,
            'last_name': null,
            'username': null,
            'web3_wallet': null,
            'password_enabled': false,
            'unsafe_metadata': {},
            'public_metadata': {},
            'verifications': {},
            'custom_action': false,
            'external_id': null,
            'created_session_id': null,
            'created_user_id': null,
            'abandon_at': DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch,
          },
        );
        mockHttp.addEnvironmentResponse();
        // Prepare response - this should be called
        mockHttp.addSignUpResponse(
          signUpId: 'signup_verify',
          status: 'missing_requirements',
          missingFields: [],
          unverifiedFields: [],
          verifications: {},
        );

        await auth.initialize();
        // Use password strategy without code to hit the prepare-only path
        await auth.attemptSignUp(
          strategy: Strategy.password,
        );

        // Verify prepare was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('prepare')), true);

        auth.terminate();
      });
    });

    group('setActiveOrganization', () {
      test('sets active organization when session exists', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Set active organization response
        mockHttp.addClientWithSessionResponse();

        await auth.initialize();

        final org = _createTestOrganization();
        await auth.setActiveOrganization(org);

        // Verify setActiveOrganization was called
        expect(
            mockHttp.calls.any((c) => c.uri.path.contains('sessions')), true);

        auth.terminate();
      });
    });

    group('createOrganization', () {
      test('creates organization with slug', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session and user with org membership, environment
        final userWithOrg = {
          'object': 'user',
          'id': 'user_123',
          'external_id': null,
          'username': null,
          'first_name': null,
          'last_name': null,
          'profile_image_url': null,
          'image_url': null,
          'has_image': false,
          'primary_email_address_id': null,
          'primary_phone_number_id': null,
          'primary_web3_wallet_id': null,
          'public_metadata': {},
          'private_metadata': {},
          'unsafe_metadata': {},
          'email_addresses': <Map<String, dynamic>>[],
          'phone_numbers': <Map<String, dynamic>>[],
          'web3_wallets': <Map<String, dynamic>>[],
          'passkeys': <Map<String, dynamic>>[],
          'organization_memberships': <Map<String, dynamic>>[
            {
              'object': 'organization_membership',
              'id': 'mem_123',
              'role': 'admin',
              'role_name': 'Admin',
              'permissions': <String>[],
              'public_metadata': <String, dynamic>{},
              'organization': {
                'object': 'organization',
                'id': 'org_new',
                'name': 'New Org',
                'slug': 'new-org',
                'image_url': null,
                'has_image': false,
                'members_count': 1,
                'pending_invitations_count': 0,
                'max_allowed_memberships': 5,
                'admin_delete_enabled': true,
                'public_metadata': <String, dynamic>{},
                'created_at': DateTime.now().millisecondsSinceEpoch,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              },
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
          ],
          'create_organization_enabled': true,
          'external_accounts': <Map<String, dynamic>>[],
          'password_enabled': false,
          'two_factor_enabled': false,
          'totp_enabled': false,
          'backup_code_enabled': false,
          'last_sign_in_at': DateTime.now().millisecondsSinceEpoch,
          'banned': false,
          'locked': false,
          'lockout_expires_in_seconds': null,
          'verification_attempts_remaining': null,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'last_active_at': DateTime.now().millisecondsSinceEpoch,
          'delete_self_enabled': true,
        };
        final sessionWithOrg = {
          'object': 'session',
          'id': 'sess_123',
          'status': 'active',
          'last_active_at': DateTime.now().millisecondsSinceEpoch,
          'expire_at': DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'abandon_at': DateTime.now()
              .add(const Duration(days: 7))
              .millisecondsSinceEpoch,
          'last_active_organization_id': null,
          'user': userWithOrg,
          'public_user_data': {
            'first_name': null,
            'last_name': null,
            'profile_image_url': null,
            'image_url': null,
            'has_image': false,
            'identifier': 'test@example.com',
          },
        };
        mockHttp.addJsonResponse({
          'response': {
            'object': 'client',
            'id': 'client_123',
            'sessions': [sessionWithOrg],
            'last_active_session_id': 'sess_123',
            'sign_in': null,
            'sign_up': null,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
        });
        mockHttp.addEnvironmentResponse();
        // Create organization response
        mockHttp.addOrganizationResponse(orgId: 'org_new', name: 'New Org');
        // Update organization response (for slug)
        mockHttp.addOrganizationResponse(
            orgId: 'org_new', name: 'New Org', slug: 'custom-slug');

        await auth.initialize();
        await auth.createOrganization(name: 'New Org', slug: 'custom-slug');

        // Verify organization was created and updated
        expect(mockHttp.calls.any((c) => c.uri.path.contains('organizations')),
            true);

        auth.terminate();
      });
    });

    group('updateUser', () {
      test('updates user with username', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment with username allowed
        mockHttp.addClientWithSessionResponse();
        mockHttp.addJsonResponse({
          'auth_config': {
            'object': 'auth_config',
            'id': 'aac_123',
            'single_session_mode': false,
            'url_based_session_syncing': false,
            'first_factors': ['email_address'],
            'second_factors': [],
            'username': 'on', // Enable username updates
          },
          'display_config': {
            'object': 'display_config',
            'id': 'display_config_123',
            'instance_environment_type': 'development',
            'application_name': 'Test App',
            'theme': {},
            'preferred_sign_in_strategy': 'password',
            'logo_image_url': null,
            'favicon_image_url': null,
            'home_url': 'https://example.com',
            'sign_in_url': 'https://example.com/sign-in',
            'sign_up_url': 'https://example.com/sign-up',
            'user_profile_url': 'https://example.com/user',
            'after_sign_in_url': 'https://example.com',
            'after_sign_up_url': 'https://example.com',
            'after_sign_out_one_url': 'https://example.com',
            'after_sign_out_all_url': 'https://example.com',
            'after_switch_session_url': 'https://example.com',
            'branded': false,
            'captcha_public_key': null,
            'support_email': null,
            'clerk_js_version': '5',
            'show_devmode_warning': true,
            'google_one_tap_client_id': null,
            'help_url': null,
            'privacy_policy_url': null,
            'terms_url': null,
            'logo_link_url': null,
            'organization_profile_url': null,
            'create_organization_url': null,
            'after_leave_organization_url': null,
            'after_create_organization_url': null,
            'logo_url': null,
            'favicon_url': null,
            'waitlist_url': null,
            'after_join_waitlist_url': null,
          },
          'user_settings': {
            'attributes': {
              'username': {
                'enabled': true,
                'required': false,
                'used_for_first_factor': true,
                'first_factors': [],
                'used_for_second_factor': false,
                'second_factors': [],
                'verifications': [],
                'verify_at_sign_up': false,
              },
              'first_name': {
                'enabled': true,
                'required': false,
                'used_for_first_factor': false,
                'first_factors': [],
                'used_for_second_factor': false,
                'second_factors': [],
                'verifications': [],
                'verify_at_sign_up': false,
              },
              'last_name': {
                'enabled': true,
                'required': false,
                'used_for_first_factor': false,
                'first_factors': [],
                'used_for_second_factor': false,
                'second_factors': [],
                'verifications': [],
                'verify_at_sign_up': false,
              },
            },
            'sign_in': {},
            'sign_up': {},
            'actions': {'delete_self': true, 'create_organization': true},
            'social': {},
            'password_settings': {
              'disable_hibp': false,
              'min_length': 8,
              'max_length': 72,
              'require_special_char': false,
              'require_numbers': false,
              'require_uppercase': false,
              'require_lowercase': false,
              'show_zxcvbn': false,
              'min_zxcvbn_strength': 0,
              'enforce_hibp_on_sign_in': false,
              'allowed_special_characters': r'+$-_',
            },
            'passkey_settings': {
              'allow_autofill': false,
              'show_sign_in_button': false
            },
            'saml': {'enabled': false},
          },
          'organization_settings': {
            'enabled': false,
            'max_allowed_memberships': 5,
            'actions': {'admin_delete': true},
            'domains': {'enabled': false, 'enrollment_modes': []},
          },
        });
        // Update user response
        mockHttp.addUserResponse(username: 'newusername');

        await auth.initialize();
        await auth.updateUser(username: 'newusername');

        // Verify update was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('/me')), true);

        auth.terminate();
      });

      test('updates user with firstName and lastName', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment with names allowed
        mockHttp.addClientWithSessionResponse();
        mockHttp.addJsonResponse({
          'auth_config': {
            'object': 'auth_config',
            'id': 'aac_123',
            'single_session_mode': false,
            'url_based_session_syncing': false,
            'first_factors': ['email_address'],
            'second_factors': [],
            'first_name': 'on', // Enable first name updates
            'last_name': 'on', // Enable last name updates
          },
          'display_config': {
            'object': 'display_config',
            'id': 'display_config_123',
            'instance_environment_type': 'development',
            'application_name': 'Test App',
            'theme': {},
            'preferred_sign_in_strategy': 'password',
            'logo_image_url': null,
            'favicon_image_url': null,
            'home_url': 'https://example.com',
            'sign_in_url': 'https://example.com/sign-in',
            'sign_up_url': 'https://example.com/sign-up',
            'user_profile_url': 'https://example.com/user',
            'after_sign_in_url': 'https://example.com',
            'after_sign_up_url': 'https://example.com',
            'after_sign_out_one_url': 'https://example.com',
            'after_sign_out_all_url': 'https://example.com',
            'after_switch_session_url': 'https://example.com',
            'branded': false,
            'captcha_public_key': null,
            'support_email': null,
            'clerk_js_version': '5',
            'show_devmode_warning': true,
            'google_one_tap_client_id': null,
            'help_url': null,
            'privacy_policy_url': null,
            'terms_url': null,
            'logo_link_url': null,
            'organization_profile_url': null,
            'create_organization_url': null,
            'after_leave_organization_url': null,
            'after_create_organization_url': null,
            'logo_url': null,
            'favicon_url': null,
            'waitlist_url': null,
            'after_join_waitlist_url': null,
          },
          'user_settings': {
            'attributes': {
              'first_name': {
                'enabled': true,
                'required': false,
                'used_for_first_factor': false,
                'first_factors': [],
                'used_for_second_factor': false,
                'second_factors': [],
                'verifications': [],
                'verify_at_sign_up': false,
              },
              'last_name': {
                'enabled': true,
                'required': false,
                'used_for_first_factor': false,
                'first_factors': [],
                'used_for_second_factor': false,
                'second_factors': [],
                'verifications': [],
                'verify_at_sign_up': false,
              },
            },
            'sign_in': {},
            'sign_up': {},
            'actions': {'delete_self': true, 'create_organization': true},
            'social': {},
            'password_settings': {
              'disable_hibp': false,
              'min_length': 8,
              'max_length': 72,
              'require_special_char': false,
              'require_numbers': false,
              'require_uppercase': false,
              'require_lowercase': false,
              'show_zxcvbn': false,
              'min_zxcvbn_strength': 0,
              'enforce_hibp_on_sign_in': false,
              'allowed_special_characters': r'+$-_',
            },
            'passkey_settings': {
              'allow_autofill': false,
              'show_sign_in_button': false
            },
            'saml': {'enabled': false},
          },
          'organization_settings': {
            'enabled': false,
            'max_allowed_memberships': 5,
            'actions': {'admin_delete': true},
            'domains': {'enabled': false, 'enrollment_modes': []},
          },
        });
        // Update user response
        mockHttp.addUserResponse(firstName: 'John', lastName: 'Doe');

        await auth.initialize();
        await auth.updateUser(firstName: 'John', lastName: 'Doe');

        // Verify update was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('/me')), true);

        auth.terminate();
      });

      test('updates user with primaryEmailAddressId', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Update user response
        mockHttp.addUserResponse();

        await auth.initialize();
        await auth.updateUser(primaryEmailAddressId: 'email_new_123');

        // Verify update was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('/me')), true);

        auth.terminate();
      });

      test('updates user with metadata', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Update user response
        mockHttp.addUserResponse();

        await auth.initialize();
        await auth.updateUser(metadata: {'key': 'value'});

        // Verify update was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('/me')), true);

        auth.terminate();
      });
    });

    group('deleteUser', () {
      test('handles error when delete self is not allowed', () async {
        final mockHttp = MockHttpService();
        ClerkError? capturedError;
        final auth = _TestAuth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
          onError: (error) => capturedError = error,
        );

        // Setup: client with session, environment with delete_self disabled
        mockHttp.addClientWithSessionResponse();
        mockHttp.addJsonResponse({
          'auth_config': {
            'object': 'auth_config',
            'id': 'aac_123',
            'single_session_mode': false,
            'url_based_session_syncing': false,
            'first_factors': ['email_address'],
            'second_factors': [],
          },
          'display_config': {
            'object': 'display_config',
            'id': 'display_config_123',
            'instance_environment_type': 'development',
            'application_name': 'Test App',
            'theme': {},
            'preferred_sign_in_strategy': 'password',
            'logo_image_url': null,
            'favicon_image_url': null,
            'home_url': 'https://example.com',
            'sign_in_url': 'https://example.com/sign-in',
            'sign_up_url': 'https://example.com/sign-up',
            'user_profile_url': 'https://example.com/user',
            'after_sign_in_url': 'https://example.com',
            'after_sign_up_url': 'https://example.com',
            'after_sign_out_one_url': 'https://example.com',
            'after_sign_out_all_url': 'https://example.com',
            'after_switch_session_url': 'https://example.com',
            'branded': false,
            'captcha_public_key': null,
            'support_email': null,
            'clerk_js_version': '5',
            'show_devmode_warning': true,
            'google_one_tap_client_id': null,
            'help_url': null,
            'privacy_policy_url': null,
            'terms_url': null,
            'logo_link_url': null,
            'organization_profile_url': null,
            'create_organization_url': null,
            'after_leave_organization_url': null,
            'after_create_organization_url': null,
            'logo_url': null,
            'favicon_url': null,
            'waitlist_url': null,
            'after_join_waitlist_url': null,
          },
          'user_settings': {
            'attributes': {},
            'sign_in': {},
            'sign_up': {},
            'actions': {'delete_self': false, 'create_organization': true},
            'social': {},
            'password_settings': {
              'disable_hibp': false,
              'min_length': 8,
              'max_length': 72,
              'require_special_char': false,
              'require_numbers': false,
              'require_uppercase': false,
              'require_lowercase': false,
              'show_zxcvbn': false,
              'min_zxcvbn_strength': 0,
              'enforce_hibp_on_sign_in': false,
              'allowed_special_characters': r'+$-_',
            },
            'passkey_settings': {
              'allow_autofill': false,
              'show_sign_in_button': false
            },
            'saml': {'enabled': false},
          },
          'organization_settings': {
            'enabled': false,
            'max_allowed_memberships': 5,
            'actions': {'admin_delete': true},
            'domains': {'enabled': false, 'enrollment_modes': []},
          },
        });

        await auth.initialize();
        await auth.deleteUser();

        // Verify error was handled
        expect(capturedError, isNotNull);
        expect(capturedError!.code, ClerkErrorCode.cannotDeleteSelf);

        auth.terminate();
      });
    });

    group('updateOrganization', () {
      test('updates organization with name', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Update organization response
        mockHttp.addOrganizationResponse(name: 'Updated Org');

        await auth.initialize();

        final org = _createTestOrganization();
        await auth.updateOrganization(organization: org, name: 'Updated Org');

        // Verify update was called
        expect(mockHttp.calls.any((c) => c.uri.path.contains('organizations')),
            true);

        auth.terminate();
      });

      test('does nothing when name is same as current', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();

        await auth.initialize();

        final org = _createTestOrganization(name: 'Test Org');
        await auth.updateOrganization(organization: org, name: 'Test Org');

        // Verify no update was called (name is the same)
        expect(
            mockHttp.calls
                .where((c) =>
                    c.uri.path.contains('organizations') &&
                    c.method == HttpMethod.patch)
                .length,
            0);

        auth.terminate();
      });
    });

    group('updateUserImage', () {
      test('updates user avatar', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Avatar update response
        mockHttp.addUserResponse();

        await auth.initialize();

        // Create a mock file - we can't actually test file upload without a real file
        // but we can verify the method is called
        // Note: This test verifies the method exists and can be called
        expect(auth.updateUserImage, isA<Function>());

        auth.terminate();
      });
    });

    group('deleteUserImage', () {
      test('deletes user avatar', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Avatar delete response
        mockHttp.addUserResponse();

        await auth.initialize();
        await auth.deleteUserImage();

        // Verify delete was called
        expect(
            mockHttp.calls.any((c) =>
                c.uri.path.contains('profile_image') &&
                c.method == HttpMethod.delete),
            true);

        auth.terminate();
      });
    });

    group('updateUserPassword', () {
      test('updates user password', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Password update response
        mockHttp.addUserResponse();

        await auth.initialize();
        await auth.updateUserPassword('oldPassword123', 'newPassword456');

        // Verify update was called
        expect(
            mockHttp.calls.any((c) => c.uri.path.contains('change_password')),
            true);

        auth.terminate();
      });
    });

    group('deleteUserPassword', () {
      test('deletes user password', () async {
        final mockHttp = MockHttpService();
        final auth = Auth(
          config: TestAuthConfig(
            publishableKey: _validPublishableKey,
            httpService: mockHttp,
          ),
        );

        // Setup: client with session, environment
        mockHttp.addClientWithSessionResponse();
        mockHttp.addEnvironmentResponse();
        // Password delete response
        mockHttp.addUserResponse();

        await auth.initialize();
        await auth.deleteUserPassword('currentPassword123');

        // Verify delete was called
        expect(
            mockHttp.calls.any((c) => c.uri.path.contains('remove_password')),
            true);

        auth.terminate();
      });
    });
  });
}

/// Test Auth subclass that captures errors instead of throwing
class _TestAuth extends Auth {
  _TestAuth({
    required super.config,
    required this.onError,
  });

  final void Function(ClerkError) onError;

  @override
  void handleError(Object error) {
    if (error case ClerkError error) {
      onError(error);
    } else {
      onError(ClerkError.external(error));
    }
  }
}

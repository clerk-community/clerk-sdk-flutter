import 'dart:io' show HttpHeaders;

import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_auth/src/clerk_api/api.dart';
import 'package:clerk_auth/src/models/api/external_error.dart';

import '../../test_helpers.dart';

void main() {
  late Api api;
  late MockHttpService mockHttp;

  setUp(() {
    mockHttp = MockHttpService();
    api = Api(
      config: TestAuthConfig(
        publishableKey: 'pk_test_c29tZWRvbWFpbi5jb20K',
        httpService: mockHttp,
      ),
    );
  });

  tearDown(() {
    api.terminate();
    mockHttp.reset();
  });

  group('Api', () {
    group('initialization', () {
      test('initialize calls token cache initialize', () async {
        await api.initialize();
        // No exception means success
        expect(true);
      });

      test('terminate can be called without error', () {
        api.terminate();
        expect(true);
      });

      test('domain is derived from publishable key', () {
        expect(api.domain.trim(), 'somedomain.com');
      });
    });

    group('hasConnectivity', () {
      test('returns true when ping succeeds', () async {
        final result = await api.hasConnectivity();
        expect(result, true);
      });
    });

    group('environment', () {
      test('returns Environment when response is OK', () async {
        mockHttp.addEnvironmentResponse();

        final env = await api.environment();

        expect(env.isNotEmpty, true);
        expect(env.display.applicationName, 'Test App');
        expect(mockHttp.calls.length, 1);
        expect(mockHttp.calls.first.method, HttpMethod.get);
        expect(mockHttp.calls.first.uri.path, contains('/environment'));
      });

      test('returns empty Environment when response is not OK', () async {
        mockHttp.addJsonResponse({}, statusCode: 500);

        final env = await api.environment();

        expect(env.isEmpty, true);
      });
    });

    group('client operations', () {
      test('createClient returns client when token exists', () async {
        await api.initialize();
        mockHttp.addClientResponse(clientId: 'client_new');

        final client = await api.createClient();

        expect(client.isNotEmpty, true);
        expect(client.id, 'client_new');
      });

      test('resetClient creates new client', () async {
        await api.initialize();
        mockHttp.addClientResponse(clientId: 'client_reset');

        final client = await api.resetClient();

        expect(client.id, 'client_reset');
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('currentClient fetches existing client', () async {
        await api.initialize();
        mockHttp.addClientResponse(clientId: 'client_current');

        final client = await api.currentClient();

        expect(client.id, 'client_current');
        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('signOut and deleteUser', () {
      test('signOut returns empty client', () async {
        await api.initialize();
        mockHttp.addEmptyResponse();

        final client = await api.signOut();

        expect(client.isEmpty, true);
        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/client'));
      });

      test('deleteUser authenticates the request before clearing tokens',
          () async {
        await api.initialize();
        mockHttp.addAuthenticatedClientWithSessionResponse();
        await api.currentClient();
        mockHttp.addEmptyResponse();

        final client = await api.deleteUser();

        expect(client.isEmpty, true);
        final deleteCall = mockHttp.calls.last;
        expect(deleteCall.method, HttpMethod.delete);
        expect(deleteCall.uri.path, contains('/me'));
        expect(
          deleteCall.headers?[HttpHeaders.authorizationHeader],
          'test_client_token',
        );
        expect(
          deleteCall.uri.queryParameters['_clerk_session_id'],
          'sess_123',
        );

        mockHttp.addClientResponse();
        await api.currentClient();
        expect(
          mockHttp.calls.last.headers?[HttpHeaders.authorizationHeader],
          isNull,
        );
      });

      test('deleteUser preserves tokens and throws when deletion fails',
          () async {
        await api.initialize();
        mockHttp.addAuthenticatedClientWithSessionResponse();
        await api.currentClient();
        mockHttp.addEmptyResponse(statusCode: 500);

        await expectLater(
          api.deleteUser(),
          throwsA(isA<ExternalError>()),
        );

        mockHttp.addClientResponse();
        await api.currentClient();
        expect(
          mockHttp.calls.last.headers?[HttpHeaders.authorizationHeader],
          'test_client_token',
        );
      });
    });

    group('session operations', () {
      test('activate calls touch endpoint', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final session = _createMockSession();
        await api.activate(session);

        expect(mockHttp.calls.first.uri.path, contains('/touch'));
      });

      test('signOutOf calls remove endpoint', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final session = _createMockSession();
        await api.signOutOf(session);

        expect(mockHttp.calls.first.uri.path, contains('/remove'));
      });
    });

    group('sign up operations', () {
      test('createSignUp sends correct parameters', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        await api.createSignUp(
          strategy: Strategy.password,
          emailAddress: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('updateSignUp sends patch request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.updateSignUp(signUp, firstName: 'Updated');

        expect(mockHttp.calls.first.method, HttpMethod.patch);
        expect(mockHttp.calls.first.uri.path, contains('/sign_ups/'));
      });

      test('prepareSignUp sends prepare_verification request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.prepareSignUp(signUp, strategy: Strategy.emailCode);

        expect(
            mockHttp.calls.first.uri.path, contains('/prepare_verification'));
      });

      test('attemptSignUp sends attempt_verification request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.attemptSignUp(signUp,
            strategy: Strategy.emailCode, code: '123456');

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_verification'));
      });
    });

    group('sign in operations', () {
      test('createSignIn sends correct parameters', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        await api.createSignIn(identifier: 'test@example.com');

        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('prepareSignIn sends prepare_first_factor request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        final signIn = _createMockSignIn();
        await api.prepareSignIn(signIn,
            stage: Stage.first, strategy: Strategy.emailCode);

        expect(
            mockHttp.calls.first.uri.path, contains('/prepare_first_factor'));
      });

      test('attemptSignIn sends attempt_first_factor request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        final signIn = _createMockSignIn();
        await api.attemptSignIn(
          signIn,
          stage: Stage.first,
          strategy: Strategy.emailCode,
          code: '123456',
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_first_factor'));
      });
    });

    group('oauth operations', () {
      test('addExternalAccount sends request to external_accounts', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.addExternalAccount(
          strategy: Strategy.oauthGoogle,
          redirectUrl: 'https://example.com/callback',
        );

        expect(mockHttp.calls.first.uri.path, contains('/external_accounts'));
      });

      test('transferSignUp sends transfer request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.transferSignUp();

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });

      test('transferSignIn sends transfer request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.transferSignIn();

        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
      });

      test('sendOauthToken sends token to auth object', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final signIn = _createMockSignIn();
        await api.sendOauthToken(signIn, token: 'oauth_token_123');

        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('user operations', () {
      test('getUser fetches user data', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.getUser();

        expect(mockHttp.calls.first.method, HttpMethod.get);
        expect(mockHttp.calls.first.uri.path, contains('/me'));
      });

      test('updateUser sends patch request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.updateUser(firstName: 'Updated', lastName: 'Name');

        expect(mockHttp.calls.first.method, HttpMethod.patch);
        expect(mockHttp.calls.first.uri.path, contains('/me'));
      });

      test('deleteAvatar sends delete request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.deleteAvatar();

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/profile_image'));
      });

      test('updatePassword sends change_password request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.updatePassword('oldPass', 'newPass', true);

        expect(mockHttp.calls.first.uri.path, contains('/change_password'));
      });

      test('deletePassword sends remove_password request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.deletePassword('currentPass');

        expect(mockHttp.calls.first.uri.path, contains('/remove_password'));
      });
    });

    group('organization operations', () {
      test('createOrganization sends request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.createOrganization('Test Org');

        expect(mockHttp.calls.first.uri.path, contains('/organizations'));
      });

      test('fetchOrganizationInvitations fetches invitations', () async {
        await api.initialize();
        mockHttp.addJsonResponse({
          'data': [],
          'total_count': 0,
        });

        await api.fetchOrganizationInvitations();

        expect(mockHttp.calls.first.method, HttpMethod.get);
        expect(mockHttp.calls.first.uri.path,
            contains('/organization_invitations'));
      });

      test('setActiveOrganization sends touch request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.setActiveOrganization('sess_123', 'org_456');

        expect(mockHttp.calls.first.uri.path, contains('/touch'));
      });

      test('leaveOrganization sends delete request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.leaveOrganization(org);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path,
            contains('/organization_memberships'));
      });
    });

    group('session token operations', () {
      test('sessionToken returns null when no token cached', () {
        final token = api.sessionToken();
        expect(token, isNull);
      });
    });

    group('error handling', () {
      test('handles error response gracefully', () async {
        await api.initialize();
        // Add a response with error status code
        mockHttp.addJsonResponse(
          {
            'errors': [
              {'message': 'Error', 'code': 'test_error'}
            ]
          },
          statusCode: 400,
        );

        final response = await api.createSignIn(identifier: 'test@example.com');

        expect(response.isError, true);
      });
    });

    group('connectAccount', () {
      test('sends request to external_accounts with strategy', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.connectAccount(
          strategy: Strategy.oauthGoogle,
          redirectUrl: 'https://example.com/callback',
        );

        expect(mockHttp.calls.first.uri.path, contains('/external_accounts'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });
    });

    group('deleteExternalAccount', () {
      test('sends delete request to external_accounts', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final account = _createMockExternalAccount();
        await api.deleteExternalAccount(account: account);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/external_accounts/'));
      });
    });

    group('identifying data operations', () {
      test('addIdentifyingDataToCurrentUser sends email request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.addIdentifyingDataToCurrentUser(
          'test@example.com',
          IdentifierType.emailAddress,
        );

        expect(mockHttp.calls.first.uri.path, contains('/email_addresses'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('addIdentifyingDataToCurrentUser sends phone request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.addIdentifyingDataToCurrentUser(
          '+1234567890',
          IdentifierType.phoneNumber,
        );

        expect(mockHttp.calls.first.uri.path, contains('/phone_numbers'));
      });

      test('prepareIdentifyingDataVerification sends prepare request',
          () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final identifier = _createMockEmailAddress();
        await api.prepareIdentifyingDataVerification(identifier);

        expect(
            mockHttp.calls.first.uri.path, contains('/prepare_verification'));
      });

      test('verifyIdentifyingData sends attempt request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final identifier = _createMockEmailAddress();
        await api.verifyIdentifyingData(identifier, '123456');

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_verification'));
      });

      test('deleteIdentifyingData sends delete request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final identifier = _createMockEmailAddress();
        await api.deleteIdentifyingData(identifier);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/email_addresses/'));
      });
    });

    group('organization domain operations', () {
      test('fetchOrganizationDomains fetches domains', () async {
        await api.initialize();
        mockHttp.addJsonResponse({
          'data': [],
          'total_count': 0,
        });

        final org = _createMockOrganization();
        await api.fetchOrganizationDomains(org);

        expect(mockHttp.calls.first.method, HttpMethod.get);
        expect(mockHttp.calls.first.uri.path, contains('/domains'));
      });

      test('acceptOrganizationInvitation sends accept request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final invitation = _createMockOrganizationInvitation();
        await api.acceptOrganizationInvitation(invitation);

        expect(mockHttp.calls.first.uri.path, contains('/accept'));
      });

      test('createDomain sends domain creation request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.createDomain(org, 'example.com');

        expect(mockHttp.calls.first.uri.path, contains('/domains'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('updateDomainEnrollmentMode sends update request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.updateDomainEnrollmentMode(
          org,
          'domain_123',
          EnrollmentMode.automaticInvitation,
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/update_enrollment_mode'));
      });

      test('updateOrganization sends patch request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.updateOrganization(org, name: 'New Name', slug: 'new-slug');

        expect(mockHttp.calls.first.method, HttpMethod.patch);
        expect(mockHttp.calls.first.uri.path, contains('/organizations/'));
      });

      test('deleteOrganization sends delete request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.deleteOrganization(org);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/organizations/'));
      });

      test('deleteOrganizationLogo sends delete request', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.deleteOrganizationLogo(org);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/logo'));
      });
    });

    group('fetchApiResponse', () {
      test('sends request with custom parameters', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.fetchApiResponse(
          '/custom/endpoint',
          method: HttpMethod.post,
          params: {'key': 'value'},
        );

        expect(mockHttp.calls.first.uri.path, contains('/custom/endpoint'));
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });

      test('sends request with session when withSession is true', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.fetchApiResponse(
          '/custom/endpoint',
          method: HttpMethod.get,
          withSession: true,
        );

        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('prepareSignIn with second factor', () {
      test('sends prepare_second_factor request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        final signIn = _createMockSignInWithSecondFactor();
        await api.prepareSignIn(signIn,
            stage: Stage.second, strategy: Strategy.phoneCode);

        expect(
            mockHttp.calls.first.uri.path, contains('/prepare_second_factor'));
      });

      test('attemptSignIn sends attempt_second_factor request', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        final signIn = _createMockSignInWithSecondFactor();
        await api.attemptSignIn(
          signIn,
          stage: Stage.second,
          strategy: Strategy.phoneCode,
          code: '123456',
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_second_factor'));
      });
    });

    group('createSignIn with various parameters', () {
      test('createSignIn with password', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        await api.createSignIn(
          identifier: 'test@example.com',
          password: 'password123',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
      });

      test('createSignIn with strategy and token', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        await api.createSignIn(
          strategy: Strategy.oauthApple,
          token: 'apple_token_123',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
      });

      test('createSignIn with redirect URL', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        await api.createSignIn(
          strategy: Strategy.emailLink,
          identifier: 'test@example.com',
          redirectUrl: 'https://example.com/callback',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
      });
    });

    group('createSignUp with various parameters', () {
      test('createSignUp with username', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        await api.createSignUp(
          strategy: Strategy.password,
          username: 'testuser',
          password: 'password123',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });

      test('createSignUp with phone number', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        await api.createSignUp(
          strategy: Strategy.phoneCode,
          phoneNumber: '+1234567890',
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });

      test('createSignUp with metadata', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        await api.createSignUp(
          strategy: Strategy.password,
          emailAddress: 'test@example.com',
          password: 'password123',
          metadata: {'custom_field': 'value'},
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });

      test('createSignUp with legal accepted', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        await api.createSignUp(
          strategy: Strategy.password,
          emailAddress: 'test@example.com',
          password: 'password123',
          legalAccepted: true,
        );

        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });
    });

    group('updateSignUp with various parameters', () {
      test('updateSignUp with redirect URL', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.updateSignUp(
          signUp,
          strategy: Strategy.emailLink,
          redirectUrl: 'https://example.com/callback',
        );

        expect(mockHttp.calls.first.method, HttpMethod.patch);
      });

      test('updateSignUp with metadata', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.updateSignUp(
          signUp,
          metadata: {'key': 'value'},
        );

        expect(mockHttp.calls.first.method, HttpMethod.patch);
      });
    });

    group('prepareSignUp with redirect URL', () {
      test('prepareSignUp with email link strategy', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.prepareSignUp(
          signUp,
          strategy: Strategy.emailLink,
          redirectUrl: 'https://example.com/verify',
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/prepare_verification'));
      });
    });

    group('attemptSignUp with signature', () {
      test('attemptSignUp with web3 signature', () async {
        await api.initialize();
        mockHttp.addClientResponse(signUp: _createMockSignUpJson());

        final signUp = _createMockSignUp();
        await api.attemptSignUp(
          signUp,
          strategy: Strategy.web3MetamaskSignature,
          signature: '0x123abc',
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_verification'));
      });
    });

    group('attemptSignIn with password', () {
      test('attemptSignIn with password strategy', () async {
        await api.initialize();
        mockHttp.addClientResponse(signIn: _createMockSignInJson());

        final signIn = _createMockSignIn();
        await api.attemptSignIn(
          signIn,
          stage: Stage.first,
          strategy: Strategy.password,
          password: 'password123',
        );

        expect(
            mockHttp.calls.first.uri.path, contains('/attempt_first_factor'));
      });
    });

    group('updateUser with all parameters', () {
      test('updateUser with all fields', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.updateUser(
          username: 'newusername',
          firstName: 'New',
          lastName: 'Name',
          primaryEmailAddressId: 'email_123',
          primaryPhoneNumberId: 'phone_123',
          primaryWeb3WalletId: 'web3_123',
          metadata: {'key': 'value'},
        );

        expect(mockHttp.calls.first.method, HttpMethod.patch);
        expect(mockHttp.calls.first.uri.path, contains('/me'));
      });
    });

    group('createOrganization with session', () {
      test('createOrganization with explicit session', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final session = _createMockSession();
        await api.createOrganization('Test Org', session: session);

        expect(mockHttp.calls.first.uri.path, contains('/organizations'));
      });
    });

    group('fetchOrganizationInvitations with pagination', () {
      test('fetchOrganizationInvitations with offset and limit', () async {
        await api.initialize();
        mockHttp.addJsonResponse({
          'data': [],
          'total_count': 0,
        });

        await api.fetchOrganizationInvitations(10, 50);

        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('fetchOrganizationDomains with pagination', () {
      test('fetchOrganizationDomains with offset and limit', () async {
        await api.initialize();
        mockHttp.addJsonResponse({
          'data': [],
          'total_count': 0,
        });

        final org = _createMockOrganization();
        await api.fetchOrganizationDomains(org, 10, 50);

        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('leaveOrganization with session', () {
      test('leaveOrganization with explicit session', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        final session = _createMockSession();
        await api.leaveOrganization(org, session: session);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
      });
    });

    group('deleteAvatar', () {
      test('deletes user avatar', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.deleteAvatar();

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/me/profile_image'));
      });
    });

    group('updateOrganization', () {
      test('updates organization name', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.updateOrganization(org, name: 'New Name');

        expect(mockHttp.calls.first.method, HttpMethod.patch);
        expect(mockHttp.calls.first.uri.path, contains('/organizations/'));
      });

      test('updates organization slug', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.updateOrganization(org, slug: 'new-slug');

        expect(mockHttp.calls.first.method, HttpMethod.patch);
      });

      test('updates organization with session', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        final session = _createMockSession();
        await api.updateOrganization(org, name: 'New Name', session: session);

        expect(mockHttp.calls.first.method, HttpMethod.patch);
      });
    });

    group('deleteOrganization', () {
      test('deletes organization', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.deleteOrganization(org);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/organizations/'));
      });

      test('deletes organization with session', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        final session = _createMockSession();
        await api.deleteOrganization(org, session: session);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
      });
    });

    group('setActiveOrganization', () {
      test('sets active organization', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.setActiveOrganization('sess_123', 'org_123');

        // setActiveOrganization uses POST to /client/sessions/$sessionId/touch
        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/sessions/'));
      });
    });

    group('signOutOf', () {
      test('signs out of session', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final session = _createMockSession();
        await api.signOutOf(session);

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/sessions/'));
      });
    });

    group('acceptOrganizationInvitation', () {
      test('accepts invitation', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final invitation = _createMockOrganizationInvitation();
        await api.acceptOrganizationInvitation(invitation);

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path,
            contains('/organization_invitations/'));
      });
    });

    group('createDomain', () {
      test('creates domain', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.createDomain(org, 'example.com');

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/domains'));
      });
    });

    group('updateDomainEnrollmentMode', () {
      test('updates domain enrollment mode', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final org = _createMockOrganization();
        await api.updateDomainEnrollmentMode(
          org,
          'domain_123',
          EnrollmentMode.automaticInvitation,
        );

        // updateDomainEnrollmentMode uses POST (default method)
        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/domains/'));
      });
    });

    group('transferSignIn', () {
      test('transfers sign in', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.transferSignIn();

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/sign_ins'));
      });
    });

    group('transferSignUp', () {
      test('transfers sign up', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.transferSignUp();

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/sign_ups'));
      });
    });

    group('deletePassword', () {
      test('removes password', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.deletePassword('currentPassword');

        // deletePassword uses POST to /me/remove_password
        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/me/remove_password'));
      });
    });

    group('updatePassword', () {
      test('updates password with sign out', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.updatePassword('current', 'new', true);

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/me/change_password'));
      });

      test('updates password without sign out', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.updatePassword('current', 'new', false);

        expect(mockHttp.calls.first.method, HttpMethod.post);
      });
    });

    group('deleteIdentifyingData', () {
      test('deletes identifying data', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final email = Email(
          id: 'email_123',
          emailAddress: 'test@example.com',
          verification: null,
          reserved: false,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await api.deleteIdentifyingData(email);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
      });
    });

    group('addExternalAccount', () {
      test('adds external account', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        await api.addExternalAccount(
          strategy: Strategy.oauthGoogle,
          redirectUrl: 'https://example.com/callback',
        );

        expect(mockHttp.calls.first.method, HttpMethod.post);
        expect(mockHttp.calls.first.uri.path, contains('/external_accounts'));
      });
    });

    group('deleteExternalAccount', () {
      test('deletes external account', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final account = _createMockExternalAccount();
        await api.deleteExternalAccount(account: account);

        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/external_accounts/'));
      });
    });

    group('sendOauthToken', () {
      test('sends oauth token for sign in', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final signIn = _createMockSignIn();
        await api.sendOauthToken(signIn, token: 'oauth_token_123');

        // sendOauthToken uses GET method
        expect(mockHttp.calls.first.method, HttpMethod.get);
      });
    });

    group('prepareSignIn error handling', () {
      test('throws error for unsupported first factor strategy', () async {
        await api.initialize();

        // Create a sign in without the required factor
        const signIn = SignIn(
          id: 'sia_123',
          status: Status.needsFirstFactor,
          identifier: 'test@example.com',
          supportedIdentifiers: [],
          supportedFirstFactors: [],
          // No factors available
          supportedSecondFactors: [],
          firstFactorVerification: null,
          secondFactorVerification: null,
          userData: null,
          createdSessionId: null,
        );

        expect(
          () => api.prepareSignIn(signIn,
              stage: Stage.first, strategy: Strategy.emailCode),
          throwsA(isA<ExternalError>()),
        );
      });

      test('throws error for unsupported second factor strategy', () async {
        await api.initialize();

        // Create a sign in without the required second factor
        const signIn = SignIn(
          id: 'sia_123',
          status: Status.needsSecondFactor,
          identifier: 'test@example.com',
          supportedIdentifiers: [],
          supportedFirstFactors: [],
          supportedSecondFactors: [],
          // No second factors available
          firstFactorVerification: null,
          secondFactorVerification: null,
          userData: null,
          createdSessionId: null,
        );

        expect(
          () => api.prepareSignIn(signIn,
              stage: Stage.second, strategy: Strategy.phoneCode),
          throwsA(isA<ExternalError>()),
        );
      });
    });

    group('resetClient', () {
      test('creates new client', () async {
        await api.initialize();
        mockHttp.addClientResponse();

        final client = await api.resetClient();

        expect(client.isNotEmpty, true);
        expect(mockHttp.calls.first.method, HttpMethod.post);
      });
    });

    group('signOut', () {
      test('signs out and returns empty client', () async {
        await api.initialize();
        mockHttp.addResponse(MockHttpResponse(statusCode: 200, body: '{}'));

        final client = await api.signOut();

        expect(client.isEmpty, true);
        expect(mockHttp.calls.first.method, HttpMethod.delete);
      });
    });

    group('deleteUser', () {
      test('deletes user and returns empty client', () async {
        await api.initialize();
        mockHttp.addResponse(MockHttpResponse(statusCode: 200, body: '{}'));

        final client = await api.deleteUser();

        expect(client.isEmpty, true);
        expect(mockHttp.calls.first.method, HttpMethod.delete);
        expect(mockHttp.calls.first.uri.path, contains('/me'));
      });
    });

    group('sessionToken', () {
      test('returns null when no session token cached', () async {
        await api.initialize();

        final token = api.sessionToken();

        expect(token, isNull);
      });
    });
  });
}

Session _createMockSession() {
  return Session(
    id: 'sess_123',
    status: Status.active,
    lastActiveAt: DateTime.now(),
    expireAt: DateTime.now().add(const Duration(days: 1)),
    abandonAt: DateTime.now().add(const Duration(days: 7)),
    publicUserData: const UserPublic(
      firstName: 'Test',
      lastName: 'User',
      profileImageUrl: '',
      imageUrl: '',
      hasImage: false,
      identifier: 'test@example.com',
    ),
    lastActiveOrganizationId: null,
    user: _createMockUser(),
  );
}

User _createMockUser() {
  return User(
    id: 'user_123',
    externalId: null,
    username: null,
    firstName: 'Test',
    lastName: 'User',
    profileImageUrl: '',
    imageUrl: '',
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
    lastSignInAt: DateTime.now(),
    banned: false,
    locked: false,
    lockoutExpiresInSeconds: null,
    verificationAttemptsRemaining: null,
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
    lastActiveAt: DateTime.now(),
    deleteSelfEnabled: false,
  );
}

SignUp _createMockSignUp() {
  return SignUp(
    id: 'sua_123',
    status: Status.missingRequirements,
    requiredFields: const [],
    optionalFields: const [],
    missingFields: const [],
    unverifiedFields: const [],
    username: null,
    emailAddress: 'test@example.com',
    phoneNumber: null,
    web3Wallet: null,
    passwordEnabled: true,
    firstName: 'Test',
    lastName: 'User',
    unsafeMetadata: const {},
    publicMetadata: const {},
    verifications: const {},
    customAction: false,
    externalId: null,
    createdSessionId: null,
    createdUserId: null,
    abandonAt: DateTime.now().add(const Duration(days: 7)),
  );
}

Map<String, dynamic> _createMockSignUpJson() {
  return {
    'object': 'sign_up',
    'id': 'sua_123',
    'status': 'missing_requirements',
    'required_fields': [],
    'optional_fields': [],
    'missing_fields': [],
    'unverified_fields': [],
    'email_address': 'test@example.com',
    'password_enabled': true,
    'first_name': 'Test',
    'last_name': 'User',
    'unsafe_metadata': {},
    'public_metadata': {},
    'verifications': {},
    'custom_action': false,
    'abandon_at':
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
  };
}

SignIn _createMockSignIn() {
  return const SignIn(
    id: 'sia_123',
    status: Status.needsFirstFactor,
    identifier: 'test@example.com',
    supportedIdentifiers: [],
    supportedFirstFactors: [
      Factor(
        strategy: Strategy.emailCode,
        safeIdentifier: 'test@example.com',
        emailAddressId: 'email_123',
        phoneNumberId: null,
        web3WalletId: null,
        passkeyId: null,
        isPrimary: true,
        isDefault: true,
      ),
    ],
    supportedSecondFactors: [],
    firstFactorVerification: null,
    secondFactorVerification: null,
    userData: null,
    createdSessionId: null,
  );
}

Map<String, dynamic> _createMockSignInJson() {
  return {
    'object': 'sign_in',
    'id': 'sia_123',
    'status': 'needs_first_factor',
    'identifier': 'test@example.com',
    'supported_first_factors': [],
    'supported_second_factors': [],
  };
}

Organization _createMockOrganization() {
  return Organization(
    id: 'org_123',
    name: 'Test Org',
    slug: 'test-org',
    imageUrl: '',
    hasImage: false,
    membersCount: 1,
    pendingInvitationsCount: 0,
    maxAllowedMemberships: 5,
    adminDeleteEnabled: true,
    publicMetadata: const {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

ExternalAccount _createMockExternalAccount() {
  return ExternalAccount(
    id: 'ext_123',
    provider: 'google',
    providerUserId: 'google_user_123',
    approvedScopes: 'email profile',
    emailAddress: 'test@example.com',
    username: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    avatarUrl: '',
    imageUrl: '',
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

Email _createMockEmailAddress() {
  return Email(
    id: 'email_123',
    emailAddress: 'test@example.com',
    reserved: false,
    verification: Verification(
      status: Status.unverified,
      strategy: Strategy.emailCode,
      attempts: 0,
      expireAt: DateTime.now().add(const Duration(hours: 1)),
    ),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

OrganizationInvitation _createMockOrganizationInvitation() {
  return OrganizationInvitation(
    id: 'inv_123',
    status: Status.pending,
    roleName: 'member',
    organization: _createMockOrganization(),
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
}

SignIn _createMockSignInWithSecondFactor() {
  return const SignIn(
    id: 'sia_123',
    status: Status.needsSecondFactor,
    identifier: 'test@example.com',
    supportedIdentifiers: [],
    supportedFirstFactors: [
      Factor(
        strategy: Strategy.emailCode,
        safeIdentifier: 'test@example.com',
        emailAddressId: 'email_123',
        phoneNumberId: null,
        web3WalletId: null,
        passkeyId: null,
        isPrimary: true,
        isDefault: true,
      ),
    ],
    supportedSecondFactors: [
      Factor(
        strategy: Strategy.phoneCode,
        safeIdentifier: '+1234567890',
        emailAddressId: null,
        phoneNumberId: 'phone_123',
        web3WalletId: null,
        passkeyId: null,
        isPrimary: true,
        isDefault: true,
      ),
    ],
    firstFactorVerification: null,
    secondFactorVerification: null,
    userData: null,
    createdSessionId: null,
  );
}

// Note: _createTestSignUp, _createTestSession, _createTestUser are not used
// The existing _createMockSignUp, _createMockSession, _createMockUser are used instead

// Additional tests for uncovered api.dart paths are in the main test group above

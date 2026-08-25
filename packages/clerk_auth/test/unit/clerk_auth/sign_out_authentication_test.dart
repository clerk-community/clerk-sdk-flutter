import 'package:clerk_auth/clerk_auth.dart';

import '../../test_helpers.dart';

void main() {
  group('signOut authentication', () {
    late MockHttpService mockHttp;
    late Auth auth;

    setUp(() async {
      mockHttp = MockHttpService();
      auth = Auth(
        config: TestAuthConfig(
          publishableKey: TestAuthConfig.kPublishableKey,
          httpService: mockHttp,
        ),
      );
      mockHttp.addAuthenticatedClientWithSessionResponse();
      mockHttp.addEnvironmentResponse();
      await auth.initialize();
    });

    tearDown(() {
      auth.terminate();
    });

    test('the DELETE that signs out carries the client token', () async {
      expect(auth.isSignedIn, true);

      mockHttp.addEmptyResponse();
      await auth.signOut();

      final delete = mockHttp.calls.lastWhere(
        (call) => call.method == HttpMethod.delete,
      );

      // Without the Authorization header the request identifies no client, so the back end
      // revokes nothing and answers 200 anyway. The session then outlives the sign-out, which
      // reports success regardless -- a local forget rather than a revocation.
      final header = delete.headers?['authorization'] ??
          delete.headers?['Authorization'];
      expect(header?.isNotEmpty, true);
    });

    test('local credentials are dropped even when the request fails', () async {
      mockHttp.isOffline = true;

      await auth.signOut();

      expect(auth.isSignedIn, false);
    });
  });
}

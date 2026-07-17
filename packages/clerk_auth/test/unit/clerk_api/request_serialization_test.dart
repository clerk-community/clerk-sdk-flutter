import 'dart:math' as math;

import 'package:clerk_auth/clerk_auth.dart';
import 'package:http/http.dart' show Response;

import '../../test_helpers.dart';

// Valid publishable key with base64-encoded domain (somedomain.com)
const _validPublishableKey = 'pk_test_c29tZWRvbWFpbi5jb20K';

/// An [MockHttpService] that records how many requests are in flight
/// simultaneously, so tests can assert that requests are serialised.
class _CountingHttpService extends MockHttpService {
  int _inFlight = 0;

  /// The largest number of requests that were ever in flight at once
  int maxInFlight = 0;

  @override
  Future<Response> send(
    HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) async {
    _inFlight += 1;
    maxInFlight = math.max(maxInFlight, _inFlight);
    try {
      // hold the request open long enough for concurrent callers to overlap
      await Future.delayed(const Duration(milliseconds: 20));
      return await super.send(
        method,
        uri,
        headers: headers,
        params: params,
        body: body,
      );
    } finally {
      _inFlight -= 1;
    }
  }
}

void main() {
  group('Api request serialisation', () {
    // The client token is a rotating credential: concurrent requests can
    // present a token that another response has just rotated away, which
    // the back end answers by minting a fresh session-less client. All
    // front-end API requests are therefore serialised.
    test('concurrent requests are sent one at a time', () async {
      final http = _CountingHttpService();
      http.addClientResponse(clientId: 'client_A');
      http.addEnvironmentResponse();
      for (var i = 0; i < 3; i++) {
        http.addClientResponse(clientId: 'client_A');
      }

      final auth = Auth(
        config: TestAuthConfig(
          publishableKey: _validPublishableKey,
          httpService: http,
        ),
      );

      await auth.initialize();
      http.maxInFlight = 0;

      await Future.wait([
        auth.refreshClient(),
        auth.refreshClient(),
        auth.refreshClient(),
      ]);

      // requests must be serialised so that no request is sent with a
      // token that a concurrent response can rotate away
      expect(http.maxInFlight, 1);

      auth.terminate();
    });
  });
}

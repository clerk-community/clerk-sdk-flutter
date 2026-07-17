import 'package:clerk_auth/clerk_auth.dart';

import '../test_helpers.dart';

void main() {
  group('IdTokenProvider', () {
    test('apple returns correct strategy', () {
      expect(
        IdTokenProvider.apple.strategy,
        equals(Strategy.oauthTokenApple),
      );
    });
    test('google returns correct strategy', () {
      expect(
        IdTokenProvider.google.strategy,
        equals(Strategy.oauthTokenGoogle),
      );
    });
  });
}

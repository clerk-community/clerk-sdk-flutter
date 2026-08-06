import 'package:clerk_auth/src/clerk_auth/clerk_error.dart';
import 'package:clerk_auth/src/models/client/strategy.dart';
import 'package:clerk_auth/src/models/enums.dart';

import '../../test_helpers.dart';

void main() {
  group('Strategy', () {
    group('constants', () {
      test('has correct numerical code length', () {
        expect(Strategy.numericalCodeLength, 6);
      });

      test('has correct textual code length', () {
        expect(Strategy.textualCodeLength, 8);
      });
    });

    group('fromJson', () {
      test('returns known strategy for known names', () {
        expect(Strategy.fromJson('password'), Strategy.password);
        expect(Strategy.fromJson('email_code'), Strategy.emailCode);
        expect(Strategy.fromJson('phone_code'), Strategy.phoneCode);
      });

      test('returns unknown for unrecognized names', () {
        expect(Strategy.fromJson('not_a_strategy'), Strategy.unknown);
      });
    });

    group('named', () {
      test('returns verification strategies', () {
        expect(Strategy.named('password'), Strategy.password);
        expect(Strategy.named('email_code'), Strategy.emailCode);
        expect(Strategy.named('email_link'), Strategy.emailLink);
        expect(Strategy.named('phone_code'), Strategy.phoneCode);
        expect(Strategy.named('passkey'), Strategy.passkey);
        expect(Strategy.named('totp'), Strategy.totp);
        expect(Strategy.named('backup_code'), Strategy.backupCode);
      });

      test('returns identification strategies', () {
        expect(Strategy.named('email_address'), Strategy.emailAddress);
        expect(Strategy.named('phone_number'), Strategy.phoneNumber);
        expect(Strategy.named('username'), Strategy.username);
      });

      test('creates oauth strategies dynamically', () {
        final strategy = Strategy.named('oauth_linkedin');
        expect(strategy, isNotNull);
        expect(strategy!.name, 'oauth');
        expect(strategy.provider, 'linkedin');
      });

      test('creates oauth_custom strategies dynamically', () {
        final strategy = Strategy.named('oauth_custom_myapp');
        expect(strategy, isNotNull);
        expect(strategy!.name, 'oauth_custom');
        expect(strategy.provider, 'myapp');
      });

      test('creates oauth_token strategies dynamically', () {
        final strategy = Strategy.named('oauth_token_facebook');
        expect(strategy, isNotNull);
        expect(strategy!.name, 'oauth_token');
        expect(strategy.provider, 'facebook');
      });

      test('returns null for completely unknown names', () {
        expect(Strategy.named('completely_unknown'), isNull);
      });
    });

    group('boolean properties', () {
      test('isUnknown', () {
        expect(Strategy.unknown.isUnknown);
        expect(Strategy.password.isUnknown, false);
      });

      test('isKnown', () {
        expect(Strategy.password.isKnown);
        expect(Strategy.unknown.isKnown, false);
      });

      test('isPassword', () {
        expect(Strategy.password.isPassword);
        expect(Strategy.emailCode.isPassword, false);
      });

      test('isEmailLink', () {
        expect(Strategy.emailLink.isEmailLink);
        expect(Strategy.emailCode.isEmailLink, false);
      });

      test('isOauth', () {
        expect(Strategy.oauthGoogle.isOauth);
        expect(Strategy.oauthApple.isOauth);
        expect(Strategy.oauthTokenApple.isOauth);
        expect(Strategy.password.isOauth, false);
      });

      test('isPhone', () {
        expect(Strategy.phoneCode.isPhone);
        expect(Strategy.phoneNumber.isPhone);
        expect(Strategy.resetPasswordPhoneCode.isPhone);
        expect(Strategy.emailCode.isPhone, false);
      });

      test('isPasswordResetter', () {
        expect(Strategy.resetPasswordEmailCode.isPasswordResetter);
        expect(Strategy.resetPasswordPhoneCode.isPasswordResetter);
        expect(Strategy.password.isPasswordResetter, false);
      });

      test('requiresPassword', () {
        expect(Strategy.password.requiresPassword);
        expect(Strategy.resetPasswordEmailCode.requiresPassword);
        expect(Strategy.resetPasswordPhoneCode.requiresPassword);
        expect(Strategy.emailCode.requiresPassword, false);
      });

      test('requiresNumericalCode', () {
        expect(Strategy.emailCode.requiresNumericalCode);
        expect(Strategy.phoneCode.requiresNumericalCode);
        expect(Strategy.totp.requiresNumericalCode);
        expect(Strategy.password.requiresNumericalCode, false);
      });

      test('requiresTextualCode', () {
        expect(Strategy.backupCode.requiresTextualCode);
        expect(Strategy.emailCode.requiresTextualCode, false);
      });

      test('requiresCode', () {
        expect(Strategy.emailCode.requiresCode);
        expect(Strategy.backupCode.requiresCode);
        expect(Strategy.password.requiresCode, false);
      });

      test('requiresPreparation', () {
        expect(Strategy.emailCode.requiresPreparation);
        expect(Strategy.phoneCode.requiresPreparation);
        expect(Strategy.password.requiresPreparation, false);
      });

      test('requiresRedirect', () {
        expect(Strategy.oauthGoogle.requiresRedirect);
        expect(Strategy.emailLink.requiresRedirect);
        expect(Strategy.enterpriseSSO.requiresRedirect);
        expect(Strategy.password.requiresRedirect, false);
      });

      test('isEnterpriseSSO', () {
        expect(Strategy.enterpriseSSO.isEnterpriseSSO);
        expect(Strategy.oauthGoogle.isEnterpriseSSO, false);
      });

      test('isSSO', () {
        expect(Strategy.oauthGoogle.isSSO);
        expect(Strategy.enterpriseSSO.isSSO);
        expect(Strategy.password.isSSO, false);
        // Bug 421: saml is returned by the server after enterprise_sso round-trip
        // and must be treated as SSO so parseDeepLink completes sign-in.
        expect(Strategy.saml.isSSO, isTrue);
      });
    });

    group('mightAccept', () {
      test('accepts valid 6-digit codes for numerical code strategies', () {
        expect(Strategy.emailCode.mightAccept('123456'));
        expect(Strategy.phoneCode.mightAccept('000000'));
        expect(Strategy.totp.mightAccept('999999'));
      });

      test('rejects invalid codes for numerical code strategies', () {
        expect(Strategy.emailCode.mightAccept('12345'), false); // too short
        expect(Strategy.emailCode.mightAccept('1234567'), false); // too long
        expect(Strategy.emailCode.mightAccept('12345a'), false); // has letter
        expect(Strategy.emailCode.mightAccept(null), false);
        expect(Strategy.emailCode.mightAccept(''), false);
      });

      test('accepts valid 8-character codes for textual code strategies', () {
        expect(Strategy.backupCode.mightAccept('abcd1234'));
        expect(Strategy.backupCode.mightAccept('12345678'));
        expect(Strategy.backupCode.mightAccept('aaaaaaaa'));
      });

      test('rejects invalid codes for textual code strategies', () {
        expect(Strategy.backupCode.mightAccept('abcd123'), false); // too short
        expect(Strategy.backupCode.mightAccept('abcd12345'), false); // too long
        expect(Strategy.backupCode.mightAccept('ABCD1234'), false); // uppercase
        expect(Strategy.backupCode.mightAccept(null), false);
      });

      test('returns false for strategies that do not require codes', () {
        expect(Strategy.password.mightAccept('123456'), false);
        expect(Strategy.oauthGoogle.mightAccept('123456'), false);
      });
    });

    group('forUserAttribute', () {
      test('returns phoneCode for phoneNumber attribute', () {
        expect(Strategy.forUserAttribute(UserAttribute.phoneNumber),
            Strategy.phoneCode);
      });

      test('returns emailCode for emailAddress attribute', () {
        expect(Strategy.forUserAttribute(UserAttribute.emailAddress),
            Strategy.emailCode);
      });

      test('throws ClerkError for unsupported attributes', () {
        expect(
          () => Strategy.forUserAttribute(UserAttribute.username),
          throwsA(isA<ClerkError>()),
        );
      });
    });

    group('toString and toJson', () {
      test('toString returns name for simple strategies', () {
        expect(Strategy.password.toString(), 'password');
        expect(Strategy.emailCode.toString(), 'email_code');
      });

      test('toString combines name and provider for oauth strategies', () {
        expect(Strategy.oauthGoogle.toString(), 'oauth_google');
        expect(Strategy.oauthApple.toString(), 'oauth_apple');
        expect(Strategy.oauthTokenApple.toString(), 'oauth_token_apple');
      });

      test('toJson returns same as toString', () {
        expect(Strategy.password.toJson(), Strategy.password.toString());
        expect(Strategy.oauthGoogle.toJson(), Strategy.oauthGoogle.toString());
      });
    });

    group('oauth strategies collection', () {
      test('contains all predefined oauth strategies', () {
        expect(Strategy.oauthStrategies.containsValue(Strategy.oauthGoogle));
        expect(Strategy.oauthStrategies.containsValue(Strategy.oauthApple));
        expect(Strategy.oauthStrategies.containsValue(Strategy.oauthGithub));
        expect(Strategy.oauthStrategies.containsValue(Strategy.oauthFacebook));
        expect(Strategy.oauthStrategies.containsValue(Strategy.oauthX));
      });
    });
  });
}

import 'package:clerk_auth/clerk_auth.dart';

import '../../test_helpers.dart';

void main() {
  group('Environment', () {
    group('empty', () {
      test('isEmpty returns true for empty environment', () {
        expect(Environment.empty.isEmpty);
      });

      test('isNotEmpty returns false for empty environment', () {
        expect(Environment.empty.isNotEmpty, false);
      });

      test('maintenanceMode is false by default', () {
        expect(Environment.empty.maintenanceMode, false);
      });
    });

    group('hasPasswordStrategy', () {
      test('returns false when password not in first factors', () {
        expect(Environment.empty.hasPasswordStrategy, false);
      });

      test('returns true when password is in first factors', () {
        const env = Environment(
          config: Config(
            firstFactors: [Strategy.password],
          ),
        );
        expect(env.hasPasswordStrategy);
      });
    });

    group('strategies', () {
      test('returns identification strategies from config', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [
              Strategy.emailAddress,
              Strategy.username
            ],
          ),
        );
        expect(env.strategies.length, 2);
        expect(env.strategies.contains(Strategy.emailAddress));
        expect(env.strategies.contains(Strategy.username));
      });
    });

    group('identificationStrategies', () {
      test('filters to only email, username, and phone strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [
              Strategy.emailAddress,
              Strategy.username,
              Strategy.phoneNumber,
              Strategy.oauthGoogle,
              Strategy.password,
            ],
          ),
        );
        final strategies = env.identificationStrategies.toList();
        expect(strategies.length, 3);
        expect(strategies.contains(Strategy.emailAddress));
        expect(strategies.contains(Strategy.username));
        expect(strategies.contains(Strategy.phoneNumber));
        expect(strategies.contains(Strategy.oauthGoogle), false);
      });
    });

    group('hasIdentificationStrategies', () {
      test('returns false when no identification strategies', () {
        expect(Environment.empty.hasIdentificationStrategies, false);
      });

      test('returns true when has identification strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [Strategy.emailAddress],
          ),
        );
        expect(env.hasIdentificationStrategies);
      });
    });

    group('oauthStrategies', () {
      test('filters to only oauth strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [
              Strategy.emailAddress,
              Strategy.oauthGoogle,
              Strategy.oauthApple,
            ],
          ),
        );
        final strategies = env.oauthStrategies.toList();
        expect(strategies.length, 2);
        expect(strategies.contains(Strategy.oauthGoogle));
        expect(strategies.contains(Strategy.oauthApple));
        expect(strategies.contains(Strategy.emailAddress), false);
      });
    });

    group('hasOauthStrategies', () {
      test('returns false when no oauth strategies', () {
        expect(Environment.empty.hasOauthStrategies, false);
      });

      test('returns true when has oauth strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [Strategy.oauthGoogle],
          ),
        );
        expect(env.hasOauthStrategies);
      });
    });

    group('signUpIsOpen', () {
      Environment envWithMode(String mode) => Environment(
            user: UserSettings(signUp: SignUpSettings(mode: mode)),
          );

      test('is true only when the instance is public', () {
        expect(envWithMode('public').signUpIsOpen, true);
      });

      test('is false when sign-up needs an invitation or a waitlist', () {
        // Neither flow is implemented here, so on these instances the sign-up form can only
        // produce a rejection from the API.
        expect(envWithMode('restricted').signUpIsOpen, false);
        expect(envWithMode('waitlist').signUpIsOpen, false);
      });

      test('is false for a mode it does not recognise, and for none at all', () {
        // Strict on purpose: an unrecognised value is likelier to be a mode this does not know
        // about than a reason to offer an account to everyone. `Environment.empty` carries no
        // mode at all, which is the state before the environment has been fetched.
        expect(envWithMode('something_new').signUpIsOpen, false);
        expect(envWithMode('').signUpIsOpen, false);
        expect(Environment.empty.signUpIsOpen, false);
      });
    });

    group('otherStrategies', () {
      test('filters to other strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [
              Strategy.emailAddress,
              Strategy.emailCode,
              Strategy.phoneCode,
            ],
          ),
        );
        final strategies = env.otherStrategies.toList();
        expect(strategies.contains(Strategy.emailCode));
        expect(strategies.contains(Strategy.phoneCode));
      });
    });

    group('hasOtherStrategies', () {
      test('returns false when only oauth strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [
              Strategy.oauthGoogle,
              Strategy.oauthApple
            ],
          ),
        );
        expect(env.hasOtherStrategies, false);
      });

      test('returns false when only password strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [Strategy.password],
          ),
        );
        expect(env.hasOtherStrategies, false);
      });

      test('returns true when has other strategies', () {
        const env = Environment(
          config: Config(
            identificationStrategies: [Strategy.emailCode, Strategy.phoneCode],
          ),
        );
        expect(env.hasOtherStrategies);
      });
    });

    group('fromJson and toJson', () {
      test('round-trip serialization produces valid json', () {
        final json = Environment.empty.toJson();
        expect(json, isA<Map<String, dynamic>>());
      });

      test('fromJson creates Environment from json', () {
        final json = Environment.empty.toJson();
        final env = Environment.fromJson(json);
        expect(env, isA<Environment>());
      });

      test('round-trip preserves maintenanceMode', () {
        const env = Environment(maintenanceMode: true);
        final json = env.toJson();
        final restored = Environment.fromJson(json);
        expect(restored.maintenanceMode);
      });
    });
  });
}

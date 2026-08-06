import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'sign_in_with_google_common.dart';

// Integration test: Sign In with Google (OAuth)
//
// Verifies the full Google OAuth sign-in flow using Patrol's native automation:
//   1. Launches the example app and navigates to the Clerk sign-in screen.
//   2. Taps the Google OAuth button (identified by its connection strategy).
//   3. On Chrome's "Choose an account" page, selects the test Google account
//      supplied via --dart-define=GOOGLE_EMAIL=<email>.
//   4. Taps "Continue" on the Google consent screen to grant access.
//   5. Waits for the app to return to the foreground via deep link and confirms
//      the signed-in UI (Profile, Sign out, Organizations) is visible.
//
// Run with:
//   patrol test --target patrol_test/sign_in_with_google_test.dart \
//     --dart-define=publishable_key=<key> \
//     --dart-define=GOOGLE_EMAIL=<email> \
//     --no-clear-test-steps
void main() {
  const googleEmail = String.fromEnvironment('GOOGLE_EMAIL');

  patrolTest(
    'Sign in with Google & sign out',
    platformAutomatorConfig: PlatformAutomatorConfig.fromOptions(
      findTimeout: const Duration(seconds: 30),
    ),
    ($) async {
      assert(
        googleEmail.isNotEmpty,
        'Provide --dart-define=GOOGLE_EMAIL=<email>',
      );

      await launchAndTapGoogleSignIn($);

      // On iOS, OAuth opens in Safari (external app); on Android it opens in Chrome.
      // UiAutomator2 searches the full screen, but XCTest defaults to the app under
      // test — so we must specify Safari's bundle ID explicitly on iOS.
      final browserAppId = Platform.isIOS ? 'com.apple.mobilesafari' : null;
      // Browser opens Google's "Choose an account" page — tap the test email
      await $.platform.tap(Selector(text: googleEmail), appId: browserAppId);

      await Future.delayed(const Duration(milliseconds: 600));

      // Tap "Continue" on the Google consent screen
      await $.platform.tap(Selector(text: 'Continue'), appId: browserAppId);

      if (Platform.isIOS) {
        await $.platform.tap(Selector(text: 'Open'), appId: browserAppId);
      }

      $.log('Should return to app and be signed in');

      // App returns to foreground via deep link; pumpAndSettle settles immediately
      // because Flutter has no pending frames until the deep link is processed.
      // Use waitUntilVisible to poll until the signed-in UI actually appears.

      await $('Profile').waitUntilVisible(timeout: const Duration(seconds: 10));

      $.log('Waiting for signed-in UI to settle');

      await $.pumpAndSettle();

      expect($('Profile'), findsOneWidget);
      expect($('Sign out'), findsOneWidget);
      expect($('Organizations'), findsOneWidget);

      await signOut($);

      await $(googleSocialButtonSelector)
          .waitUntilVisible(timeout: const Duration(seconds: 5));

      expect(googleSocialButtonSelector, findsOneWidget);
    },
  );
}

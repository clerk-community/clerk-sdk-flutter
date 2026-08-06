import 'dart:async';
import 'dart:convert';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;

import '../test_support/test_support.dart';

void main() {
  group('ClerkAuthState', () {
    group('create', () {
      test('creates an initialized ClerkAuthState', () async {
        final authState = await createSignedOutAuthState();
        expect(authState, isA<ClerkAuthState>());
        expect(authState.config, isA<ClerkAuthConfig>());
        authState.terminate();
      });

      test('creates signed-in state with user', () async {
        final authState = await createSignedInAuthState();
        expect(authState.user, isNotNull);
        authState.terminate();
      });

      test('creates signed-out state without user', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.user, isNull);
        authState.terminate();
      });
    });

    group('handleError', () {
      test('adds error to stream when listener is present', () async {
        final authState = await createSignedOutAuthState();
        final errors = <clerk.ClerkError>[];
        final subscription = authState.errorStream.listen(errors.add);

        final error = clerk.ClerkError.clientAppError(message: 'Test error');
        authState.handleError(error);

        await Future.delayed(Duration.zero);
        expect(errors.length, 1);
        expect(errors.first.message, 'Test error');

        await subscription.cancel();
        authState.terminate();
      });
    });

    group('update', () {
      test('notifies listeners when unlocked', () async {
        final authState = await createSignedOutAuthState();
        var notified = false;
        authState.addListener(() => notified = true);

        authState.update();

        expect(notified, isTrue);
        authState.terminate();
      });
    });

    group('passwordIsValid', () {
      test('returns false when password is null', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.passwordIsValid(null, null), isFalse);
        authState.terminate();
      });

      test('returns false when password is empty', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.passwordIsValid('', ''), isFalse);
        authState.terminate();
      });

      test('returns false when password and confirmation do not match',
          () async {
        final authState = await createSignedOutAuthState();
        expect(authState.passwordIsValid('password1', 'password2'), isFalse);
        authState.terminate();
      });

      test('returns true when password matches confirmation and meets criteria',
          () async {
        final authState = await createSignedOutAuthState();
        // The test environment has minimal password requirements
        expect(authState.passwordIsValid('password', 'password'), isTrue);
        authState.terminate();
      });
    });

    group('localizationsOf', () {
      testWidgets('returns localizations for context', (tester) async {
        final authState = await createSignedOutAuthState();
        late ClerkSdkLocalizations localizations;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                localizations = authState.localizationsOf(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(localizations, isA<ClerkSdkLocalizations>());
        authState.terminate();
      });
    });

    group('checkPassword', () {
      testWidgets('returns null for empty password', (tester) async {
        final authState = await createSignedOutAuthState();
        String? result;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                result = authState.checkPassword('', '', context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result, isNull);
        authState.terminate();
      });

      testWidgets('returns error for mismatched passwords', (tester) async {
        final authState = await createSignedOutAuthState();
        String? result;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                result =
                    authState.checkPassword('password1', 'password2', context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result, isNotNull);
        authState.terminate();
      });

      testWidgets('returns null for matching passwords', (tester) async {
        final authState = await createSignedOutAuthState();
        String? result;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                result =
                    authState.checkPassword('password', 'password', context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result, isNull);
        authState.terminate();
      });
    });

    group('safelyCall', () {
      testWidgets('executes callback successfully', (tester) async {
        final authState = await createSignedOutAuthState();
        var executed = false;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                authState.safelyCall(context, () async {
                  executed = true;
                });
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pump();

        expect(executed, isTrue);
        authState.terminate();
      });

      testWidgets('handles errors from callback', (tester) async {
        final authState = await createSignedOutAuthState();

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await expectLater(
                      authState.safelyCall(context, () async {
                        throw clerk.ClerkError.clientAppError(
                            message: 'Test error');
                      }),
                      throwsA(isA<clerk.ClerkError>()),
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Test'));
        await tester.pump();

        authState.terminate();
      });
    });

    group('config', () {
      test('returns ClerkAuthConfig', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.config, isA<ClerkAuthConfig>());
        authState.terminate();
      });

      test('config has publishableKey', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.config.publishableKey, isNotEmpty);
        authState.terminate();
      });
    });

    group('errorStream', () {
      test('is a broadcast stream', () async {
        final authState = await createSignedOutAuthState();
        expect(authState.errorStream.isBroadcast, isTrue);
        authState.terminate();
      });

      test('can have multiple listeners', () async {
        final authState = await createSignedOutAuthState();
        final errors1 = <clerk.ClerkError>[];
        final errors2 = <clerk.ClerkError>[];

        final sub1 = authState.errorStream.listen(errors1.add);
        final sub2 = authState.errorStream.listen(errors2.add);

        final error = clerk.ClerkError.clientAppError(message: 'Test error');
        authState.handleError(error);

        await Future.delayed(Duration.zero);
        expect(errors1.length, 1);
        expect(errors2.length, 1);

        await sub1.cancel();
        await sub2.cancel();
        authState.terminate();
      });
    });

    group('emailVerificationRedirectUri', () {
      testWidgets('returns null when email link not supported', (tester) async {
        final authState = await createSignedOutAuthState();
        Uri? result;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                result = authState.emailVerificationRedirectUri(context);
                return const SizedBox();
              },
            ),
          ),
        );

        // Default test environment doesn't support email link
        expect(result, isNull);
        authState.terminate();
      });
    });

    group('terminate', () {
      test('cleans up resources', () async {
        final authState = await createSignedOutAuthState();

        // Should not throw
        authState.terminate();
      });
    });

    group('signOut', () {
      test('signs out user', () async {
        final authState = await createSignedInAuthState();
        expect(authState.user, isNotNull);

        await authState.signOut();

        expect(authState.user, isNull);
        authState.terminate();
      });
    });

    group('ssoConnect', () {
      testWidgets(
        'completes without dialog when user has no unverified external accounts',
        (tester) async {
          final authState = await createSignedInAuthState();

          await tester.pumpWidget(
            TestClerkAuthWrapper(
              authState: authState,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await authState.ssoConnect(
                        context,
                        clerk.Strategy.oauthGoogle,
                      );
                    },
                    child: const Text('Connect'),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Connect'));
          await tester.pump();

          expect(find.byType(Dialog), findsNothing);
          authState.terminate();
        },
      );

      testWidgets('calls onError when connection fails', (tester) async {
        final config = TestClerkAuthConfig(
          httpService: _SsoErrorHttpService(
            failPaths: ['/me/external_accounts'],
          ),
        );
        final authState = await ClerkAuthState.create(config: config);
        clerk.ClerkError? capturedError;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await authState.ssoConnect(
                      context,
                      clerk.Strategy.oauthGoogle,
                      onError: (error) => capturedError = error,
                    );
                  },
                  child: const Text('Connect'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Connect'));
        await tester.pump();

        expect(capturedError, isNotNull);
        authState.terminate();
      });
    });

    group('refreshClient race condition', () {
      test('stale refreshClient() response overwrites signed-in client',
          () async {
        final now = DateTime.now();
        final signedInClient = createSignedInClient();
        final staleClient = clerk.Client(
          id: 'client_stale',
          sessions: const [],
          updatedAt: now.subtract(const Duration(seconds: 10)),
          createdAt: now.subtract(const Duration(hours: 1)),
        );

        final authState = await ClerkAuthState.create(
          config: TestClerkAuthConfig(
            httpService: _StaleRefreshHttpService(
              initialClient: signedInClient,
              staleClient: staleClient,
            ),
          ),
        );

        expect(authState.user, isNotNull,
            reason: 'should be signed in initially');

        await authState.refreshClient();

        expect(
          authState.user,
          isNotNull,
          reason: 'stale refreshClient() must not revert the signed-in client',
        );

        authState.terminate();
      });

      // Demonstrates the Guard 2 equal-timestamp loophole:
      // A stale client whose updatedAt exactly matches the current client's
      // updatedAt passes the `<` check and overwrites the signed-in state.
      test(
        'stale client with equal timestamp bypasses Guard 2 and overwrites signed-in state',
        () async {
          final signedInClient = createSignedInClient();
          final staleClient = clerk.Client(
            id: 'client_stale',
            sessions: const [],
            updatedAt:
                signedInClient.updatedAt, // same timestamp — `<` does not block
            createdAt: signedInClient.createdAt,
          );

          final authState = await ClerkAuthState.create(
            config: TestClerkAuthConfig(
              httpService: _StaleRefreshHttpService(
                initialClient: signedInClient,
                staleClient: staleClient,
              ),
            ),
          );

          expect(authState.user, isNotNull, reason: 'should start signed in');

          await authState.refreshClient();

          expect(
            authState.user,
            isNotNull,
            reason:
                'equal-timestamp stale refreshClient() must not overwrite the signed-in state',
          );

          authState.terminate();
        },
      );

      // Demonstrates the missing Guard 1:
      // refreshClient() runs even while safelyCall holds the lock. When the
      // stale client (equal timestamp) passes Guard 2's `<` check, it replaces
      // the signed-in client. When the lock then releases, update() fires with
      // the stale (signed-out) client.
      testWidgets(
        'refreshClient during safelyCall corrupts state when lock releases without Guard 1',
        (tester) async {
          final signedInClient = createSignedInClient();
          final staleClient = clerk.Client(
            id: 'client_stale',
            sessions: const [],
            updatedAt: signedInClient.updatedAt, // same timestamp
            createdAt: signedInClient.createdAt,
          );

          final authState = await ClerkAuthState.create(
            config: TestClerkAuthConfig(
              httpService: _StaleRefreshHttpService(
                initialClient: signedInClient,
                staleClient: staleClient,
              ),
            ),
          );

          expect(authState.user, isNotNull, reason: 'should start signed in');

          final safelyCallCompleter = Completer<void>();
          var lockStarted = false;

          await tester.pumpWidget(
            TestClerkAuthWrapper(
              authState: authState,
              child: Builder(builder: (context) {
                if (!lockStarted) {
                  lockStarted = true;
                  // Start safelyCall — acquires the lock and suspends at the
                  // completer, keeping the lock held for the rest of the test.
                  authState.safelyCall(
                      context, () => safelyCallCompleter.future);
                }
                return const SizedBox();
              }),
            ),
          );

          // Lock is now held. Without Guard 1, refreshClient() runs anyway,
          // applies the equal-timestamp stale client (Guard 2 `<` doesn't block
          // equal timestamps), and suppresses update() via the lock.
          await authState.refreshClient();

          // Releasing the lock causes safelyCall's finally block to call
          // update() — which fires notifyListeners() with whatever client is
          // current. Without the fix that client is the stale one (no user).
          safelyCallCompleter.complete();
          await tester.pump();

          expect(
            authState.user,
            isNotNull,
            reason:
                'refreshClient during a locked safelyCall must not corrupt the signed-in state',
          );

          authState.terminate();
        },
      );
    });

    group('ssoSignIn', () {
      testWidgets(
        'completes without dialog when signIn has no redirect URL',
        (tester) async {
          final authState = await createSignedOutAuthState();

          await tester.pumpWidget(
            TestClerkAuthWrapper(
              authState: authState,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await authState.ssoSignIn(
                        context,
                        clerk.Strategy.oauthGoogle,
                      );
                    },
                    child: const Text('Sign In'),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Sign In'));
          await tester.pump();

          expect(find.byType(Dialog), findsNothing);
          authState.terminate();
        },
      );

      testWidgets('calls onError when sign-in fails', (tester) async {
        final config = TestClerkAuthConfig(
          httpService: _SsoErrorHttpService(failPaths: ['/sign_ins']),
        );
        final authState = await ClerkAuthState.create(config: config);
        clerk.ClerkError? capturedError;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await authState.ssoSignIn(
                      context,
                      clerk.Strategy.oauthGoogle,
                      onError: (error) => capturedError = error,
                    );
                  },
                  child: const Text('Sign In'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Sign In'));
        await tester.pump();

        expect(capturedError, isNotNull);
        authState.terminate();
      });
    });

    group('ssoSignUp', () {
      testWidgets(
        'completes without dialog when signUp has no verification redirect URL',
        (tester) async {
          final authState = await createSignedOutAuthState();

          await tester.pumpWidget(
            TestClerkAuthWrapper(
              authState: authState,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await authState.ssoSignUp(
                        context,
                        clerk.Strategy.oauthGoogle,
                      );
                    },
                    child: const Text('Sign Up'),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Sign Up'));
          await tester.pump();

          expect(find.byType(Dialog), findsNothing);
          authState.terminate();
        },
      );

      testWidgets('calls onError when sign-up fails', (tester) async {
        final config = TestClerkAuthConfig(
          httpService: _SsoErrorHttpService(failPaths: ['/sign_ups']),
        );
        final authState = await ClerkAuthState.create(config: config);
        clerk.ClerkError? capturedError;

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await authState.ssoSignUp(
                      context,
                      clerk.Strategy.oauthGoogle,
                      onError: (error) => capturedError = error,
                    );
                  },
                  child: const Text('Sign Up'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Sign Up'));
        await tester.pump();

        expect(capturedError, isNotNull);
        authState.terminate();
      });
    });
  });
// Bug 421 — Bug 1: oauthSignIn must forward identifier for enterprise_sso
  group('oauthSignIn identifier forwarding', () {
    test(
      'passes identifier from existing signIn to createSignIn for enterprise_sso',
      () async {
        final signIn = createTestSignIn(
          identifier: 'user@saml-domain.com',
          status: clerk.Status.needsFirstFactor,
          // Provide a verification so hasVerification==true and oauthSignIn
          // skips the prepareSignIn call (which would fail for enterpriseSSO).
          firstFactorVerification: createTestVerification(
            strategy: clerk.Strategy.enterpriseSSO,
            status: clerk.Status.unverified,
          ),
        );
        final client = createTestClient(signIn: signIn);
        final capturingService = _CapturingHttpService(client: client);
        final authState = await ClerkAuthState.create(
          config: TestClerkAuthConfig(httpService: capturingService),
        );

        await authState.oauthSignIn(
          strategy: clerk.Strategy.enterpriseSSO,
          redirect: null,
        );

        final createSignInCall = capturingService.capturedRequests
            .where((r) =>
                r.uri.path.contains('/sign_ins') &&
                r.method == clerk.HttpMethod.post)
            .firstOrNull;
        expect(
          createSignInCall,
          isNotNull,
          reason: 'Expected a POST to /sign_ins',
        );
        expect(
          createSignInCall!.params?['identifier'],
          'user@saml-domain.com',
          reason:
              'enterprise_sso createSignIn must include the identifier so the server can resolve the SAML connection',
        );

        authState.terminate();
      },
    );
  });

  // Bug 421 — Bug 2: parseDeepLink must complete sign-in when verification strategy is saml
  group('parseDeepLink saml strategy', () {
    test(
      'calls completeOAuthSignIn when firstFactorVerification strategy is saml',
      () async {
        final signIn = createTestSignIn(
          status: clerk.Status.needsFirstFactor,
          firstFactorVerification: createTestVerification(
            strategy: clerk.Strategy.saml,
            status: clerk.Status.unverified,
          ),
        );
        final client = createTestClient(signIn: signIn);
        final capturingService = _CapturingHttpService(client: client);
        final authState = await ClerkAuthState.create(
          config: TestClerkAuthConfig(httpService: capturingService),
        );

        final uri = Uri.parse(
          'com.clerk.flutter://callback?rotating_token_nonce=nonce_abc123',
        );
        await authState.parseDeepLink(uri);

        final oauthCompletionCall = capturingService.capturedRequests
            .where((r) =>
                r.uri.path.contains('/sign_ins/') &&
                r.method == clerk.HttpMethod.get &&
                r.uri.queryParameters['rotating_token_nonce'] == 'nonce_abc123')
            .firstOrNull;
        expect(
          oauthCompletionCall,
          isNotNull,
          reason:
              'parseDeepLink must call completeOAuthSignIn (GET /sign_ins/{id}?rotating_token_nonce=...) '
              'when the verification strategy is saml',
        );

        authState.terminate();
      },
    );
  });
}

class _CapturedRequest {
  _CapturedRequest(this.method, this.uri, this.params);

  final clerk.HttpMethod method;
  final Uri uri;
  final Map<String, dynamic>? params;
}

class _CapturingHttpService extends TestHttpService {
  _CapturingHttpService({super.client});

  final List<_CapturedRequest> capturedRequests = [];

  @override
  Future<Response> send(
    clerk.HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) {
    capturedRequests.add(_CapturedRequest(method, uri, params));
    return super.send(
      method,
      uri,
      headers: headers,
      params: params,
      body: body,
    );
  }
}

class _StaleRefreshHttpService extends TestHttpService {
  _StaleRefreshHttpService({
    required clerk.Client initialClient,
    required this.staleClient,
  }) : super(client: initialClient);

  final clerk.Client staleClient;
  bool _initialized = false;

  @override
  Future<Response> send(
    clerk.HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) {
    if (uri.path.contains('/client')) {
      if (_initialized) {
        final clientJson = staleClient.toJson();
        return Future.value(Response(
          jsonEncode({'response': clientJson, 'client': clientJson}),
          200,
        ));
      }
      _initialized = true;
    }
    return super
        .send(method, uri, headers: headers, params: params, body: body);
  }
}

class _SsoErrorHttpService extends TestHttpService {
  _SsoErrorHttpService({
    required this.failPaths,
  });

  final List<String> failPaths;

  @override
  Future<Response> send(
    clerk.HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) {
    if (failPaths.any((p) => uri.path.contains(p))) {
      return Future.value(Response(
        jsonEncode({
          'errors': [
            {'message': 'OAuth failed', 'code': 'form_code_incorrect'},
          ],
        }),
        422,
      ));
    }
    return super
        .send(method, uri, headers: headers, params: params, body: body);
  }
}

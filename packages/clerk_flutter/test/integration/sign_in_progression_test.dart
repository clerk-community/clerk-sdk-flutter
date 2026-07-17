import 'dart:convert';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_in_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;

import '../test_support/test_support.dart';

// The live API does not advance `client.updated_at` when a sign_in is
// created or progresses (see the recorded fixtures in
// packages/clerk_auth/test/_responses/clerk_auth/sign_in_test/, where the
// timestamp is identical on every response of every flow). These tests
// model that: every client the mock serves shares one `updated_at`, so any
// staleness heuristic keyed on the timestamp alone must not reject the
// progressed sign-in.
void main() {
  final sharedTimestamp = DateTime.now();

  const environment = clerk.Environment(
    config: clerk.Config(
      identificationStrategies: [
        clerk.Strategy.emailAddress,
      ],
      firstFactors: [
        clerk.Strategy.password,
        clerk.Strategy.emailCode,
      ],
    ),
  );

  clerk.Client initialClient() => createTestClient(
        sessions: [],
        updatedAt: sharedTimestamp,
        createdAt: sharedTimestamp,
      );

  clerk.Client progressedClient() => createTestClient(
        signIn: createTestSignIn(
          status: clerk.Status.needsFirstFactor,
          identifier: 'user@example.com',
          supportedFirstFactors: [
            createTestFactor(strategy: clerk.Strategy.password),
            createTestFactor(
              strategy: clerk.Strategy.emailCode,
              safeIdentifier: 'u***@example.com',
            ),
          ],
        ),
        updatedAt: sharedTimestamp,
        createdAt: sharedTimestamp,
      );

  group('Sign-in progression with constant client.updated_at', () {
    test(
      'attemptSignIn adopts the progressed sign-in '
      'even though updated_at has not advanced',
      () async {
        final authState = await createTestAuthState(
          config: TestClerkAuthConfig(
            httpService: _SignInFlowHttpService(
              initialClient: initialClient(),
              signInClient: progressedClient(),
              environment: environment,
            ),
          ),
        );

        expect(authState.signIn, isNull, reason: 'should start without a sign-in');

        // What ClerkSignInPanel._continue runs when "Continue" is tapped
        // on the identifier screen.
        await authState.attemptSignIn(
          strategy: clerk.Strategy.password,
          identifier: 'user@example.com',
        );

        expect(
          authState.signIn,
          isNotNull,
          reason: 'the created sign-in must be adopted even though the '
              'response client shares updated_at with the current client',
        );
        expect(authState.signIn?.status, clerk.Status.needsFirstFactor);

        authState.terminate();
      },
    );

    testWidgets(
      'tapping Continue on the identifier screen progresses to first factor',
      (tester) async {
        final authState = await createTestAuthState(
          config: TestClerkAuthConfig(
            httpService: _SignInFlowHttpService(
              initialClient: initialClient(),
              signInClient: progressedClient(),
              environment: environment,
            ),
          ),
        );

        await tester.pumpWidget(
          TestClerkAuthWrapper(
            authState: authState,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: ClerkSignInPanel(),
              ),
            ),
          ),
        );
        await tester.pump();

        // Identifier screen: enter an email address and tap Continue
        await tester.enterText(
          find.byType(TextFormField).first,
          'user@example.com',
        );
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(
          authState.signIn?.status,
          clerk.Status.needsFirstFactor,
          reason: 'Continue must move the flow to the first-factor stage',
        );

        final identifierInput = tester.widget<Openable>(
          find.byKey(const Key('identifierInput')),
        );
        expect(
          identifierInput.closed,
          isTrue,
          reason: 'the identifier input must close once a sign-in exists',
        );

        authState.terminate();
      },
    );
  });
}

/// Serves a scripted sign-in flow: the initial client for `GET /client`,
/// and the progressed client for `POST /client/sign_ins` — both carrying
/// the same `updated_at`, as the live API does.
class _SignInFlowHttpService extends TestHttpService {
  _SignInFlowHttpService({
    required clerk.Client initialClient,
    required this.signInClient,
    required clerk.Environment environment,
  }) : super(client: initialClient, environment: environment);

  final clerk.Client signInClient;

  @override
  Future<Response> send(
    clerk.HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) {
    if (uri.path.contains('/sign_ins')) {
      final clientJson = signInClient.toJson();
      return Future.value(
        Response(
          jsonEncode({
            'response': clientJson['sign_in'],
            'client': clientJson,
          }),
          200,
        ),
      );
    }
    return super.send(method, uri, headers: headers, params: params, body: body);
  }
}

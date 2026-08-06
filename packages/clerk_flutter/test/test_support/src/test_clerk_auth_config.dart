import 'dart:convert';
import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_file_cache.dart';
import 'package:http/http.dart' show ByteStream, Response;

import 'test_data.dart';

/// A test configuration for ClerkAuthConfig that uses mock services
class TestClerkAuthConfig extends ClerkAuthConfig {
  /// Create a test configuration with sensible defaults for testing
  TestClerkAuthConfig({
    super.publishableKey = 'pk_test_dGVzdC5jbGVyay5kZXYk',
    super.deepLinkStream,
    TestHttpService? httpService,
    Client? initialClient,
    Environment? initialEnvironment,
  }) : super(
          httpService: httpService ??
              TestHttpService(
                client: initialClient,
                environment: initialEnvironment,
              ),
          persistor: Persistor.none,
          sessionTokenPolling: false,
          clientRefreshPeriod: Duration.zero,
          telemetryPeriod: Duration.zero,
          loading: null,
          fileCache: TestFileCache(),
        );

  /// Create a config for a signed-in state
  factory TestClerkAuthConfig.signedIn({User? user}) {
    return TestClerkAuthConfig(
      initialClient: createSignedInClient(user: user),
    );
  }

  /// Create a config for a signed-out state
  factory TestClerkAuthConfig.signedOut() {
    return TestClerkAuthConfig(
      initialClient: createSignedOutClient(),
    );
  }
}

/// A mock HTTP service that returns configurable responses for testing
class TestHttpService implements HttpService {
  const TestHttpService({
    this.client,
    this.environment,
  });

  /// The client to return in responses
  final Client? client;

  /// The environment to return in responses
  final Environment? environment;

  @override
  Future<void> initialize() async {}

  @override
  void terminate() {}

  @override
  Future<bool> ping(Uri uri, {required Duration timeout}) => Future.value(true);

  @override
  Future<Response> send(
    HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    String? body,
  }) {
    final path = uri.path;
    if (path.contains('/client')) {
      final clientJson = client?.toJson() ?? {};
      return Future.value(Response(
        jsonEncode({'response': clientJson, 'client': clientJson}),
        200,
      ));
    }
    if (path.contains('/environment')) {
      final envJson = environment?.toJson() ?? {};
      return Future.value(Response(
        jsonEncode(envJson),
        200,
      ));
    }
    return Future.value(Response('{}', 200));
  }

  @override
  Future<Response> sendByteStream(
    HttpMethod method,
    Uri uri,
    ByteStream byteStream,
    int length,
    Map<String, String> headers,
  ) {
    return Future.value(Response('{}', 200));
  }
}

/// A mock file cache for testing
class TestFileCache implements ClerkFileCache {
  @override
  Future<void> initialize() async {}

  @override
  void terminate() {}

  @override
  Stream<File> stream(
    Uri uri, {
    Duration ttl = ClerkFileCache.defaultTTL,
    Map<String, String>? headers,
  }) {
    // Return an empty stream for testing
    return const Stream.empty();
  }
}

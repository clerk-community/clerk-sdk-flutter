import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import 'test_clerk_auth_config.dart';

/// Creates a ClerkAuthState for testing with the given configuration
Future<ClerkAuthState> createTestAuthState({
  TestClerkAuthConfig? config,
  clerk.Client? client,
  clerk.User? user,
  clerk.Environment? environment,
}) async {
  final effectiveConfig = config ??
      (user != null
          ? TestClerkAuthConfig.signedIn(user: user)
          : TestClerkAuthConfig(
              initialClient: client,
              initialEnvironment: environment,
            ));

  return ClerkAuthState.create(config: effectiveConfig);
}

/// Creates a ClerkAuthState for a signed-in user
Future<ClerkAuthState> createSignedInAuthState({
  clerk.User? user,
  clerk.Client? client,
}) async {
  if (client != null) {
    return createTestAuthState(
      config: TestClerkAuthConfig(initialClient: client),
    );
  }
  return createTestAuthState(
    config: TestClerkAuthConfig.signedIn(user: user),
  );
}

/// Creates a ClerkAuthState for a signed-out user
Future<ClerkAuthState> createSignedOutAuthState() async {
  return createTestAuthState(
    config: TestClerkAuthConfig.signedOut(),
  );
}

/// A wrapper widget that provides ClerkAuth context for testing
/// Use this for synchronous widget tests where you already have an authState
class TestClerkAuthWrapper extends StatelessWidget {
  const TestClerkAuthWrapper({
    super.key,
    required this.child,
    required this.authState,
    this.themeExtension,
  });

  final Widget child;
  final ClerkAuthState authState;
  final ClerkThemeExtension? themeExtension;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = themeExtension ?? ClerkThemeExtension.light;

    return MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: [effectiveTheme],
      ),
      home: ClerkAuth(
        authState: authState,
        child: child,
      ),
    );
  }
}

/// A wrapper widget that creates its own ClerkAuthState for testing
/// Use this for simpler tests where you don't need to control the auth state
class TestClerkAuthWrapperAsync extends StatefulWidget {
  const TestClerkAuthWrapperAsync({
    super.key,
    required this.child,
    this.config,
    this.themeExtension,
  });

  final Widget child;
  final TestClerkAuthConfig? config;
  final ClerkThemeExtension? themeExtension;

  @override
  State<TestClerkAuthWrapperAsync> createState() =>
      _TestClerkAuthWrapperAsyncState();
}

class _TestClerkAuthWrapperAsyncState extends State<TestClerkAuthWrapperAsync> {
  ClerkAuthState? _authState;

  @override
  void initState() {
    super.initState();
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    final authState = await createTestAuthState(config: widget.config);
    if (mounted) {
      setState(() => _authState = authState);
    }
  }

  @override
  void dispose() {
    _authState?.terminate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.themeExtension ?? ClerkThemeExtension.light;

    if (_authState == null) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [effectiveTheme],
        ),
        home: const Center(child: CircularProgressIndicator()),
      );
    }

    return MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: [effectiveTheme],
      ),
      home: ClerkAuth(
        authState: _authState!,
        child: widget.child,
      ),
    );
  }
}

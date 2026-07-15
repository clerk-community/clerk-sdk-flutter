<p align="center">
<img src="https://images.clerk.com/static/logo-light-mode-400x400.png" height="90">
</p>

## Community-maintained [Clerk](https://clerk.com) Dart SDK (Beta)

[![Pub Version](https://img.shields.io/pub/v/clerk_auth?color=blueviolet)](https://pub.dev/packages/clerk_auth)
[![Pub Points](https://img.shields.io/pub/points/clerk_auth?label=pub%20points)](https://pub.dev/packages/clerk_auth/score)
[![chat on Discord](https://img.shields.io/discord/856971667393609759.svg?logo=discord)](https://clerk.com/discord)
[![documentation](https://img.shields.io/badge/documentation-docs.page-green.svg)](https://docs.page/clerk-community/clerk-sdk-flutter)
[![Follow on X](https://img.shields.io/twitter/follow/clerk?style=social)](https://x.com/intent/follow?screen_name=clerk)

> ### ⚠️ The Clerk Flutter SDK is in Beta ⚠️
> ❗️ Breaking changes should be expected until the first stable release (1.0.0) ❗️

**[Clerk](https://clerk.com) provides user management: sign-up, sign-in, and profile management for your users, straight from your Dart code.**

> This SDK is community-maintained and provided as-is — not officially supported by Clerk. Clerk employees may contribute on their own time. See [clerk-community](https://github.com/clerk-community) for what that means.

## Requirements

* Dart >= 3.6.2

## Example Usage

To use this package you will need to go to your [Clerk Dashboard](https://dashboard.clerk.com/)
create an application and copy the public and publishable API keys into your project.

```dart
import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart';

Future<void> main() async {
  final auth = Auth(
    config: const AuthConfig(
      publishableKey: '<YOUR-PUBLISHABLE-KEY>',
    ),
    persistor: DefaultPersistor(
      getCacheDirectory: () => Directory.current,
    ),
    // To enable running of the example in e.g. Flutter environments where
    // [Directory.current] causes problems, use the `clerk_flutter` package and
    // use:
    // persistor: DefaultCachingPersistor(
    //   getCacheDirectory: getApplicationDocumentsDirectory,
    // )
    // Which will use the correct directory for the platform your Flutter app
    // is running on. You can also implement a bespoke [Persistor] specific
    // to your applications storage mechanism,
    //
    // or replace the above line with...
    // persistor: Persistor.none,
  );

  await auth.initialize();

  await auth.attemptSignIn(
    strategy: Strategy.password,
    identifier: '<USER-EMAIL>',
    password: '<PASSWORD>',
  );

  print('Signed in as ${auth.user}');

  await auth.signOut();

  auth.terminate();
}
```

For more details see [Clerk Auth object](https://pub.dev/documentation/clerk_auth/latest/clerk_auth/Auth-class.html)

## Session Token Polling

By default, `ClerkAuth` will regularly poll for session tokens, providing them into the app
via the `sessionTokenStream`. In line with other Clerk SDKs (and if organizations are enabled) the stream 
of session tokens will be augmented with data from the `Organization` most recently activated.

If you do not wish for session tokens to be polled in this way, the behaviour can be disabled 
through the config object when creating your `Auth` object:

```dart
final auth = Auth(
  config: const AuthConfig(
    publishableKey: '<YOUR-PUBLISHABLE-KEY>',
    sessionTokenPolling: false,
    ...
  ), 
  ...
);
```

### Note re: v0.0.12-beta and previous

Note that the behaviour described above has been introduced in v0.0.13-beta. Prior versions defaulted to
polling off, enabling it via a `SessionTokenPollMode` object in the config. This object has been deprecated in 
v0.0.13-beta: it is no longer used, and will be deleted in a future version. If you are using it, or relying on
the system defaulting to no polling, please review your code.

## License

This SDK is licensed under the MIT license found in the [LICENSE](./LICENSE) file.

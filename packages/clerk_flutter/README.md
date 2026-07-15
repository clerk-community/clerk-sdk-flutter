<p align="center">
<img src="https://images.clerk.com/static/logo-light-mode-400x400.png" height="90">
</p>

## Community-maintained [Clerk](https://clerk.com) Flutter SDK (Beta)

[![Pub Version](https://img.shields.io/pub/v/clerk_flutter?color=blueviolet)](https://pub.dev/packages/clerk_flutter)
[![Pub Points](https://img.shields.io/pub/points/clerk_flutter?label=pub%20points)](https://pub.dev/packages/clerk_flutter/score)
[![chat on Discord](https://img.shields.io/discord/856971667393609759.svg?logo=discord)](https://clerk.com/discord)
[![documentation](https://img.shields.io/badge/documentation-docs.page-green.svg)](https://docs.page/clerk-community/clerk-sdk-flutter)
[![Follow on X](https://img.shields.io/twitter/follow/clerk?style=social)](https://x.com/intent/follow?screen_name=clerk)

> ### ⚠️ The Clerk Flutter SDK is in Beta ⚠️
> ❗️ Breaking changes should be expected until the first stable release (1.0.0) ❗️

**[Clerk](https://clerk.com) provides user management: sign-up, sign-in, and profile management for your users, straight from your Flutter code.**

> This SDK is community-maintained and provided as-is — not officially supported by Clerk. Clerk employees may contribute on their own time. See [clerk-community](https://github.com/clerk-community) for what that means.

## Requirements

* Flutter >= 3.27.4
* Dart >= 3.6.2

## In Development

* Organization support

## Example Usage

To use this package you will need to go to your [Clerk Dashboard](https://dashboard.clerk.com/)
create an application and copy the public and publishable API keys into your project.

The bundled example app requires one, possibly two, variables to be set up in your environment:
- `publishable_key`: your Clerk publishable key, usually starting `pk_`
- `google_client_id`: the ID of your GCP web project, if you are using Google token oauth

```dart
/// Example App
class ExampleApp extends StatelessWidget {
  /// Constructs an instance of Example App
  const ExampleApp({super.key, required this.publishableKey});

  /// Publishable Key
  final String publishableKey;

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: publishableKey),
      child: MaterialApp(
        theme: ThemeData.light(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: ClerkErrorListener(
              child: ClerkAuthBuilder(
                signedInBuilder: (context, authState) {
                  return const ClerkUserButton();
                },
                signedOutBuilder: (context, authState) {
                  return const ClerkAuthentication();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Installation (Android)

Add the following line to your `android/app/src/main/AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## License

This SDK is licensed under the MIT license found in the [LICENSE](./LICENSE) file.

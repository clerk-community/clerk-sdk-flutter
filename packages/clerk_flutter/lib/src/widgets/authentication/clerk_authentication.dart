import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_telemetry.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_oauth_panel.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_in_panel.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_sign_up_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_panel_header.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_vertical_card.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:clerk_flutter/src/widgets/ui/or_divider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum _AuthState {
  signingIn,
  signingUp;

  bool get isSigningIn => this == signingIn;

  bool get isSigningUp => this == signingUp;

  _AuthState get nextState => values[(index + 1) % values.length];
}

/// The [ClerkAuthentication] renders a UI for signing users or up.
///
/// The functionality of the [ClerkAuthentication] is controlled by the instance settings you
/// specify in your Clerk Dashboard, such as sign-in and sign-ip options and social
/// connections. You can further customize you [ClerkAuthentication] by passing additional
/// properties.
///
/// That includes the instance's **sign-up mode**. On a `restricted` or `waitlist` instance the
/// widget offers sign-in only: the "Don't have an account? Sign up" toggle is not rendered,
/// because filling in the form it leads to can only end in the API refusing the sign-up.
///
/// **The panel itself is not gated, only the way to reach it by choice.** If something has already
/// put the auth state into signing-up, [ClerkSignUpPanel] still renders — a sign-up in flight must
/// not become a blank card, and hiding a form somebody is part-way through is a worse failure than
/// showing one that is refused.
///
@immutable
class ClerkAuthentication extends StatefulWidget {
  /// Constructs a new [ClerkAuthentication].
  const ClerkAuthentication({super.key});

  @override
  State<ClerkAuthentication> createState() => _ClerkAuthenticationState();
}

class _ClerkAuthenticationState extends State<ClerkAuthentication>
    with ClerkTelemetryStateMixin {
  _AuthState _state = _AuthState.signingIn;

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    if (authState.isNotAvailable) {
      // We have no environment, implying ClerkAuth has not been initialised
      // or initialisation has failed (no connectivity?).
      return emptyWidget;
    }

    final display = ClerkAuth.displayConfigOf(context);
    final localizations = ClerkAuth.localizationsOf(context);

    // Coerce [_state] if we're in one specific one
    if (authState.isSigningIn && authState.isSigningUp == false) {
      _state = _AuthState.signingIn;
    } else if (authState.isSigningUp) {
      _state = _AuthState.signingUp;
    }

    return ClerkVerticalCard(
      topPortion: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClerkPanelHeader(
            title: _state.isSigningIn
                ? localizations.signInTo(display.applicationName)
                : localizations.signUpTo(display.applicationName),
            subtitle: _state.isSigningIn
                ? localizations.welcomeBackPleaseSignInToContinue
                : localizations.welcomePleaseFillInTheDetailsToGetStarted,
          ),
          Padding(
            padding: horizontalPadding32,
            child: Column(
              children: [
                if (authState.env.hasOauthStrategies) ...[
                  Closeable(
                    closed: authState.isSigningUp ||
                        (authState.isSigningIn &&
                            authState.signIn!.verification?.strategy.isOauth !=
                                true),
                    child: const ClerkOAuthPanel(),
                  ),
                  Closeable(
                    closed: authState.isSigningUp || authState.isSigningIn,
                    child: const OrDivider(),
                  ),
                ],
                Openable(
                  open: _state.isSigningIn,
                  keepAlive: true,
                  child: const ClerkSignInPanel(),
                ),
                Openable(
                  open: _state.isSigningUp,
                  keepAlive: true,
                  child: const ClerkSignUpPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
      // The toggle to *choose* sign-up, and nothing else — see the class doc above. Gone when the
      // instance does not allow one, so the widget stops offering an account it cannot create.
      bottomPortion: authState.env.signUpIsOpen
          ? _BottomPortion(
              state: _state,
              onChange: () => setState(() => _state = _state.nextState),
            )
          : emptyWidget,
    );
  }
}

@immutable
class _BottomPortion extends StatelessWidget {
  const _BottomPortion({required this.onChange, required this.state});

  final VoidCallback onChange;
  final _AuthState state;

  @override
  Widget build(BuildContext context) {
    final localizations = ClerkAuth.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        verticalMargin12,
        Padding(
          padding: horizontalPadding32,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: state.isSigningIn
                      ? localizations.dontHaveAnAccount
                      : localizations.alreadyHaveAnAccount,
                  style: themeExtension.styles.subheading,
                ),
                const WidgetSpan(child: SizedBox(width: 6)),
                TextSpan(
                  text: state.isSigningIn
                      ? localizations.signUp
                      : localizations.signIn,
                  style: themeExtension.styles.subheading
                      .copyWith(color: themeExtension.colors.accent),
                  recognizer: TapGestureRecognizer()..onTap = onChange,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        verticalMargin12,
      ],
    );
  }
}

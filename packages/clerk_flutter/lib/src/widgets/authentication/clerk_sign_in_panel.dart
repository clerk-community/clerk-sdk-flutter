import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_telemetry.dart';
import 'package:clerk_flutter/src/utils/extensions.dart';
import 'package:clerk_flutter/src/utils/identifier.dart';
import 'package:clerk_flutter/src/widgets/authentication/clerk_forgotten_password_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_code_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_control_buttons.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_identifier_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_material_button.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:clerk_flutter/src/widgets/ui/or_divider.dart';
import 'package:clerk_flutter/src/widgets/ui/strategy_button.dart';
import 'package:flutter/material.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// The [ClerkSignInPanel] renders a UI for signing in users.
///
/// The functionality of the [ClerkSignInPanel] is controlled by the instance settings you
/// specify in your Clerk Dashboard, such as sign-in and sign-ip options and social
/// connections. You can further customize you [ClerkSignInPanel] by passing additional
/// properties.
///
class ClerkSignInPanel extends StatefulWidget {
  /// Constructs a new [ClerkSignInPanel].
  const ClerkSignInPanel({super.key});

  @override
  State<ClerkSignInPanel> createState() => _ClerkSignInPanelState();
}

class _ClerkSignInPanelState extends State<ClerkSignInPanel>
    with ClerkTelemetryStateMixin {
  final _passkeyAvailable = PasskeyAuthenticator().isAvailable;

  clerk.Strategy _strategy = clerk.Strategy.unknown;
  Identifier _identifier = const Identifier('');
  String _password = '';
  String _code = '';

  void _onError(clerk.ClerkError _) {
    setState(() {
      _password = _code = '';
      _strategy = clerk.Strategy.unknown;
    });
  }

  Future<void> _reset(ClerkAuthState authState) async {
    _password = _code = '';
    _strategy = clerk.Strategy.unknown;
    await authState.resetClient();
  }

  Future<void> _resend(ClerkAuthState authState) async {
    await authState.safelyCall(context, () async {
      await authState.resendCode(_strategy);
    });
  }

  Future<void> _continue(
    ClerkAuthState authState, {
    clerk.Strategy? strategy,
    String? code,
  }) async {
    if (_strategy.isUnknown) {
      // By this stage, if we don't know a strategy assume password
      _strategy = clerk.Strategy.password;
    }

    strategy ??= _strategy;
    code ??= _code;

    if (_strategy != strategy || _code != code) {
      setState(() {
        _strategy = strategy!;
        _code = code!;
      });
    }

    if (_strategy.isKnown) {
      final redirectUri = _strategy.isEmailLink
          ? authState.emailVerificationRedirectUri(context)
          : null;

      bool needsEnterpriseSSO = false;

      await authState.safelyCall(
        context,
        () async {
          await authState.attemptSignIn(
            strategy: strategy!,
            identifier: _identifier.identifier.orNullIfEmpty,
            password: _password.orNullIfEmpty,
            code: code?.orNullIfEmpty,
            redirectUrl: redirectUri?.toString(),
          );

          if (authState.signIn case clerk.SignIn signIn when mounted) {
            if (signIn.firstFactorVerification
                case clerk.Verification verification
                when verification.strategy.isPasskey &&
                    verification.status.isUnverified) {
              if (verification.nonce case clerk.VerificationNonce nonce) {
                final authenticator = PasskeyAuthenticator();
                final requestType = AuthenticateRequestType(
                  challenge: nonce.challenge,
                  relyingPartyId: nonce.relyingParty.id,
                  mediation: MediationType.Required,
                  timeout: nonce.timeout,
                  userVerification: nonce.userVerification,
                  preferImmediatelyAvailableCredentials: true,
                );
                final res = await authenticator.authenticate(requestType);
                await authState.attemptSignIn(
                  strategy: clerk.Strategy.passkey,
                  passkeyCredential: res.toJsonString(),
                );
              }
              // await authState.passkeySignIn();
            } else if (signIn.factors case final factors
                when factors.isNotEmpty) {
              if (factors.any((f) => f.strategy.isEnterpriseSSO)) {
                needsEnterpriseSSO = true;
              } else if (signIn.needsFactor && factors.length == 1) {
                await authState.attemptSignIn(strategy: factors.first.strategy);
              }
              if (authState.signIn case clerk.SignIn signIn
                  when signIn.needsFactor && signIn.factors.length == 1) {
                _strategy = signIn.factors.first.strategy;
              }
            }
          }
        },
        onError: _onError,
      );

      if (needsEnterpriseSSO && mounted) {
        await authState.ssoSignIn(
          context,
          clerk.Strategy.enterpriseSSO,
          onError: _onError,
        );
      }
    }
  }

  bool _needsBack(clerk.SignIn signIn) => signIn.status.isUnknown == false;

  bool _needsCont(clerk.SignIn signIn) =>
      signIn.status.isUnknown ||
      (_strategy.isPassword && _password.isNotEmpty) ||
      _strategy.mightAccept(_code);

  bool _externalActionFactorChosen(List<clerk.Factor> factors) =>
      _strategy.requiresExternalAction
          ? factors.any((f) => f.strategy == _strategy)
          : false;

  void _checkForRebuild(String newValue, String oldValue) {
    if (newValue.isEmpty != oldValue.isEmpty) {
      setState(() {});
    }
  }

  void _updatePassword(String password) {
    _checkForRebuild(password, _password);
    _password = password;
  }

  void _updateCode(String code) {
    _checkForRebuild(code, _code);
    _code = code;
  }

  Future<bool> _submitCode(String code, ClerkAuthState authState) async {
    await _continue(authState, code: code);
    _strategy = clerk.Strategy.unknown;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    final env = authState.env;
    if (authState.isNotAvailable || env.hasIdentificationStrategies == false) {
      return emptyWidget;
    }

    final l10ns = authState.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);

    final signIn = authState.signIn ?? clerk.SignIn.empty;
    final safeIdentifier = signIn.factorFor(_strategy)?.safeIdentifier ??
        _identifier.prettyIdentifier.orNullIfEmpty;

    final showIdentifierInput = signIn.status.isUnknown;
    final showHeading = signIn.status.needsFactor;
    final showEmailLinkMessage =
        signIn.needsFirstFactor && _strategy.isEmailLink;
    final showCodeInput = _strategy.requiresCode;

    final firstFactors = signIn.factorsFor(clerk.Stage.first);
    final showFirstFactors = signIn.needsFirstFactor &&
        _externalActionFactorChosen(firstFactors) == false;

    final secondFactors = signIn.factorsFor(clerk.Stage.second);
    final showSecondFactors = signIn.needsSecondFactor &&
        _externalActionFactorChosen(secondFactors) == false;

    final clientTrustFactors = signIn.factorsFor(clerk.Stage.second);
    final showClientTrustFactors = signIn.needsClientTrust &&
        _externalActionFactorChosen(clientTrustFactors) == false;

    final showSomething = showIdentifierInput ||
        showHeading ||
        showEmailLinkMessage ||
        showCodeInput ||
        showFirstFactors ||
        showSecondFactors ||
        showClientTrustFactors;

    if (showSomething == false && signIn.hasVerification == false) {
      // If we get here, there is no way to progress. Reset.
      _reset(authState);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Identifier input
        Openable(
          key: const Key('identifierInput'),
          open: showIdentifierInput,
          builder: (context) => ClerkIdentifierInput(
            initialValue: _identifier,
            strategies: env.identificationStrategies.toList(),
            onChanged: (identifier) => _identifier = identifier,
            onSubmit: (_) => _continue(authState),
          ),
        ),

        // Identifier
        Openable(
          key: const Key('heading'),
          open: showHeading,
          builder: (context) {
            late String headingText;
            if (signIn.needsSecondFactor) {
              headingText = l10ns.twoStepVerification;
            } else if (signIn.needsClientTrust) {
              headingText = l10ns.verifyThisDevice;
            } else {
              headingText = _identifier.identifier;
            }
            return Text(headingText, style: themeExtension.styles.heading);
          },
        ),

        verticalMargin8,

        // Email link message
        Openable(
          open: showEmailLinkMessage,
          child: _EmailLinkMessage(
            key: const Key('emailLinkMessage'),
            identifier: safeIdentifier,
          ),
        ),

        // Code input
        Openable(
          open: showCodeInput,
          child: _CodeInput(
            key: const Key('codeInput'),
            strategy: _strategy,
            identifier: safeIdentifier,
            onChanged: _updateCode,
            onSubmit: (code) => _submitCode(code, authState),
            onResend: () => _resend(authState),
          ),
        ),

        // Factors for first stage
        Openable(
          open: showFirstFactors,
          child: _FactorList(
            key: const Key('firstFactors'),
            factors: firstFactors,
            onPasswordChanged: _updatePassword,
            onSubmit: (strategy) => _continue(authState, strategy: strategy),
          ),
        ),

        // Factors for second stage
        Openable(
          open: showSecondFactors,
          child: _FactorList(
            key: const Key('secondFactors'),
            factors: secondFactors,
            onPasswordChanged: _updatePassword,
            onSubmit: (strategy) => _continue(authState, strategy: strategy),
          ),
        ),

        // Factors for device-trust stage
        Openable(
          open: showClientTrustFactors,
          child: _FactorList(
            key: const Key('clientTrustFactors'),
            factors: clientTrustFactors,
            onPasswordChanged: _updatePassword,
            onSubmit: (strategy) => _continue(authState, strategy: strategy),
          ),
        ),

        verticalMargin8,

        // Buttons
        ClerkControlButtons(
          onContinue: _needsCont(signIn) ? () => _continue(authState) : null,
          onBack: _needsBack(signIn) ? () => _reset(authState) : null,
        ),

        verticalMargin16,

        if (env.user.passkeySettings.showSignInButton &&
            env.supportsPasskeys) //
          FutureBuilder(
            future: _passkeyAvailable,
            builder: (context, snapshot) {
              return Openable(
                open: snapshot.data == true && signIn.status.isUnknown,
                builder: (context) => _UsePasskeyAction(
                  onTap: () =>
                      _continue(authState, strategy: clerk.Strategy.passkey),
                ),
              );
            },
          ),

        verticalMargin16,
      ],
    );
  }
}

class _UsePasskeyAction extends StatelessWidget {
  const _UsePasskeyAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    final l10ns = authState.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(
          l10ns.usePasskeyInstead,
          style: themeExtension.styles.clickableText,
        ),
      ),
    );
  }
}

class _EmailLinkMessage extends StatelessWidget {
  const _EmailLinkMessage({
    super.key,
    required this.identifier,
  });

  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final l10ns = ClerkAuth.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Column(
      children: [
        Text(
          identifier is String
              ? l10ns.clickOnTheLinkThatsBeenSentTo(identifier!)
              : l10ns.clickOnTheLinkThatsBeenSentToYou,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: themeExtension.styles.subheading,
        ),
        verticalMargin16,
        defaultLoadingWidget,
        verticalMargin16,
      ],
    );
  }
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({
    super.key,
    required this.strategy,
    required this.identifier,
    required this.onChanged,
    required this.onSubmit,
    required this.onResend,
  });

  final clerk.Strategy strategy;

  final String? identifier;

  final ValueChanged<String> onChanged;

  final Future<bool> Function(String) onSubmit;

  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10ns = ClerkAuth.localizationsOf(context);
    return Padding(
      padding: verticalPadding8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClerkCodeInput(
            title: switch (strategy) {
              clerk.Strategy.emailCode ||
              clerk.Strategy.resetPasswordEmailCode =>
                identifier is String
                    ? l10ns.enterTheCodeSentTo(identifier!)
                    : l10ns.enterTheCodeSentToYouByEmail,
              clerk.Strategy.phoneCode ||
              clerk.Strategy.resetPasswordPhoneCode =>
                identifier is String
                    ? l10ns.enterTheCodeSentTo(identifier!)
                    : l10ns.enterTheCodeSentToYouByTextMessage,
              clerk.Strategy.backupCode => l10ns.enterOneOfYourBackupCodes,
              clerk.Strategy.totp => l10ns.enterTheCodeFromYourAuthenticatorApp,
              _ => null,
            },
            isTextual: strategy.requiresTextualCode,
            onChanged: onChanged,
            onSubmit: onSubmit,
          ),
          Padding(
            padding: topPadding8,
            child: SizedBox(
              width: 80,
              height: 20,
              child: ClerkMaterialButton(
                style: ClerkMaterialButtonStyle.light,
                onPressed: onResend,
                label: Text(l10ns.resend),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorList extends StatelessWidget {
  const _FactorList({
    super.key,
    required this.factors,
    required this.onSubmit,
    this.onPasswordChanged,
  });

  final List<clerk.Factor> factors;

  final ValueChanged<clerk.Strategy> onSubmit;

  final ValueChanged<String>? onPasswordChanged;

  Future<void> _openPasswordResetFlow(BuildContext context) async {
    await ClerkForgottenPasswordPanel.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context, listen: false);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    final l10ns = authState.localizationsOf(context);
    final hasPassword = factors.any((f) => f.strategy.isPassword);
    final otherFactors = factors.where(StrategyButton.supports).toList();
    final canResetPassword =
        authState.env.config.firstFactors.any((s) => s.isPasswordResetter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onPasswordChanged case final onPasswordChanged? when hasPassword) //
          Padding(
            padding: topPadding8 + bottomPadding2,
            child: ClerkTextFormField(
              label: l10ns.password,
              hint: l10ns.enterYourPassword,
              obscureText: true,
              onChanged: onPasswordChanged,
              onSubmit: (_) => onSubmit(clerk.Strategy.password),
              trailing: canResetPassword
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openPasswordResetFlow(context),
                      child: Text(
                        l10ns.forgottenPassword,
                        style: themeExtension.styles.clickableText,
                      ),
                    )
                  : null,
            ),
          ),
        if (otherFactors.isNotEmpty) ...[
          if (hasPassword) //
            const OrDivider(),
          for (final factor in otherFactors)
            Padding(
              padding: topPadding4,
              child: StrategyButton(
                key: ValueKey<clerk.Factor>(factor),
                strategy: factor.strategy,
                safeIdentifier: factor.safeIdentifier,
                onClick: () => onSubmit(factor.strategy),
              ),
            ),
        ],
        verticalMargin24,
      ],
    );
  }
}

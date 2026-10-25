import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_code_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_identifier_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_material_button.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_panel_header.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:flutter/material.dart';

enum _ResetFlowState {
  unstarted,
  started,
  awaitingCode,
  awaitingReset;

  bool get isUnstarted => this == unstarted;

  bool get isAwaitingCode => this == awaitingCode;

  bool get isAwaitingReset => this == awaitingReset;
}

/// The [ClerkForgottenPasswordPanel] renders UI for the forgotten password
/// flow.
///
/// Initially the email address for the missing account is requested,
/// followed by a code and new password entry boxes
///
class ClerkForgottenPasswordPanel extends StatefulWidget {
  /// Constructor
  const ClerkForgottenPasswordPanel({super.key});

  /// Open the panel
  static Future<bool?> show(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => const ClerkForgottenPasswordPanel(),
    );
  }

  @override
  State<ClerkForgottenPasswordPanel> createState() =>
      _ClerkForgottenPasswordPanelState();
}

class _ClerkForgottenPasswordPanelState
    extends State<ClerkForgottenPasswordPanel> {
  final _identifierType = ValueNotifier(clerk.IdentifierType.emailAddress);

  _ResetFlowState _flowState = _ResetFlowState.unstarted;

  bool _obscured = true;
  String _code = '';
  String _identifier = '';
  String _password = '';
  String _confirmation = '';

  clerk.Strategy get _strategy => _identifierType.value.isPhoneNumber //
      ? clerk.Strategy.resetPasswordPhoneCode
      : clerk.Strategy.resetPasswordEmailCode;

  Future<void> _initiatePasswordReset(ClerkAuthState authState) async {
    setState(() {
      _flowState = _ResetFlowState.started;
      _code = '';
    });

    await authState.initiatePasswordReset(
      identifier: _identifierType.value.sanitize(_identifier),
      strategy: _strategy,
    );

    final newFlowState =
        authState.signIn?.status == clerk.Status.needsFirstFactor
            ? _ResetFlowState.awaitingCode
            : _ResetFlowState.unstarted;
    setState(() => _flowState = newFlowState);
  }

  Future<bool> _setCode(String code) async {
    setState(() => _code = code);
    return true;
  }

  void _toggleObscurePassword() => setState(() => _obscured = !_obscured);

  void _restartFlow() => setState(() => _flowState = _ResetFlowState.unstarted);

  Future<void> _submit(ClerkAuthState authState, BuildContext context) async {
    if (authState.checkPassword(_password, _confirmation, context)
        case String errorMessage) {
      authState.handleError(
        clerk.ClerkError.clientAppError(message: errorMessage),
      );
    } else {
      final code = _code;
      setState(() => _flowState = _ResetFlowState.awaitingReset);
      await authState.attemptSignIn(
        strategy: _strategy,
        identifier: _identifier,
        password: _password,
        code: code,
      );
      if (context.mounted) {
        if (authState.isSignedIn) {
          Navigator.of(context).pop(true);
        } else {
          final l10ns = ClerkAuth.localizationsOf(context);
          authState.handleError(
            clerk.ClerkError.clientAppError(message: l10ns.resetFailed),
          );
          await _initiatePasswordReset(authState);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    if (authState.isNotAvailable) {
      return emptyWidget;
    }

    final l10ns = ClerkAuth.localizationsOf(context);
    final factors = authState.env.config.firstFactors
        .where((f) => f.isPasswordResetter)
        .toList(growable: false);

    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return AlertDialog(
      scrollable: true,
      backgroundColor: themeExtension.colors.background,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClerkPanelHeader(
            title: l10ns.forgottenPassword,
            padding: EdgeInsets.zero,
          ),
          Closeable(
            closed: _flowState.isUnstarted == false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClerkIdentifierInput(
                  strategies: factors,
                  identifierType: _identifierType,
                  onChanged: (identifier) =>
                      _identifier = identifier.identifier,
                  onSubmit: (_) => _initiatePasswordReset(authState),
                ),
                verticalMargin8,
                _ActionButton(
                  onPressed: () => _initiatePasswordReset(authState),
                  label: l10ns.sendMeTheCode,
                  isProcessing: _flowState.isAwaitingReset,
                ),
              ],
            ),
          ),
          Closeable(
            closed: _flowState.isAwaitingCode == false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClerkCodeInput(
                  key: const Key('code'),
                  code: _code,
                  subtitle: l10ns.enterTheCodeSentTo(_identifier),
                  onSubmit: _setCode,
                ),
                Closeable(
                  closed: _code.length == 6,
                  child: Column(
                    children: [
                      verticalMargin8,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ActionButton(
                          label: l10ns.didntReceiveCode,
                          onPressed: _restartFlow,
                        ),
                      ),
                    ],
                  ),
                ),
                Closeable(
                  closed: _code.length != 6,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        verticalMargin16,
                        ClerkTextFormField(
                          label: l10ns.newPassword,
                          obscureText: _obscured,
                          autofillHints: const [AutofillHints.newPassword],
                          onObscure: _toggleObscurePassword,
                          onChanged: (password) => _password = password,
                          onSubmit: (_) => _submit(authState, context),
                        ),
                        verticalMargin8,
                        ClerkTextFormField(
                          label: l10ns.newPasswordConfirmation,
                          obscureText: _obscured,
                          autofillHints: const [AutofillHints.newPassword],
                          onObscure: _toggleObscurePassword,
                          onChanged: (conf) => _confirmation = conf,
                          onSubmit: (_) => _submit(authState, context),
                        ),
                        verticalMargin8,
                        _ActionButton(
                          onPressed: () => _submit(authState, context),
                          label: l10ns.resetPassword,
                          isProcessing:
                              _flowState.isAwaitingReset, // hack by-product
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.label,
    this.isProcessing = false,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return defaultLoadingWidget;
    }

    return ClerkMaterialButton(
      style: ClerkMaterialButtonStyle.dark,
      onPressed: onPressed,
      label: Padding(
        padding: horizontalPadding8,
        child: Text(label),
      ),
    );
  }
}

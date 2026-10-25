import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_sdk_localization_ext.dart';
import 'package:clerk_flutter/src/utils/clerk_telemetry.dart';
import 'package:clerk_flutter/src/utils/identifier.dart';
import 'package:clerk_flutter/src/utils/localization_extensions.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_code_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_control_buttons.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_material_button.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_phone_number_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:clerk_flutter/src/widgets/ui/strategy_button.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The [ClerkSignUpPanel] renders a UI for signing up users.
///
/// The functionality of the [ClerkSignUpPanel] is controlled by the instance settings
/// you specify in your Clerk Dashboard, such as sign-in and social connections. You can
/// further customize your [ClerkSignUpPanel] by passing additional properties.
///
/// https://clerk.com/docs/components/authentication/sign-up
///
@immutable
class ClerkSignUpPanel extends StatefulWidget {
  /// Construct a new [ClerkSignUpPanel]
  const ClerkSignUpPanel({super.key});

  @override
  State<ClerkSignUpPanel> createState() => _ClerkSignUpPanelState();
}

class _ClerkSignUpPanelState extends State<ClerkSignUpPanel>
    with ClerkTelemetryStateMixin {
  static const _uaFieldMap = {
    clerk.Field.emailAddress: clerk.UserAttribute.emailAddress,
    clerk.Field.phoneNumber: clerk.UserAttribute.phoneNumber,
    clerk.Field.firstName: clerk.UserAttribute.firstName,
    clerk.Field.lastName: clerk.UserAttribute.lastName,
    clerk.Field.username: clerk.UserAttribute.username,
    clerk.Field.password: clerk.UserAttribute.password,
  };

  final Map<clerk.UserAttribute, Identifier?> _values = {};
  bool _needsLegalAcceptance = true;
  bool _hasLegalAcceptance = false;
  bool _highlightMissing = false;
  clerk.Strategy _strategy = clerk.Strategy.password;

  static const _signUpAttributes = [
    clerk.UserAttribute.firstName,
    clerk.UserAttribute.lastName,
    clerk.UserAttribute.username,
    clerk.UserAttribute.emailAddress,
    clerk.UserAttribute.phoneNumber,
    clerk.UserAttribute.password,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authState = ClerkAuth.of(context, listen: false);

    _needsLegalAcceptance = authState.env.user.signUp.legalConsentEnabled;

    if (authState.signUp case clerk.SignUp signUp) {
      _values[clerk.UserAttribute.firstName] ??=
          Identifier.orNull(signUp.firstName);
      _values[clerk.UserAttribute.lastName] ??=
          Identifier.orNull(signUp.lastName);
      _values[clerk.UserAttribute.username] ??=
          Identifier.orNull(signUp.username);
      _values[clerk.UserAttribute.emailAddress] ??=
          Identifier.orNull(signUp.emailAddress);
      _values[clerk.UserAttribute.phoneNumber] ??=
          PhoneNumberIdentifier.orNull(signUp.phoneNumber);
    }
  }

  String? _valueOrNull(clerk.UserAttribute? attr) =>
      _values[attr]?.identifier.trim().orNullIfEmpty;

  Future<void> _sendCode(
    ClerkAuthState authState,
    String code,
    clerk.Strategy strategy,
  ) async {
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      await authState.attemptSignUp(strategy: strategy, code: code);
    });
  }

  Future<void> _resend(
    ClerkAuthState authState,
    clerk.Strategy strategy,
  ) async {
    await authState.safelyCall(context, () async {
      await authState.resendCode(strategy);
    });
  }

  Future<void> _continue(
    ClerkAuthState authState,
    List<_Attribute> attributes, {
    clerk.Strategy? strategy,
  }) async {
    final l10ns = authState.localizationsOf(context);

    _strategy = strategy ?? _strategy;

    final password = _valueOrNull(clerk.UserAttribute.password);
    if (authState.signUp?.missing(clerk.Field.password) == true &&
        password == null) {
      authState.handleError(
        clerk.ClerkError.clientAppError(message: l10ns.passwordMustBeSupplied),
      );
      return;
    }

    final passwordConfirmation =
        _valueOrNull(clerk.UserAttribute.passwordConfirmation);
    if (authState.checkPassword(password, passwordConfirmation, context)
        case String error) {
      authState.handleError(
        clerk.ClerkError.clientAppError(message: error),
      );
      return;
    }

    if (_requiresInformation(authState.signUp, attributes)) {
      authState.handleError(
        clerk.ClerkError.clientAppError(
          message: l10ns.pleaseAddRequiredInformation,
        ),
      );
      setState(() => _highlightMissing = true);
      return;
    }

    if (_strategy.isPassword &&
        authState.signUp?.unverified(clerk.Field.phoneNumber) == true) {
      _strategy = clerk.Strategy.phoneCode;
    }

    final username = _valueOrNull(clerk.UserAttribute.username);
    final emailAddress = _valueOrNull(clerk.UserAttribute.emailAddress);
    final phoneNumber = _valueOrNull(clerk.UserAttribute.phoneNumber);
    final redirectUrl =
        authState.emailVerificationRedirectUri(context)?.toString();

    await authState.safelyCall(
      context,
      () async {
        await authState.attemptSignUp(
          strategy: _strategy,
          firstName: _valueOrNull(clerk.UserAttribute.firstName),
          lastName: _valueOrNull(clerk.UserAttribute.lastName),
          username: username,
          emailAddress: emailAddress,
          phoneNumber: phoneNumber,
          password: password,
          passwordConfirmation: passwordConfirmation,
          redirectUrl: redirectUrl,
          legalAccepted: _needsLegalAcceptance ? _hasLegalAcceptance : null,
        );

        if (authState.signUp case clerk.SignUp signUp when mounted) {
          if (_requiresInformation(signUp, attributes)) {
            setState(() => _highlightMissing = true);
            authState.handleError(
              clerk.ClerkError.clientAppError(
                message: l10ns.pleaseAddRequiredInformation,
              ),
            );
          } else {
            final env = authState.env;
            if (signUp.requiresEnterpriseSSOSignUp) {
              await authState.ssoSignUp(context, clerk.Strategy.enterpriseSSO);
            } else if (env.supportsPhoneCode &&
                signUp.unverified(clerk.Field.phoneNumber)) {
              await _prepareVerification(authState, clerk.Strategy.phoneCode);
            } else if (signUp.unverified(clerk.Field.emailAddress)) {
              if (env.supportsEmailCode && env.supportsEmailLink == false) {
                await _prepareVerification(authState, clerk.Strategy.emailCode);
              } else if (env.supportsEmailLink &&
                  env.supportsEmailCode == false) {
                await _prepareVerification(authState, clerk.Strategy.emailLink);
              }
            }
          }
        }
      },
    );
  }

  bool _requiresInformation(clerk.SignUp? signUp, List<_Attribute> attrs) =>
      switch (signUp?.missingFields) {
        List<clerk.Field> missingFields => missingFields.any(
            (f) => f == clerk.Field.legalAccepted
                ? _hasLegalAcceptance == false
                : _valueOrNull(_uaFieldMap[f]) == null,
          ),
        _ => attrs.any((a) => a.isRequired && _valueOrNull(a.attr) == null),
      };

  Future<void> _prepareVerification(
    ClerkAuthState authState,
    clerk.Strategy strategy,
  ) async {
    _strategy = strategy;
    await authState.attemptSignUp(
      strategy: strategy,
      redirectUrl: strategy.isEmailLink
          ? authState.emailVerificationRedirectUri(context)?.toString()
          : null,
    );
  }

  void _acceptTerms(bool hasLegalAcceptance) =>
      setState(() => _hasLegalAcceptance = hasLegalAcceptance);

  Future<void> _reset(ClerkAuthState authState) async {
    _strategy = clerk.Strategy.password;
    await authState.resetClient();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ClerkAuth.of(context);
    if (authState.isNotAvailable) {
      return emptyWidget;
    }

    final env = authState.env;
    final signUp = authState.signUp;
    final l10ns = authState.localizationsOf(context);
    final userAttrs = authState.env.user.attributes;
    final attributes = [
      for (final attr in _signUpAttributes) //
        if (userAttrs[attr] case clerk.UserAttributeData data
            when data.isEnabled) //
          _Attribute(attr, data),
    ];

    final hasMissingFields = signUp?.missingFields.isNotEmpty == true;
    final awaitingPhoneCode = hasMissingFields == false &&
        signUp?.awaiting(clerk.Field.phoneNumber) == true;
    final needsEmail = hasMissingFields == false &&
        (env.supportsEmailCode || env.supportsEmailLink) &&
        signUp?.unverified(clerk.Field.emailAddress) == true;
    final awaitingEmailCode = awaitingPhoneCode == false &&
        _strategy == clerk.Strategy.emailCode &&
        needsEmail;
    final awaitingEmailLink = awaitingPhoneCode == false &&
        awaitingEmailCode == false &&
        _strategy == clerk.Strategy.emailLink &&
        needsEmail;
    final needsEmailStrategy =
        needsEmail && awaitingEmailCode == false && awaitingEmailLink == false;
    final awaitingSomething = needsEmail || awaitingPhoneCode;

    // if we have both first and last name, associate them
    attributes.firstWhereOrNull((a) => a.isFirstName)?.associated =
        attributes.removeFirstOrNull((a) => a.isLastName);

    final emailAddress =
        _values[clerk.UserAttribute.emailAddress]?.prettyIdentifier;

    // if we have a password, associate a confirmation
    final password = attributes.firstWhereOrNull((a) => a.isPassword);
    password?.associated =
        _Attribute(clerk.UserAttribute.passwordConfirmation, password.data);

    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phone code input
          if (env.supportsPhoneCode) //
            _CodeInputBox(
              attribute: clerk.UserAttribute.phoneNumber,
              value: _values[clerk.UserAttribute.phoneNumber]?.prettyIdentifier,
              localizations: l10ns,
              open: awaitingPhoneCode,
              onSubmit: (code) async {
                await _sendCode(authState, code, clerk.Strategy.phoneCode);
                return false;
              },
              onResend: () => _resend(authState, clerk.Strategy.phoneCode),
            ),

          // Email code input
          if (env.supportsEmailCode) //
            _CodeInputBox(
              attribute: clerk.UserAttribute.emailAddress,
              value: emailAddress,
              localizations: l10ns,
              open: awaitingEmailCode,
              onSubmit: (code) async {
                await _sendCode(authState, code, clerk.Strategy.emailCode);
                return false;
              },
              onResend: () => _resend(authState, clerk.Strategy.emailCode),
            ),

          // Email link message
          if (env.supportsEmailLink) //
            Openable(
              open: awaitingEmailLink,
              builder: (context) => Column(
                children: [
                  Text(
                    emailAddress is String
                        ? l10ns.clickOnTheLinkThatsBeenSentTo(emailAddress)
                        : l10ns.clickOnTheLinkThatsBeenSentToYou,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: themeExtension.styles.subheading,
                  ),
                  verticalMargin16,
                  defaultLoadingWidget,
                ],
              ),
            ),

          // Choose email strategy
          if (needsEmail) //
            Openable(
              open: awaitingPhoneCode == false && needsEmailStrategy,
              builder: (context) => Column(
                children: [
                  for (final strategy in [
                    if (env.supportsEmailCode) clerk.Strategy.emailCode,
                    if (env.supportsEmailLink) clerk.Strategy.emailLink,
                  ]) //
                    Padding(
                      padding: topPadding4,
                      child: StrategyButton(
                        key: ValueKey<clerk.Strategy>(strategy),
                        strategy: strategy,
                        safeIdentifier:
                            _valueOrNull(clerk.UserAttribute.emailAddress),
                        onClick: () async {
                          await authState.safelyCall(
                            context,
                            () => _prepareVerification(authState, strategy),
                          );
                        },
                      ),
                    ),
                  verticalMargin8,
                ],
              ),
            ),

          // Input fields
          Openable(
            open: awaitingSomething == false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final attribute in attributes) //
                  if (hasMissingFields == false ||
                      signUp?.missing(
                              clerk.Field.forUserAttribute(attribute.attr)) ==
                          true)
                    _FormField(
                      attribute: attribute,
                      authState: authState,
                      localizations: l10ns,
                      values: _values,
                      highlight: _highlightMissing,
                    ),
              ],
            ),
          ),

          // Control buttons
          _ControlButtons(
            onAcceptTerms: _acceptTerms,
            onContinue: awaitingEmailLink == false
                ? () => _continue(authState, attributes)
                : null,
            onBack: awaitingSomething ? () => _reset(authState) : null,
            needsLegalAcceptance: _needsLegalAcceptance,
            hasLegalAcceptance: _hasLegalAcceptance,
          ),

          verticalMargin32,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.attribute,
    required this.authState,
    required this.localizations,
    required this.values,
    required this.highlight,
  });

  final _Attribute attribute;

  final ClerkAuthState authState;

  final ClerkSdkLocalizations localizations;

  final Map<clerk.UserAttribute, Identifier?> values;

  final bool highlight;

  static final _obscure = ValueNotifier(true);

  bool _isMissing(ClerkAuthState authState, _Attribute attribute) =>
      authState.signUp?.missing(clerk.Field.forUserAttribute(attribute.attr)) ==
          true ||
      (highlight &&
          attribute.isRequired &&
          (values[attribute.attr]?.identifier.trim() ?? '').isEmpty);

  Widget _formField(_Attribute attribute) {
    final hints = switch (attribute.attr) {
      clerk.UserAttribute.emailAddress => const [AutofillHints.email],
      clerk.UserAttribute.username => const [AutofillHints.username],
      clerk.UserAttribute.password => const [AutofillHints.newPassword],
      clerk.UserAttribute.passwordConfirmation => const [
          AutofillHints.newPassword,
        ],
      clerk.UserAttribute.firstName => const [AutofillHints.givenName],
      clerk.UserAttribute.lastName => const [AutofillHints.familyName],
      clerk.UserAttribute.phoneNumber => const [AutofillHints.telephoneNumber],
      _ => null,
    };
    final keyboardType = switch (attribute.attr) {
      clerk.UserAttribute.emailAddress => TextInputType.emailAddress,
      clerk.UserAttribute.phoneNumber => TextInputType.phone,
      clerk.UserAttribute.firstName ||
      clerk.UserAttribute.lastName =>
        TextInputType.name,
      _ => null,
    };

    if (attribute.needsObscuring) {
      return ValueListenableBuilder(
        valueListenable: _obscure,
        builder: (context, obscure, _) {
          return ClerkTextFormField(
            initial: values[attribute.attr]?.identifier,
            label: attribute.title(localizations),
            obscureText: obscure,
            onObscure: () => _obscure.value = !obscure,
            isMissing: _isMissing(authState, attribute),
            autofillHints: hints,
            keyboardType: keyboardType,
            onChanged: (value) => values[attribute.attr] = Identifier(value),
          );
        },
      );
    }

    return ClerkTextFormField(
      initial: values[attribute.attr]?.identifier,
      label: attribute.title(localizations),
      isMissing: _isMissing(authState, attribute),
      autofillHints: hints,
      keyboardType: keyboardType,
      onChanged: (value) => values[attribute.attr] = Identifier(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: bottomPadding16,
      child: switch (attribute) {
        _Attribute attribute when attribute.isPhoneNumber =>
          ClerkPhoneNumberFormField(
            initial: values[attribute.attr]?.identifier,
            label: attribute.title(localizations),
            isMissing: _isMissing(authState, attribute),
            isOptional: attribute.isOptional,
            onChanged: (identifier) => values[attribute.attr] = identifier,
          ),
        _Attribute attribute when attribute.associated is _Attribute => Flex(
            direction: attribute.isFirstName ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(fit: FlexFit.loose, child: _formField(attribute)),
              const SizedBox.square(dimension: 16),
              Flexible(
                fit: FlexFit.loose,
                child: _formField(attribute.associated!),
              ),
            ],
          ),
        _Attribute attribute => _formField(attribute),
      },
    );
  }
}

class _ControlButtons extends StatefulWidget {
  const _ControlButtons({
    required this.onAcceptTerms,
    required this.onContinue,
    required this.onBack,
    required this.needsLegalAcceptance,
    required this.hasLegalAcceptance,
  });

  final ValueChanged<bool> onAcceptTerms;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final bool needsLegalAcceptance;
  final bool hasLegalAcceptance;

  @override
  State<_ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<_ControlButtons> {
  late bool hasLegalAcceptance = widget.hasLegalAcceptance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.needsLegalAcceptance) //
          Closeable(
            closed: widget.onBack is VoidCallback,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final acceptance = hasLegalAcceptance == false;
                    setState(() => hasLegalAcceptance = acceptance);
                    widget.onAcceptTerms(acceptance);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                    child: Icon(
                      hasLegalAcceptance
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                    ),
                  ),
                ),
                const Expanded(child: _LegalAcceptanceConfirmation()),
              ],
            ),
          ),
        Openable(
          open: widget.needsLegalAcceptance == false || hasLegalAcceptance,
          child: Padding(
            padding: verticalPadding16,
            child: ClerkControlButtons(
              onContinue: widget.onContinue,
              onBack: widget.onBack,
            ),
          ),
        )
      ],
    );
  }
}

class _LegalAcceptanceConfirmation extends StatelessWidget {
  const _LegalAcceptanceConfirmation();

  List<TextSpan> _subSpans(
    String text,
    String target,
    String? url,
    ClerkThemeExtension themeExtension,
  ) {
    if (url case String url when url.isNotEmpty) {
      final segments = text.split(target);
      final spans = [TextSpan(text: segments.first)];
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrlString(url);

      for (final segmentText in segments.skip(1)) {
        spans.add(
          TextSpan(
            text: target,
            style: TextStyle(color: themeExtension.colors.accent),
            recognizer: recognizer,
          ),
        );
        if (segmentText.isNotEmpty) {
          spans.add(TextSpan(text: segmentText));
        }
      }

      return spans;
    }

    return [TextSpan(text: text)];
  }

  // We're assuming here that, whatever language has had its localizations
  // generated, the `termsOfService` and `privacyPolicy` will be literal
  // unique substrings of `acceptTerms`, so can be turned into links in
  // this manner - and it's the responsibility of the engineer dealing with
  // translations to ensure that's the case, so that this will work. (I'm not
  // aware of any language where that won't work, but would love to be told
  // if there is one.)
  List<InlineSpan> _spans(BuildContext context) {
    final authState = ClerkAuth.of(context, listen: false);
    final display = authState.env.display;
    final l10ns = authState.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    final spans = _subSpans(
      l10ns.acceptTerms,
      l10ns.termsOfService,
      display.termsUrl,
      themeExtension,
    );

    return [
      for (final span in spans) //
        if (span.text case String text when span.recognizer == null) //
          ..._subSpans(
            text,
            l10ns.privacyPolicy,
            display.privacyPolicyUrl,
            themeExtension,
          )
        else //
          span,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Text.rich(
      TextSpan(children: _spans(context)),
      maxLines: 2,
      style: themeExtension.styles.subheading,
    );
  }
}

class _CodeInputBox extends StatefulWidget {
  const _CodeInputBox({
    required this.attribute,
    required this.onResend,
    required this.onSubmit,
    required this.localizations,
    required this.open,
    required this.value,
  });

  final clerk.UserAttribute attribute;

  final Future<bool> Function(String) onSubmit;

  final VoidCallback onResend;

  final ClerkSdkLocalizations localizations;

  final bool open;

  final String? value;

  @override
  State<_CodeInputBox> createState() => _CodeInputBoxState();
}

class _CodeInputBoxState extends State<_CodeInputBox> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Openable(
      open: widget.open,
      onEnd: (closed) {
        if (closed == false) {
          _focus.requestFocus();
        }
      },
      child: Padding(
        padding: verticalPadding8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClerkCodeInput(
              key: Key(widget.attribute.name),
              focusNode: _focus,
              title: switch (widget.attribute) {
                clerk.UserAttribute.emailAddress =>
                  widget.localizations.verifyYourEmailAddress,
                clerk.UserAttribute.phoneNumber =>
                  widget.localizations.verifyYourPhoneNumber,
                _ => widget.attribute.toString(),
              },
              subtitle: widget.value is String
                  ? widget.localizations.enterTheCodeSentTo(widget.value!)
                  : widget.localizations.enterTheCodeSentToYou,
              onSubmit: widget.onSubmit,
            ),
            Padding(
              padding: topPadding8,
              child: SizedBox(
                width: 80,
                height: 20,
                child: ClerkMaterialButton(
                  style: ClerkMaterialButtonStyle.light,
                  onPressed: widget.onResend,
                  label: Text(widget.localizations.resend),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Attribute {
  _Attribute(this.attr, this.data);

  final clerk.UserAttribute attr;

  final clerk.UserAttributeData data;

  _Attribute? associated;

  bool get isPhoneNumber => attr == clerk.UserAttribute.phoneNumber;

  bool get isPassword => attr == clerk.UserAttribute.password;

  bool get isFirstName => attr == clerk.UserAttribute.firstName;

  bool get isLastName => attr == clerk.UserAttribute.lastName;

  bool get isRequired => data.isRequired;

  bool get isOptional => isRequired == false;

  bool get needsObscuring =>
      isPassword || attr == clerk.UserAttribute.passwordConfirmation;

  String title(ClerkSdkLocalizations l10ns) =>
      l10ns.grammar.toSentence(attr.localizedMessage(l10ns));
}

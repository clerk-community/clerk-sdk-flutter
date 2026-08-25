import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/utils/clerk_sdk_localization_ext.dart';
import 'package:clerk_flutter/src/utils/identifier.dart';
import 'package:clerk_flutter/src/utils/localization_extensions.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_phone_number_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:phone_input/phone_input_package.dart';

/// A class that allows an identifier to be input, depending on what the
/// env allows
///
/// Will swap between phone based input and pure textual
///
class ClerkIdentifierInput extends StatefulWidget {
  /// Constructor
  const ClerkIdentifierInput({
    super.key,
    required this.onChanged,
    required this.strategies,
    this.identifierType,
    this.initialValue,
    this.onSubmit,
  });

  /// The method to call when the input text changes
  final ValueChanged<Identifier> onChanged;

  /// The method to call when the input text is submitted
  final ValueChanged<Identifier?>? onSubmit;

  /// Available strategies
  final List<clerk.Strategy> strategies;

  /// The method to toggle phone/email input
  final ValueNotifier<clerk.IdentifierType>? identifierType;

  /// The value with which to initialise the field
  final Identifier? initialValue;

  @override
  State<ClerkIdentifierInput> createState() => _ClerkIdentifierInputState();
}

class _ClerkIdentifierInputState extends State<ClerkIdentifierInput> {
  late ValueNotifier<clerk.IdentifierType> identifierType =
      widget.identifierType ?? ValueNotifier(clerk.IdentifierType.emailAddress);
  late List<clerk.Strategy> phoneStrategies;
  late List<clerk.Strategy> emailStrategies;

  final _identifiers = <clerk.IdentifierType, Identifier?>{};

  bool get hasEmailStrategies => emailStrategies.isNotEmpty;

  bool get hasPhoneStrategies => phoneStrategies.isNotEmpty;

  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    phoneStrategies = widget.strategies.where((f) => f.isPhone).toList();
    emailStrategies =
        widget.strategies.where((f) => f.isPhone == false).toList();

    if (_checkPhoneNumber(widget.initialValue?.identifier) case final ident?) {
      identifierType.value = clerk.IdentifierType.phoneNumber;
      _identifiers[clerk.IdentifierType.phoneNumber] = ident;
    } else if (emailStrategies.isNotEmpty) {
      identifierType.value = clerk.IdentifierType.emailAddress;
      _identifiers[clerk.IdentifierType.emailAddress] = widget.initialValue;
    } else {
      identifierType.value = clerk.IdentifierType.phoneNumber;
    }

    _setFocus();
  }

  void _onChanged(Identifier identifier) {
    _identifiers[identifierType.value] = identifier;
    widget.onChanged(identifier);
  }

  void _onSubmit(String _) {
    widget.onSubmit?.call(_identifiers[identifierType.value]);
  }

  Identifier? _checkPhoneNumber(String? identifier) {
    if (identifier?.trim() case String identifier when identifier.isNotEmpty) {
      try {
        if (PhoneNumber.parse(identifier) case PhoneNumber number
            when number.isValid()) {
          return PhoneNumberIdentifier(
            number.international,
            number.intlFormattedNsn,
          );
        }
      } catch (e) {
        // We want to ignore [PhoneNumberException]s but rethrow other
        // exceptions. Annoyingly, [PhoneNumberException] neither inherits from
        // something available, nor is exported from the phone_input package,so
        // we have to do this instead. Boo.
        if (e.toString().startsWith('PhoneNumberException') == false) {
          rethrow;
        }
      }
    }
    return null;
  }

  void _setFocus() {
    if (identifierType.value.isPhoneNumber) {
      _phoneFocusNode.requestFocus();
    } else {
      _emailFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onToggle() {
    final type = switch (identifierType.value) {
      clerk.IdentifierType.phoneNumber when emailStrategies.isNotEmpty =>
        clerk.IdentifierType.emailAddress,
      _ => clerk.IdentifierType.phoneNumber,
    };
    widget.onChanged(_identifiers[type] ?? const Identifier(''));
    setState(() => identifierType.value = type);
    _setFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.strategies.isEmpty) {
      return emptyWidget;
    }

    final authState = ClerkAuth.of(context);
    final l10ns = authState.localizationsOf(context);
    return Column(
      children: [
        if (hasEmailStrategies) //
          Closeable(
            closed: identifierType.value.isPhoneNumber,
            child: ClerkTextFormField(
              key: const Key('identifier'),
              initial:
                  _identifiers[clerk.IdentifierType.emailAddress]?.identifier,
              label: l10ns.grammar.toSentence(
                l10ns.grammar.toLitany(
                  emailStrategies
                      .map((i) => i.localizedMessage(l10ns))
                      .toList(),
                  context: context,
                ),
              ),
              onChanged: (ident) => _onChanged(Identifier(ident)),
              onSubmit: _onSubmit,
              focusNode: _emailFocusNode,
              // An email address is not prose. Left to the platform defaults,
              // iOS autocorrect rewrites a correctly typed address as it is
              // entered -- capitalising `derek@...` to `Derek@...` because the
              // local part matches a proper noun in its dictionary. The
              // identifier then no longer matches its normalised form on the
              // back end. The hints also let the platform offer saved
              // credentials, which it cannot do without them.
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              trailing: hasPhoneStrategies
                  ? _SwapIdentifierButton(
                      strategies: phoneStrategies,
                      localizations: l10ns,
                      onTap: _onToggle,
                    )
                  : null,
            ),
          ),
        if (hasPhoneStrategies) //
          Closeable(
            closed: identifierType.value.isEmailAddress,
            child: ClerkPhoneNumberFormField(
              key: const Key('phoneIdentifier'),
              initial:
                  _identifiers[clerk.IdentifierType.phoneNumber]?.identifier,
              label: l10ns.grammar.toSentence(
                l10ns.grammar.toLitany(
                  phoneStrategies
                      .map((i) => i.localizedMessage(l10ns))
                      .toList(),
                  context: context,
                ),
              ),
              onChanged: _onChanged,
              onSubmit: _onSubmit,
              focusNode: _phoneFocusNode,
              trailing: hasEmailStrategies
                  ? _SwapIdentifierButton(
                      strategies: emailStrategies,
                      localizations: l10ns,
                      onTap: _onToggle,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _SwapIdentifierButton extends StatelessWidget {
  const _SwapIdentifierButton({
    required this.strategies,
    required this.onTap,
    required this.localizations,
  });

  final List<clerk.Strategy> strategies;
  final VoidCallback onTap;
  final ClerkSdkLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final l10ns = ClerkAuth.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(
          l10ns.grammar.toLitany(
            strategies
                .map((i) => i.localizedMessage(l10ns, concise: true))
                .toList(),
            note: l10ns.switchTo,
            context: context,
          ),
          style: themeExtension.styles.clickableText,
        ),
      ),
    );
  }
}

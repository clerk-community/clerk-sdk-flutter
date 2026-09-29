import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/assets.dart';
import 'package:clerk_flutter/src/utils/clerk_telemetry.dart';
import 'package:clerk_flutter/src/utils/extensions.dart';
import 'package:clerk_flutter/src/utils/localization_extensions.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_cached_image.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_code_input.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_divider.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_icon.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_input_dialog.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_page.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_panel.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_phone_number_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_row_label.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_text_form_field.dart';
import 'package:clerk_flutter/src/widgets/ui/closeable.dart';
import 'package:clerk_flutter/src/widgets/ui/common.dart';
import 'package:clerk_flutter/src/widgets/ui/editable_profile_data.dart';
import 'package:clerk_flutter/src/widgets/user/connect_account_panel.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:phone_input/phone_input_package.dart';

/// [ClerkUserProfile] displays user details
/// and allows their editing
///
class ClerkUserProfile extends StatefulWidget {
  /// Construct a [ClerkUserProfile]
  const ClerkUserProfile({super.key});

  @override
  State<ClerkUserProfile> createState() => _ClerkUserProfileState();
}

class _ClerkUserProfileState extends State<ClerkUserProfile>
    with ClerkTelemetryStateMixin {
  final _passkeyAvailable = PasskeyAuthenticator().isAvailable;

  bool _validate(String? identifier, clerk.IdentifierType type) {
    if (identifier?.trim() case String identifier when identifier.isNotEmpty) {
      switch (type) {
        case clerk.IdentifierType.emailAddress:
          return EmailValidator.validate(identifier);
        case clerk.IdentifierType.phoneNumber:
          return PhoneNumber.parse(identifier).isValid();
        default:
          final localizations = ClerkAuth.localizationsOf(context);
          throw clerk.ClerkError.clientAppError(
            message: localizations.typeTypeInvalid(type.name),
          );
      }
    }
    return false;
  }

  Future<void> _verifyIdentifyingData(
    BuildContext context,
    ClerkAuthState authState,
    String identifier,
  ) async {
    final localizations = authState.localizationsOf(context);

    final uid = authState.user?.identifierFrom(identifier);
    if (uid case clerk.UserIdentifyingData uid when uid.isUnverified) {
      await ClerkInputDialog.show(
        context,
        showOk: false,
        child: ClerkCodeInput(
          title: switch (uid.type) {
            clerk.IdentifierType.emailAddress =>
              localizations.verificationEmailAddress,
            clerk.IdentifierType.phoneNumber =>
              localizations.verificationPhoneNumber,
            _ => uid.type.toString(),
          },
          subtitle: localizations.enterTheCodeSentTo(identifier),
          onSubmit: (code) async {
            await authState.verifyIdentifyingData(uid, code);
            final newUid = authState.user!.identifierFrom(uid.identifier);
            if (context.mounted) Navigator.of(context).pop(true);
            return newUid?.isVerified == true;
          },
        ),
      );
    }
  }

  Future<void> _addIdentifyingData(
    BuildContext context,
    ClerkAuthState authState,
    clerk.IdentifierType type,
  ) async {
    final localizations = authState.localizationsOf(context);

    String identifier = '';

    final submitted = await ClerkInputDialog.show(
      context,
      child: switch (type) {
        clerk.IdentifierType.emailAddress => ClerkTextFormField(
            label: localizations.emailAddress,
            autofocus: true,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) => identifier = text,
            onSubmit: (_) => Navigator.of(context).pop(true),
            validator: (text) => _validate(text, type),
          ),
        clerk.IdentifierType.phoneNumber => ClerkPhoneNumberFormField(
            label: localizations.phoneNumber,
            onChanged: (ident) => identifier = ident.identifier,
            onSubmit: (_) => Navigator.of(context).pop(true),
          ),
        _ => throw clerk.ClerkError.clientAppError(
            message: localizations.typeTypeInvalid(type.name),
          ),
      },
    );

    if (submitted) {
      identifier = identifier.trim().toLowerCase();
      if (_validate(identifier, type)) {
        await authState.addIdentifyingData(identifier, type);
        if (context.mounted) {
          await _verifyIdentifyingData(context, authState, identifier);
        }
      } else {
        throw clerk.ClerkError.clientAppError(
          message: type == clerk.IdentifierType.phoneNumber
              ? localizations.invalidPhoneNumber(identifier)
              : localizations.invalidEmailAddress(identifier),
        );
      }
    }
  }

  Future<void> _update(String name, File? image) async {
    final authState = ClerkAuth.of(context, listen: false);
    await authState.safelyCall(context, () async {
      final user = authState.user!;
      if (name.isNotEmpty && name != user.name) {
        final names = name.split(' ').where((s) => s.isNotEmpty).toList();
        final lastName = names.length > 1 ? names.removeLast() : null;
        final firstName = names.join(' ');
        await authState.updateUser(
          firstName: firstName,
          lastName: lastName,
          avatar: image,
        );
      }
    });
  }

  // For passkeys to work the app needs to be added to the Clerk dashboard
  // Native Applications (https://dashboard.clerk.com/apps/<APPLICATION ID>/instances/<INSTANCE ID>/native-applications)
  //
  // * Android:
  //    * Namespace: 'android_app'
  //    * Package name: '<your app's package name>'
  //    * SHA-256 certificate fingerprint: '<SHA-256 fingerprint>'
  // To find the cert for debug/dev builds:
  // 1. Run `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore` (assuming that's where your keystore is)
  // 2. Enter the password. Default is 'android'
  // 3. Copy the SHA-256 fingerprint
  //
  // * iOS
  //    * App ID prefix: '<your app's team ID>'
  //    * Bundle ID: '<your app's bundle ID>'
  //
  Future<void> _addNewPasskey(ClerkAuthState authState) async {
    await authState.safelyCall(
      context,
      () async {
        final passkey = await authState.createPasskey();
        if (passkey?.verification?.nonce case clerk.VerificationNonce nonce) {
          final authenticator = PasskeyAuthenticator(debugMode: true);
          final challenge = RegisterRequestType(
            challenge: nonce.challenge,
            relyingParty: nonce.relyingParty.toRelyingPartyType(),
            user: nonce.user!.toUserType(),
            excludeCredentials: const [],
            timeout: nonce.timeout,
            // where hardware security keys are unsupported (e.g. iOS
            // simulator) force platform attachment only to avoid
            // system erroring
            authSelectionType:
                authState.config.supportsHardwareSecurityKeys == false
                    ? AuthenticatorSelectionType(
                        authenticatorAttachment: 'platform',
                        requireResidentKey: false,
                        residentKey: '',
                        userVerification: '',
                      )
                    : null,
          );
          final res = await authenticator.register(challenge);
          await authState.attemptPasskeyVerification(
            passkey!,
            res.toJsonString(),
          );
        }
      },
    );
  }

  late final _dateFormatter =
      DateFormat(ClerkAuth.localizationsOf(context).longDateFormat);

  @override
  Widget build(BuildContext context) {
    final l10ns = ClerkAuth.localizationsOf(context);

    return ClerkPanel(
      padding: horizontalPadding24,
      child: ClerkAuthBuilder(
        builder: (_, __) => emptyWidget,
        signedInBuilder: (context, authState) {
          final themeExtension = ClerkAuth.themeExtensionOf(context);
          final user = authState.user!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              verticalMargin32,
              Text(
                l10ns.profileDetails,
                maxLines: 1,
                style: themeExtension.styles.heading,
              ),
              const ClerkDivider(),
              Expanded(
                child: ListView(
                  children: [
                    _ProfileRow(
                      title: l10ns.profile,
                      withDivider: false,
                      child: EditableProfileData(
                        name: user.name,
                        imageUrl: user.imageUrl,
                        onSubmit: _update,
                      ),
                    ),
                    if (authState.env.config.allowsEmailAddress) //
                      _ProfileRow(
                        title: l10ns.emailAddresses,
                        child: _IdentifierList<clerk.Email>(
                          user: user,
                          identifiers: user.emailAddresses,
                          addLine: l10ns.addEmailAddress,
                          builder: (context, email) => Text(
                            email.emailAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: themeExtension.styles.text,
                          ),
                          onAddNew: () => _addIdentifyingData(
                            context,
                            authState,
                            clerk.IdentifierType.emailAddress,
                          ),
                          onIdentifierUnverified: (emailAddress) {
                            _verifyIdentifyingData(
                                context, authState, emailAddress);
                          },
                        ),
                      ),
                    if (authState.env.config.allowsPhoneNumber) //
                      _ProfileRow(
                        title: l10ns.phoneNumbers,
                        child: _IdentifierList<clerk.PhoneNumber>(
                          user: user,
                          identifiers: user.phoneNumbers,
                          builder: (context, number) => Text(
                            PhoneNumber.parse(number.phoneNumber)
                                .intlFormattedNsn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: themeExtension.styles.text,
                          ),
                          addLine: l10ns.addPhoneNumber,
                          onAddNew: () => _addIdentifyingData(
                            context,
                            authState,
                            clerk.IdentifierType.phoneNumber,
                          ),
                          onIdentifierUnverified: (phoneNumber) {
                            _verifyIdentifyingData(
                                context, authState, phoneNumber);
                          },
                        ),
                      ),
                    if (authState.env.supportsPasskeys) //
                      FutureBuilder(
                        future: _passkeyAvailable,
                        builder: (context, snapshot) {
                          return Openable(
                            open: snapshot.data == true,
                            builder: (context) => _ProfileRow(
                              title: l10ns.passkeys,
                              child: _IdentifierList<clerk.Passkey>(
                                user: user,
                                identifiers: user.passkeys,
                                addLine: l10ns.addPasskey,
                                builder: (context, passkey) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passkey.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: themeExtension.styles.text,
                                    ),
                                    verticalMargin4,
                                    Text(
                                      '${l10ns.created}: ${_dateFormatter.format(passkey.createdAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: themeExtension.styles.subtext,
                                    ),
                                    verticalMargin4,
                                    Text(
                                      '${l10ns.lastUsed}: ${_dateFormatter.format(passkey.lastUsedAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: themeExtension.styles.subtext,
                                    ),
                                  ],
                                ),
                                onAddNew: () => _addNewPasskey(authState),
                              ),
                            ),
                          );
                        },
                      ),
                    _ProfileRow(
                      title: l10ns.connectedAccounts,
                      child: _ExternalAccountList(
                        user: user,
                        env: authState.env,
                      ),
                    ),
                  ],
                ),
              ),
              verticalMargin20,
            ],
          );
        },
      ),
    );
  }
}

class _ExternalAccountList extends StatelessWidget {
  const _ExternalAccountList({
    required this.user,
    required this.env,
  });

  final clerk.User user;
  final clerk.Environment env;

  void _onAddNew(BuildContext context) {
    ClerkPage.show(
      context,
      builder: (context) => ConnectAccountPanel(
        onDone: (context) async {
          Navigator.of(context).pop();

          final auth = ClerkAuth.of(context);
          if (auth.user?.externalAccounts case final accounts?) {
            for (final account in accounts) {
              if (account.verification.errorMessage case String errorMessage) {
                final l10ns = ClerkAuth.localizationsOf(context);
                auth.handleError(
                  clerk.ClerkError.clientAppError(
                    message: l10ns.serverErrorResponse(errorMessage),
                  ),
                );
                await auth.deleteExternalAccount(account: account);
              }
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = ClerkAuth.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user.externalAccounts case List<clerk.ExternalAccount> accounts) //
          for (final account in accounts.where((a) => a.isExpired == false)) //
            if (env.user.socialSettings[account.provider]
                case clerk.SocialConnection social) //
              Padding(
                padding: bottomPadding16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClerkCachedImage(social.logoUrl, width: 14),
                    horizontalMargin4,
                    if (account.isVerified) ...[
                      Text(social.name, style: themeExtension.styles.text),
                      horizontalMargin4,
                    ],
                    Expanded(
                      child: Text(
                        account.emailAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: themeExtension.styles.text,
                      ),
                    ),
                    if (account.isVerified == false) //
                      ClerkRowLabel(
                        label: account.verification.status
                            .localizedMessage(localizations)
                            .toUpperCase(),
                      ),
                  ],
                ),
              ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onAddNew(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const ClerkIcon(ClerkAssets.addIconSimpleLight, size: 10),
              horizontalMargin12,
              Expanded(
                child: Text(
                  localizations.connectAccount,
                  style: themeExtension.styles.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentifierList<T extends clerk.UserIdentifyingData>
    extends StatelessWidget {
  const _IdentifierList({
    required this.user,
    required this.addLine,
    required this.builder,
    this.onIdentifierUnverified,
    this.onAddNew,
    this.identifiers,
  });

  final clerk.User user;
  final List<T>? identifiers;
  final String addLine;
  final VoidCallback? onAddNew;
  final ValueChanged<String>? onIdentifierUnverified;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) {
    final localizations = ClerkAuth.localizationsOf(context);
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identifiers case List<T> identifiers) //
          for (final uid in identifiers) //
            Padding(
              padding: bottomPadding16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: builder(context, uid)),
                  if (onIdentifierUnverified case final onIdentifierUnverified?
                      when uid.isUnverified) //
                    ClerkRowLabel(
                      label: localizations.unverified,
                      color: themeExtension.colors.error,
                      onTap: () => onIdentifierUnverified(uid.identifier),
                    ),
                  if (user.isPrimary(uid)) //
                    ClerkRowLabel(label: localizations.primary),
                ],
              ),
            ),
        if (onAddNew is VoidCallback) //
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAddNew,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const ClerkIcon(ClerkAssets.addIconSimpleLight, size: 10),
                horizontalMargin12,
                Expanded(
                  child: Text(addLine, style: themeExtension.styles.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.title,
    required this.child,
    this.withDivider = true,
  });

  final String title;
  final Widget child;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    final themeExtension = ClerkAuth.themeExtensionOf(context);
    return Column(
      children: [
        if (withDivider) //
          const ClerkDivider(),
        Padding(
          padding: topPadding16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  title,
                  maxLines: 2,
                  style: themeExtension.styles.subheading,
                ),
              ),
              horizontalMargin8,
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

extension on clerk.RelyingParty {
  RelyingPartyType toRelyingPartyType() =>
      RelyingPartyType(name: name!, id: id);
}

extension on clerk.PasskeyUser {
  UserType toUserType() =>
      UserType(id: id, name: name, displayName: displayName);
}

// ignore_for_file: public_member_api_docs, use_super_parameters
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'clerk_sdk_localizations_en.dart';

// ignore_for_file: type=lint
// coverage:ignore-file
/// Callers can lookup localized strings with an instance of ClerkSdkLocalizations
/// returned by `ClerkSdkLocalizations.of(context)`.
///
/// Applications need to include `ClerkSdkLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/clerk_sdk_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ClerkSdkLocalizations.localizationsDelegates,
///   supportedLocales: ClerkSdkLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ClerkSdkLocalizations.supportedLocales
/// property.
abstract class ClerkSdkLocalizations {
  ClerkSdkLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ClerkSdkLocalizations? of(BuildContext context) {
    return Localizations.of<ClerkSdkLocalizations>(
        context, ClerkSdkLocalizations);
  }

  static const LocalizationsDelegate<ClerkSdkLocalizations> delegate =
      _ClerkSdkLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @aLengthOfBetweenMINAndMAX.
  ///
  /// In en, this message translates to:
  /// **'a length of between {min} and {max}'**
  String aLengthOfBetweenMINAndMAX(int min, int max);

  /// No description provided for @aLengthOfMINOrGreater.
  ///
  /// In en, this message translates to:
  /// **'a length of {min} or greater'**
  String aLengthOfMINOrGreater(int min);

  /// No description provided for @aLowercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'a LOWERCASE letter'**
  String get aLowercaseLetter;

  /// No description provided for @aNumber.
  ///
  /// In en, this message translates to:
  /// **'a NUMBER'**
  String get aNumber;

  /// No description provided for @aSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'a SPECIAL CHARACTER ({chars})'**
  String aSpecialCharacter(String chars);

  /// No description provided for @abandoned.
  ///
  /// In en, this message translates to:
  /// **'abandoned'**
  String get abandoned;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get acceptTerms;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @addDomain.
  ///
  /// In en, this message translates to:
  /// **'Add domain'**
  String get addDomain;

  /// No description provided for @addEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Add email address'**
  String get addEmailAddress;

  /// No description provided for @addPasskey.
  ///
  /// In en, this message translates to:
  /// **'Add a passkey'**
  String get addPasskey;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get addPhoneNumber;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @anUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'an UPPERCASE letter'**
  String get anUppercaseLetter;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @authenticationServiceError.
  ///
  /// In en, this message translates to:
  /// **'There was an error in the authentication service: {arg}'**
  String authenticationServiceError(String arg);

  /// No description provided for @authenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'authenticator app'**
  String get authenticatorApp;

  /// No description provided for @automaticInvitation.
  ///
  /// In en, this message translates to:
  /// **'Automatic invitation'**
  String get automaticInvitation;

  /// No description provided for @automaticSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Automatic suggestion'**
  String get automaticSuggestion;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backupCode.
  ///
  /// In en, this message translates to:
  /// **'backup code'**
  String get backupCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to delete your user'**
  String get cannotDeleteSelf;

  /// No description provided for @clickOnTheLinkThatsBeenSentTo.
  ///
  /// In en, this message translates to:
  /// **'Click on the link that‘s been sent to {identifier} and then check back here'**
  String clickOnTheLinkThatsBeenSentTo(String identifier);

  /// No description provided for @clickOnTheLinkThatsBeenSentToYou.
  ///
  /// In en, this message translates to:
  /// **'Click on the link that‘s been sent to you and then check back here'**
  String get clickOnTheLinkThatsBeenSentToYou;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get complete;

  /// No description provided for @connectAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect account'**
  String get connectAccount;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get connectedAccounts;

  /// No description provided for @cont.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cont;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create organization'**
  String get createOrganization;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @developmentMode.
  ///
  /// In en, this message translates to:
  /// **'Development mode'**
  String get developmentMode;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @domainName.
  ///
  /// In en, this message translates to:
  /// **'Domain name'**
  String get domainName;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get edit;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'email address'**
  String get emailAddress;

  /// No description provided for @emailAddressConcise.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get emailAddressConcise;

  /// No description provided for @emailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Email addresses'**
  String get emailAddresses;

  /// No description provided for @enrollment.
  ///
  /// In en, this message translates to:
  /// **'Enrollment'**
  String get enrollment;

  /// No description provided for @enrollmentMode.
  ///
  /// In en, this message translates to:
  /// **'Enrollment mode:'**
  String get enrollmentMode;

  /// No description provided for @enterOneOfYourBackupCodes.
  ///
  /// In en, this message translates to:
  /// **'Enter one of your backup codes'**
  String get enterOneOfYourBackupCodes;

  /// No description provided for @enterTheCodeFromYourAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Enter the code generated by your authenticator app'**
  String get enterTheCodeFromYourAuthenticatorApp;

  /// No description provided for @enterTheCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {identifier}'**
  String enterTheCodeSentTo(String identifier);

  /// No description provided for @enterTheCodeSentToYou.
  ///
  /// In en, this message translates to:
  /// **'Enter the code that has been sent to you'**
  String get enterTheCodeSentToYou;

  /// No description provided for @enterTheCodeSentToYouByEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to you by email'**
  String get enterTheCodeSentToYouByEmail;

  /// No description provided for @enterTheCodeSentToYouByTextMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to you by text message'**
  String get enterTheCodeSentToYouByTextMessage;

  /// No description provided for @enterYourOrganizationDetailsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your organization details to continue'**
  String get enterYourOrganizationDetailsToContinue;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get expired;

  /// No description provided for @externalError.
  ///
  /// In en, this message translates to:
  /// **'{arg} (EXTERNAL ERROR)'**
  String externalError(String arg);

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get failed;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'first name'**
  String get firstName;

  /// No description provided for @forgottenPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgotten password?'**
  String get forgottenPassword;

  /// No description provided for @generalDetails.
  ///
  /// In en, this message translates to:
  /// **'General details'**
  String get generalDetails;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address: {address}'**
  String invalidEmailAddress(String address);

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number: {number}'**
  String invalidPhoneNumber(String number);

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'JOIN'**
  String get join;

  /// No description provided for @jwtPoorlyFormatted.
  ///
  /// In en, this message translates to:
  /// **'JWT poorly formatted: {arg}'**
  String jwtPoorlyFormatted(String arg);

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'last name'**
  String get lastName;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveOrg.
  ///
  /// In en, this message translates to:
  /// **'Leave {organization}'**
  String leaveOrg(String organization);

  /// No description provided for @leaveOrganization.
  ///
  /// In en, this message translates to:
  /// **'Leave organization'**
  String get leaveOrganization;

  /// No description provided for @legalAcceptanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Legal acceptance is required to proceed with sign up'**
  String get legalAcceptanceRequired;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @longDateFormat.
  ///
  /// In en, this message translates to:
  /// **'d MMMM y, \'h:mm a'**
  String get longDateFormat;

  /// No description provided for @manualInvitation.
  ///
  /// In en, this message translates to:
  /// **'Manual invitation'**
  String get manualInvitation;

  /// No description provided for @missingRequirements.
  ///
  /// In en, this message translates to:
  /// **'missing requirements'**
  String get missingRequirements;

  /// No description provided for @myOrganization.
  ///
  /// In en, this message translates to:
  /// **'My Organization'**
  String get myOrganization;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @needsFirstFactor.
  ///
  /// In en, this message translates to:
  /// **'needs first factor'**
  String get needsFirstFactor;

  /// No description provided for @needsIdentifier.
  ///
  /// In en, this message translates to:
  /// **'needs identifier'**
  String get needsIdentifier;

  /// No description provided for @needsSecondFactor.
  ///
  /// In en, this message translates to:
  /// **'needs second factor'**
  String get needsSecondFactor;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get newPasswordConfirmation;

  /// No description provided for @noAssociatedCodeRetrievalMethod.
  ///
  /// In en, this message translates to:
  /// **'Could not find a code retrieval method associated with {arg}'**
  String noAssociatedCodeRetrievalMethod(String arg);

  /// No description provided for @noAssociatedStrategy.
  ///
  /// In en, this message translates to:
  /// **'No strategy associated with {arg}'**
  String noAssociatedStrategy(String arg);

  /// No description provided for @noInitialCodeHasBeenSetUpToResend.
  ///
  /// In en, this message translates to:
  /// **'No initial code has been set up to resend'**
  String get noInitialCodeHasBeenSetUpToResend;

  /// No description provided for @noSessionFoundForUser.
  ///
  /// In en, this message translates to:
  /// **'No session found for user {arg}'**
  String noSessionFoundForUser(String arg);

  /// No description provided for @noSessionTokenRetrieved.
  ///
  /// In en, this message translates to:
  /// **'No session token retrieved'**
  String get noSessionTokenRetrieved;

  /// No description provided for @noStageForStatus.
  ///
  /// In en, this message translates to:
  /// **'No stage found for status {arg}'**
  String noStageForStatus(String arg);

  /// No description provided for @noSuchFirstFactorStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy {arg} not supported for first factor'**
  String noSuchFirstFactorStrategy(String arg);

  /// No description provided for @noSuchSecondFactorStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy {arg} not supported for second factor'**
  String noSuchSecondFactorStrategy(String arg);

  /// No description provided for @noUserAttributeForField.
  ///
  /// In en, this message translates to:
  /// **'No user attribute found for field {arg}'**
  String noUserAttributeForField(String arg);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optional;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @organizationProfile.
  ///
  /// In en, this message translates to:
  /// **'Organization profile'**
  String get organizationProfile;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @passkey.
  ///
  /// In en, this message translates to:
  /// **'passkey'**
  String get passkey;

  /// No description provided for @passkeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeys;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'confirm password'**
  String get passwordConfirmation;

  /// No description provided for @passwordMatchError.
  ///
  /// In en, this message translates to:
  /// **'Password and password confirmation must match'**
  String get passwordMatchError;

  /// No description provided for @passwordMustBeSupplied.
  ///
  /// In en, this message translates to:
  /// **'A password must be supplied'**
  String get passwordMustBeSupplied;

  /// No description provided for @passwordRequires.
  ///
  /// In en, this message translates to:
  /// **'Password requires:'**
  String get passwordRequires;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal account'**
  String get personalAccount;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberConcise.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get phoneNumberConcise;

  /// No description provided for @phoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers'**
  String get phoneNumbers;

  /// No description provided for @pleaseAddRequiredInformation.
  ///
  /// In en, this message translates to:
  /// **'Something seems to be missing. Please add the required information'**
  String get pleaseAddRequiredInformation;

  /// No description provided for @pleaseChooseAnAccountToConnect.
  ///
  /// In en, this message translates to:
  /// **'Please choose an account to connect'**
  String get pleaseChooseAnAccountToConnect;

  /// No description provided for @pleaseEnterYourIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Please enter your identifier'**
  String get pleaseEnterYourIdentifier;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get primary;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetails;

  /// No description provided for @recommendSize.
  ///
  /// In en, this message translates to:
  /// **'Recommend size 1:1, up to 5MB.'**
  String get recommendSize;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'(required)'**
  String get requiredField;

  /// No description provided for @requiredFieldsAreMissing.
  ///
  /// In en, this message translates to:
  /// **'Required fields are missing'**
  String get requiredFieldsAreMissing;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'That password reset attempt failed. A new code has been sent.'**
  String get resetFailed;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password and sign in'**
  String get resetPassword;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select the account with which you wish to continue'**
  String get selectAccount;

  /// No description provided for @sendMeTheCode.
  ///
  /// In en, this message translates to:
  /// **'Send me the reset code'**
  String get sendMeTheCode;

  /// No description provided for @serverErrorResponse.
  ///
  /// In en, this message translates to:
  /// **'{arg} (ERROR RECEIVED FROM SERVER)'**
  String serverErrorResponse(String arg);

  /// No description provided for @setUpYourOrganization.
  ///
  /// In en, this message translates to:
  /// **'Set up your organization'**
  String get setUpYourOrganization;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInByCodeSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Send code to your email'**
  String get signInByCodeSentToYourEmail;

  /// No description provided for @signInByEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Email code to {arg}'**
  String signInByEmailCode(String arg);

  /// No description provided for @signInByEmailLink.
  ///
  /// In en, this message translates to:
  /// **'Email link to {arg}'**
  String signInByEmailLink(String arg);

  /// No description provided for @signInByEnteringOneOfYourBackupCodes.
  ///
  /// In en, this message translates to:
  /// **'Use a backup codes'**
  String get signInByEnteringOneOfYourBackupCodes;

  /// No description provided for @signInByLinkSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Send link to your email'**
  String get signInByLinkSentToYourEmail;

  /// No description provided for @signInBySMSCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS code to {arg}'**
  String signInBySMSCode(String arg);

  /// No description provided for @signInBySMSCodeToYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Send code to your phone'**
  String get signInBySMSCodeToYourPhone;

  /// No description provided for @signInTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {name}'**
  String signInTo(String name);

  /// No description provided for @signInUsingEnterpriseSSO.
  ///
  /// In en, this message translates to:
  /// **'Sign in using Enterprise SSO'**
  String get signInUsingEnterpriseSSO;

  /// No description provided for @signInUsingYourAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Use your authenticator app'**
  String get signInUsingYourAuthenticatorApp;

  /// No description provided for @signInWithOneOfYourBackupCodes.
  ///
  /// In en, this message translates to:
  /// **'Use one of your backup codes'**
  String get signInWithOneOfYourBackupCodes;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Sign out {identifier}'**
  String signOutIdentifier(String identifier);

  /// No description provided for @signOutOfAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all accounts'**
  String get signOutOfAllAccounts;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signUpTo.
  ///
  /// In en, this message translates to:
  /// **'Sign up to {name}'**
  String signUpTo(String name);

  /// No description provided for @slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get slug;

  /// No description provided for @slugUrl.
  ///
  /// In en, this message translates to:
  /// **'Slug URL'**
  String get slugUrl;

  /// No description provided for @switchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to'**
  String get switchTo;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @tooManyRetries.
  ///
  /// In en, this message translates to:
  /// **'Sorry, the server is busy. Please try again later.'**
  String get tooManyRetries;

  /// No description provided for @transferable.
  ///
  /// In en, this message translates to:
  /// **'transferable'**
  String get transferable;

  /// No description provided for @twoStepVerification.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get twoStepVerification;

  /// No description provided for @typeTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type \'{type}\' is invalid'**
  String typeTypeInvalid(String type);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error has occurred: {arg}'**
  String unknownError(String arg);

  /// No description provided for @unsupportedPasswordResetStrategy.
  ///
  /// In en, this message translates to:
  /// **'Unsupported password reset strategy: {arg}'**
  String unsupportedPasswordResetStrategy(String arg);

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'unverified'**
  String get unverified;

  /// No description provided for @usePasskeyInstead.
  ///
  /// In en, this message translates to:
  /// **'Use passkey instead'**
  String get usePasskeyInstead;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get username;

  /// No description provided for @verificationEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address verification'**
  String get verificationEmailAddress;

  /// No description provided for @verificationPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number verification'**
  String get verificationPhoneNumber;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get verified;

  /// No description provided for @verifiedDomains.
  ///
  /// In en, this message translates to:
  /// **'Verified domains'**
  String get verifiedDomains;

  /// No description provided for @verifyThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Verify this device'**
  String get verifyThisDevice;

  /// No description provided for @verifyYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address'**
  String get verifyYourEmailAddress;

  /// No description provided for @verifyYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number'**
  String get verifyYourPhoneNumber;

  /// No description provided for @viaAutomaticInvitation.
  ///
  /// In en, this message translates to:
  /// **'via automatic invitation'**
  String get viaAutomaticInvitation;

  /// No description provided for @viaAutomaticSuggestion.
  ///
  /// In en, this message translates to:
  /// **'via automatic suggestion'**
  String get viaAutomaticSuggestion;

  /// No description provided for @viaManualInvitation.
  ///
  /// In en, this message translates to:
  /// **'via manual invitation'**
  String get viaManualInvitation;

  /// No description provided for @web3Wallet.
  ///
  /// In en, this message translates to:
  /// **'web3 wallet'**
  String get web3Wallet;

  /// No description provided for @welcomeBackPleaseSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue'**
  String get welcomeBackPleaseSignInToContinue;

  /// No description provided for @welcomePleaseFillInTheDetailsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please fill in the details to get started'**
  String get welcomePleaseFillInTheDetailsToGetStarted;
}

class _ClerkSdkLocalizationsDelegate
    extends LocalizationsDelegate<ClerkSdkLocalizations> {
  const _ClerkSdkLocalizationsDelegate();

  @override
  Future<ClerkSdkLocalizations> load(Locale locale) {
    return SynchronousFuture<ClerkSdkLocalizations>(
        lookupClerkSdkLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_ClerkSdkLocalizationsDelegate old) => false;
}

ClerkSdkLocalizations lookupClerkSdkLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ClerkSdkLocalizationsEn();
  }

  throw FlutterError(
      'ClerkSdkLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

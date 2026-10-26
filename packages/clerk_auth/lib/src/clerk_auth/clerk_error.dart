import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_auth/src/models/api/external_error.dart';

/// Error class renamed this is for backwards compatibility
@Deprecated('Use ClerkError instead.')
typedef AuthError = ClerkError;

/// Error class renamed this is for backwards compatibility
@Deprecated('Use ClerkErrorCode instead.')
typedef AuthErrorCode = ClerkErrorCode;

/// Container for errors encountered during Clerk auth(entication|orization)
///
class ClerkError implements Exception {
  /// Construct an [ClerkError]
  const ClerkError({
    required this.code,
    required this.message,
    this.argument,
    this.errors,
  });

  /// Construct from an [ExternalErrorCollection]
  factory ClerkError.from(ExternalErrorCollection errors) => ClerkError(
        code: ClerkErrorCode.serverErrorResponse,
        message: '{arg} (ERROR RECEIVED FROM SERVER)',
        argument: errors.errorMessage,
        errors: errors,
      );

  /// Construct a client app error
  factory ClerkError.clientAppError({required String message}) => ClerkError(
        code: ClerkErrorCode.clientAppError,
        message: message,
      );

  /// Construct an external error
  factory ClerkError.external(Object error) {
    var argument = error.toString();
    if (argument.startsWith('Instance of ')) {
      argument = error.runtimeType.toString().camelToSentenceCase();
    }
    return ClerkError(
      code: ClerkErrorCode.externalError,
      message: '{arg} (EXTERNAL ERROR)',
      argument: argument,
    );
  }

  /// Error code
  final ClerkErrorCode code;

  /// The associated [message]
  final String message;

  /// Any arguments
  final String? argument;

  /// Any associated [ExternalErrorCollection]
  final ExternalErrorCollection? errors;

  /// Does this error report a verification code the back end rejected?
  ///
  /// Recoverable where the user stands: the code was wrong, but the
  /// verification it was checked against is still valid, so retyping it is
  /// enough. Distinct from an expired or consumed verification, which needs a
  /// new code.
  bool get isIncorrectCode => errors?.containsIncorrectCodeError == true;

  @override
  String toString() {
    if (argument case String argument) {
      return message.replaceFirst('{arg}', argument);
    }
    return message;
  }
}

/// Code to enable consuming apps to identify the error
enum ClerkErrorCode {
  /// Server error response
  serverErrorResponse,

  /// No stage for status
  noStageForStatus,

  /// No session token retrieved
  noSessionTokenRetrieved,

  /// No strategy associated with type,
  noAssociatedStrategy,

  /// No code retrieval method associated with type
  noAssociatedCodeRetrievalMethod,

  /// Password and password confirmation must match
  passwordMatchError,

  /// Legal acceptance required
  legalAcceptanceRequired,

  /// JWT poorly formatted
  jwtPoorlyFormatted,

  /// No initial code has been set up to resend
  noInitialCodeHasBeenSetUpToResend,

  /// No session found for user
  noSessionFoundForUser,

  /// Unsupported strategy for first factor
  noSuchFirstFactorStrategy,

  /// Unsupported strategy for second factor
  noSuchSecondFactorStrategy,

  /// No user attribute found for field
  noUserAttributeForField,

  /// Password reset error
  passwordResetStrategyError,

  /// You are not authorized to delete your user
  cannotDeleteSelf,

  /// Unknown error
  unknownError,

  /// too many retries
  tooManyRetries,

  /// Client app error
  clientAppError,

  /// External error
  externalError,
}

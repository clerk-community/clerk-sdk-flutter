import 'package:clerk_auth/src/clerk_auth/clerk_error.dart';
import 'package:clerk_auth/src/models/api/external_error.dart';

import '../../test_helpers.dart';

void main() {
  group('ClerkError', () {
    group('constructor', () {
      test('creates error with required fields', () {
        const error = ClerkError(
          code: ClerkErrorCode.unknownError,
          message: 'An error occurred',
        );

        expect(error.code, ClerkErrorCode.unknownError);
        expect(error.message, 'An error occurred');
        expect(error.argument, isNull);
        expect(error.errors, isNull);
      });

      test('creates error with all fields', () {
        const error = ClerkError(
          code: ClerkErrorCode.serverErrorResponse,
          message: 'Error: {arg}',
          argument: 'test argument',
        );

        expect(error.code, ClerkErrorCode.serverErrorResponse);
        expect(error.message, 'Error: {arg}');
        expect(error.argument, 'test argument');
      });
    });

    group('factory constructors', () {
      test('from creates error from ExternalErrorCollection', () {
        const externalErrors = ExternalErrorCollection(
          errors: [
            ExternalError(
              message: 'External error message',
              code: 'external_error',
            ),
          ],
        );

        final error = ClerkError.from(externalErrors);

        expect(error.code, ClerkErrorCode.serverErrorResponse);
        expect(error.message, contains('ERROR RECEIVED FROM SERVER'));
        expect(error.errors, externalErrors);
      });

      test('clientAppError creates error with clientAppError code', () {
        final error = ClerkError.clientAppError(
          message: 'Client app error message',
        );

        expect(error.code, ClerkErrorCode.clientAppError);
        expect(error.message, 'Client app error message');
      });
    });

    group('toString', () {
      test('returns message when no argument', () {
        const error = ClerkError(
          code: ClerkErrorCode.unknownError,
          message: 'Simple error message',
        );

        expect(error.toString(), 'Simple error message');
      });

      test('replaces {arg} placeholder with argument', () {
        const error = ClerkError(
          code: ClerkErrorCode.noSessionFoundForUser,
          message: 'No session found for {arg}',
          argument: 'John Doe',
        );

        expect(error.toString(), 'No session found for John Doe');
      });

      test('handles message without placeholder when argument exists', () {
        const error = ClerkError(
          code: ClerkErrorCode.unknownError,
          message: 'Error without placeholder',
          argument: 'unused argument',
        );

        expect(error.toString(), 'Error without placeholder');
      });
    });

    group('implements Exception', () {
      test('can be thrown and caught as Exception', () {
        const error = ClerkError(
          code: ClerkErrorCode.unknownError,
          message: 'Test error',
        );

        expect(
          () => throw error,
          throwsA(isA<Exception>()),
        );
      });

      test('can be caught as ClerkError', () {
        const error = ClerkError(
          code: ClerkErrorCode.passwordMatchError,
          message: 'Passwords do not match',
        );

        expect(
          () => throw error,
          throwsA(isA<ClerkError>()),
        );
      });
    });
  });

  group('ClerkErrorCode', () {
    test('has all expected error codes', () {
      expect(
          ClerkErrorCode.values.contains(ClerkErrorCode.serverErrorResponse));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.noStageForStatus));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.noSessionTokenRetrieved));
      expect(
          ClerkErrorCode.values.contains(ClerkErrorCode.noAssociatedStrategy));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.noAssociatedCodeRetrievalMethod));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.passwordMatchError));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.jwtPoorlyFormatted));
      expect(
          ClerkErrorCode.values.contains(ClerkErrorCode.noSessionFoundForUser));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.noUserAttributeForField));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.noSuchFirstFactorStrategy));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.noSuchSecondFactorStrategy));
      expect(ClerkErrorCode.values
          .contains(ClerkErrorCode.passwordResetStrategyError));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.cannotDeleteSelf));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.unknownError));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.tooManyRetries));
      expect(ClerkErrorCode.values.contains(ClerkErrorCode.clientAppError));
    });
  });

  // A rejected code is recoverable in place, and `ClerkSignInPanel` keys its
  // decision to hold the code input on this predicate. Getting it wrong returns
  // the panel to the factor chooser, where retrying re-sends the code and
  // invalidates the one the user is holding.
  group('ClerkError.isIncorrectCode', () {
    test('is true for a server response carrying form_code_incorrect', () {
      const error = ClerkError(
        code: ClerkErrorCode.serverErrorResponse,
        message: 'Incorrect code',
        errors: ExternalErrorCollection(
          errors: [
            ExternalError(
              message: 'Incorrect code',
              code: 'form_code_incorrect',
            ),
          ],
        ),
      );

      expect(error.isIncorrectCode, isTrue);
    });

    test('is false for a different server error', () {
      const error = ClerkError(
        code: ClerkErrorCode.serverErrorResponse,
        message: 'Expired',
        errors: ExternalErrorCollection(
          errors: [
            ExternalError(message: 'Expired', code: 'verification_expired'),
          ],
        ),
      );

      expect(error.isIncorrectCode, isFalse);
    });

    test('is false when the error carries no external errors', () {
      const error = ClerkError(
        code: ClerkErrorCode.unknownError,
        message: 'An error occurred',
      );

      expect(error.isIncorrectCode, isFalse);
    });
  });
}

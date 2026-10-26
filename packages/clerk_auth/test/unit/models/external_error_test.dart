import 'package:clerk_auth/src/clerk_auth/clerk_error.dart';
import 'package:clerk_auth/src/models/api/external_error.dart';

import '../../test_helpers.dart';

void main() {
  group('ExternalError', () {
    test('constructor creates error with required fields', () {
      const error = ExternalError(message: 'Test error');

      expect(error.message, 'Test error');
      expect(error.code, isNull);
      expect(error.meta, isNull);
      expect(error.longMessage, isNull);
      expect(error.errors, isNull);
      expect(error.errorCode, isNull);
    });

    test('constructor creates error with all fields', () {
      const error = ExternalError(
        message: 'Short message',
        code: 'ERR_001',
        meta: {'key': 'value'},
        longMessage: 'This is a longer error message',
        errorCode: ClerkErrorCode.clientAppError,
      );

      expect(error.message, 'Short message');
      expect(error.code, 'ERR_001');
      expect(error.meta?['key'], 'value');
      expect(error.longMessage, 'This is a longer error message');
      expect(error.errorCode, ClerkErrorCode.clientAppError);
    });

    test('fullMessage returns longMessage when available', () {
      const error = ExternalError(
        message: 'Short',
        longMessage: 'Long message here',
      );

      expect(error.fullMessage, 'Long message here');
    });

    test('fullMessage returns message when longMessage is null', () {
      const error = ExternalError(message: 'Short message');

      expect(error.fullMessage, 'Short message');
    });

    test('unknown static constant has correct values', () {
      expect(ExternalError.unknown.message, 'Unknown error');
      expect(ExternalError.unknown.errorCode, ClerkErrorCode.unknownError);
    });

    test('fromJson creates error from JSON', () {
      final json = <String, dynamic>{
        'message': 'JSON error',
        'code': 'JSON_ERR',
        'long_message': 'Detailed JSON error message',
        'meta': <String, dynamic>{'detail': 'info'},
      };

      final error = ExternalError.fromJson(json);

      expect(error.message, 'JSON error');
      expect(error.code, 'JSON_ERR');
      expect(error.longMessage, 'Detailed JSON error message');
    });

    test('toJson serializes error', () {
      const error = ExternalError(
        message: 'Serialize me',
        code: 'SER_001',
      );

      final json = error.toJson();

      expect(json['message'], 'Serialize me');
      expect(json['code'], 'SER_001');
    });
  });

  group('ExternalErrorCollection', () {
    test('constructor creates collection with errors', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'Error 1'),
          ExternalError(message: 'Error 2'),
        ],
      );

      expect(collection.errors?.length, 2);
    });

    test('errorMessage joins all error messages', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'First error'),
          ExternalError(message: 'Second error'),
        ],
      );

      expect(collection.errorMessage, 'First error; Second error');
    });

    test('errorMessage returns unknown when errors is null', () {
      const collection = ExternalErrorCollection();

      expect(collection.errorMessage, 'Unknown error');
    });

    test('hasSingleError returns true for single error', () {
      const collection = ExternalErrorCollection(
        errors: [ExternalError(message: 'Only one')],
      );

      expect(collection.hasSingleError, true);
    });

    test('hasSingleError returns false for multiple errors', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'Error 1'),
          ExternalError(message: 'Error 2'),
        ],
      );

      expect(collection.hasSingleError, false);
    });

    test('error returns first error', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'First'),
          ExternalError(message: 'Second'),
        ],
      );

      expect(collection.error.message, 'First');
    });

    test('error returns unknown when errors is null', () {
      const collection = ExternalErrorCollection();

      expect(collection.error.message, 'Unknown error');
    });

    test('fromJson creates collection from JSON', () {
      final json = <String, dynamic>{
        'errors': [
          <String, dynamic>{'message': 'Error from JSON'},
        ],
      };

      final collection = ExternalErrorCollection.fromJson(json);

      expect(collection.errors?.length, 1);
      expect(collection.errors?.first.message, 'Error from JSON');
    });

    test('toJson serializes collection', () {
      const collection = ExternalErrorCollection(
        errors: [ExternalError(message: 'To serialize')],
      );

      final json = collection.toJson();

      expect(json['errors'], isNotNull);
    });

    test('containsIncorrectCodeError detects form_code_incorrect', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'Incorrect code', code: 'form_code_incorrect'),
        ],
      );

      expect(collection.containsIncorrectCodeError, isTrue);
    });

    test('containsIncorrectCodeError finds it among several errors', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(message: 'Something else', code: 'form_param_missing'),
          ExternalError(message: 'Incorrect code', code: 'form_code_incorrect'),
        ],
      );

      expect(collection.containsIncorrectCodeError, isTrue);
    });

    test('containsIncorrectCodeError is false for another code', () {
      const collection = ExternalErrorCollection(
        errors: [
          ExternalError(
            message: 'Expired',
            code: 'verification_expired',
          ),
        ],
      );

      expect(collection.containsIncorrectCodeError, isFalse);
    });

    test('containsIncorrectCodeError is false when there are no errors', () {
      const collection = ExternalErrorCollection();

      expect(collection.containsIncorrectCodeError, isFalse);
    });
  });
}

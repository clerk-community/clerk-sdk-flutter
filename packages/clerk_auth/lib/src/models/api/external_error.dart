import 'package:clerk_auth/src/clerk_auth/clerk_error.dart';
import 'package:clerk_auth/src/models/informative_to_string_mixin.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'external_error.g.dart';

/// Error class renamed this is for backwards compatibility
@Deprecated('Use ExternalError instead.')
typedef ApiError = ExternalError;

/// [ExternalError] Clerk object
@immutable
@JsonSerializable()
class ExternalError with InformativeToStringMixin {
  /// Constructor
  const ExternalError({
    required this.message,
    this.code,
    this.meta,
    this.longMessage,
    this.errors,
    this.errorCode,
  });

  /// message
  final String message;

  /// code
  final String? code;

  /// meta data
  final Map<String, dynamic>? meta;

  /// long message
  final String? longMessage;

  /// The longer of the two messages
  String get fullMessage => longMessage ?? message;

  /// Optional list of errors if multiple
  final ExternalErrorCollection? errors;

  /// An optional [ClerkErrorCode], indicating this
  /// error is internally generated
  final ClerkErrorCode? errorCode;

  /// fromJson
  static ExternalError fromJson(dynamic json) {
    return _$ExternalErrorFromJson(json as Map<String, dynamic>);
  }

  /// toJson
  @override
  Map<String, dynamic> toJson() => _$ExternalErrorToJson(this);

  /// Unknown error
  static const unknown = ExternalError(
    message: 'Unknown error',
    errorCode: ClerkErrorCode.unknownError,
  );
}

/// Error class renamed this is for backwards compatibility
@Deprecated('Use ExternalErrorCollection instead.')
typedef ApiErrorCollection = ExternalErrorCollection;

/// [ExternalErrorCollection] Clerk object
@immutable
@JsonSerializable()
class ExternalErrorCollection {
  /// Constructor
  const ExternalErrorCollection({this.errors});

  /// The [ExternalError]s
  final List<ExternalError>? errors;

  /// formatted error message
  String get errorMessage =>
      errors?.map((e) => e.fullMessage).join('; ') ??
      ExternalError.unknown.message;

  /// Does this collection contain only a single error?
  bool get hasSingleError => errors?.length == 1;

  /// The first error or a representation of this
  ExternalError get error => errors?.first ?? ExternalError.unknown;

  /// Does this represent external_account_not_found?
  bool get containsExternalAccountNotFoundError =>
      _contains('external_account_not_found');

  /// Does this represent form_code_incorrect?
  bool get containsIncorrectCodeError => _contains('form_code_incorrect');

  bool _contains(String err) => errors?.any((e) => e.code == err) == true;

  /// fromJson
  static ExternalErrorCollection fromJson(dynamic json) {
    return _$ExternalErrorCollectionFromJson(json as Map<String, dynamic>);
  }

  /// toJson
  Map<String, dynamic> toJson() => _$ExternalErrorCollectionToJson(this);
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart';
import 'package:clerk_auth/src/clerk_api/api.dart';
import 'package:clerk_auth/src/models/api/external_error.dart';
import 'package:meta/meta.dart';

/// [Auth] provides more abstracted access to the Clerk API.
///
/// [config]: SDK Configuration containing your publishable key.
///
/// [persistor]: an instance of a [Persistor] which will keep track of
/// tokens and expiry etc between app activations
///
/// [httpService]: an instance of [HttpService] to manage low-level
/// communications with the back end. Injected for e.g. test mocking
///
class Auth {
  /// Create an [Auth] object using appropriate Clerk credentials
  Auth({required this.config});

  /// Use 'English' as the default locale
  static List<String> defaultLocalesLookup() => <String>['en'];

  /// The configuration object
  final AuthConfig config;

  /// The service to send telemetry to the back end
  late final Telemetry telemetry;

  late final Api _api;

  static const _initialisationTimeout = Duration(milliseconds: 1000);
  static const _refetchDelay = Duration(seconds: 10);
  static const _kClientKey = r'$client';
  static const _kEnvKey = r'$env';
  static const _defaultPollDelay = Duration(seconds: 53);

  Timer? _clientTimer;
  Timer? _refetchTimer;
  Timer? _pollTimer;

  /// Stream of [SessionToken]s as they renew
  Stream<SessionToken> get sessionTokenStream => _sessionTokens.stream;
  final _sessionTokens = StreamController<SessionToken>.broadcast();

  /// Adds [error] to [errorStream]
  @Deprecated('Please use handleError instead.')
  void addError(ClerkError error) => handleError(error);

  /// Handles [ClerkError]s when they occur
  void handleError(Object error) => throw error;

  Future<T?> _catchExternalErrors<T>(
    FutureOr<T?> Function() fn, {
    FutureOr<void> Function()? onFinally,
  }) async {
    T? result;

    try {
      result = await fn();
    } on ExternalError catch (error) {
      if (error.errors case ExternalErrorCollection errors) {
        handleError(ClerkError.from(errors));
      } else {
        handleError(
          ClerkError(
            message: error.toString(),
            code: error.errorCode ?? ClerkErrorCode.serverErrorResponse,
          ),
        );
      }
    } catch (error) {
      handleError(error);
    } finally {
      await onFinally?.call();
    }

    return result;
  }

  ApiResponse _housekeeping(ApiResponse resp) {
    if (resp.isError) {
      handleError(ClerkError.from(resp.errorCollection));
    } else if (resp.client case Client client) {
      this.client = client;
    }
    return resp;
  }

  /// Are we not yet initialised?
  bool get isNotAvailable => env.isEmpty;

  /// The [Environment] object
  ///
  /// configuration of the Clerk account - rarely changes
  ///
  Environment get env => _env;

  set env(Environment env) {
    _env = env;
    config.persistor.write(_kEnvKey, env.toJson());
  }

  Environment _env = Environment.empty;

  /// The [Client] object
  ///
  /// The current state of authentication - changes frequently
  ///
  Client get client => _client;

  set client(Client client) {
    _client = client;
    config.persistor.write(_kClientKey, client.toJson());
  }

  Client _client = Client.empty;

  /// The current [SignIn] object, or null
  SignIn? get signIn => client.signIn;

  /// The current [SignUp] object, or null
  SignUp? get signUp => client.signUp;

  /// The current [Session] object, or null
  Session? get session => client.activeSession;

  /// The current [User] object, or null
  User? get user => session?.user;

  /// The current [Organization] object, or null
  Organization? get organization => session?.organization;

  /// Are we currently signed in?
  bool get isSignedIn => user != null;

  /// Are we currently signing in?
  bool get isSigningIn => signIn != null;

  /// Are we currently signing up?
  bool get isSigningUp => signUp != null;

  /// A method to be overridden by extension classes to cope with
  /// updating their systems when things change (e.g. the clerk_flutter
  /// ClerkAuth class)
  ///
  @mustCallSuper
  void update() {}

  /// Initialisation of the [Auth] object
  ///
  /// [initialize] must be called before any further use of the [Auth]
  /// object is made
  ///
  @mustCallSuper
  Future<void> initialize() async {
    await config.initialize();
    telemetry = Telemetry(config: config);
    _api = Api(config: config);
    await _api.initialize();

    final (client, env) = await _fetchClientAndEnv();

    if (client.isEmpty) {
      switch (await config.persistor.read(_kClientKey)) {
        case Map<String, dynamic> data:
          _client = Client.fromJson(data);
        case String data:
          // backward compatibility with earlier versions
          _client = Client.fromJson(jsonDecode(data));
      }
    } else {
      this.client = client;
    }

    if (env.isEmpty) {
      switch (await config.persistor.read(_kEnvKey)) {
        case Map<String, dynamic> data:
          _env = Environment.fromJson(data);
        case String data:
          // backward compatibility with earlier versions
          _env = Environment.fromJson(jsonDecode(data));
      }
    } else {
      this.env = env;
    }

    if (_client.isEmpty || _env.isEmpty) {
      _refetchTimer = Timer.periodic(_refetchDelay, _retryFetchClientAndEnv);
    }

    await telemetry.initialize(
      instanceType: env.display.instanceEnvironmentType,
    );

    if (config.clientRefreshPeriod.isNotZero) {
      _clientTimer = Timer.periodic(
        config.clientRefreshPeriod,
        (_) async {
          if (await _api.hasConnectivity()) {
            await refreshClient();
          }
        },
      );
    }

    if (config.sessionTokenPolling) {
      await _pollForSessionToken();
    }
  }

  /// Disposal of the [Auth] object
  ///
  /// Named [terminate] so as not to clash with [ChangeNotifier]'s [dispose]
  /// method, if that is mixed in e.g. in clerk_flutter
  ///
  @mustCallSuper
  void terminate() {
    _pollTimer?.cancel();
    _clientTimer?.cancel();
    _refetchTimer?.cancel();
    _api.terminate();
    _sessionTokens.close();
    telemetry.terminate();
    config.terminate();
  }

  Future<SessionToken?> _pollForSessionToken() async {
    _pollTimer?.cancel();

    Duration delay = _defaultPollDelay;
    SessionToken? sessionToken;

    await _catchExternalErrors(
      () async {
        if (isSignedIn) {
          sessionToken =
              await _api.updateSessionToken(config.defaultSessionTokenTemplate);
          if (sessionToken case SessionToken token) {
            _sessionTokens.add(token);
            if (token.expiry.difference(DateTime.timestamp())
                case Duration tokenBasedDelay
                when tokenBasedDelay > Duration.zero) {
              delay = tokenBasedDelay;
            }
          }
        }
      },
      onFinally: () {
        _pollTimer = Timer(delay, _pollForSessionToken);
      },
    );

    return sessionToken;
  }

  Future<void> _retryFetchClientAndEnv(_) async {
    final (client, env) = await _fetchClientAndEnv();
    if (client.isNotEmpty && env.isNotEmpty) {
      this.client = client;
      this.env = env;
      _refetchTimer?.cancel();
      _refetchTimer = null;
      update();
    }
  }

  Future<(Client, Environment)> _fetchClientAndEnv() async {
    try {
      final client = await _api.createClient().timeout(_initialisationTimeout);
      final env = await _api.environment().timeout(_initialisationTimeout);
      return (client, env);
    } on Exception {
      // either get both or neither (shouldn't initialise with different
      // timestamped versions anyway)
      return (Client.empty, Environment.empty);
    }
  }

  /// Refresh the current [Client]
  ///
  Future<void> refreshClient() async {
    client = await _api.currentClient();
    update();
  }

  /// Reset the current [Client]: clear any [SignUp] or [SignIn] object
  ///
  Future<void> resetClient() async {
    client = await _api.resetClient();
    update();
  }

  /// Refresh the current [Environment]
  ///
  Future<void> refreshEnvironment() async {
    env = await _api.environment();
    update();
  }

  /// Sign out of all [Session]s and delete the current [Client]
  ///
  Future<void> signOut() async {
    client = await _api.signOut();
    await config.persistor.delete(_kClientKey);
    update();
  }

  /// Transfer an oAuth authentication into a [User]
  ///
  Future<void> transfer() async {
    if (signIn?.isTransferable == true) {
      await _api.transferSignUp().then(_housekeeping);
      update();
    } else if (signUp?.isTransferable == true) {
      await _api.transferSignIn().then(_housekeeping);
      update();
    }
  }

  /// Get the current [sessionToken] for an [Organization] , or the
  /// last organization used if empty
  ///
  Future<SessionToken> sessionToken({
    Organization? organization,
    String? templateName,
  }) async {
    final org = env.organization.isEnabled ? organization : null;
    SessionToken? token = _api.sessionToken(templateName, org);
    if (token == null) {
      if (org == null && templateName == null) {
        // this resets the timer too, and adds a token to _sessionTokens
        // if retrieved
        token = await _pollForSessionToken();
      } else {
        token = await _catchExternalErrors(
          () => _api.updateSessionToken(templateName, org),
        );
        if (token != null) {
          _sessionTokens.add(token);
        }
      }
      if (token == null) {
        throw const ClerkError(
          message: 'No session token retrieved',
          code: ClerkErrorCode.noSessionTokenRetrieved,
        );
      }
    }

    return token;
  }

  /// Prepare for sign in via an oAuth provider
  ///
  Future<void> oauthSignIn({
    required Strategy strategy,
    required Uri? redirect,
  }) async {
    final redirectUrl = redirect?.toString() ?? ClerkConstants.oauthRedirect;
    final identifier = strategy.isEnterpriseSSO ? client.signIn?.identifier : null;
    await _api
        .createSignIn(strategy: strategy, redirectUrl: redirectUrl, identifier: identifier)
        .then(_housekeeping);
    if (client.signIn case SignIn signIn when signIn.hasVerification == false) {
      await _catchExternalErrors(
        () => _api
            .prepareSignIn(
              signIn,
              stage: Stage.first,
              strategy: strategy,
              redirectUrl: redirectUrl,
            )
            .then(_housekeeping),
      );
    }
    update();
  }

  /// Complete oAuth sign in by presenting the token
  ///
  Future<void> completeOAuthSignIn({
    required String token,
  }) async {
    if (signIn ?? signUp case AuthObject authObject) {
      await _api.sendOauthToken(authObject, token: token).then(_housekeeping);
      update();
    }
  }

  /// Prepare to connect an account via an oAuth provider
  ///
  Future<void> oauthConnect({
    required Strategy strategy,
    required Uri? redirect,
  }) async {
    final redirectUrl = redirect?.toString() ?? ClerkConstants.oauthRedirect;
    await _api
        .addExternalAccount(strategy: strategy, redirectUrl: redirectUrl)
        .then(_housekeeping);
    update();
  }

  /// Sign in with an ID token from a provider (e.g., Apple)
  ///
  /// This method attempts to sign in an existing user using an ID token
  /// obtained from an identity provider like Apple.
  ///
  /// **Transfer Flow:**
  /// If the user doesn't exist, the verification status will be `transferable`.
  /// Call [transfer] to switch to the sign-up flow.
  ///
  /// **Example:**
  /// ```dart
  /// await clerk_auth.idTokenSignIn(
  ///   provider: IdTokenProvider.apple,
  ///   idToken: credential.identityToken!,
  /// );
  ///
  /// // Check if transfer needed
  /// if (clerk_auth.signIn?.isTransferable == true) {
  ///   await clerk_auth.transfer();
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [provider]: The identity provider (e.g., [IdTokenProvider.apple])
  /// - [idToken]: The ID token string obtained from the provider
  ///
  /// **Throws:**
  /// [ClerkError] if the API request fails. Errors are also sent to [errorStream].
  Future<void> idTokenSignIn({
    required IdTokenProvider provider,
    required String? token,
  }) async {
    var response =
        await _api.createSignIn(strategy: provider.strategy, token: token);
    if (response.isError) {
      if (response.errorCollection.containsExternalAccountNotFoundError) {
        response =
            await _api.createSignUp(strategy: provider.strategy, token: token);
      }
    } else if (response.client case Client client
        when client.signIn?.isTransferable == true) {
      this.client = client;
      response = await _api.transferSignUp();
    }
    _housekeeping(response);
    update();
  }

  /// Sign up with an ID token from a provider (e.g., Apple)
  ///
  /// This method attempts to sign up a new user using an ID token
  /// obtained from an identity provider like Apple.
  ///
  /// **Transfer Flow:**
  /// If the user already exists, the verification status will be `transferable`.
  /// Call [transfer] to switch to the sign-in flow.
  ///
  /// **Example:**
  /// ```dart
  /// await clerk_auth.idTokenSignUp(
  ///   provider: IdTokenProvider.apple,
  ///   idToken: credential.identityToken!,
  ///   firstName: credential.givenName,
  ///   lastName: credential.familyName,
  /// );
  ///
  /// // Check if transfer needed
  /// if (clerk_auth.signUp?.isTransferable == true) {
  ///   await clerk_auth.transfer();
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [provider]: The identity provider (e.g., [IdTokenProvider.apple])
  /// - [idToken]: The ID token string obtained from the provider
  /// - [firstName]: Optional first name from the provider's credential
  /// - [lastName]: Optional last name from the provider's credential
  ///
  /// **Throws:**
  /// [ClerkError] if the API request fails. Errors are also sent to [errorStream].
  Future<void> idTokenSignUp({
    required IdTokenProvider provider,
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    await attemptSignUp(
      strategy: provider.strategy,
      token: idToken,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Delete an external account
  Future<void> deleteExternalAccount({required ExternalAccount account}) async {
    await _api.deleteExternalAccount(account: account).then(_housekeeping);
    update();
  }

  /// Initiate a password reset
  Future<void> initiatePasswordReset({
    required String identifier,
    required Strategy strategy,
  }) async {
    if (strategy.isPasswordResetter) {
      await _api
          .createSignIn(identifier: identifier, strategy: strategy)
          .then(_housekeeping);
    } else {
      handleError(
        ClerkError(
          code: ClerkErrorCode.passwordResetStrategyError,
          message: 'Unsupported password reset strategy: {arg}',
          argument: strategy.toString(),
        ),
      );
    }
  }

  /// Progressively attempt sign in
  ///
  /// Can be repeatedly called with updated parameters
  /// until the user is signed in.
  ///
  Future<void> attemptSignIn({
    required Strategy strategy,
    String? identifier,
    String? password,
    String? code,
    String? token,
    String? redirectUrl,
    String? passkeyCredential,
  }) async {
    if (strategy.isOauthToken) {
      if (token?.isNotEmpty == true || code?.isNotEmpty == true) {
        await _api
            .createSignIn(strategy: strategy, token: token, code: code)
            .then(_housekeeping);
        update();
      }
      return;
    } else if (strategy.isPasskey && passkeyCredential == null) {
      await _api.createSignIn(strategy: strategy).then(_housekeeping);
      return;
    }

    // Ensure we have a signIn object for the current identifier
    if (client.signIn == null ||
        (identifier?.orNullIfEmpty is String &&
            identifier != client.signIn!.identifier)) {
      // if password and identifier been presented, we can immediately attempt
      // a sign in;  if null they will be ignored
      await _api
          .createSignIn(identifier: identifier, password: password)
          .then(_housekeeping);
    }

    switch (client.signIn) {
      case null when client.user is User:
        // We have signed in - possibly when creating the [SignIn] above
        break;

      case SignIn signIn when strategy.isPasskey && passkeyCredential is String:
        await _api
            .attemptSignIn(
              signIn,
              stage: Stage.first,
              strategy: strategy,
              passkeyCredential: passkeyCredential,
            )
            .then(_housekeeping);

      case SignIn signIn when strategy.isSSO && token is String:
        await _api.sendOauthToken(signIn, token: token).then(_housekeeping);

      case SignIn signIn
          when strategy.isPasswordResetter &&
              code?.length == Strategy.numericalCodeLength &&
              password is String:
        await _api
            .attemptSignIn(
              signIn,
              stage: Stage.first,
              strategy: strategy,
              password: password,
              code: code,
            )
            .then(_housekeeping);

      case SignIn signIn
          when strategy == Strategy.emailLink && redirectUrl is String:
        final response = await _catchExternalErrors(
          () => _api
              .prepareSignIn(
                signIn,
                stage: Stage.first,
                strategy: Strategy.emailLink,
                redirectUrl: redirectUrl,
              )
              .then(_housekeeping),
        );
        if (response?.isOkay == true) {
          unawaited(_pollForEmailLinkCompletion());
        }

      case SignIn signIn
          when signIn.needsFirstFactor &&
              strategy.isPassword &&
              password is String:
        await _api
            .attemptSignIn(
              signIn,
              stage: Stage.forStatus(signIn.status),
              strategy: Strategy.password,
              password: password,
            )
            .then(_housekeeping);

      case SignIn signIn when signIn.status.needsFactor:
        final stage = Stage.forStatus(signIn.status);
        if (signIn.requiresPreparationFor(strategy)) {
          await _api
              .prepareSignIn(signIn, stage: stage, strategy: strategy)
              .then(_housekeeping);
        }
        if (client.signIn case SignIn signIn
            when signIn.requiresPreparationFor(strategy) == false &&
                strategy.mightAccept(code)) {
          await _api
              .attemptSignIn(
                signIn,
                stage: stage,
                strategy: strategy,
                code: code,
              )
              .then(_housekeeping);
        }
    }

    update();
  }

  bool? _checkLegalAcceptance(bool? legalAccepted, bool acceptanceRequired) {
    if (acceptanceRequired) {
      if (legalAccepted == true) {
        return true;
      }

      throw const ClerkError(
        message: "Legal acceptance is required to proceed with sign up",
        code: ClerkErrorCode.legalAcceptanceRequired,
      );
    }

    return null;
  }

  /// Progressively attempt sign up
  ///
  /// Can be repeatedly called with updated parameters
  /// until the user is signed up and in.
  ///
  Future<Client> attemptSignUp({
    Strategy strategy = Strategy.password,
    String? firstName,
    String? lastName,
    String? username,
    String? emailAddress,
    String? phoneNumber,
    String? password,
    String? passwordConfirmation,
    String? code,
    String? token,
    String? signature,
    String? redirectUrl,
    Map<String, dynamic>? metadata,
    bool? legalAccepted,
  }) async {
    final hasVerificationCredential = code is String || signature is String;

    if (password != passwordConfirmation) {
      throw const ClerkError(
        message: "Password and password confirmation must match",
        code: ClerkErrorCode.passwordMatchError,
      );
    }

    if (client.signUp case SignUp signUp) {
      legalAccepted = _checkLegalAcceptance(
        legalAccepted,
        signUp.missingFields.contains(Field.legalAccepted),
      );

      final needsUpdate = (password?.isNotEmpty == true) ||
          (firstName is String && firstName != signUp.firstName) ||
          (lastName is String && lastName != signUp.lastName) ||
          (username is String && username != signUp.username) ||
          (emailAddress is String && emailAddress != signUp.emailAddress) ||
          (phoneNumber is String && phoneNumber != signUp.phoneNumber) ||
          (legalAccepted is bool) ||
          (metadata is Map && _deeplyUnequal(metadata, signUp.unsafeMetadata));
      if (needsUpdate) {
        await _api
            .updateSignUp(
              signUp,
              strategy: strategy,
              password: password,
              firstName: firstName,
              lastName: lastName,
              username: username,
              emailAddress: emailAddress,
              phoneNumber: phoneNumber,
              legalAccepted: legalAccepted,
              metadata: metadata,
            )
            .then(_housekeeping);
      }
    } else {
      legalAccepted = _checkLegalAcceptance(
        legalAccepted,
        env.user.signUp.legalConsentEnabled,
      );

      await _api
          .createSignUp(
            strategy: strategy,
            password: password,
            firstName: firstName,
            lastName: lastName,
            username: username,
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            token: token,
            legalAccepted: legalAccepted,
            metadata: metadata,
          )
          .then(_housekeeping);
    }

    if (client.user is! User) {
      switch (client.signUp) {
        case SignUp signUp
            when strategy.requiresVerification && hasVerificationCredential:
          await _api
              .attemptSignUp(
                signUp,
                strategy: strategy,
                code: code,
                signature: signature,
              )
              .then(_housekeeping);

        case SignUp signUp
            when signUp.status == Status.missingRequirements &&
                signUp.missingFields.isEmpty &&
                signUp.unverifiedFields.isNotEmpty:
          if (strategy == Strategy.phoneCode &&
              env.supportsPhoneCode &&
              signUp.unverified(Field.phoneNumber) &&
              signUp.isVerifying(Strategy.phoneCode) == false) {
            await _api
                .prepareSignUp(signUp, strategy: Strategy.phoneCode)
                .then(_housekeeping);
          }

          if (signUp.unverified(Field.emailAddress)) {
            if (strategy == Strategy.emailCode &&
                env.supportsEmailCode &&
                signUp.isVerifying(Strategy.emailCode) == false) {
              await _api
                  .prepareSignUp(signUp, strategy: Strategy.emailCode)
                  .then(_housekeeping);
            } else if (strategy == Strategy.emailLink &&
                env.supportsEmailLink &&
                redirectUrl is String &&
                signUp.isVerifying(Strategy.emailLink) == false) {
              await _api
                  .prepareSignUp(
                    signUp,
                    strategy: Strategy.emailLink,
                    redirectUrl: redirectUrl,
                  )
                  .then(_housekeeping);
              unawaited(_pollForEmailLinkCompletion());
            }
          }

        case SignUp signUp
            when signUp.requiresEnterpriseSSOSignUp && redirectUrl is String:
          await _api
              .updateSignUp(
                signUp,
                strategy: strategy,
                redirectUrl: redirectUrl,
              )
              .then(_housekeeping);

        case SignUp signUp
            when signUp.status == Status.missingRequirements &&
                signUp.missingFields.isEmpty:
          await _api
              .prepareSignUp(signUp, strategy: strategy)
              .then(_housekeeping);
          if (code is String || signature is String) {
            await _api
                .attemptSignUp(
                  client.signUp!,
                  strategy: strategy,
                  code: code,
                  signature: signature,
                )
                .then(_housekeeping);
          }
      }
    }

    update();
    return client;
  }

  /// Resend code if requested
  ///
  Future<ApiResponse> resendCode(Strategy strategy) async {
    ApiResponse? response;

    if (client.signUp case SignUp signUp when signUp.isVerifying(strategy)) {
      response = await _api
          .prepareSignUp(signUp, strategy: strategy)
          .then(_housekeeping);
    } else if (client.signIn case SignIn signIn) {
      for (final stage in Stage.values) {
        if (signIn.isVerifying(stage, strategy)) {
          response = await _api
              .prepareSignIn(signIn, stage: stage, strategy: strategy)
              .then(_housekeeping);
          break;
        }
      }
    }

    if (response is ApiResponse) {
      update();
    } else {
      throw const ClerkError(
        message: "No initial code has been set up to resend",
        code: ClerkErrorCode.noInitialCodeHasBeenSetUpToResend,
      );
    }

    return response;
  }

  /// Passkeys

  /// Creates an unverified passkey for the current [User]
  ///
  Future<Passkey?> createPasskey() async {
    final resp = await _api.createPasskey().then(_housekeeping);
    if (resp.response case final json?) {
      return Passkey.fromJson(json);
    }
    return null;
  }

  /// Attempt to verify a passkey
  ///
  Future<void> attemptPasskeyVerification(
    Passkey passkey,
    String credential,
  ) async {
    await _api
        .attemptPasskeyVerification(passkey.id, credential)
        .then(_housekeeping);
    update();
  }

  /// Sign out of the given [Session]
  ///
  Future<void> signOutOf(Session session) async {
    await _api.signOutOf(session).then(_housekeeping);
    update();
  }

  /// Make an [Organization] active
  ///
  Future<void> setActiveOrganization(Organization organization) async {
    if (session case Session session) {
      await _api
          .setActiveOrganization(session.id, organization.id)
          .then(_housekeeping);
      update();
    }
  }

  /// Create a new [Organization]
  ///
  Future<void> createOrganization({
    required String name,
    String? slug,
    File? logo,
  }) async {
    await _api.createOrganization(name).then(_housekeeping);

    if (user?.organizationNamed(name) case Organization org) {
      if (slug?.isNotEmpty == true) {
        await _api
            .updateOrganization(org, slug: slug, session: session)
            .then(_housekeeping);
      }
      if (logo case File logo) {
        await _api
            .updateOrganizationLogo(org, logo: logo, session: session)
            .then(_housekeeping);
      }
    }

    update();
  }

  /// Update an [Organization]
  ///
  Future<void> updateOrganization({
    required Organization organization,
    String? name,
    File? logo,
  }) async {
    final hasName =
        name is String && name.isNotEmpty && name != organization.name;
    if (hasName || logo is File) {
      if (hasName) {
        await _api
            .updateOrganization(organization, name: name, session: session)
            .then(_housekeeping);
      }
      if (logo case File logo) {
        await _api
            .updateOrganizationLogo(organization, logo: logo, session: session)
            .then(_housekeeping);
      }
      update();
    }
  }

  /// Leave an [Organization]
  ///
  Future<bool> leaveOrganization({
    required Organization organization,
    Session? session,
  }) async {
    final result = await _api
        .leaveOrganization(organization, session: session)
        .then(_housekeeping);
    update();
    return result.isOkay;
  }

  static const _page = 20;

  /// Get all the [Organization] invitations awaiting the user
  ///
  Future<List<OrganizationInvitation>> fetchOrganizationInvitations() async {
    final invitations = <OrganizationInvitation>[];

    for (int offset = 0; true; offset += _page) {
      final response = await _api.fetchOrganizationInvitations(offset, _page);
      if (response.response?['data'] == null) {
        break;
      }

      final responseInvitations = response.response?['data'] as List<dynamic>;
      invitations.addAll(
        responseInvitations.map(OrganizationInvitation.fromJson),
      );

      if (responseInvitations.length < _page) {
        break;
      }
    }

    update();
    return invitations;
  }

  /// Get all the [Organization]'s [Domain]s
  ///
  Future<List<OrganizationDomain>> fetchOrganizationDomains({
    required Organization organization,
  }) async {
    final domains = <OrganizationDomain>[];

    for (int offset = 0; true; offset += _page) {
      final response = await _api.fetchOrganizationDomains(
        organization,
        offset,
        _page,
      );
      if (response.response?['data'] == null) {
        break;
      }

      final responseDomains = response.response?['data'] as List<dynamic>;
      domains.addAll(
        responseDomains.map(OrganizationDomain.fromJson),
      );

      if (responseDomains.length < _page) {
        break;
      }
    }

    update();
    return domains;
  }

  /// Accept an invitation to join an [Organization]
  ///
  Future<ApiResponse> acceptOrganizationInvitation(
    OrganizationInvitation invitation,
  ) async {
    return await _api
        .acceptOrganizationInvitation(invitation)
        .then(_housekeeping);
  }

  /// Create a new [Domain] within an [Organization]
  ///
  Future<void> createDomain({
    required Organization organization,
    required String name,
    required EnrollmentMode mode,
  }) async {
    final response =
        await _api.createDomain(organization, name).then(_housekeeping);
    if (mode != EnrollmentMode.manualInvitation) {
      final domainId = response.response!['id'];
      await _api
          .updateDomainEnrollmentMode(organization, domainId, mode)
          .then(_housekeeping);
    }
  }

  /// Activate the given [Session]
  ///
  Future<void> activate(Session session) async {
    await _api.activate(session).then(_housekeeping);
    update();
  }

  /// Update the [name] of the current [User]
  ///
  Future<void> updateUser({
    String? username,
    String? firstName,
    String? lastName,
    String? primaryEmailAddressId,
    String? primaryPhoneNumberId,
    String? primaryWeb3WalletId,
    Map<String, dynamic>? metadata,
    File? avatar,
  }) async {
    final config = env.config;
    if (user case User user) {
      final needsUpdate = (config.allowsUsername &&
              username is String &&
              username != user.username) ||
          (config.allowsFirstName &&
              firstName is String &&
              firstName != user.firstName) ||
          (config.allowsLastName &&
              lastName is String &&
              lastName != user.lastName) ||
          (primaryEmailAddressId is String &&
              primaryEmailAddressId != user.primaryEmailAddressId) ||
          (primaryPhoneNumberId is String &&
              primaryPhoneNumberId != user.primaryPhoneNumberId) ||
          (primaryWeb3WalletId is String &&
              primaryWeb3WalletId != user.primaryWeb3WalletId) ||
          (metadata?.isNotEmpty == true);
      if (needsUpdate || avatar is File) {
        if (needsUpdate) {
          await _api
              .updateUser(
                username: config.allowsUsername ? username : null,
                firstName: config.allowsFirstName ? firstName : null,
                lastName: config.allowsLastName ? lastName : null,
                primaryEmailAddressId: primaryEmailAddressId,
                primaryPhoneNumberId: primaryPhoneNumberId,
                primaryWeb3WalletId: primaryWeb3WalletId,
                metadata: metadata,
              )
              .then(_housekeeping);
        }
        if (avatar case File avatar) {
          await _api.updateAvatar(avatar).then(_housekeeping);
        }
        update();
      }
    }
  }

  /// Delete the current [User]
  ///
  Future<void> deleteUser() async {
    if (env.user.actions.deleteSelf) {
      await _api.deleteUser();
      client = await _api.currentClient();
      update();
    } else {
      handleError(
        const ClerkError(
          code: ClerkErrorCode.cannotDeleteSelf,
          message: 'You are not authorized to delete your user',
        ),
      );
    }
  }

  /// Add an [identifier] address to the current [User]
  ///
  Future<void> addIdentifyingData(
    String identifier,
    IdentifierType type,
  ) async {
    await _api
        .addIdentifyingDataToCurrentUser(identifier, type)
        .then(_housekeeping);
    if (user?.identifierFrom(identifier) case UserIdentifyingData ident) {
      await _api.prepareIdentifyingDataVerification(ident).then(_housekeeping);
    }
    update();
  }

  /// Attempt to verify some [UserIdentifyingData]
  ///
  Future<void> verifyIdentifyingData(
    UserIdentifyingData uid,
    String code,
  ) async {
    await _api.verifyIdentifyingData(uid, code).then(_housekeeping);
    update();
  }

  /// Attempt to delete some [UserIdentifyingData]
  ///
  Future<void> deleteIdentifyingData(
    UserIdentifyingData uid,
  ) async {
    await _api.deleteIdentifyingData(uid).then(_housekeeping);
    update();
  }

  /// Update the avatar of the current [User]
  ///
  Future<void> updateUserImage(File file) async {
    await _api.updateAvatar(file).then(_housekeeping);
    update();
  }

  /// Delete the avatar of the current [User]
  ///
  Future<void> deleteUserImage() async {
    await _api.deleteAvatar().then(_housekeeping);
    update();
  }

  /// Update the password of the current [User]
  ///
  Future<void> updateUserPassword(
    String currentPassword,
    String newPassword, {
    bool signOut = true,
  }) async {
    await _api
        .updatePassword(currentPassword, newPassword, signOut)
        .then(_housekeeping);
    update();
  }

  /// Delete the password of the current [User]
  ///
  Future<void> deleteUserPassword(String currentPassword) async {
    await _api.deletePassword(currentPassword).then(_housekeeping);
    update();
  }

  Future<void> _pollForEmailLinkCompletion() async {
    while (client.user == null) {
      await Future.delayed(const Duration(seconds: 1));

      final client = await _api.currentClient();
      if (client.user is User || client.signIn?.needsSecondFactor == true) {
        this.client = client;
        update();
        break;
      } else {
        final expiry = client.signIn?.firstFactorVerification?.expireAt ??
            client.signUp?.verifications[Field.emailAddress]?.expireAt;
        if (expiry == null || expiry.isBefore(DateTime.timestamp())) {
          break;
        }
      }
    }
  }

  /// Low level access to the API
  ///
  /// While this SDK is in beta and feature-incomplete, these functions
  /// provide access to the underlying Clerk API for advanced use cases.
  ///
  /// Note that this method will be deprecated in a future version.
  ///
  /// [url]: the component of the url after '/v1'
  /// [method]: HTTP method to use
  /// [headers]: additional headers to send (most necessary headers are set up
  ///   automatically inside the `fetchApiResponse` method)
  /// [params]: query parameters to send. NB only non-null [params] are
  ///   stringified and sent
  /// [nullableParams]: query parameters to send that should be sent as null
  ///   if they are null
  /// [withSession]: whether to include the session token in the request
  ///
  Future<ApiResponse> fetchApiResponse(
    String url, {
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Map<String, dynamic>? nullableParams,
    bool withSession = false,
  }) async {
    return await _api
        .fetchApiResponse(
          url,
          method: method,
          headers: headers,
          params: params,
          nullableParams: nullableParams,
          withSession: withSession,
        )
        .then(_housekeeping);
  }
}

bool _deeplyUnequal(Object? a, Object? b) {
  if (a.runtimeType != b.runtimeType) {
    return true;
  }

  switch (a) {
    case Map aMap:
      final bMap = b as Map;
      if (aMap.keys.length != bMap.keys.length) {
        return true;
      }
      for (final key in aMap.keys) {
        if (_deeplyUnequal(aMap[key], bMap[key])) {
          return true;
        }
      }

    case List aList:
      final bList = b as List;
      if (aList.length != bList.length) {
        return true;
      }
      for (int i = 0; i < aList.length; ++i) {
        if (_deeplyUnequal(aList[i], bList[i])) {
          return true;
        }
      }

    default:
      return a != b;
  }

  return false;
}

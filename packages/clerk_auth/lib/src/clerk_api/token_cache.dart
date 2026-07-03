import 'dart:convert';
import 'dart:io';

import 'package:clerk_auth/clerk_auth.dart';
import 'package:http/http.dart' as http;

/// A store for authentication tokens and IDs from the
/// Clerk back end
///
/// Only intended for use by [Api]
///
class TokenCache {
  /// Create a [TokenCache] instance
  ///
  TokenCache({
    required this.persistor,
    required String publishableKey,
  }) : _cacheId = publishableKey.hashCode;

  /// The [Persistor] used to store session and client data
  final Persistor persistor;

  final int _cacheId;
  final _sessionTokens = <String, SessionToken>{};

  String _sessionId = '';
  String _clientToken = '';
  String _clientId = '';

  /// Whether or not we have a [clientToken]
  bool get hasClientToken => _clientToken.isNotEmpty;

  /// Whether or not we have a [clientId]
  bool get hasClientId => _clientId.isNotEmpty;

  /// Whether or not the [sessionTokenFor] can be refreshed
  bool get canRefreshSessionToken => hasClientToken && sessionId.isNotEmpty;

  String get _sessionIdKey => '_clerkSession_Id_$_cacheId';

  String get _sessionTokenKey => '_clerkSession_Tokens_$_cacheId';

  String get _clientTokenKey => '_clerkClient_Token_$_cacheId';

  String get _clientIdKey => '_clerkClient_Id_$_cacheId';

  List<String> get _persistorKeys =>
      [_sessionIdKey, _sessionTokenKey, _clientTokenKey, _clientIdKey];

  /// Initialise the cache
  Future<void> initialize() async {
    // Read all stored variables first before assignment
    final sessionId = await persistor.read<String>(_sessionIdKey) ?? '';
    _sessionId = sessionId;

    final sessionTokens = await persistor.read<String>(_sessionTokenKey);
    if (sessionTokens case String sessionTokens) {
      final sessionTokenData =
          json.decode(sessionTokens) as Map<String, dynamic>;
      for (final entry in sessionTokenData.entries) {
        final sessionToken =
            SessionToken.fromJson(entry.value as Map<String, dynamic>);
        if (sessionToken.isNotExpired) {
          _sessionTokens[entry.key] = sessionToken;
        }
      }
    }

    final clientToken = await persistor.read<String>(_clientTokenKey) ?? '';
    _clientToken = clientToken;

    final clientId = await persistor.read<String>(_clientIdKey) ?? '';
    _clientId = clientId;
  }

  /// Dispose of [TokenCache]
  void terminate() {}

  /// Reset the [TokenCache]
  ///
  void clear() {
    _sessionId = '';
    _clientToken = '';
    _clientId = '';
    _sessionTokens.clear();
    for (final key in _persistorKeys) {
      persistor.delete(key);
    }
  }

  /// Get the [sessionId]
  String get sessionId => _sessionId;

  void _setSessionId(String id) {
    if (_sessionId == id) return;

    _sessionId = id;
    persistor.write(_sessionIdKey, id);
  }

  /// Get the [clientToken]
  String get clientToken => _clientToken;

  void _setClientToken(String token) {
    if (token == _clientToken) return;

    _clientToken = token;
    persistor.write(_clientTokenKey, token);
  }

  /// Get the [clientId]
  String get clientId => _clientId;

  void _setClientId(String id) {
    if (_clientId == id) return;

    _clientId = id;
    persistor.write(_clientIdKey, id);
  }

  /// Get the [sessionTokenFor] for a [orgId]
  SessionToken? sessionTokenFor(String? templateName, Organization? org) {
    org ??= Organization.personal;
    return switch (_sessionTokens[_sessionTokenId(org.id, templateName)]) {
      SessionToken token when token.isNotExpired => token,
      _ => null,
    };
  }

  String _sessionTokenId(String orgId, String? templateName) =>
      switch (templateName) {
        String templateName => '$orgId-$templateName',
        _ => orgId,
      };

  /// Set a [sessionToken] for an organization
  SessionToken makeAndCacheSessionToken(String token, [String? templateName]) {
    final sessionToken = SessionToken(jwt: token, templateName: templateName);
    final id = _sessionTokenId(sessionToken.orgId, templateName);
    if (token != _sessionTokens[id]?.jwt) {
      _sessionTokens[id] = sessionToken;
      persistor.write(_sessionTokenKey, json.encode(_sessionTokens));
    }

    return _sessionTokens[id]!;
  }

  /// Update the tokens and IDs from a newly arrived [http.Response]
  /// and [Session]
  ///
  /// Once a client id is cached, credentials for a different client are
  /// discarded unless [allowClientChange] is set: a response resolving to
  /// another client means the token presented by its request had already
  /// been rotated away (e.g. during an oAuth handoff), and adopting the
  /// new identity would orphan the pinned client and its sessions.
  ///
  /// Returns whether the credentials were accepted.
  bool updateFrom(
    http.Response resp,
    Client client, {
    bool allowClientChange = false,
  }) {
    if (client.id case String id when id != _clientId) {
      if (hasClientId && allowClientChange == false) {
        return false;
      }
      _setClientId(id);
    }

    final newClientToken = resp.headers[HttpHeaders.authorizationHeader];
    if (newClientToken case String token) {
      _setClientToken(token);
    }

    if (client.activeSession case Session session) {
      if (session.id case String id) {
        _setSessionId(id);
      }

      if (session.lastActiveToken?.jwt case String jwt) {
        makeAndCacheSessionToken(jwt);
      }
    }

    return true;
  }
}

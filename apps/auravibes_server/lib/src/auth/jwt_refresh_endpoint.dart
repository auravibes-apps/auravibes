import 'package:serverpod_auth_idp_server/core.dart';

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
// Serverpod discovers this marker subclass during endpoint generation.
// ignore: empty_container_bodies
class JwtRefreshEndpoint extends RefreshJwtTokensEndpoint {}

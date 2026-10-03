import 'dart:io';

/// Connects only to a previously validated IP while retaining HTTPS checks.
HttpClient pinnedHttpClient(Uri allowedUri, InternetAddress address) {
  final client = HttpClient()..findProxy = (_) => 'DIRECT';
  client.connectionFactory = (target, proxyHost, proxyPort) async {
    if (proxyHost != null ||
        proxyPort != null ||
        target.scheme != allowedUri.scheme ||
        target.host != allowedUri.host ||
        target.port != allowedUri.port) {
      throw const SocketException('MCP request origin changed.');
    }
    final task = await Socket.startConnect(address, target.port);
    if (target.scheme != 'https') return task;
    return ConnectionTask.fromSocket(
      task.socket.then(
        (socket) => SecureSocket.secure(socket, host: target.host),
      ),
      task.cancel,
    );
  };
  return client;
}

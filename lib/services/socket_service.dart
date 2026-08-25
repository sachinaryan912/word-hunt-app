import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'auth_service.dart';

/// Wraps the Socket.IO connection to the Node backend. One socket per app
/// session, authenticated with a fresh Firebase ID token at connect time.
class SocketService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://word-hunt-backend-62164525100.us-central1.run.app',
  );

  final AuthService authService;
  socket_io.Socket? _socket;

  SocketService(this.authService);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await authService.idToken;
    if (token == null) return;

    _socket?.dispose();
    _socket = socket_io.io(
      baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void joinMatchmaking() => emit('matchmaking:join');
  void cancelMatchmaking() => emit('matchmaking:cancel');

  void sendWordSelect(String matchId, List<Map<String, int>> path) {
    emit('word:select', {'matchId': matchId, 'path': path});
  }

  void rejoinMatch(String matchId) {
    emit('match:rejoin', {'matchId': matchId});
  }

  void createRoom() => emit('room:create');
  void joinRoom(String code) => emit('room:join', {'code': code});
  void setRoomReady(String code, bool ready) => emit('room:ready', {'code': code, 'ready': ready});
  void leaveRoom(String code) => emit('room:leave', {'code': code});
  void startRoom(String code) => emit('room:start', {'code': code});
  void inviteToRoom(String code, String friendUid) => emit('room:invite', {'code': code, 'friendUid': friendUid});

  void sendChat(String channel, String text) => emit('chat:send', {'channel': channel, 'text': text});
}

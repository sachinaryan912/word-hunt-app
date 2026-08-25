import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

class RoomPlayer {
  final String uid;
  final String displayName;
  final int rating;
  final bool ready;
  const RoomPlayer({required this.uid, required this.displayName, required this.rating, required this.ready});

  factory RoomPlayer.fromJson(Map<String, dynamic> json) => RoomPlayer(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? 'Player',
        rating: json['rating'] as int? ?? 1200,
        ready: json['ready'] as bool? ?? false,
      );
}

/// Live private-room lobby state. Once both players are ready and the host
/// starts, the server folds this into a normal authoritative match — from
/// that point on MatchProvider (already listening globally) takes over.
class RoomProvider extends ChangeNotifier {
  final SocketService socketService;
  RoomProvider(this.socketService);

  String? code;
  RoomPlayer? host;
  RoomPlayer? guest;
  String? closedReason;
  String? errorCode;
  int? errorXpNeeded;
  int? xpChargedAmount;
  String? disconnectedUid;

  bool _listening = false;

  void startListening() {
    if (_listening) return;
    _listening = true;
    socketService.on('room:created', _onCreated);
    socketService.on('room:update', _onUpdate);
    socketService.on('room:closed', _onClosed);
    socketService.on('error', _onError);
    socketService.on('room:xp_charged', _onXpCharged);
    socketService.on('room:player_disconnected', _onPlayerDisconnected);
    socketService.on('room:player_reconnected', _onPlayerReconnected);
    // A socket reconnect (brief network drop) doesn't automatically put this
    // player's socket back in the server's room broadcast group — only an
    // explicit room:sync does that, and it also cancels the disconnect
    // grace timer so the lobby isn't torn down from under them.
    socketService.onConnect(() {
      if (code != null) socketService.syncRoom();
    });
  }

  void reset() {
    code = null;
    host = null;
    guest = null;
    closedReason = null;
    errorCode = null;
    errorXpNeeded = null;
    xpChargedAmount = null;
    disconnectedUid = null;
    notifyListeners();
  }

  void clearError() {
    errorCode = null;
    errorXpNeeded = null;
  }

  void clearXpCharge() {
    xpChargedAmount = null;
  }

  void create() {
    reset();
    socketService.createRoom();
  }

  void join(String joinCode) {
    reset();
    socketService.joinRoom(joinCode);
  }

  void setReady(bool ready) {
    final c = code;
    if (c == null) return;
    socketService.setRoomReady(c, ready);
  }

  void leave() {
    final c = code;
    if (c == null) return;
    socketService.leaveRoom(c);
    reset();
  }

  void start() {
    final c = code;
    if (c == null) return;
    socketService.startRoom(c);
  }

  void invite(String friendUid) {
    final c = code;
    if (c == null) return;
    socketService.inviteToRoom(c, friendUid);
  }

  void _onCreated(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    code = json['code'] as String;
    notifyListeners();
  }

  void _onUpdate(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    code = json['code'] as String;
    host = RoomPlayer.fromJson(Map<String, dynamic>.from(json['host'] as Map));
    final guestJson = json['guest'];
    guest = guestJson != null ? RoomPlayer.fromJson(Map<String, dynamic>.from(guestJson as Map)) : null;
    notifyListeners();
  }

  void _onClosed(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    closedReason = json['reason'] as String?;
    notifyListeners();
  }

  void _onError(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    errorCode = json['code'] as String?;
    errorXpNeeded = json['xpNeeded'] as int?;
    notifyListeners();
  }

  void _onXpCharged(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    xpChargedAmount = json['amount'] as int?;
    notifyListeners();
  }

  void _onPlayerDisconnected(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    disconnectedUid = json['uid'] as String?;
    notifyListeners();
  }

  void _onPlayerReconnected(dynamic data) {
    disconnectedUid = null;
    notifyListeners();
  }
}

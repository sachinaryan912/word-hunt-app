import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';

enum FriendInviteOutcome { none, pending, declined, expired, failed }

class IncomingFriendInvite {
  final String inviteId;
  final String fromUid;
  final String fromDisplayName;
  const IncomingFriendInvite({required this.inviteId, required this.fromUid, required this.fromDisplayName});
}

/// Live "play with a friend" invite flow — a real-time request to a specific
/// friend to start a match right now (distinct from a private room's
/// share-a-code invite, which has no accept/decline step). Fed entirely by
/// Socket.IO events, mirroring MatchProvider/RoomProvider.
class FriendMatchProvider extends ChangeNotifier {
  final SocketService socketService;
  FriendMatchProvider(this.socketService);

  bool _listening = false;

  // Outgoing: I invited someone and am waiting for their response.
  String? outgoingInviteId;
  String? outgoingToUid;
  String? outgoingToDisplayName;
  FriendInviteOutcome outgoingOutcome = FriendInviteOutcome.none;
  String? outgoingFailureCode;

  // Incoming: a friend invited me. Surfaced globally (any screen) via MainShell.
  IncomingFriendInvite? incomingInvite;

  // Set when I accepted an invite but the match couldn't start (friend went
  // busy/offline in the meantime) — the connecting screen watches this.
  String? acceptFailureCode;

  void startListening() {
    if (_listening) return;
    _listening = true;
    socketService.on('friend_match:invite', _onIncomingInvite);
    socketService.on('friend_match:invite_sent', _onInviteSent);
    socketService.on('friend_match:declined', _onDeclined);
    socketService.on('friend_match:cancelled', _onCancelled);
    socketService.on('friend_match:expired', _onExpired);
    socketService.on('friend_match:error', _onError);
    socketService.on('friend_match:accept_failed', _onAcceptFailed);
  }

  Map<String, dynamic> _asMap(dynamic data) => Map<String, dynamic>.from(data as Map);

  void sendInvite(String toUid, String toDisplayName) {
    outgoingInviteId = null;
    outgoingToUid = toUid;
    outgoingToDisplayName = toDisplayName;
    outgoingOutcome = FriendInviteOutcome.pending;
    outgoingFailureCode = null;
    notifyListeners();
    socketService.emit('friend_match:invite', {'toUid': toUid});
  }

  void cancelOutgoing() {
    final id = outgoingInviteId;
    if (id != null) socketService.emit('friend_match:cancel', {'inviteId': id});
    _resetOutgoing();
  }

  void _resetOutgoing() {
    outgoingInviteId = null;
    outgoingToUid = null;
    outgoingToDisplayName = null;
    outgoingOutcome = FriendInviteOutcome.none;
    notifyListeners();
  }

  void accept(String inviteId) {
    acceptFailureCode = null;
    socketService.emit('friend_match:accept', {'inviteId': inviteId});
    if (incomingInvite?.inviteId == inviteId) {
      incomingInvite = null;
      notifyListeners();
    }
  }

  void decline(String inviteId) {
    socketService.emit('friend_match:decline', {'inviteId': inviteId});
    if (incomingInvite?.inviteId == inviteId) {
      incomingInvite = null;
      notifyListeners();
    }
  }

  void dismissIncoming() {
    incomingInvite = null;
    notifyListeners();
  }

  /// Surfaces an invite that arrived via a push notification (app was
  /// backgrounded/closed) through the exact same Accept/Decline prompt used
  /// for a live in-app invite — tapping the notification only opens the app
  /// and shows the choice, it doesn't accept on its own.
  void showIncomingFromPush({required String inviteId, required String fromUid, required String fromDisplayName}) {
    incomingInvite = IncomingFriendInvite(inviteId: inviteId, fromUid: fromUid, fromDisplayName: fromDisplayName);
    notifyListeners();
  }

  void clearAcceptFailure() {
    acceptFailureCode = null;
  }

  void _onIncomingInvite(dynamic data) {
    final json = _asMap(data);
    incomingInvite = IncomingFriendInvite(
      inviteId: json['inviteId'] as String,
      fromUid: json['fromUid'] as String,
      fromDisplayName: json['fromDisplayName'] as String? ?? 'A friend',
    );
    notifyListeners();
  }

  void _onInviteSent(dynamic data) {
    final json = _asMap(data);
    outgoingInviteId = json['inviteId'] as String?;
    notifyListeners();
  }

  void _onDeclined(dynamic data) {
    outgoingOutcome = FriendInviteOutcome.declined;
    notifyListeners();
  }

  void _onCancelled(dynamic data) {
    final json = _asMap(data);
    final inviteId = json['inviteId'] as String?;
    if (incomingInvite?.inviteId == inviteId) {
      incomingInvite = null;
      notifyListeners();
    }
  }

  void _onExpired(dynamic data) {
    final json = _asMap(data);
    final inviteId = json['inviteId'] as String?;
    if (incomingInvite?.inviteId == inviteId) incomingInvite = null;
    if (outgoingInviteId != null && outgoingInviteId == inviteId) {
      outgoingOutcome = FriendInviteOutcome.expired;
    }
    notifyListeners();
  }

  void _onError(dynamic data) {
    if (outgoingOutcome != FriendInviteOutcome.pending) return;
    final json = _asMap(data);
    outgoingOutcome = FriendInviteOutcome.failed;
    outgoingFailureCode = json['code'] as String?;
    notifyListeners();
  }

  void _onAcceptFailed(dynamic data) {
    final json = _asMap(data);
    acceptFailureCode = json['code'] as String? ?? 'friend_unavailable';
    notifyListeners();
  }
}

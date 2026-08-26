import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';
import 'navigation_service.dart';
import '../screens/private_room_screen.dart';
import '../screens/friend_requests_sheet.dart';
import '../state/friend_match_provider.dart';

/// Requests notification permission, obtains the FCM token, and keeps it
/// synced to the backend so the server can push (friend requests, room
/// invites, daily challenge reminders). Also routes a tapped notification
/// to the right screen — e.g. a room invite drops the player straight into
/// that room's join flow.
class NotificationService {
  final ApiClient apiClient;
  final FriendMatchProvider friendMatchProvider;
  NotificationService(this.apiClient, this.friendMatchProvider);

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _syncToken(token);
    }
    messaging.onTokenRefresh.listen(_syncToken);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage);
  }

  Future<void> _syncToken(String token) async {
    try {
      await apiClient.updateFcmToken(token);
    } catch (_) {
      // Best-effort — will retry next app launch or token refresh.
    }
  }

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    switch (data['type']) {
      case 'room_invite':
        final code = data['code'] as String?;
        if (code == null) return;
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => PrivateRoomScreen(initialJoinCode: code)),
        );
        break;
      case 'friend_request':
        final context = navigatorKey.currentContext;
        if (context == null) return;
        FriendRequestsSheet.show(context, apiClient);
        break;
      case 'friend_match_invite':
        final inviteId = data['inviteId'] as String?;
        final fromUid = data['fromUid'] as String?;
        final fromDisplayName = data['fromDisplayName'] as String? ?? 'Your friend';
        if (inviteId == null || fromUid == null) return;
        // Opening the notification only surfaces the same Accept/Decline
        // prompt a live in-app invite shows — it doesn't accept on its own.
        friendMatchProvider.showIncomingFromPush(
          inviteId: inviteId,
          fromUid: fromUid,
          fromDisplayName: fromDisplayName,
        );
        break;
    }
  }
}

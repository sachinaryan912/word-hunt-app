import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';
import 'navigation_service.dart';
import '../screens/private_room_screen.dart';

/// Requests notification permission, obtains the FCM token, and keeps it
/// synced to the backend so the server can push (friend requests, room
/// invites, daily challenge reminders). Also routes a tapped notification
/// to the right screen — e.g. a room invite drops the player straight into
/// that room's join flow.
class NotificationService {
  final ApiClient apiClient;
  NotificationService(this.apiClient);

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
    if (data['type'] != 'room_invite') return;
    final code = data['code'] as String?;
    if (code == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PrivateRoomScreen(initialJoinCode: code)),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/player_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class SessionState extends ChangeNotifier {
  final AuthService authService;
  final ApiClient apiClient;
  final SocketService socketService;

  SessionState({required this.authService, required this.apiClient, required this.socketService});

  PlayerProfile? profile;
  List<AchievementDto> achievements = [];
  bool isLoading = false;

  bool get isAnonymous => authService.isAnonymous;
  String? get email => authService.email;

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    try {
      await authService.ensureSignedIn();
      await socketService.connect();
      profile = await apiClient.getMe();
      unawaited(refreshAchievements());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    profile = await apiClient.getMe();
    notifyListeners();
  }

  Future<void> refreshAchievements() async {
    try {
      achievements = await apiClient.getAchievements();
      notifyListeners();
    } catch (_) {
      // Non-critical — profile screen just keeps whatever it last had.
    }
  }

  void applyProfile(PlayerProfile updated) {
    profile = updated;
    notifyListeners();
    unawaited(refreshAchievements());
  }

  Future<void> signInWithGoogle() async {
    await authService.signInWithGoogle();
    await refreshProfile();
  }

  Future<void> signOut() async {
    socketService.disconnect();
    await authService.signOut();
    profile = null;
    achievements = [];
    notifyListeners();
  }
}

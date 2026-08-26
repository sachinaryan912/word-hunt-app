import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/socket_service.dart';
import 'services/ads_service.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/update_service.dart';
import 'state/session_state.dart';
import 'state/match_provider.dart';
import 'state/room_provider.dart';
import 'state/friend_match_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AdsService.initialize();

  // Draw edge-to-edge and make the system status/navigation bars transparent
  // so they blend into the app's own dark background instead of showing up
  // as a separate black bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

  runApp(const WordHuntingApp());
}

class WordHuntingApp extends StatelessWidget {
  const WordHuntingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiClient>(
          update: (_, auth, previous) => ApiClient(auth),
        ),
        ProxyProvider<AuthService, SocketService>(
          update: (_, auth, previous) => previous ?? SocketService(auth),
        ),
        ProxyProvider<ApiClient, UpdateService>(
          update: (_, api, previous) => previous ?? UpdateService(api),
        ),
        Provider<AdsService>(create: (_) => AdsService()),
        Provider<SoundService>(
          create: (_) => SoundService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProxyProvider3<AuthService, ApiClient, SocketService, SessionState>(
          create: (context) => SessionState(
            authService: context.read<AuthService>(),
            apiClient: context.read<ApiClient>(),
            socketService: context.read<SocketService>(),
          ),
          update: (_, auth, api, socket, previous) =>
              previous ?? SessionState(authService: auth, apiClient: api, socketService: socket),
        ),
        ChangeNotifierProxyProvider<SocketService, MatchProvider>(
          create: (context) => MatchProvider(context.read<SocketService>()),
          update: (_, socket, previous) => previous ?? MatchProvider(socket),
        ),
        ChangeNotifierProxyProvider<SocketService, RoomProvider>(
          create: (context) => RoomProvider(context.read<SocketService>()),
          update: (_, socket, previous) => previous ?? RoomProvider(socket),
        ),
        ChangeNotifierProxyProvider<SocketService, FriendMatchProvider>(
          create: (context) => FriendMatchProvider(context.read<SocketService>()),
          update: (_, socket, previous) => previous ?? FriendMatchProvider(socket),
        ),
        ProxyProvider2<ApiClient, FriendMatchProvider, NotificationService>(
          update: (_, api, friendMatch, previous) => previous ?? NotificationService(api, friendMatch),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'WORD HUNTING',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

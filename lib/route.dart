import 'package:go_router/go_router.dart';
import 'package:socketchat/pages/chat.dart';
import 'package:socketchat/pages/home.dart';

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
        name:
            'home', // Optional, add name to your routes. Allows you navigate by name instead of path
        path: '/',
        builder: (context, state) => HomeScreen(),
        routes: [
          GoRoute(
            name: 'chat',
            path: '/chat',
            builder: (context, state) => ChatScreen(),
          ),
        ]),
  ],
);

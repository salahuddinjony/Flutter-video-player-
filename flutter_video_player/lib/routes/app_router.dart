import 'package:go_router/go_router.dart';
import '../views/video_player_view.dart';

class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'video-player',
        builder: (context, state) => const VideoPlayerView(),
      ),
    ],
  );
}


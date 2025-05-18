import 'package:push_notifications_app/presentation/screens/screens.dart';

import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomeScreen()),

    GoRoute(
      path: '/push-details/:messageId',
      builder: (context, state) => DetailsScreen(pushMessageId: state.pathParameters['messageId'] ?? ''),
    ),
  ],
);

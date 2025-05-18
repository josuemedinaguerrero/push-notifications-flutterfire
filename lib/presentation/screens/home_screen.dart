import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:push_notifications_app/presentation/blocs/blocs.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: context.select((NotificationsBloc value) => Text('Permisos: ${value.state.status}')),
        actions: [IconButton(onPressed: () => context.read<NotificationsBloc>().requestPermission(), icon: Icon(Icons.settings))],
      ),
      body: _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsBloc>().state.notifications;

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          title: Text(notification.title),
          subtitle: Text(notification.body),
          leading: notification.imageUrl != null ? Image.network(notification.imageUrl!) : null,
          onTap: () => context.push('/push-details/${notification.messageId}'),
        );
      },
    );
  }
}

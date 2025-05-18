import 'dart:developer';

import 'package:push_notifications_app/domain/entities/push_message.dart';
import 'package:push_notifications_app/firebase_options.dart';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final Future<void> Function() requestLocalNotificationPermissions;
  final void Function({required int id, String? title, String? body, String? data}) showLocalNotification;
  int pushNumberId = 0;

  NotificationsBloc({required this.requestLocalNotificationPermissions, required this.showLocalNotification})
    : super(NotificationsState()) {
    on<NotificationStatusChanged>(_notificationStatusChanged);
    on<NotificationReceived>(_onPushMessageReceived);

    // Verifica estado de las notificaciones
    _initialStatusCheck();

    // Listener para notificaciones en Foreground
    _onForegroundMessage();
  }

  static Future<void> initializeFirebaseNotifications() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  void _notificationStatusChanged(NotificationStatusChanged event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(status: event.status));
    _getFCMToken();
  }

  void _onPushMessageReceived(NotificationReceived event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(notifications: [event.pushMessage, ...state.notifications]));
  }

  void _initialStatusCheck() async {
    final settings = await messaging.getNotificationSettings();
    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  void _getFCMToken() async {
    if (state.status != AuthorizationStatus.authorized) return;

    final token = await messaging.getToken();
    log("FCM TOKEN: $token");
  }

  void handleRemoteMessage(RemoteMessage message) {
    if (message.notification == null) return;

    final notification = PushMessage(
      messageId: message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl,
    );

    showLocalNotification(id: ++pushNumberId, body: notification.body, data: notification.messageId, title: notification.title);

    add(NotificationReceived(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Solicitar acceso para local notifications
    await requestLocalNotificationPermissions();

    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  PushMessage? getMessageById(String messageId) {
    final exists = state.notifications.any((element) => element.messageId == messageId);
    if (!exists) return null;

    return state.notifications.firstWhere((element) => element.messageId == messageId);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

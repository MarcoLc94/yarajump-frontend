import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Push con Firebase Cloud Messaging. Firebase solo se usa para esto.
/// Si Firebase no está configurado (falta google-services.json / GoogleService-Info.plist),
/// la app funciona igual, solo que sin notificaciones.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool disponible = false;
  final _local = FlutterLocalNotificationsPlugin();

  static const _canal = AndroidNotificationChannel(
    'vencimientos', // debe coincidir con channel_id en el backend (notify/fcm.go)
    'Vencimientos de plan',
    description: 'Avisos cuando tu plan está por vencer',
    importance: Importance.high,
  );

  Future<void> init() async {
    // En la PWA no hay push por ahora (requiere Web Push + VAPID; en iPhone solo con la app instalada).
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      disponible = true;
    } catch (e) {
      debugPrint('Firebase no configurado, push desactivado: $e');
      return;
    }

    await _local.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    // Con la app abierta FCM no muestra nada por sí solo: lo mostramos aquí.
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(_canal.id, _canal.name,
              channelDescription: _canal.description, importance: Importance.high, priority: Priority.high),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Pide permiso y entrega el token a [guardar] (que lo manda a la API).
  Future<void> registrarToken(Future<void> Function(String token) guardar) async {
    if (!disponible) return;
    final fcm = FirebaseMessaging.instance;
    final settings = await fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await fcm.getToken();
    if (token != null) await guardar(token);
    fcm.onTokenRefresh.listen(guardar);
  }
}

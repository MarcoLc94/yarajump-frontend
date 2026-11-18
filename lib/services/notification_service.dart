import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'push_web/push_web.dart';

/// Push con Firebase Cloud Messaging. Firebase solo se usa para esto.
/// Si Firebase no está configurado (falta google-services.json / GoogleService-Info.plist),
/// la app funciona igual, solo que sin notificaciones.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool disponible = false;

  /// Solo web: si se puede/hace falta pedir permiso (lo muestra la tarjeta en "Mi plan").
  final estadoWeb = ValueNotifier(EstadoPushWeb.noSoportado);
  Future<void> Function(String token)? _guardar;

  final _local = FlutterLocalNotificationsPlugin();

  static const _canal = AndroidNotificationChannel(
    'vencimientos', // debe coincidir con channel_id en el backend (notify/fcm.go)
    'Vencimientos de plan',
    description: 'Avisos cuando tu plan está por vencer',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      disponible = true;
    } catch (e) {
      debugPrint('Firebase no configurado, push desactivado: $e');
      return;
    }
    if (kIsWeb) {
      // En la PWA las notificaciones las muestra el service worker (web/firebase-messaging-sw.js).
      estadoWeb.value = estadoPushWeb();
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
  /// En web solo manda el token si ya dio permiso; para pedirlo está [activarWeb].
  Future<void> registrarToken(Future<void> Function(String token) guardar) async {
    if (!disponible) return;
    if (kIsWeb) {
      _guardar = guardar;
      if (estadoWeb.value != EstadoPushWeb.activado) return;
      try {
        final token = await tokenPushWeb(DefaultFirebaseOptions.vapidKey, pedirPermiso: false);
        if (token != null) await guardar(token);
      } catch (e) {
        debugPrint('push web: $e');
      }
      return;
    }
    final fcm = FirebaseMessaging.instance;
    final settings = await fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await fcm.getToken();
    if (token != null) await guardar(token);
    fcm.onTokenRefresh.listen(guardar);
  }

  /// Pide permiso en la PWA. Llamar directo desde el onPressed (sin awaits antes):
  /// Safari en iPhone solo muestra el permiso si viene de un toque.
  Future<bool> activarWeb() async {
    String? token;
    try {
      token = await tokenPushWeb(DefaultFirebaseOptions.vapidKey, pedirPermiso: true);
    } catch (e) {
      debugPrint('push web: $e');
    }
    estadoWeb.value = estadoPushWeb();
    if (token == null) return false;
    await _guardar?.call(token);
    return true;
  }
}

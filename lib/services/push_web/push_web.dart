// Push en la PWA: habla con window.yaraPush (web/index.html), que registra
// firebase-messaging-sw.js dentro de /app/ y pide el token de FCM.
// El import condicional evita compilar código web en Android/iOS.
export 'push_web_stub.dart' if (dart.library.js_interop) 'push_web_impl.dart';

enum EstadoPushWeb {
  /// Navegador sin Web Push (o no es web).
  noSoportado,

  /// iPhone/iPad fuera de la app instalada: hay que "Agregar a pantalla de inicio" desde Safari.
  instalarEnIphone,

  /// Aún no se pide permiso.
  pendiente,
  activado,
  bloqueado,
}

EstadoPushWeb estadoDesdeJs(String s) => switch (s) {
      'instalar' => EstadoPushWeb.instalarEnIphone,
      'default' => EstadoPushWeb.pendiente,
      'granted' => EstadoPushWeb.activado,
      'denied' => EstadoPushWeb.bloqueado,
      _ => EstadoPushWeb.noSoportado,
    };

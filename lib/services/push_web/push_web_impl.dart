import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'push_web.dart';

JSObject? get _yaraPush => globalContext.getProperty<JSObject?>('yaraPush'.toJS);

EstadoPushWeb estadoPushWeb() {
  final p = _yaraPush;
  if (p == null) return EstadoPushWeb.noSoportado;
  return estadoDesdeJs(p.callMethod<JSString>('estado'.toJS).toDart);
}

/// Con [pedirPermiso] debe llamarse directo desde un toque del usuario
/// (Safari solo deja pedir permiso así): el permiso se pide antes de cualquier await.
Future<String?> tokenPushWeb(String vapidKey, {required bool pedirPermiso}) async {
  final p = _yaraPush;
  if (p == null) return null;
  final r = await p.callMethod<JSPromise<JSString?>>('token'.toJS, vapidKey.toJS, pedirPermiso.toJS).toDart;
  return r?.toDart;
}

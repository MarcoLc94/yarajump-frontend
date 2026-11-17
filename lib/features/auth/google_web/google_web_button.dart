// Botón oficial de Google para la PWA. En web, google_sign_in no permite
// authenticate(): hay que mostrar el botón de Google y escuchar authenticationEvents.
// El import condicional evita compilar código web en Android/iOS.
export 'google_web_button_stub.dart' if (dart.library.js_interop) 'google_web_button_web.dart';

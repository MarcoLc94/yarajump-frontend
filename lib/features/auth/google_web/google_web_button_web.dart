import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Botón "Continuar con Google" de Google Identity Services.
/// El ancho de GIS va de 200 a 400 px.
Widget googleWebButton({required double width}) => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        logoAlignment: web.GSIButtonLogoAlignment.center,
        minimumWidth: width.clamp(200, 400).toDouble(),
        locale: 'es',
      ),
    );

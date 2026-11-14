# yarajump-frontend

App móvil (Flutter, Android / iOS) de **Yara Jumping**. Consume la API de [yarajump-backend](https://github.com/MarcoLc94/yarajump-backend).

## Correr la app

```bash
flutter pub get
cp env/dev.json.example env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json`:

| Clave | Valor |
|---|---|
| `API_URL` | Emulador Android: `http://10.0.2.2:8080` · Celular físico: `http://<IP de tu PC>:8080` · Producción: URL de Railway |
| `GOOGLE_SERVER_CLIENT_ID` | El **Web client ID** de Google Cloud |
| `DEV_AUTH` | `"true"` muestra "Entrar con correo (pruebas)" en el login |

Ya están aplicados los ajustes de Android: `FlutterFragmentActivity` para la huella, los permisos (internet, biometría, notificaciones), `minSdk = 23` y `usesCleartextTraffic` solo en la versión de depuración.

**iOS:** en `Info.plist` agrega `NSFaceIDUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, y `GIDClientID` con el iOS client ID más su URL scheme.

## Login con Google

En Google Cloud Console → Credenciales crea los IDs de cliente OAuth:
- **Android:** paquete `com.yarajumping.yara_jumping` y el SHA-1 (`cd android && ./gradlew signingReport`).
- **Web:** su ID va en `GOOGLE_SERVER_CLIENT_ID`.
- **iOS** (si aplica): su ID va en el `Info.plist`.

## Notificaciones push (opcional)

Ejecuta `flutterfire configure` en esta carpeta; agrega `google-services.json` y `GoogleService-Info.plist`.

Ver `docs/PLAN.md` para el plan completo del proyecto.

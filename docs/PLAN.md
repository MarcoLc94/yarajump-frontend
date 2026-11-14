# Yara Jumping: plan de la app

App móvil (Android / iOS) para administrar los clientes, planes y vencimientos de pago de un gimnasio de **jumping**.

---

## 1. Arquitectura

```
 App Flutter ──HTTPS/JSON──▶ API Go (Railway) ──▶ PostgreSQL (Railway)
     │  ▲                         │
     │  └── push ◀── FCM ◀────────┘  (cron interno: avisos de vencimiento)
     └── Google Sign-In (ID token → la API lo verifica y emite su propio JWT)
```

| Capa | Tecnología | Por qué |
|---|---|---|
| App | **Flutter** + **Riverpod 2** | Un solo código para Android e iOS |
| API | **Go** (`chi`, `lib/pq`, `golang-jwt`) | Binario de ~15 MB, ~20 MB de RAM: barato en Railway |
| Base de datos | **PostgreSQL** en Railway | Relacional, con transacciones para los pagos |
| Login | **Google Sign-In** → JWT propio | Un clic; sin contraseñas que administrar |
| Huella | **local_auth** | Desbloquea la sesión guardada |
| Push | **Firebase Cloud Messaging** (solo push) | Gratis; la API lo llama por HTTP v1 |
| Fotos | Volumen de Railway (`/data/uploads`) | Simple; migrable a R2/S3 |
| WhatsApp | `url_launcher` → `https://wa.me/<número>` | |

**Costo estimado:** plan Hobby de Railway (USD 5 al mes con USD 5 de consumo incluido). Con este volumen, la API y Postgres deberían caber ahí o pasarse muy poco.

---

## 2. Roles

| Rol | Cómo se asigna | Qué puede hacer |
|---|---|---|
| `admin` | Su correo está en `ADMIN_EMAILS` (variable de la API) | Clientes, planes, recordatorios y pagos |
| `usuario` | Cualquier otra cuenta de Google | **Mi plan** y **Mi perfil** |

**Vinculación cliente ↔ cuenta de Google:** la admin registra al cliente con su **correo de Gmail**. Cuando ese correo entra con Google, la API los vincula, sin importar quién llegó primero.
Si no existe ningún cliente con ese correo, la app muestra *"Tu cuenta aún no está registrada"*, con un botón de WhatsApp y otro de "Ya me registraron".

---

## 3. Módulos

### Administrador
1. **Clientes:** alta, edición y baja (nombre, teléfono, correo, plan, fecha de inicio y frecuencia). Un toque largo **registra un pago**. Los clientes que aún no entran a la app aparecen marcados.
2. **Planes:** nombre, costo, descripción, frecuencia sugerida y activo/inactivo. No se puede borrar un plan con clientes asignados (hay que desactivarlo).
3. **Recordatorios:** clientes ordenados por vencimiento, con filtros (Expirado / Último día / Por vencer / Activo) y la frecuencia de cada uno:
   - Semanal (7 días) · Quincenal (15 días) · Mensual · Bimestral · Semestral · Anual (por meses de calendario)
   - **Libre:** N días

### Usuario
1. **Mi plan:** plan, días restantes y fecha de vencimiento.
   - 3 y 2 días: aviso naranja *"Tu plan está por expirar"*
   - 1 día: *"Hoy es tu último día"*
   - 0 días o menos: **"PLAN EXPIRADO"** en rojo y el botón **"Regularizar pago por WhatsApp"**
2. **Mi perfil:** foto (cámara o galería), teléfono, contacto de emergencia y fecha de nacimiento.

---

## 4. Flujo de acceso

```
Abrir app
 └─ ¿Hay JWT guardado y la API lo acepta (GET /me)?
     ├─ No → Login → [Continuar con Google] → POST /auth/google → JWT
     │       └─ ¿Ya se le preguntó por la huella? No → "¿Activar huella?"
     └─ Sí → ¿Huella activada? → pedir huella → Home según rol
```
Si la huella falla 3 veces, aparece "Entrar con Google de nuevo". El JWT dura 60 días; al vencer, se vuelve a entrar con Google en un clic.

---

## 5. Reglas de vencimiento (las calcula la API)

- `fechaFin` = **último día cubierto**. `diasRestantes = fechaFin − hoy + 1` (en hora de CDMX).
- **Registrar pago:** si el plan sigue vigente, el periodo nuevo empieza en `fechaFin + 1` (no se pierden días); si ya expiró, empieza en la fecha del pago. Cada pago queda en el historial.
- **Push** (cada 30 min a partir de las 9:00, una sola vez por aviso):

| diasRestantes | Título | Mensaje |
|---|---|---|
| 3 | Tu plan está por vencer | Te quedan 3 días. Realiza tu pago para seguir saltando 💪 |
| 2 | Tu plan está por vencer | Te quedan 2 días. No olvides realizar tu pago. |
| 1 | Hoy es tu último día | Realiza tu pago hoy para continuar mañana. |
| 0 | Plan expirado | Tu plan expiró. Comunícate con Yara Jumping para regularizar tu pago. |

---

## 6. Modelo de datos (PostgreSQL)

```
planes           id, nombre, precio, descripcion, frecuencia_sugerida, activo
clientes         id, nombre, email (único), telefono, fecha_nacimiento, contacto_emergencia, foto_url,
                 plan_id → planes, frecuencia, dias_personalizados, fecha_inicio, fecha_fin, activo
users            id, email (único), nombre, foto_url, rol (admin|usuario), cliente_id → clientes (único), fcm_token
pagos            id, cliente_id → clientes, monto, fecha_pago, periodo_inicio, periodo_fin, plan_nombre, registrado_por
avisos_enviados  (cliente_id, fecha_fin, dias)  ← evita mandar dos veces el mismo push
```
Migraciones en `backend/internal/store/migrations/`, que se aplican solas al arrancar.

---

## 7. Roadmap

| Fase | Entregable | Estado |
|---|---|---|
| 0. Base | API Go + Postgres, app Flutter conectada, modo pruebas | ✅ |
| 1. Google | Client IDs de OAuth, probar el login real en el celular | ⬜ |
| 2. Push | Proyecto Firebase, `flutterfire configure`, cuenta de servicio en la API | ⬜ |
| 3. Railway | Deploy de API y Postgres, volumen y dominio | ⬜ |
| 4. Pulido | Logo, colores e íconos de Yara, splash, pruebas con la clienta | ⬜ |
| 5. Publicar | Play Store (y App Store si aplica) | ⬜ |

**Mejoras para una segunda versión:** historial de pagos visible para el usuario (el endpoint `/me/pagos` ya existe), reporte de ingresos del mes, aviso a la admin de los clientes que vencen hoy y login con correo y contraseña.

---

## 8. Pendiente de confirmar con la clienta
- [ ] Número de WhatsApp de la admin (con lada 52)
- [ ] Correo(s) de admin
- [ ] Logo y colores de Yara Jumping
- [ ] ¿Solo Android o también iOS? (iOS requiere una cuenta de Apple Developer, USD 99 al año)
- [ ] ¿"Mensual" es por mes de calendario (15 → 14 del siguiente mes) o cada 30 días?
- [ ] ¿Hay clientes sin Gmail?
- [ ] Hora de los avisos (por defecto, 9:00 a. m.)

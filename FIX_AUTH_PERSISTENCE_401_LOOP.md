# FIX: Auth Persistence + 401 Loop Spam

## PROBLEMA ORIGINAL

1. **Auth no persistía**: cada vez que se abría la app, el usuario debía hacer login de nuevo
2. **401 loop spam**: el backend recibía constantemente requests de `/api/attendance/punches` y `/api/crm/chats/stats` con 401 
3. **Auto-logout**: requests fallidos causaban que la app cerrara sesión automáticamente

## CAUSA RAÍZ

**Race condition en el startup**:
- Los widgets `AutoSync` y `AutoAttendanceSync` se montaban ANTES de que `bootstrap()` completara la validación del token
- Estos widgets llamaban `Future.microtask(_scheduleSync)` inmediatamente en `initState()`
- Esto causaba requests a endpoints protegidos ANTES de que el token estuviera cargado/validado
- Backend respondía 401 → App interpretaba como "sesión inválida" → Logout automático

## SOLUCIÓN IMPLEMENTADA

### 1. **Splash Screen durante Bootstrap**
- Creado `splash_screen.dart`: pantalla de carga que se muestra mientras auth se valida
- Modificado `app_router.dart`:
  - `initialLocation: '/splash'` en lugar de `/login`
  - Redirect lógic: `AuthUnknown`/`AuthValidating` → `/splash`, luego redirige según resultado

### 2. **Eliminar Sync en Startup**
**Archivos modificados**:
- `auto_sync.dart`: Removido `Future.microtask(_scheduleSync)` de `initState()`
- `auto_attendance_sync.dart`: Removido `Future.microtask(_scheduleSync)` de `initState()`

**Nueva estrategia**:
- NO sync al iniciar
- Sync solo se dispara cuando:
  1. Usuario completa login exitoso (listener de `AuthAuthenticated`)
  2. Conectividad regresa
  3. App resume desde background
  4. Queue de sync tiene nuevos items

### 3. **Mejor Manejo de 401**
**Modificado `auth_controller.dart`**:
```dart
// ANTES: limpiaba sesión en cualquier 401
await _db.clearSession();
state = const AuthUnauthenticated();

// AHORA: solo limpia si ya estábamos autenticados
final currentState = state;
if (currentState is! AuthAuthenticated) {
  if (kDebugMode) {
    debugPrint('[AUTH] ignoring 401 - not authenticated yet');
  }
  return;
}
```

Esto previene que 401s durante startup/bootstrap limpien la sesión válida.

### 4. **Auth Guards ya Existentes** (verificados, no modificados)
- ✅ `ApiClient` ya lee el token de `LocalDb` y lo agrega a headers
- ✅ `CrmChatStatsController.start()` solo se llama después de auth
- ✅ `AutoSync` auth listener ya verifica `is AuthAuthenticated`

## FLUJO FINAL

### Al Abrir la App:
```
1. main() → init LocalDb
2. _Bootstrapper mounts
3. GoRouter initialLocation = '/splash' → SplashScreen shown
4. bootstrap() llamado:
   - Lee token de SQLite (auth_session table)
   - Si existe: valida con GET /api/auth/me
   - Si 200 → AuthAuthenticated → redirect a /crm
   - Si 401 → AuthUnauthenticated → redirect a /login
5. Usuario ve Home (si token válido) o Login (si no hay token/expirado)
```

### Después de Login:
```
1. login() → guarda token en SQLite
2. state = AuthAuthenticated
3. GoRouter redirige a /crm
4. AutoSync listener detecta AuthAuthenticated
5. Inicia sync de módulos (attendance, sales, cotizaciones, etc.)
6. CrmChatStatsController.start() inicia timer de 30s
```

### Si Token Expira:
```
1. Request protegido → 401
2. ApiClient interceptor:
   - Verifica que request tenía Authorization header
   - Emite AuthEvent.unauthorized
3. AuthController listener:
   - Verifica que state es AuthAuthenticated
   - Solo entonces limpia sesión y marca como Unauthenticated
4. GoRouter redirige a /login
5. Todos los timers/sync se detienen (auth listeners)
```

## RESULTADOS ESPERADOS

✅ **Auth persiste entre runs**: usuario abre la app y ya está logueado
✅ **No más 401 spam**: no hay requests protegidos antes de auth
✅ **No auto-logout accidental**: 401s durante startup no afectan sesión válida
✅ **Splash screen profesional**: feedback visual mientras se valida token
✅ **Sync solo cuando necesario**: no hay timers/requests en background sin auth

## ARCHIVOS MODIFICADOS

1. ✅ `lib/features/auth/screens/splash_screen.dart` (NEW)
2. ✅ `lib/core/routing/app_router.dart`
3. ✅ `lib/features/auth/state/auth_controller.dart`
4. ✅ `lib/core/widgets/auto_sync.dart`
5. ✅ `lib/features/ponchado/presentation/widgets/auto_attendance_sync.dart`

## TESTING

Para verificar que funciona:

1. **Logout y cerrar app**
2. **Login y cerrar app**
3. **Reabrir app** → debería mostrar splash por 1-2 segundos, luego home (sin login)
4. **Verificar backend logs** → no debería haber 401 spam al iniciar
5. **Dejar app abierta 10+ minutos** → no debería hacer logout solo
6. **Probar offline** → app debería mantener sesión y usar cache

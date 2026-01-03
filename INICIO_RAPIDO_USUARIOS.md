# ⚡ INICIO RÁPIDO - 10 MINUTOS

## 1️⃣ COPIAR ARCHIVOS (2 minutos)

### Backend
Todos estos archivos YA ESTÁN CREADOS en la carpeta del proyecto:
- ✅ `fulltech_api/src/services/aiIdentityService.ts`
- ✅ `fulltech_api/src/modules/usuarios/usuarios.schema.ts`
- ✅ `fulltech_api/src/modules/usuarios/usuarios.controller.ts`
- ✅ `fulltech_api/src/modules/usuarios/uploads.controller.ts`
- ✅ `fulltech_api/src/modules/usuarios/pdf.controller.ts`
- ✅ `fulltech_api/src/modules/usuarios/usuarios.routes.ts`

### Frontend
Todos estos archivos YA ESTÁN CREADOS:
- ✅ `fulltech_app/lib/features/usuarios/models/usuario_model.dart`
- ✅ `fulltech_app/lib/features/usuarios/data/datasources/usuarios_remote_datasource.dart`
- ✅ `fulltech_app/lib/features/usuarios/data/repositories/usuarios_repository.dart`
- ✅ `fulltech_app/lib/features/usuarios/state/usuarios_controller.dart`
- ✅ `fulltech_app/lib/features/usuarios/presentation/pages/users_list_page.dart`
- ✅ `fulltech_app/lib/features/usuarios/presentation/pages/user_form_page.dart`
- ✅ `fulltech_app/lib/features/usuarios/presentation/pages/user_detail_page.dart`
- ✅ `fulltech_app/lib/features/usuarios/usuarios_menu.dart`

---

## 2️⃣ INSTALAR DEPENDENCIAS (4 minutos)

### Backend

```bash
cd fulltech_api

# Instalar nuevas librerías
npm install multer puppeteer axios bcrypt uuid

# Esto te pedirá permiso para descargar Chromium (para PDFs)
# Presiona 'Y' cuando pregunte

echo "✅ Backend listo"
```

### Frontend

```bash
cd fulltech_app

# Instalar paquetes Flutter
flutter pub add image_picker intl flutter_riverpod dio json_annotation
flutter pub add --dev json_serializable build_runner

# Generar código JSON
dart run build_runner build

echo "✅ Frontend listo"
```

---

## 3️⃣ CONFIGURAR BASE DE DATOS (1 minuto)

### Aplicar migraciones Prisma

```bash
cd fulltech_api

# Ver si hay cambios pendientes (solo info)
npx prisma migrate status

# APLICAR CAMBIOS A LA BD
npx prisma migrate dev --name add_usuarios_module

# Cuando pregunte "Do you want to continue?" → Presiona Y
# Cuando pregunte sobre generar client → Presiona Y
```

✅ Tablas `Usuario` y `CompanySettings` creadas automáticamente

---

## 4️⃣ INICIAR SERVICIOS (3 minutos)

### Terminal 1: Backend

```bash
cd fulltech_api
npm run dev
```

Espera a ver:
```
Server running on port 3000
Connected to database fulltechapp_sistem
```

### Terminal 2: Frontend

```bash
cd fulltech_app
flutter run -d windows
```

Espera a ver:
```
✓ Built build/windows/x64/runner/Debug/fulltech_app.exe
Launching lib/main.dart on Windows in debug mode...
```

---

## 5️⃣ INTEGRAR EN LA APP (Opcional si quieres que aparezca en el menu)

Abre `fulltech_app/lib/main.dart` y busca donde estén tus rutas:

Agrega esto donde tengas otras rutas:
```dart
import 'features/usuarios/presentation/pages/users_list_page.dart';

// En tu router/routes:
'/usuarios': (context) => const UsersListPage(),
```

Si tienes sidebar/drawer, agrega el item:
```dart
import 'features/usuarios/usuarios_menu.dart';

ListTile(
  leading: const Icon(Icons.people),
  title: const Text('Usuarios'),
  onTap: () {
    Navigator.pushNamed(context, '/usuarios');
  },
),
```

---

## 🧪 PROBAR INMEDIATAMENTE

### 1. Crear usuario por API (opcional)

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "nombre_completo": "Juan Test",
    "password": "Test123!",
    "rol": "vendedor",
    "posicion": "vendedor",

    "fecha_nacimiento": "1990-01-01",
    "cedula_numero": "00112233445",
    "telefono": "8095550123",
    "direccion": "Calle Test 123",
    "ubicacion_mapa": "https://maps.google.com/?q=18.4861,-69.9312",

    "fecha_ingreso_empresa": "2024-01-01",
    "salario_mensual": 20000,
    "beneficios": "Seguro, dieta, etc.",

    "licencia_conducir_numero": "LIC-12345",
    "licencia_conducir_fecha_vencimiento": "2027-12-31",
    "tipo_vehiculo": "Motor",
    "placa": "A123456",

    "es_casado": false,
    "cantidad_hijos": 0,
    "tiene_casa": false,
    "tiene_vehiculo": true,

    "foto_perfil_url": "/uploads/users/foto.jpg",
    "cedula_frontal_url": "/uploads/users/cedula-frontal.jpg",
    "cedula_posterior_url": "/uploads/users/cedula-posterior.jpg",
    "licencia_conducir_url": "/uploads/users/licencia.jpg",
    "carta_trabajo_url": "/uploads/users/carta.pdf",
    "otros_documentos": ["/uploads/users/otro1.pdf"]
  }'
```

### 2. Crear usuario en la app

1. Abre la app en Windows
2. Navega a "Usuarios" (si lo agregaste en menu) o abre directamente:
   ```
   http://localhost:... → Usuarios (si está en sidebar)
   ```
3. Haz click en "Nuevo Usuario"
4. Completa el formulario
5. Haz click en "Crear Usuario"

### 3. Probar con IA

1. En el formulario de usuario
2. Secc "Datos Personales"
3. Click "Capturar Cédula y Autocompletar"
4. Toma una foto de cédula (o carga una imagen)
5. Espera a que IA procese (2-3 segundos)
6. ✅ Campos se rellenan automáticamente

### 4. Ver lista

1. Vuelve a "Usuarios"
2. ✅ Usuario aparece en la tabla/lista
3. Filtra por rol
4. Busca por nombre
5. Click en usuario → Ver detalle
6. Click "Editar" → Cambiar datos
7. Click "Descargar PDF Ficha" → Se descarga PDF

---

## 🐛 Si hay errores

### Error: "Port 3000 already in use"
```bash
# Busca qué proceso usa puerto 3000
netstat -ano | findstr :3000

# Mata el proceso (obtén PID de comando anterior)
taskkill /PID <PID> /F

# O cambia port en backend: PORT=3001 npm run dev
```

### Error: "Database connection failed"
```bash
# Verifica DATABASE_URL en .env
cat fulltech_api/.env

# Debe ser:
DATABASE_URL=postgres://n8n_user:Ayleen10.yahaira@gcdndd.easypanel.host:5432/fulltechapp_sistem?sslmode=disable

# Si está mal, edita y reinicia backend
```

### Error: "APIKEY_CHATGPT missing"
```bash
# Debe estar en .env:
APIKEY_CHATGPT=sk-proj-...

# Si no está:
1. Abre fulltech_api/.env
2. Agrega la key (ya debe estar del trabajo anterior)
3. Reinicia backend
```

### Error: "Cannot find file xyz"
```bash
# Asegúrate de que estés en la carpeta correcta
cd c:\Users\PC\Desktop\fulltech_app_sistema\fulltech_api

# O en frontend
cd c:\Users\PC\Desktop\fulltech_app_sistema\fulltech_app

# Verifica rutas con:
ls src/modules/usuarios/  # Backend
ls lib/features/usuarios/  # Frontend
```

### Error: "Compilation error in Flutter"
```bash
# Regenera modelos
cd fulltech_app
dart run build_runner build

# Si sigue fallando:
flutter clean
flutter pub get
flutter run -d windows
```

---

## ✅ CHECKLIST RÁPIDO

- [ ] npm install hecho (backend)
- [ ] flutter pub add hecho (frontend)
- [ ] npx prisma migrate dev ejecutado
- [ ] Backend corriendo en puerto 3000
- [ ] Frontend corriendo en Windows
- [ ] Puedes crear usuario desde formulario
- [ ] Puedes ver lista de usuarios
- [ ] Puedes editar usuario
- [ ] PDFs se descargan

---

## 📊 URLs Útiles

```
App Flutter:     http://localhost:xxxxx (muestra en terminal)
Backend API:     http://localhost:3000/api
Prisma Studio:   cd fulltech_api && npx prisma studio
DevTools Flutter: Automático al ejecutar flutter run
```

---

## 🚀 PRÓXIMOS PASOS (Opcional)

1. **Autenticación:** Agregar middleware JWT en rutas usuarios
2. **Permisos:** Solo admin puede crear usuarios
3. **Auditoría:** Log de quién cambió qué en cada usuario
4. **Notificaciones:** Email al crear usuario con contraseña temporal
5. **Importación:** CSV para crear usuarios en batch

---

## 📞 AYUDA RÁPIDA

**¿Dónde están los archivos?**
→ Todos creados en las carpetas `usuarios/` de ambos proyectos

**¿Qué es lo mínimo para que funcione?**
→ Backend corriendo + Frontend compilando + BD migrada

**¿Puedo usar otra BD?**
→ Sí, cambia DATABASE_URL en .env

**¿Puedo desactivar IA?**
→ Sí, comentar endpoint `/api/usuarios/ia/cedula` en routes

**¿Los PDFs se almacenan?**
→ No, se generan bajo demanda y se descargan directamente

**¿Puedo cambiar colores?**
→ Sí, edita colores en las páginas Flutter (Colors.blue → tu color)

---

## ⏱️ TIMELINE

```
Instalación deps:      4 min
Migraciones BD:        1 min
Backend startup:       1 min
Frontend startup:      3 min
Primer usuario:        1 min
                       ──────
TOTAL:                 10 min ⚡
```

---

**¡Listo! Ahora a divertirse con los usuarios 🎉**

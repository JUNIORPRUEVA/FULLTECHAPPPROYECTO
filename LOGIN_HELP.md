# 🔐 LOGIN TROUBLESHOOTING GUIDE / GUÍA DE SOLUCIÓN DE PROBLEMAS DE INICIO DE SESIÓN

## ✅ CREDENCIALES DE ACCESO / LOGIN CREDENTIALS

**Por defecto, usa estas credenciales:**

```
Email: admin@fulltech.com
Contraseña: Admin1234
```

---

## 🚀 SOLUCIÓN RÁPIDA / QUICK FIX

Si no puedes iniciar sesión, ejecuta estos comandos:

### 1. Asegúrate de que la base de datos esté configurada

```bash
cd fulltech_api
```

Verifica que existe el archivo `.env` con la configuración de base de datos:
```bash
cat .env | grep DATABASE_URL
```

Deberías ver algo como:
```
DATABASE_URL=postgresql://usuario:password@host:5432/database_name
```

### 2. Crea o actualiza el usuario admin

```bash
# Opción 1: Crear/actualizar admin automáticamente
npm run bootstrap-admin

# Opción 2: Verificar si el usuario existe y está activo
npm run verify-user -- admin@fulltech.com

# Opción 3: Resetear la contraseña del admin
npm run reset-password -- admin@fulltech.com Admin1234
```

### 3. Verifica que el usuario está activo

```bash
npm run verify-user -- admin@fulltech.com
```

Esto mostrará:
- ✅ Si el usuario existe
- ✅ Si el estado es "activo"
- ✅ Los detalles del usuario

### 4. Inicia el servidor

```bash
npm run dev
```

Espera a ver:
```
FULLTECH API listening on http://localhost:3000
```

### 5. Prueba el login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@fulltech.com","password":"Admin1234"}'
```

Deberías recibir un token JWT y datos del usuario.

---

## 🔧 PROBLEMAS COMUNES / COMMON ISSUES

### ❌ Error: "Invalid credentials" / "Credenciales inválidas"

**Causa:** La contraseña es incorrecta o el usuario no existe.

**Solución:**
```bash
# Resetear contraseña
npm run reset-password -- admin@fulltech.com Admin1234

# O crear nuevo admin
npm run bootstrap-admin
```

### ❌ Error: "User access revoked" / "Acceso de usuario revocado"

**Causa:** El usuario existe pero su estado NO es "activo".

**Solución:**
```bash
# Verificar y corregir el estado del usuario
npm run verify-user -- admin@fulltech.com

# Si necesitas resetear contraseña también:
npm run verify-user -- admin@fulltech.com Admin1234
```

El script automáticamente cambiará el estado a "activo" si está en otro valor.

### ❌ Error: "User not found" / "Usuario no encontrado"

**Causa:** El usuario no existe en la base de datos.

**Solución:**
```bash
# Crear usuario admin
npm run bootstrap-admin
```

### ❌ Error: "Database connection failed"

**Causa:** La base de datos no está configurada o no está corriendo.

**Solución:**

1. Verifica la configuración en `.env`:
```bash
cat .env | grep DATABASE_URL
```

2. Asegúrate de que PostgreSQL esté corriendo:
```bash
# En Linux/Mac
sudo service postgresql status

# En Windows
net start postgresql-x64-16
```

3. Prueba la conexión:
```bash
npx prisma db pull
```

---

## 📝 COMANDOS ÚTILES / USEFUL COMMANDS

### Ver todos los usuarios
```bash
npx prisma studio
```
Abre una interfaz web en http://localhost:5555 donde puedes ver y editar usuarios.

### Verificar un usuario específico
```bash
npm run verify-user -- email@ejemplo.com
```

### Cambiar contraseña de cualquier usuario
```bash
npm run reset-password -- email@ejemplo.com NuevaContraseña123
```

### Crear usuario admin desde cero
```bash
npm run bootstrap-admin
```

### Ver logs del servidor
```bash
npm run dev
# Los logs aparecerán en la consola
```

---

## 🔑 CREAR NUEVOS USUARIOS / CREATE NEW USERS

### Opción 1: Desde la API (después de hacer login)

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{
    "email": "nuevo@ejemplo.com",
    "nombre_completo": "Juan Pérez",
    "password": "Password123",
    "rol": "vendedor",
    "posicion": "vendedor"
  }'
```

### Opción 2: Desde Prisma Studio

```bash
npx prisma studio
```

1. Abre http://localhost:5555
2. Selecciona tabla "Usuario"
3. Click "Add record"
4. Llena los campos (asegúrate de hashear la contraseña con bcrypt)

---

## 🌐 ACCESO DESDE LA APP FLUTTER / FLUTTER APP ACCESS

### 1. Asegúrate de que el backend esté corriendo
```bash
cd fulltech_api
npm run dev
```

### 2. Configura la URL del backend en la app Flutter

Edita `fulltech_app/lib/core/services/api_client.dart` y verifica que la URL base sea correcta:

```dart
final baseUrl = 'http://localhost:3000'; // Para desarrollo local
// o
final baseUrl = 'https://tu-dominio.com'; // Para producción
```

### 3. Inicia la app Flutter
```bash
cd fulltech_app
flutter run -d windows
# o
flutter run -d chrome
```

### 4. Usa las credenciales
```
Email: admin@fulltech.com
Contraseña: Admin1234
```

---

## 🔐 SEGURIDAD / SECURITY

### Cambiar las credenciales por defecto en producción

**¡IMPORTANTE!** Las credenciales por defecto son:
- Email: admin@fulltech.com
- Password: Admin1234

**Para producción, debes cambiarlas:**

1. Edita el archivo `.env`:
```env
ADMIN_EMAIL=tu_email@empresa.com
ADMIN_PASSWORD=TuContraseñaSegura123!
ADMIN_NAME=Tu Nombre
```

2. Reinicia el servidor:
```bash
npm run bootstrap-admin
npm run dev
```

---

## 📞 AYUDA ADICIONAL / ADDITIONAL HELP

Si sigues teniendo problemas:

1. **Verifica los logs del servidor:** Cuando ejecutas `npm run dev`, revisa los mensajes de error.

2. **Verifica la base de datos:** 
```bash
npx prisma studio
```

3. **Reinicia todo:**
```bash
# Mata procesos
pkill -f "node"

# Reinicia PostgreSQL
sudo service postgresql restart

# Inicia de nuevo
cd fulltech_api
npm run dev
```

4. **Regenera el cliente Prisma:**
```bash
cd fulltech_api
npx prisma generate
npm run build
```

---

## 📊 VERIFICACIÓN COMPLETA / COMPLETE VERIFICATION

Ejecuta estos comandos uno por uno para verificar que todo esté funcionando:

```bash
# 1. Verifica la base de datos
cd fulltech_api
npx prisma db pull

# 2. Verifica/crea el admin
npm run bootstrap-admin

# 3. Verifica el usuario
npm run verify-user -- admin@fulltech.com

# 4. Inicia el servidor
npm run dev
```

En otra terminal:
```bash
# 5. Prueba el login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@fulltech.com","password":"Admin1234"}'
```

Si ves un token JWT en la respuesta, ¡todo está funcionando! ✅

---

## 🎯 RESUMEN / SUMMARY

**Credenciales por defecto:**
- **Email:** admin@fulltech.com
- **Contraseña:** Admin1234

**Comandos más importantes:**
```bash
npm run bootstrap-admin      # Crear/actualizar admin
npm run verify-user -- admin@fulltech.com  # Verificar usuario
npm run reset-password -- admin@fulltech.com NewPass  # Cambiar contraseña
npm run dev                  # Iniciar servidor
```

**URL de login en producción:**
```
POST /api/auth/login
Body: {"email":"admin@fulltech.com","password":"Admin1234"}
```

---

✅ **¡Listo! Ahora deberías poder iniciar sesión sin problemas.**

# 📚 Guía de Desarrollo - FULLTECHAPPPROYECTO

## 🎯 Propósito de esta Guía

Esta guía te explica **cómo hacer cambios en el proyecto, cómo aplicarlos, y cómo subirlos/bajarlos** del repositorio usando Git.

---

## 📋 Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Flujo de Trabajo con Git](#flujo-de-trabajo-con-git)
4. [Hacer Cambios en el Backend](#hacer-cambios-en-el-backend)
5. [Hacer Cambios en el Frontend](#hacer-cambios-en-el-frontend)
6. [Pruebas y Validación](#pruebas-y-validación)
7. [Comandos Útiles](#comandos-útiles)
8. [Solución de Problemas](#solución-de-problemas)

---

## 🔧 Prerrequisitos

### Software Necesario

**Para el Backend (`fulltech_api`):**
- Node.js 18 o superior (versión recomendada: 18.x LTS o 20.x LTS) ([Descargar](https://nodejs.org/))
- PostgreSQL 12 o superior ([Descargar](https://www.postgresql.org/download/))
- Git ([Descargar](https://git-scm.com/downloads))

**Para el Frontend (`fulltech_app`):**
- Flutter SDK 3.10.1 o superior (ver versión exacta en `pubspec.yaml`) ([Instalar](https://docs.flutter.dev/get-started/install))
- Editor de código (VS Code, Android Studio, etc.)

---

## ⚙️ Configuración Inicial

### 1. Clonar el Proyecto (Primera Vez)

Abre una terminal y ejecuta:

```bash
# Clonar el repositorio (reemplaza con la URL de tu proyecto)
git clone https://github.com/JUNIORPRUEVA/FULLTECHAPPPROYECTO.git

# Entrar al directorio del proyecto
cd FULLTECHAPPPROYECTO
```

### 2. Configurar el Backend

```bash
# Ir a la carpeta del backend
cd fulltech_api

# Instalar dependencias de Node.js
npm install

# Crear archivo de configuración .env (copia de ejemplo)
# Edita este archivo con tus credenciales de base de datos
cp .env.example .env

# Generar el cliente de Prisma
npm run prisma:generate

# Ejecutar migraciones de base de datos
npm run prisma:migrate

# Iniciar el servidor en modo desarrollo
npm run dev
```

**Configuración del archivo `.env`:**
```env
DATABASE_URL="postgresql://your_username:your_password@localhost:5432/your_database_name"
JWT_SECRET="your_secret_key_here_at_least_32_characters_long"
PORT=3000
```

### 3. Configurar el Frontend

```bash
# Desde la raíz del proyecto, ir a la carpeta del frontend
cd fulltech_app

# Instalar dependencias de Flutter
flutter pub get

# Verificar que Flutter está correctamente instalado
flutter doctor

# Ejecutar la aplicación (ejemplo: Windows)
flutter run -d windows
```

---

## 🔄 Flujo de Trabajo con Git

### Conceptos Básicos

Git es un sistema de control de versiones que te permite:
- **Bajar cambios** que otros hicieron (pull)
- **Subir tus cambios** para compartirlos (push)
- **Crear versiones** de tu código (commits)
- **Trabajar en paralelo** sin afectar a otros (branches)

### Workflow Diario

#### 1. Antes de Empezar a Trabajar (Bajar Cambios)

```bash
# Asegurarte de estar en la rama principal
git checkout main

# Bajar los últimos cambios del repositorio
git pull origin main
```

**¿Qué hace esto?**
- `git checkout main`: Cambia a la rama principal del proyecto
- `git pull origin main`: Descarga y fusiona los cambios que otros subieron

#### 2. Crear una Nueva Rama para tu Trabajo

```bash
# Crear y cambiar a una nueva rama
git checkout -b feature/mi-nuevo-cambio

# Verificar en qué rama estás
git branch
```

**¿Por qué crear una rama?**
- Puedes trabajar sin afectar el código principal
- Facilita la revisión de código
- Permite trabajar en múltiples características al mismo tiempo

**Convenciones de nombres de ramas:**
- `feature/nombre`: Para nuevas funcionalidades
- `fix/nombre`: Para correcciones de errores
- `docs/nombre`: Para cambios en documentación

#### 3. Hacer tus Cambios

Edita los archivos que necesites usando tu editor de código favorito.

#### 4. Ver qué Archivos Cambiaste

```bash
# Ver estado de archivos modificados
git status

# Ver los cambios específicos en cada archivo
git diff
```

#### 5. Guardar tus Cambios (Commit)

```bash
# Agregar todos los archivos modificados
git add .

# O agregar archivos específicos
git add ruta/al/archivo.ts

# Crear un commit con un mensaje descriptivo
git commit -m "Descripción clara de lo que hiciste"
```

**Ejemplos de buenos mensajes de commit:**
```bash
git commit -m "Agregar validación de email en formulario de registro"
git commit -m "Corregir error 401 en autenticación de usuarios"
git commit -m "Actualizar documentación del módulo CRM"
```

#### 6. Subir tus Cambios al Repositorio

```bash
# Subir tu rama al repositorio remoto
git push origin feature/mi-nuevo-cambio
```

**¿Qué hace esto?**
- Sube tu código a GitHub
- Otros pueden ver tus cambios
- Permite crear un Pull Request para revisión

#### 7. Crear un Pull Request (PR)

1. Ve a GitHub (al repositorio del proyecto)
2. Verás un botón "Compare & pull request"
3. Escribe una descripción de tus cambios
4. Solicita revisión de código
5. Una vez aprobado, fusiona tu rama con `main`

#### 8. Actualizar tu Rama Local después del Merge

```bash
# Volver a la rama principal
git checkout main

# Bajar los últimos cambios (incluyendo tu PR fusionado)
git pull origin main

# Eliminar tu rama local (ya no la necesitas)
git branch -d feature/mi-nuevo-cambio
```

---

## 💻 Hacer Cambios en el Backend

### Estructura del Backend

```
fulltech_api/
├── src/
│   ├── modules/        # Módulos de funcionalidad (CRM, ventas, etc.)
│   ├── core/          # Configuración y utilidades
│   └── index.ts       # Punto de entrada
├── prisma/            # Esquemas de base de datos
├── sql/              # Migraciones SQL
└── package.json      # Dependencias
```

### Ejemplo: Agregar un Nuevo Endpoint

**1. Crear el controlador** (`src/modules/miModulo/mi_modulo.controller.ts`):

```typescript
import { Request, Response } from 'express';

export const miNuevaFuncion = async (req: Request, res: Response) => {
  try {
    // Tu lógica aquí
    const resultado = { mensaje: 'Éxito' };
    res.json(resultado);
  } catch (error) {
    res.status(500).json({ error: 'Error al procesar' });
  }
};
```

**2. Registrar la ruta** (`src/modules/miModulo/mi_modulo.routes.ts`):

```typescript
import { Router } from 'express';
import { miNuevaFuncion } from './mi_modulo.controller';

const router = Router();
router.post('/mi-endpoint', miNuevaFuncion);

export default router;
```

**3. Probar el cambio:**

```bash
# Iniciar servidor en modo desarrollo (con auto-reload)
npm run dev

# El servidor se reiniciará automáticamente cuando guardes cambios
```

**4. Probar con curl o Postman:**

```bash
curl -X POST http://localhost:3000/api/mi-endpoint \
  -H "Content-Type: application/json" \
  -d '{"datos": "ejemplo"}'
```

### Agregar Migraciones de Base de Datos

```bash
# Formato del nombre: YYYY-MM-DD_descripcion.sql
# Usa la fecha actual cuando crees la migración
cd fulltech_api/sql
touch $(date +%Y-%m-%d)_agregar_campo_usuario.sql
```

**Ejemplo de migración:**

```sql
-- sql/YYYY-MM-DD_agregar_campo_usuario.sql
-- Reemplaza YYYY-MM-DD con la fecha actual
ALTER TABLE users ADD COLUMN telefono text;
CREATE INDEX idx_users_telefono ON users(telefono);
```

**⚠️ IMPORTANTE:** Nunca edites archivos de migración ya aplicados. Siempre crea un nuevo archivo.

### Compilar para Producción

```bash
# Compilar TypeScript a JavaScript
npm run build

# Los archivos compilados estarán en la carpeta dist/
```

---

## 📱 Hacer Cambios en el Frontend

### Estructura del Frontend

```
fulltech_app/
├── lib/
│   ├── features/        # Módulos por funcionalidad
│   │   ├── auth/       # Autenticación
│   │   ├── crm/        # CRM
│   │   └── ventas/     # Ventas
│   ├── core/           # Servicios y utilidades
│   └── main.dart       # Punto de entrada
└── pubspec.yaml        # Dependencias
```

### Ejemplo: Agregar una Nueva Pantalla

**1. Crear el archivo de la pantalla** (`lib/features/mi_modulo/mi_pantalla.dart`):

```dart
import 'package:flutter/material.dart';

class MiPantalla extends StatelessWidget {
  const MiPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Nueva Pantalla'),
      ),
      body: Center(
        child: Text('Contenido de la pantalla'),
      ),
    );
  }
}
```

**2. Agregar la ruta** (si usas go_router):

```dart
// En tu configuración de rutas
GoRoute(
  path: '/mi-pantalla',
  builder: (context, state) => const MiPantalla(),
)
```

**3. Probar el cambio:**

```bash
# Ejecutar en modo debug con hot reload
flutter run -d windows

# Presiona 'r' en la terminal para hot reload
# Presiona 'R' para hot restart
```

### Agregar una Nueva Dependencia

```bash
# Agregar paquete de pub.dev
flutter pub add nombre_paquete

# Actualizar dependencias
flutter pub get
```

### Generar Código (si usas build_runner)

```bash
# Para modelos con freezed o json_serializable
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🧪 Pruebas y Validación

### Backend

```bash
cd fulltech_api

# Verificar errores de TypeScript
npm run build

# Si tienes tests configurados
npm test
```

### Frontend

```bash
cd fulltech_app

# Analizar código Dart
flutter analyze

# Ejecutar tests
flutter test

# Compilar para verificar que no hay errores
flutter build windows --debug
```

---

## 📝 Comandos Útiles

### Git - Comandos Comunes

```bash
# Ver historial de commits
git log --oneline

# Ver cambios sin confirmar
git status
git diff

# Descartar cambios en un archivo
git checkout -- ruta/al/archivo

# Descartar todos los cambios sin confirmar
git reset --hard

# Crear una nueva rama
git checkout -b nueva-rama

# Cambiar de rama
git checkout nombre-rama

# Ver todas las ramas
git branch -a

# Bajar cambios de una rama específica
git pull origin nombre-rama

# Subir cambios de tu rama
git push origin nombre-rama
```

### Backend - Comandos Frecuentes

```bash
# Desarrollo
npm run dev              # Iniciar servidor con auto-reload
npm run build            # Compilar TypeScript
npm start                # Ejecutar servidor en producción

# Base de datos
npm run prisma:generate  # Generar cliente Prisma
npm run prisma:migrate   # Ejecutar migraciones
npm run prisma:studio    # Abrir interfaz visual de BD

# Scripts útiles
npm run reset-password   # Resetear contraseña de usuario
```

### Frontend - Comandos Frecuentes

```bash
# Desarrollo
flutter run -d windows        # Ejecutar en Windows
flutter run -d chrome         # Ejecutar en navegador
flutter run --release         # Ejecutar en modo release

# Verificación
flutter doctor               # Verificar instalación
flutter analyze              # Analizar código
flutter test                 # Ejecutar tests

# Construcción
flutter build windows        # Compilar para Windows
flutter build apk           # Compilar para Android
flutter build ios           # Compilar para iOS

# Mantenimiento
flutter pub get             # Instalar dependencias
flutter pub upgrade         # Actualizar dependencias
flutter clean               # Limpiar caché
```

---

## 🔧 Solución de Problemas

### Problema: "No puedo hacer push"

**Error:** `! [rejected] main -> main (fetch first)`

**Solución:**
```bash
# Alguien subió cambios antes que tú
# Primero baja los cambios
git pull origin main

# Resuelve conflictos si los hay (Git te indicará qué archivos)
# Luego intenta subir de nuevo
git push origin main
```

### Problema: "Conflictos al hacer pull"

**Qué significa:** Tú y otra persona modificaron las mismas líneas de código.

**Solución:**
```bash
# Git marcará los archivos con conflictos
# Abre cada archivo y verás marcadores como:
# <<<<<<< HEAD
# Tu código
# =======
# Código del otro
# >>>>>>> origin/main

# Edita manualmente para quedarte con la versión correcta
# Elimina los marcadores (<<<, ===, >>>)

# Luego:
git add archivo_resuelto.ts
git commit -m "Resolver conflicto de merge"
```

### Problema: Backend no inicia

**Posibles causas:**

1. **Puerto ocupado:**
   ```bash
   # Windows: Matar proceso en puerto 3000
   netstat -ano | findstr :3000
   taskkill /PID <numero_pid> /F
   
   # Linux/Mac:
   lsof -ti:3000 | xargs kill -9
   ```

2. **Dependencias faltantes:**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Base de datos no conecta:**
   - Verifica que PostgreSQL esté corriendo
   - Revisa credenciales en `.env`
   - Prueba conexión: `psql -U usuario -d nombre_db`

### Problema: Flutter no compila

**Posibles soluciones:**

```bash
# Limpiar caché y reinstalar dependencias
flutter clean
flutter pub get

# Si persiste, borrar carpetas generadas
rm -rf .dart_tool/
rm -rf build/
flutter pub get
```

### Problema: "No encuentro mi rama"

```bash
# Listar todas las ramas (locales y remotas)
git branch -a

# Descargar todas las ramas remotas
git fetch --all

# Cambiar a una rama remota
git checkout nombre-rama
```

---

## 📚 Documentación Adicional

### Documentos en Español

- **[SOLUCION_PROBLEMA_SESSION_ES.md](SOLUCION_PROBLEMA_SESSION_ES.md)** - Solución de problemas de sesión
- **[GUIA_PRUEBAS_CRM_ENVIO.md](GUIA_PRUEBAS_CRM_ENVIO.md)** - Guía de pruebas del CRM
- **[RESUMEN_FINAL_CRM.md](RESUMEN_FINAL_CRM.md)** - Resumen del módulo CRM
- **[INICIO_RAPIDO_USUARIOS.md](INICIO_RAPIDO_USUARIOS.md)** - Inicio rápido para usuarios

### Documentos en Inglés

- **[README.md](README.md)** - Vista general del proyecto
- **[QUICK_START.md](QUICK_START.md)** - Inicio rápido técnico
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Guía de pruebas
- **Backend**: [fulltech_api/README.md](fulltech_api/README.md)
- **Deploy**: [fulltech_api/README_EASYPANEL.md](fulltech_api/README_EASYPANEL.md)

---

## 🎓 Mejores Prácticas

### Al Hacer Commits

✅ **Hacer:**
- Commits pequeños y frecuentes
- Mensajes descriptivos en español
- Un commit por cambio lógico

❌ **Evitar:**
- Commits con muchos archivos no relacionados
- Mensajes vagos ("fix", "cambios", "wip")
- Subir archivos de configuración personal (.env, .vscode)

### Al Crear Ramas

✅ **Hacer:**
- Nombres descriptivos: `feature/agregar-login`
- Partir de `main` actualizado
- Una rama por funcionalidad

❌ **Evitar:**
- Nombres genéricos: `rama1`, `test`, `fix`
- Ramas con múltiples funcionalidades
- Trabajar directamente en `main`

### Al Hacer Pull Requests

✅ **Incluir:**
- Descripción clara del cambio
- Capturas de pantalla si hay cambios visuales
- Lista de archivos importantes modificados
- Instrucciones de prueba

❌ **Evitar:**
- PRs muy grandes (más de 10 archivos)
- Cambios no relacionados en el mismo PR
- Mezclar refactoring con nuevas funcionalidades

---

## 📞 Ayuda y Soporte

### ¿Tienes Dudas?

1. **Revisa esta documentación primero**
2. **Busca en el historial de commits:** `git log --all --grep="palabra_clave"`
3. **Pregunta al equipo**

### Recursos Útiles

- **Git:** https://git-scm.com/book/es/v2
- **Node.js:** https://nodejs.org/docs/
- **TypeScript:** https://www.typescriptlang.org/docs/
- **Flutter:** https://docs.flutter.dev/
- **PostgreSQL:** https://www.postgresql.org/docs/

---

## 📋 Resumen: Workflow Completo

### Empezar a Trabajar

```bash
# 1. Bajar últimos cambios
git checkout main
git pull origin main

# 2. Crear tu rama
git checkout -b feature/mi-cambio

# 3. Hacer cambios en archivos...
```

### Subir tus Cambios

```bash
# 4. Ver qué cambiaste
git status
git diff

# 5. Agregar archivos
git add .

# 6. Crear commit
git commit -m "Descripción de tu cambio"

# 7. Subir al repositorio
git push origin feature/mi-cambio

# 8. Crear Pull Request en GitHub
```

### Después del Merge

```bash
# 9. Volver a main y actualizar
git checkout main
git pull origin main

# 10. Eliminar rama local
git branch -d feature/mi-cambio
```

---

**Versión:** 1.0  
**Mantenedor:** Equipo FULLTECHAPPPROYECTO

---

## ✅ Checklist de Desarrollo

Antes de crear tu Pull Request, verifica:

- [ ] El código compila sin errores
- [ ] Probaste localmente los cambios
- [ ] Agregaste migraciones si modificaste la BD
- [ ] Actualizaste documentación si es necesario
- [ ] Los commits tienen mensajes descriptivos
- [ ] No subes archivos de configuración personal (.env, etc.)
- [ ] La rama está actualizada con `main`

# MÓDULO DE USUARIOS - FULLTECH CRM

## 📋 DESCRIPCIÓN GENERAL

Módulo completo y funcional para gestión de usuarios con:
- ✅ CRUD de usuarios con todos los campos especificados
- ✅ Subida de documentos (foto, cédula, carta de trabajo)
- ✅ Integración con IA para extraer datos de cédulas dominicanas
- ✅ Generación de PDFs (ficha de empleado y contrato laboral)
- ✅ Gestión de roles y permisos
- ✅ UI responsiva (desktop y móvil)
- ✅ Paginación y filtros avanzados

---

## 🏗️ ESTRUCTURA DEL CÓDIGO

### Backend (Node.js/TypeScript)

```
fulltech_api/
├── src/
│   ├── services/
│   │   └── aiIdentityService.ts          # Servicio de IA para cédulas
│   └── modules/
│       └── usuarios/
│           ├── usuarios.schema.ts        # Zod schemas + tipos
│           ├── usuarios.controller.ts    # Controlador CRUD
│           ├── uploads.controller.ts     # Manejo de archivos
│           ├── pdf.controller.ts         # Generación de PDFs
│           └── usuarios.routes.ts        # Rutas/endpoints
├── prisma/
│   └── schema.prisma                     # Modelos (Usuario, CompanySettings)
└── uploads/
    └── users/                            # Carpeta para documentos subidos
```

### Frontend (Flutter/Dart)

```
fulltech_app/
├── lib/
│   └── features/
│       └── usuarios/
│           ├── data/
│           │   ├── datasources/
│           │   │   └── usuarios_remote_datasource.dart
│           │   └── repositories/
│           │       └── usuarios_repository.dart
│           ├── models/
│           │   └── usuario_model.dart
│           ├── state/
│           │   └── usuarios_controller.dart         # Riverpod
│           ├── presentation/
│           │   ├── pages/
│           │   │   ├── users_list_page.dart
│           │   │   ├── user_form_page.dart
│           │   │   └── user_detail_page.dart
│           │   └── widgets/
│           ├── usuarios_menu.dart                   # Integración
│           └── usuario_item_model.dart
```

---

## 🚀 INSTALACIÓN Y CONFIGURACIÓN

### 1️⃣ BACKEND

#### Dependencias adicionales

```bash
cd fulltech_api
npm install multer puppeteer axios bcrypt uuid
```

#### Variables de entorno (.env)

```env
# Existentes
DATABASE_URL=postgres://user:pass@host:5432/fulltechapp_sistem
JWT_SECRET=dev_secret_change_me
NODE_ENV=development
PORT=3000

# API KEY para IA (ya debe existir)
APIKEY_CHATGPT=sk-proj-...

# Opcional (si usas otro proveedor de IA)
AI_API_URL=https://api.openai.com/v1/vision/analyze
```

#### Aplicar migraciones Prisma

```bash
# Ver cambios pendientes
npx prisma migrate diff --from-empty --to-schema-datamodel --script

# Aplicar migraciones
npx prisma migrate dev --name add_usuarios_module

# Ver datos en UI
npx prisma studio
```

#### Iniciar servidor

```bash
npm run dev
# o
npm start
```

El servidor estará en `http://localhost:3000`

---

### 2️⃣ FRONTEND

#### Dependencias adicionales

```bash
cd fulltech_app
flutter pub add image_picker intl flutter_riverpod dio json_annotation
flutter pub add --dev json_serializable build_runner
```

#### Generar modelos JSON

```bash
cd fulltech_app
dart run build_runner build
```

#### Actualizar pubspec.yaml

Asegúrate de que tienes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  flutter_riverpod: ^2.0.0
  intl: ^0.19.0
  image_picker: ^1.0.0
  json_annotation: ^4.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
```

#### Ejecutar la app

```bash
flutter pub get
flutter run -d windows  # o el dispositivo que uses
```

---

## 🔌 INTEGRACIÓN EN MAIN.APP

En tu `main.dart` o archivo de rutas, agrega el módulo de usuarios:

```dart
import 'features/usuarios/usuarios_menu.dart';

// En tu navegación lateral (Sidebar)
final menuItems = [
  // ... otros items
  UsuariosMenuItems.getMenuItem(),
  // ...
];

// En tu router o MaterialApp
routes: {
  '/usuarios': (context) => const UsersListPage(),
  // ...
}
```

Si usas GoRouter:

```dart
GoRoute(
  path: '/usuarios',
  builder: (context, state) => const UsersListPage(),
),
```

---

## 📡 ENDPOINTS API

### Usuarios CRUD

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users` | Listar usuarios (con paginación y filtros) |
| GET | `/api/users/:id` | Obtener usuario completo |
| POST | `/api/users` | Crear nuevo usuario |
| PUT | `/api/users/:id` | Actualizar usuario |
| PATCH | `/api/users/:id/block` | Bloquear |
| PATCH | `/api/users/:id/unblock` | Desbloquear |
| DELETE | `/api/users/:id` | Eliminar (soft delete) |

### IA y Documentos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/users/ia/extraer-desde-cedula` | Extraer datos (placeholder) |
| POST | `/api/uploads/users` | Subir documentos |

### PDFs

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users/:id/profile-pdf` | PDF ficha de empleado |
| GET | `/api/users/:id/contract-pdf` | PDF contrato laboral |

---

## 🤖 INTEGRACIÓN CON IA

### Flujo de funcionamiento

1. **Usuario sube foto de cédula** → `UserFormPage` → `ImagePicker`
2. **Frontend llama** → `POST /api/users/ia/extraer-desde-cedula` (placeholder)
3. **Backend procesa**:
   - Convierte imagen a Base64 si es necesario
   - Envía a OpenAI (GPT-4 Vision)
   - Usa prompt especializado para cédulas dominicanas
   - Extrae: fecha_nacimiento, lugar_nacimiento, cedula_numero, nombre_completo
4. **Backend devuelve** datos extraídos en JSON
5. **Frontend prellena** automáticamente los campos del formulario

### API Key

- **Proveedor**: (pendiente de integrar)
- **Variable**: `APIKEY_CHATGPT` en `.env`
- **Estado**: Endpoint existe como placeholder; la integración OCR/IA real queda para fase posterior.

### Personalización

Para integrar un proveedor de IA/OCR en el futuro, crea un servicio dedicado y conéctalo en el controller.

```typescript
// Cambiar URL
this.apiUrl = process.env.AI_API_URL || 'https://mi-proveedor.com/vision';

// Cambiar método de envío (adaptar a tu proveedor)
const response = await axios.post(this.apiUrl, {
  // Tu formato específico
});
```

---

## 📊 MODELO DE DATOS

### Tabla: Usuario

```sql
CREATE TABLE "Usuario" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id UUID NOT NULL REFERENCES "Empresa"(id),
  email TEXT UNIQUE NOT NULL,
  nombre_completo TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL, -- vendedor, tecnico_fijo, contratista, administrador, asistente_administrativo
  posicion TEXT,
  
  -- Personales
  fecha_nacimiento DATE,
  edad INT,
  lugar_nacimiento TEXT,
  cedula_numero TEXT NOT NULL,
  
  -- Contacto
  telefono TEXT NOT NULL,
  direccion TEXT NOT NULL,
  ubicacion_mapa TEXT,
  
  -- Familiar/Patrimonial
  tiene_casa_propia BOOLEAN DEFAULT FALSE,
  tiene_vehiculo BOOLEAN DEFAULT FALSE,
  tipo_vehiculo TEXT,
  es_casado BOOLEAN DEFAULT FALSE,
  cantidad_hijos INT DEFAULT 0,
  
  -- Laboral
  ultimo_trabajo TEXT,
  motivo_salida_ultimo_trabajo TEXT,
  fecha_ingreso_empresa DATE NOT NULL,
  salario_mensual DECIMAL(12,2) NOT NULL,
  beneficios TEXT,
  es_tecnico_con_licencia BOOLEAN DEFAULT FALSE,
  numero_licencia TEXT,
  
  -- Documentos
  foto_perfil_url TEXT,
  cedula_foto_url TEXT,
  carta_ultimo_trabajo_url TEXT,
  
  -- Control
  estado TEXT DEFAULT 'activo', -- activo, bloqueado, eliminado
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  FOREIGN KEY (empresa_id) REFERENCES "Empresa"(id)
);
```

### Tabla: CompanySettings

```sql
CREATE TABLE company_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  empresa_id UUID UNIQUE NOT NULL REFERENCES "Empresa"(id),
  nombre_empresa TEXT NOT NULL,
  rnc TEXT NOT NULL,
  telefono TEXT NOT NULL,
  direccion TEXT NOT NULL,
  email TEXT,
  ciudad TEXT,
  pais TEXT,
  otros_detalles TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🎨 UI/UX FEATURES

### Desktop
- Tabla completa con foto, nombre, rol, teléfono, estado, fecha ingreso
- Filtros en fila superior: búsqueda, rol, estado, botón refrescar
- Botones de acción inline: ver, editar, bloquear, eliminar
- Paginación con controles anterior/siguiente

### Móvil
- Cards verticales para cada usuario
- Foto circular, nombre, email, rol en chip
- Menú desplegable con acciones
- Búsqueda optimizada para toque

### Formulario
- Secciones organizadas por tabs/expansiones conceptuales
- Date pickers integrados para fechas
- Autocompletado con IA al capturar cédula
- Vista previa de documentos subidos
- Validaciones en tiempo real

### Detalle
- Header con foto, nombre, rol, estado
- Bloques de información (personales, contacto, familiar, laboral)
- Botones de acción contextuales
- Vista previa de documentos (cédula, carta trabajo)
- Descarga de PDFs

---

## 🔐 ROLES Y PERMISOS

### Roles disponibles

- **administrador**: Acceso total
- **vendedor**: Gestión de clientes y ventas
- **tecnico_fijo**: Mantenimiento en planta
- **contratista**: Trabajos por proyecto
- **asistente_administrativo**: Soporte administrativo

### Control de acceso

```typescript
// En middleware auth (agregar si no existe)
function checkRole(requiredRole: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.user?.rol !== requiredRole && req.user?.rol !== 'administrador') {
      return res.status(403).json({ error: 'No autorizado' });
    }
    next();
  };
}

// Uso en rutas
router.post('/usuarios', checkRole('administrador'), UsuariosController.createUsuario);
```

---

## 📝 EJEMPLO DE FLUJO COMPLETO

### 1. Crear Usuario

**Frontend:**
```dart
// user_form_page.dart
final nuevoUsuario = await ref.read(usuarioFormProvider.notifier)
  .createUsuario({
    'nombre_completo': 'Juan Pérez',
    'email': 'juan@example.com',
    'password': 'securePass123',
    'rol': 'vendedor',
    'fecha_nacimiento': '1990-05-15',
    'cedula_numero': '00112233445',
    'telefono': '+1-809-555-0123',
    'direccion': 'Calle Principal 123',
    'fecha_ingreso_empresa': '2024-01-01',
    'salario_mensual': '25000.00',
  });
```

**Backend:**
```typescript
// POST /api/usuarios
{
  "nombre_completo": "Juan Pérez",
  "email": "juan@example.com",
  "password": "securePass123",
  "rol": "vendedor",
  // ...
}

// Response
{
  "id": "uuid-xxx",
  "nombre_completo": "Juan Pérez",
  "email": "juan@example.com",
  "rol": "vendedor",
  "posicion": "vendedor",
  "edad": 34,
  "estado": "activo",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### 2. Subir Cédula y Extraer con IA

**Frontend:**
```dart
// 1. Capturar foto de cédula
final imagePicker = ImagePicker();
final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);

// 2. Enviar a IA
final datos = await ref.read(usuarioFormProvider.notifier)
  .extractCedulaData(pickedFile.path);

// 3. Preguntar si quiere prerellenar
if (datos['nombre_completo'] != null) {
  _nombreCtrl.text = datos['nombre_completo'];
}
// ... etc
```

**Backend:**
```typescript
// POST /api/usuarios/ia/cedula
{
  "imagenUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}

// Response
{
  "success": true,
  "data": {
    "nombre_completo": "Juan Pérez Martínez",
    "cedula_numero": "00112233445",
    "fecha_nacimiento": "1990-05-15",
    "lugar_nacimiento": "Santo Domingo"
  }
}
```

### 3. Descargar PDF

**Frontend:**
```dart
final pdfBytes = await ref.read(usuarioDetailProvider.notifier)
  .downloadProfilePDF(usuarioId);

// Guardar a archivo o abrir
```

**Backend:**
```
GET /api/usuarios/{id}/profile-pdf
↓
Genera HTML con datos
↓
Convierte a PDF con Puppeteer
↓
Devuelve binary PDF con headers
Content-Type: application/pdf
Content-Disposition: attachment; filename="ficha_xyz.pdf"
```

---

## 🧪 TESTING

### Backend - Crear usuario

```bash
curl -X POST http://localhost:3000/api/usuarios \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "nombre_completo": "Test User",
    "password": "Test123!",
    "rol": "vendedor",
    "fecha_nacimiento": "1990-01-01",
    "cedula_numero": "00112233445",
    "telefono": "8095550123",
    "direccion": "Test Street 123",
    "fecha_ingreso_empresa": "2024-01-01",
    "salario_mensual": 20000
  }'
```

### Backend - Listar usuarios

```bash
curl "http://localhost:3000/api/usuarios?page=1&limit=10&rol=vendedor&search=juan"
```

### Backend - Descargar PDF

```bash
curl "http://localhost:3000/api/usuarios/{id}/profile-pdf" \
  --output ficha_usuario.pdf
```

---

## 🐛 TROUBLESHOOTING

### Error: "EMAIL_ALREADY_EXISTS"
- Verifica que el email no esté ya registrado
- Usa email único en base de datos

### Error: "PASSWORD_HASH_FAILED"
- Asegúrate de tener `bcrypt` instalado
- Regenera el package-lock.json: `npm install`

### Error: "PUPPETEER_LAUNCH_FAILED"
- Instala dependencias del sistema:
  ```bash
  # En Ubuntu/Debian
  sudo apt-get install libxss1 libnss3 libgconf-2-4 libx11-6
  
  # En Windows (sin pasos adicionales)
  ```

### Error: "IMAGE_CONVERT_FAILED"
- Verifica que la imagen sea JPEG/PNG válida
- Tamaño máximo 5MB
- Intenta reconvertir la imagen

### Error: "AI_API_KEY_MISSING"
- Verifica que `APIKEY_CHATGPT` esté en `.env`
- Regenera la API key en OpenAI si es necesario
- Reinicia el servidor después de cambiar `.env`

### El formulario no carga datos al editar
- Asegúrate de que `usuarioDetailProvider` esté inicializando correctamente
- Verifica que el `usuarioId` sea válido (UUID)
- Revisa la consola del navegador (DevTools)

---

## 📚 ARCHIVOS GENERADOS

### Backend
- ✅ `src/services/aiIdentityService.ts` - Servicio de IA
- ✅ `src/modules/usuarios/usuarios.schema.ts` - Validaciones Zod
- ✅ `src/modules/usuarios/usuarios.controller.ts` - Controlador CRUD
- ✅ `src/modules/usuarios/uploads.controller.ts` - Gestor de archivos
- ✅ `src/modules/usuarios/pdf.controller.ts` - Generador de PDFs
- ✅ `src/modules/usuarios/usuarios.routes.ts` - Rutas API

### Frontend
- ✅ `lib/features/usuarios/models/usuario_model.dart` - Modelo
- ✅ `lib/features/usuarios/data/datasources/usuarios_remote_datasource.dart` - Datasource
- ✅ `lib/features/usuarios/data/repositories/usuarios_repository.dart` - Repository
- ✅ `lib/features/usuarios/state/usuarios_controller.dart` - State (Riverpod)
- ✅ `lib/features/usuarios/presentation/pages/users_list_page.dart` - Lista
- ✅ `lib/features/usuarios/presentation/pages/user_form_page.dart` - Formulario
- ✅ `lib/features/usuarios/presentation/pages/user_detail_page.dart` - Detalle
- ✅ `lib/features/usuarios/usuarios_menu.dart` - Integración

---

## 📞 SOPORTE

Para errores o preguntas:

1. Revisa los logs del backend: `npm run dev` mostrará errores
2. Abre DevTools en Flutter: `flutter devtools`
3. Verifica estado de base de datos: `npx prisma studio`
4. Valida API keys en `.env`

---

## ✨ FEATURES OPCIONALES (Futura expansión)

- [ ] Importar usuarios desde CSV
- [ ] Búsqueda fulltext en nombre/email/cédula
- [ ] Historial de cambios (audit log)
- [ ] Notificaciones por email
- [ ] Integración con WhatsApp para credenciales
- [ ] Dashboard de estadísticas RRHH
- [ ] Generación de nómina
- [ ] Cálculo automático de impuestos

---

**Generado**: 2024 | **Proyecto**: Fulltech CRM & Operaciones | **Versión**: 1.0.0

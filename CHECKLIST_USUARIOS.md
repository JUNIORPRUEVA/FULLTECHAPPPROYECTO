# ✅ CHECKLIST - MÓDULO DE USUARIOS FULLTECH

## 📌 TAREAS PREVIAS A EJECUTAR

### 1. Instalar dependencias backend

- [ ] `npm install multer`
- [ ] `npm install puppeteer`
- [ ] `npm install axios`
- [ ] `npm install bcrypt`
- [ ] `npm install uuid`
- [ ] Ejecutar: `npm install` (actualizar package-lock.json)

### 2. Instalar dependencias frontend

- [ ] `flutter pub add image_picker`
- [ ] `flutter pub add intl`
- [ ] `flutter pub add flutter_riverpod`
- [ ] `flutter pub add dio`
- [ ] `flutter pub add json_annotation`
- [ ] `flutter pub add --dev json_serializable`
- [ ] `flutter pub add --dev build_runner`

### 3. Configurar variables de entorno

**fulltech_api/.env**
- [ ] Verificar `APIKEY_CHATGPT` (debe existir de fase anterior)
- [ ] Verificar `DATABASE_URL` apunta a `fulltechapp_sistem`
- [ ] Opcional: Agregar `AI_API_URL` si usas otro proveedor

### 4. Crear estructura de carpetas backend

```bash
# Ejecutar en fulltech_api/
mkdir -p src/services
mkdir -p src/modules/usuarios
mkdir -p uploads/users
```

### 5. Crear estructura de carpetas frontend

```bash
# Ejecutar en fulltech_app/
mkdir -p lib/features/usuarios/{data/{datasources,repositories},models,state,presentation/{pages,widgets}}
```

---

## 🔧 IMPLEMENTACIÓN BACKEND

### Paso 1: Servicio de IA

- [ ] Crear archivo: `src/services/aiIdentityService.ts`
- [ ] Copiar código completo del archivo proporcionado
- [ ] Verificar importaciones (axios, types)
- [ ] Verificar método `calculateAge()` (funciona)

### Paso 2: Esquemas y validaciones

- [ ] Crear archivo: `src/modules/usuarios/usuarios.schema.ts`
- [ ] Copiar esquemas Zod
- [ ] Exportar tipos TypeScript
- [ ] Verificar enums de roles

### Paso 3: Controlador CRUD

- [ ] Crear archivo: `src/modules/usuarios/usuarios.controller.ts`
- [ ] Copiar controlador completo
- [ ] Verificar importaciones (Prisma, bcrypt, schemas)
- [ ] Verificar métodos CRUD (list, get, create, update, block, delete)
- [ ] Verificar método de IA: `extractCedulaData()`

### Paso 4: Controlador de uploads

- [ ] Crear archivo: `src/modules/usuarios/uploads.controller.ts`
- [ ] Copiar controlador de uploads
- [ ] Verificar configuración de multer
- [ ] Verificar ruta de destino: `uploads/users/`

### Paso 5: Controlador de PDFs

- [ ] Crear archivo: `src/modules/usuarios/pdf.controller.ts`
- [ ] Copiar controlador de PDFs
- [ ] Verificar métodos:
  - [ ] `generateProfilePDF()` - ficha de empleado
  - [ ] `generateContractPDF()` - contrato laboral
- [ ] Verificar uso de puppeteer

### Paso 6: Rutas API

- [ ] Crear archivo: `src/modules/usuarios/usuarios.routes.ts`
- [ ] Copiar rutas
- [ ] Verificar endpoints:
  - [ ] GET `/api/usuarios`
  - [ ] GET `/api/usuarios/:id`
  - [ ] GET `/api/users`
  - [ ] GET `/api/users/:id`
  - [ ] POST `/api/users`
  - [ ] PUT `/api/users/:id`
  - [ ] PATCH `/api/users/:id/block`
  - [ ] PATCH `/api/users/:id/unblock`
  - [ ] DELETE `/api/users/:id`
  - [ ] POST `/api/users/ia/extraer-desde-cedula`
  - [ ] GET `/api/users/:id/profile-pdf`
  - [ ] GET `/api/users/:id/contract-pdf`
### Paso 7: Registrar rutas en Express

- [ ] Abrir `src/main.ts` o `src/app.ts` (entrada principal)
- [ ] Agregar importación: `import usuariosRouter from './modules/usuarios/usuarios.routes'`
- [ ] Agregar: `app.use('/api', usuariosRouter)`
- [ ] Servir carpeta uploads como estática:
  ```typescript
  app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
  ```

### Paso 8: Aplicar migraciones Prisma

```bash
cd fulltech_api

# Verificar cambios
npx prisma migrate status

# Aplicar migración
npx prisma migrate dev --name add_usuarios_module

# Verificar datos (opcional)
npx prisma studio
```

- [ ] Migraciones aplicadas exitosamente
- [ ] Tablas `Usuario` y `CompanySettings` creadas

### Paso 9: Probar backend

```bash
# Iniciar servidor
npm run dev

# En otra terminal, probar endpoints
curl http://localhost:3000/api/users
```

- [ ] Servidor inicia sin errores
- [ ] Endpoint `/api/users` responde (aunque esté vacío)
- [ ] Logs muestran conexión a BD exitosa

---

## 🎨 IMPLEMENTACIÓN FRONTEND

### Paso 1: Modelo de datos

- [ ] Crear archivo: `lib/features/usuarios/models/usuario_model.dart`
- [ ] Copiar modelo completo
- [ ] Verificar campos (todos los especificados)
- [ ] Generar archivo .g.dart:
  ```bash
  cd fulltech_app
  dart run build_runner build
  ```

### Paso 2: Remote datasource

- [ ] Crear archivo: `lib/features/usuarios/data/datasources/usuarios_remote_datasource.dart`
- [ ] Copiar datasource
- [ ] Cambiar `baseUrl` si tu backend está en otro host
- [ ] Verificar métodos:
  - [ ] `listUsuarios()`
  - [ ] `getUsuario()`
  - [ ] `createUsuario()`
  - [ ] `updateUsuario()`
  - [ ] `blockUsuario()`
  - [ ] `deleteUsuario()`
  - [ ] `uploadUserDocuments()`
  - [ ] `extractCedulaData()`
  - [ ] `downloadProfilePDF()`
  - [ ] `downloadContractPDF()`

### Paso 3: Repository

- [ ] Crear archivo: `lib/features/usuarios/data/repositories/usuarios_repository.dart`
- [ ] Copiar repository
- [ ] Verificar inyección de dependencia

### Paso 4: State management

- [ ] Crear archivo: `lib/features/usuarios/state/usuarios_controller.dart`
- [ ] Copiar controlador Riverpod
- [ ] Verificar providers:
  - [ ] `usuariosRepositoryProvider`
  - [ ] `usuariosListProvider`
  - [ ] `usuarioDetailProvider`
  - [ ] `usuarioFormProvider`
- [ ] Verificar notifiers (lista, detalle, formulario)

### Paso 5: Pantalla de lista

- [ ] Crear archivo: `lib/features/usuarios/presentation/pages/users_list_page.dart`
- [ ] Copiar código
- [ ] Verificar:
  - [ ] Tabla para desktop
  - [ ] Cards para móvil
  - [ ] Filtros (rol, estado, búsqueda)
  - [ ] Paginación
  - [ ] Responsive design

### Paso 6: Pantalla de formulario

- [ ] Crear archivo: `lib/features/usuarios/presentation/pages/user_form_page.dart`
- [ ] Copiar código
- [ ] Verificar secciones:
  - [ ] Datos básicos
  - [ ] Datos personales
  - [ ] Captura de cédula con IA
  - [ ] Contacto y ubicación
  - [ ] Familiar/patrimonial
  - [ ] Laboral
  - [ ] Documentos
  - [ ] Validaciones
- [ ] Verificar date pickers
- [ ] Verificar integración con IA

### Paso 7: Pantalla de detalle

- [ ] Crear archivo: `lib/features/usuarios/presentation/pages/user_detail_page.dart`
- [ ] Copiar código
- [ ] Verificar:
  - [ ] Header con foto
  - [ ] Secciones de datos
  - [ ] Vista previa de documentos
  - [ ] Botones de acción (editar, bloquear, eliminar)
  - [ ] Descargas de PDF
  - [ ] Responsive layout

### Paso 8: Archivo de integración

- [ ] Crear archivo: `lib/features/usuarios/usuarios_menu.dart`
- [ ] Copiar código
- [ ] Definir ruta y widget

### Paso 9: Integrar en main.dart

En tu archivo principal de rutas:

```dart
import 'features/usuarios/presentation/pages/users_list_page.dart';

// En rutas named
routes: {
  '/usuarios': (context) => const UsersListPage(),
  // ...
}

// O si usas GoRouter
GoRoute(
  path: '/usuarios',
  builder: (context, state) => const UsersListPage(),
),
```

- [ ] Ruta agregada a router
- [ ] MenuItem agregada a sidebar/drawer

### Paso 10: Compilar y ejecutar

```bash
cd fulltech_app

# Generar modelos
dart run build_runner build

# Obtener dependencias
flutter pub get

# Ejecutar
flutter run -d windows
```

- [ ] App compila sin errores
- [ ] Pantalla de usuarios es accesible
- [ ] Lista carga correctamente

---

## 🧪 TESTING FUNCIONAL

### Test 1: Crear usuario

```
1. Abrir app → Usuarios
2. Click "Nuevo Usuario"
3. Llenar formulario:
   - Nombre: Juan Pérez
   - Email: juan@test.com
   - Password: Test123!
   - Rol: Vendedor
   - Fecha Nac: 1990-05-15
   - Cédula: 00112233445
   - Teléfono: 8095550123
   - Dirección: Calle Test 123
   - Fecha Ingreso: 2024-01-15
   - Salario: 25000
4. Click "Crear Usuario"
5. ✓ Usuario aparece en lista
```

- [ ] Usuario creado exitosamente
- [ ] Aparece en lista inmediatamente
- [ ] Datos se guardaron correctamente

### Test 2: Capturar cédula con IA

```
1. Abrir formulario nuevo usuario
2. Ir a sección "Datos Personales"
3. Click "Capturar Cédula y Autocompletar"
4. Tomar foto de cédula (o usar imagen)
5. Esperar a que IA procese
6. ✓ Campos se rellenan automáticamente:
   - Nombre
   - Cédula
   - Fecha nacimiento
   - Lugar nacimiento
```

- [ ] IA extrae datos correctamente
- [ ] Campos se prellenan automáticamente
- [ ] No hay errores de API

### Test 3: Subir documentos

```
1. En formulario usuario
2. Sección "Documentos"
3. Click "Foto de Perfil"
4. Seleccionar imagen del dispositivo
5. ✓ Se carga correctamente
6. Repetir para "Carta Último Trabajo"
```

- [ ] Archivos se suben sin error
- [ ] Se muestra confirmación
- [ ] URLs se generan correctamente

### Test 4: Listar y filtrar

```
1. Abrir lista de usuarios
2. Escribir en búsqueda: "juan"
3. ✓ Lista filtra por nombre
4. Cambiar filtro Rol: "Vendedor"
5. ✓ Solo vendedores aparecen
6. Cambiar filtro Estado: "Activo"
7. ✓ Solo activos aparecen
8. Click "Refrescar"
9. ✓ Lista se actualiza
```

- [ ] Búsqueda funciona
- [ ] Filtros funcionan
- [ ] Botón refrescar actualiza datos
- [ ] Paginación funciona (si hay >20 usuarios)

### Test 5: Ver detalle de usuario

```
1. En lista, click icono "ver" de un usuario
2. ✓ Abre página de detalle
3. ✓ Muestra todos los datos
4. ✓ Foto visible (si existe)
5. ✓ Documentos visibles (si existen)
6. Click "Editar"
7. ✓ Abre formulario con datos prellenados
8. Cambiar algo, click "Actualizar"
9. ✓ Cambios se guardan
```

- [ ] Detalle carga correctamente
- [ ] Datos completos visibles
- [ ] Edición funciona
- [ ] Cambios se persisten

### Test 6: Bloquear usuario

```
1. En lista o detalle
2. Click menú (tres puntos)
3. Click "Bloquear"
4. ✓ Estado cambia a "bloqueado"
5. Click "Desbloquear" (si está disponible)
6. ✓ Estado vuelve a "activo"
```

- [ ] Bloqueo funciona
- [ ] Estado se actualiza inmediatamente
- [ ] En lista se refleja el cambio

### Test 7: Descargar PDFs

```
1. En detalle del usuario
2. Click "Descargar PDF Ficha"
3. ✓ Se descarga ficha_usuario.pdf
4. ✓ PDF contiene todos los datos
5. Click "Descargar Contrato"
6. ✓ Se descarga contrato_usuario.pdf
7. ✓ PDF contiene datos de empresa y usuario
```

- [ ] PDFs se descargan sin error
- [ ] PDFs contienen datos correctos
- [ ] Formato es profesional

### Test 8: Responsividad

```
Móvil:
1. Abrir en dispositivo móvil
2. ✓ Usuarios muestran como cards
3. ✓ Filtros son accesibles
4. ✓ Formulario es deslizable
5. ✓ No hay overflow

Desktop:
1. Maximizar ventana
2. ✓ Tabla completa visible
3. ✓ Columnas bien distribuidas
4. ✓ Botones accesibles
```

- [ ] Mobile UI funciona correctamente
- [ ] Desktop UI funciona correctamente
- [ ] Responsividad sin problemas

---

## 🐛 VALIDACIÓN DE ERRORES

### Error: "Connection refused 127.0.0.1:3000"
- [ ] Backend está ejecutándose (`npm run dev`)
- [ ] Puerto 3000 disponible
- [ ] URL en datasource es correcta

### Error: "Email already exists"
- [ ] No duplicar emails
- [ ] Usar emails únicos para testing

### Error: "No such file or directory: uploads/users"
- [ ] Carpeta creada manualmente: `mkdir -p uploads/users`
- [ ] O dejar que Express la cree automáticamente

### Error: "Cannot read property 'data' of undefined"
- [ ] Backend respuesta no coincide con esperado
- [ ] Revisar consola backend (npm run dev) para errores
- [ ] Validar endpoint existe

### Error: "Image format not supported"
- [ ] Usar JPEG/PNG
- [ ] Tamaño <5MB
- [ ] Imagen no corrupta

### Error: "AI API key missing"
- [ ] Verificar `APIKEY_CHATGPT` en `.env`
- [ ] Reiniciar server después de cambiar `.env`
- [ ] API key válida en OpenAI

---

## ✨ CHECKLIST FINAL

### Implementación completada
- [ ] Todos los archivos backend creados
- [ ] Todos los archivos frontend creados
- [ ] Migraciones Prisma aplicadas
- [ ] Dependencias instaladas
- [ ] Variables de entorno configuradas

### Funcionalidad verificada
- [ ] CRUD de usuarios (create, read, update, delete)
- [ ] Filtros y búsqueda
- [ ] Subida de documentos
- [ ] Integración con IA
- [ ] Generación de PDFs
- [ ] Bloqueo/desbloqueo
- [ ] Paginación

### UI/UX completa
- [ ] Pantalla de lista
- [ ] Formulario con validaciones
- [ ] Pantalla de detalle
- [ ] Responsive (desktop y móvil)
- [ ] Integración en sidebar

### Producción lista
- [ ] Sin errores de compilación
- [ ] Sin warnings importantes
- [ ] Todos los tests pasaron
- [ ] Documentación completa
- [ ] API funcionando

---

## 📞 NOTAS

- Tiempo estimado de implementación: **2-3 horas**
- Si algo no funciona: revisa logs (backend en terminal, frontend en DevTools)
- Para debug rápido: abre `npx prisma studio` para ver datos en BD
- PDF generation requiere Chromium (descarga automáticamente con puppeteer)

---

**Estado**: ✅ LISTO PARA IMPLEMENTAR
**Última actualización**: Enero 2024
**Versión**: 1.0.0

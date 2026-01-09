# 📖 Referencia Rápida de Git

## 🔽 Bajar Cambios de Git a tu PC

```bash
# 1. Ir a la rama principal
git checkout main

# 2. Bajar los últimos cambios
git pull origin main
```

**Resultado:** Ahora tienes la última versión del código en tu computadora.

---

## 🔼 Subir Cambios de tu PC a Git

```bash
# 1. Ver qué archivos modificaste
git status

# 2. Agregar los archivos modificados
git add .

# 3. Crear un commit con un mensaje
git commit -m "Descripción de tu cambio"

# 4. Subir los cambios a GitHub
git push origin nombre-de-tu-rama
```

**Resultado:** Tus cambios están ahora en GitHub y otros pueden verlos.

---

## 🔄 Workflow Completo (Paso a Paso)

### Paso 1: Bajar los últimos cambios
```bash
git checkout main
git pull origin main
```

### Paso 2: Crear una rama para tu trabajo
```bash
git checkout -b feature/mi-cambio
```

### Paso 3: Hacer tus cambios
Edita los archivos que necesites...

### Paso 4: Guardar tus cambios localmente
```bash
git add .
git commit -m "Descripción clara del cambio"
```

### Paso 5: Subir tus cambios a GitHub
```bash
git push origin feature/mi-cambio
```

### Paso 6: Crear Pull Request
Ve a GitHub y crea un Pull Request para que revisen tu código.

---

## 💡 Comandos Más Usados

| Comando | Descripción |
|---------|-------------|
| `git status` | Ver qué archivos cambiaron |
| `git pull origin main` | Bajar cambios del repositorio |
| `git add .` | Agregar todos los archivos modificados |
| `git commit -m "mensaje"` | Guardar cambios localmente |
| `git push origin rama` | Subir cambios a GitHub |
| `git checkout main` | Cambiar a rama principal |
| `git checkout -b nueva-rama` | Crear y cambiar a nueva rama |
| `git log --oneline` | Ver historial de commits |

---

## 🆘 Si Algo Sale Mal

### Error: "No puedo hacer push"
```bash
# Primero baja los cambios
git pull origin main

# Luego intenta subir de nuevo
git push origin tu-rama
```

### Descartar cambios en un archivo
```bash
git checkout -- nombre-del-archivo
```

### Ver diferencias antes de commit
```bash
git diff
```

---

## 📚 Documentación Completa

Para más detalles, lee **[GUIA_DESARROLLO.md](GUIA_DESARROLLO.md)** - Guía completa con:
- Configuración inicial del proyecto
- Ejemplos de código backend y frontend
- Solución de problemas
- Mejores prácticas

---

**Tip:** Guarda este archivo como referencia rápida. Para aprender más sobre el flujo de trabajo completo, consulta GUIA_DESARROLLO.md.

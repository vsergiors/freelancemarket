# FreelanceMarket — Guía de instalación

## Archivos incluidos

| Archivo | Descripción |
|---|---|
| `index.html` | Página principal (landing) |
| `login.html` | Login/Registro con Google, Discord, GitHub y email |
| `dashboard.html` | Panel del usuario |
| `create-service.html` | Crear/publicar servicios (4 pasos) |
| `explore.html` | Marketplace con filtros y búsqueda |
| `chat.html` | Mensajería en tiempo real |
| `config.js` | Configuración de Supabase (editar aquí) |
| `schema.sql` | Schema completo de la base de datos |

---

## Configuración en 5 pasos

### 1. Crear proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta gratuita
2. Crea un nuevo proyecto
3. Espera a que se inicialice (~2 minutos)

### 2. Obtener credenciales
En tu proyecto de Supabase ve a:
**Settings → API** y copia:
- `Project URL` → reemplaza `https://TU_PROYECTO.supabase.co`
- `anon public key` → reemplaza `TU_ANON_KEY_AQUI`

Edita el archivo `config.js` con estos valores.

### 3. Crear la base de datos
En Supabase ve a **SQL Editor** y ejecuta el contenido de `schema.sql`.

### 4. Configurar OAuth (opcional pero recomendado)

**Google:**
- Ve a [console.cloud.google.com](https://console.cloud.google.com)
- Crea credenciales OAuth 2.0
- Authorized redirect URI: `https://TU_PROYECTO.supabase.co/auth/v1/callback`
- En Supabase: Authentication → Providers → Google → añade Client ID y Secret

**Discord:**
- Ve a [discord.com/developers](https://discord.com/developers)
- Crea una aplicación → OAuth2
- Redirect URI: `https://TU_PROYECTO.supabase.co/auth/v1/callback`
- En Supabase: Authentication → Providers → Discord

**GitHub:**
- Ve a GitHub → Settings → Developer settings → OAuth Apps
- Authorization callback URL: `https://TU_PROYECTO.supabase.co/auth/v1/callback`
- En Supabase: Authentication → Providers → GitHub

### 5. Habilitar Realtime para el chat
En Supabase ve a:
**Database → Replication** y activa la tabla `messages`.

---

## Despliegue

### Opción A: Netlify (gratuito)
1. Sube la carpeta a GitHub
2. Conecta con Netlify → Deploy

### Opción B: Vercel
1. Instala Vercel CLI: `npm i -g vercel`
2. Desde la carpeta: `vercel`

### Opción C: Servidor propio
Simplemente sube los archivos a cualquier hosting estático (Apache, Nginx).

---

## Funcionalidades incluidas

- ✅ Autenticación con Google, Discord, GitHub y email/contraseña
- ✅ Crear y publicar servicios con paquetes (básico/estándar/premium)
- ✅ Marketplace con búsqueda y filtros por categoría, precio y valoración
- ✅ Chat en tiempo real con Supabase Realtime
- ✅ Panel de usuario con estadísticas
- ✅ Row Level Security (datos protegidos por usuario)
- ✅ Auto-creación de perfil al registrarse

## Próximas funcionalidades (pendientes de implementar)
- [ ] `service.html` — Página de detalle de servicio
- [ ] `orders.html` — Gestión de pedidos
- [ ] `profile.html` — Perfil público de freelancer
- [ ] `my-services.html` — Lista de mis servicios
- [ ] Sistema de pagos (Stripe)
- [ ] Sistema de notificaciones
- [ ] Panel de administración

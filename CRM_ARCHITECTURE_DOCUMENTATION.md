# CRM Architecture Documentation

**Date:** January 10, 2026  
**Purpose:** Research and documentation of current CRM architecture  
**Status:** No code changes made (research only)

---

## 1. Database Schema

### 1.1 `crm_chats` Table

**Location:** `fulltech_api/prisma/schema.prisma` (lines ~1409-1438)  
**Raw SQL:** `fulltech_api/scripts/create_crm_whatsapp_tables.ts` (lines 10-23)

**Columns:**

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | `uuid` | Primary key | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` |
| `empresa_id` | `uuid` | Multi-tenant company ID | `FOREIGN KEY -> empresas(id)`, indexed |
| `wa_id` | `String` | WhatsApp ID (normalized) | `NOT NULL`, unique per empresa |
| `display_name` | `String?` | Contact display name | Optional |
| `phone` | `String?` | E.164 phone number | Optional, indexed |
| `last_message_preview` | `String?` | Preview text of last message | Optional |
| `last_message_at` | `DateTime?` | Timestamp of last message | Indexed (DESC) |
| `unread_count` | `Int` | Number of unread messages | `DEFAULT 0` |
| `status` | `String` | CRM status/stage | `DEFAULT "primer_contacto"` |
| `scheduled_at` | `DateTime?` | Scheduled appointment time | Optional |
| `location_text` | `String?` | Customer location text | Optional |
| `assigned_tech_id` | `uuid?` | Assigned technician | Optional |
| `service_id` | `uuid?` | Related service | Optional |
| `purchased_at` | `DateTime?` | Purchase completion date | Optional |
| `active_client_message_pending` | `Boolean` | Flag for bought client inbox | `DEFAULT false` |
| `post_sale_state` | `CrmPostSaleState` | Post-sale status | Enum, `DEFAULT NORMAL` |
| `created_at` | `DateTime` | Creation timestamp | `DEFAULT now()` |
| `updated_at` | `DateTime` | Last update timestamp | Auto-updated |

**Indexes:**
- `empresa_id_wa_id` (unique composite)
- `last_message_at` (DESC)
- `empresa_id`

**Relationships:**
- → `empresas.id` (empresa_id)
- → `crm_messages` (one-to-many)
- → `operations_jobs` (one-to-many)

---

### 1.2 `crm_messages` Table

**Location:** `fulltech_api/prisma/schema.prisma` (lines ~1439-1461)  
**Raw SQL:** `fulltech_api/scripts/create_crm_whatsapp_tables.ts` (lines 30-46)

**Model Name:** `CrmChatMessage` (Prisma)

**Columns:**

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | `uuid` | Primary key | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` |
| `empresa_id` | `uuid` | Multi-tenant company ID | `FOREIGN KEY -> empresas(id)` |
| `chat_id` | `uuid` | Parent chat | `FOREIGN KEY -> crm_chats(id)`, `ON DELETE CASCADE` |
| `direction` | `String` | Message direction | `in` or `out` |
| `message_type` | `String` | Message type | `text`, `image`, `video`, `audio`, `document`, `sticker`, `location`, `contact` |
| `text` | `String?` | Message text content | Optional |
| `remote_message_id` | `String?` | Evolution API message ID | Optional, unique per empresa |
| `quoted_message_id` | `String?` | ID of quoted message | Optional |
| `status` | `String` | Delivery status | `DEFAULT "received"` (values: `sent`, `delivered`, `read`, `failed`, `received`) |
| `error` | `String?` | Error message if failed | Optional |
| `timestamp` | `DateTime` | Message timestamp | `NOT NULL` |
| `created_at` | `DateTime` | Creation timestamp | `DEFAULT now()` |

**Indexes:**
- `empresa_id_remote_message_id` (unique composite)
- `chat_id, timestamp` (DESC - for pagination)
- `empresa_id`

**Relationships:**
- → `empresas.id` (empresa_id)
- → `crm_chats.id` (chat_id, CASCADE on delete)

---

### 1.3 `crm_webhook_events` Table

**Location:** `fulltech_api/prisma/schema.prisma` (lines 1464-1491)  
**Raw SQL:** `fulltech_api/scripts/create_crm_whatsapp_tables.ts` (lines 54-60)

**Purpose:** Audit trail and debugging for all incoming webhook events from Evolution API

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | `uuid` | Primary key |
| `created_at` | `DateTime` | When webhook was received |
| `headers` | `Json?` | HTTP headers (content-type, user-agent, etc.) |
| `ip_address` | `String?` | Source IP address |
| `user_agent` | `String?` | Client user agent |
| `payload` | `Json` | Full webhook payload |
| `event_type` | `String?` | Parsed event type (`message.new`, `message.status`, etc.) |
| `source` | `String` | Event source (`DEFAULT "evolution"`) |
| `processed` | `Boolean` | Whether event was processed |
| `processed_at` | `DateTime?` | When processing completed |
| `processing_error` | `String?` | Error message if processing failed |
| `raw_body` | `String?` | Raw request body for debugging |

**Indexes:**
- `created_at` (DESC)
- `event_type`
- `processed`

---

### 1.4 Additional CRM Tables (Created via SQL script)

#### `quick_replies`
**Purpose:** Predefined message templates for quick responses

| Column | Type | Description |
|--------|------|-------------|
| `id` | `uuid` | Primary key |
| `title` | `text` | Template title |
| `category` | `text` | Category/group |
| `content` | `text` | Template content |
| `is_active` | `boolean` | Active status |
| `created_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update |

**Indexes:** `category`, `is_active`

#### `crm_chat_meta`
**Purpose:** Extended metadata for chats (CRM management features)

| Column | Type | Description |
|--------|------|-------------|
| `chat_id` | `uuid` | Primary key, FK to crm_chats |
| `important` | `boolean` | Important flag |
| `follow_up` | `boolean` | Follow-up flag |
| `product_id` | `text` | Associated product |
| `internal_note` | `text` | Internal notes |
| `assigned_user_id` | `uuid` | Assigned user |
| `created_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update |

**Indexes:** `product_id`, `important`, `follow_up`

---

## 2. Webhook System

### 2.1 Webhook Endpoint Structure

**Base URL:** `/webhooks/evolution`  
**Router:** `fulltech_api/src/modules/webhooks/webhooks.routes.ts`  
**Controller:** `fulltech_api/src/modules/webhooks/evolution_webhook.controller.ts`

#### Available Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/webhooks/evolution` | Main webhook receiver (Evolution API) |
| `GET` | `/webhooks/evolution/ping` | Health check / connectivity test |
| `POST` | `/webhooks/evolution/test` | Test endpoint with dummy payload |
| `GET` | `/webhooks/evolution` | Legacy endpoint (returns info message) |

#### Webhook Authentication

**Status:** Currently **UNAUTHENTICATED** (public endpoint)  
**Config:** Optional `WEBHOOK_SECRET` or `EVOLUTION_WEBHOOK_SECRET` env var (not currently enforced)  
**Security Note:** Endpoint is protected by obscurity and optional secret validation (if Evolution supports it)

### 2.2 Webhook Flow

```
Evolution API → POST /webhooks/evolution → evolutionWebhook()
  1. Parse incoming event (text/JSON auto-detection)
  2. Log headers, IP, user-agent, body preview
  3. ALWAYS save to crm_webhook_events table (never throw)
  4. Respond 200 immediately (acknowledge receipt)
  5. Process event asynchronously (via setImmediate)
     a. Parse event type (message.new, message.status, unknown)
     b. For message.new:
        - Normalize waId and phone (E.164)
        - Dedupe by remote_message_id
        - Upsert crm_chats
        - Insert crm_messages
        - Emit SSE event (crm_stream)
     c. For message.status:
        - Update crm_messages.status
        - Emit SSE event
     d. Update crm_webhook_events.processed = true
```

### 2.3 Event Parser

**Location:** `fulltech_api/src/services/evolution/evolution_event_parser.ts`

**Function:** `parseEvolutionWebhook(body: any): ParsedEvolutionWebhook`

**Supported Event Types:**
- `message.new` - New incoming/outgoing message
- `message.status` - Message status update (sent, delivered, read, failed)
- `unknown` - Unrecognized payload shape

**Parsed Fields:**
- `kind`: `'message'`, `'status'`, or `'unknown'`
- `eventType`: String identifier
- `waId`: WhatsApp ID (normalized)
- `phoneNumber`: E.164 phone number
- `displayName`: Contact display name
- `fromMe`: Boolean (outbound vs inbound)
- `body`: Message text
- `type`: Message type (text, image, video, etc.)
- `mediaUrl`: Media URL if present
- `timestamp`: Message timestamp
- `messageId`: Remote message ID (for deduplication)
- `status`: Delivery status (for status updates)

---

## 3. Evolution API Configuration

### 3.1 Environment Variables

**Location:** `fulltech_api/.env` and `fulltech_api/src/config/env.ts`

**Required Variables:**

```env
EVOLUTION_BASE_URL=https://your-evolution-api.host
EVOLUTION_API_KEY=your-api-key
EVOLUTION_INSTANCE=your-instance-name
```

**Current Configuration (.env):**

```env
EVOLUTION_API_URL="https://evolucionapi-evolution-api.gcdndd.easypanel.host"
EVOLUTION_API_INSTANCE_NAME="fulltech"
EVOLUTION_API_KEY="6359FDA0467A-48E3-A056-70E6566008F3"
```

**Backward Compatibility Aliases:**
- `EVOLUTION_API_URL` → `EVOLUTION_BASE_URL`
- `EVOLUTION_API_INSTANCE_NAME` → `EVOLUTION_INSTANCE`
- `EVOLUTION_INSTANCE_ID` → `EVOLUTION_INSTANCE`

### 3.2 Optional Configuration

```env
# Country code for phone number normalization (NANP default)
EVOLUTION_DEFAULT_COUNTRY_CODE=1

# Whether to format numbers as JIDs (@s.whatsapp.net)
EVOLUTION_NUMBER_AS_JID=true  # Default: true

# Webhook secret validation (if Evolution supports it)
WEBHOOK_SECRET=your-webhook-secret
EVOLUTION_WEBHOOK_SECRET=your-webhook-secret
```

### 3.3 Evolution Client

**Location:** `fulltech_api/src/services/evolution/evolution_client.ts`

**Class:** `EvolutionClient`

**Methods:**

| Method | Purpose | Parameters |
|--------|---------|------------|
| `sendText()` | Send text message | `toPhone?`, `toWaId?`, `text` |
| `sendMedia()` | Send media message | `toPhone?`, `toWaId?`, `mediaUrl`, `caption?`, `mediaType?` |
| `markAsRead()` | Mark message as read | `messageId` |
| `deleteMessage()` | Delete message | `messageId` |
| `updateProfileName()` | Update profile name | `name` |
| `updateProfileStatus()` | Update profile status | `status` |
| `getProfilePicture()` | Get profile picture URL | `waId` |

**Phone Number Normalization:**
- Strips non-digits
- Applies country code if 10 digits (NANP)
- Converts to JID format (`@s.whatsapp.net`) if `EVOLUTION_NUMBER_AS_JID=true`
- Prefers phone number over `@lid` (unstable Evolution LID format)

---

## 4. Flutter CRM Screens

### 4.1 Screen Locations

**Base Path:** `fulltech_app/lib/features/crm/`

#### Main Screens

| File | Screen | Purpose |
|------|--------|---------|
| `presentation/pages/crm_home_page.dart` | CRM Home | Tab container (Chats + Customers) |
| `presentation/pages/crm_chats_page.dart` | Chats Page | WhatsApp-like chat list + detail |
| `presentation/pages/crm_customers_page_enhanced.dart` | Customers Page | Customer directory |
| `presentation/pages/thread_chat_page.dart` | Chat Detail | Individual chat thread view |
| `presentation/pages/customer_detail_page.dart` | Customer Detail | Customer profile and history |
| `presentation/pages/crm_instance_settings_page.dart` | Instance Settings | Evolution API configuration |

### 4.2 CRM Instance Settings Screen

**Location:** `fulltech_app/lib/features/crm/presentation/pages/crm_instance_settings_page.dart`

**Purpose:** Configure Evolution API connection per user/instance

**Form Fields:**

| Field | Model Property | Description |
|-------|----------------|-------------|
| Instance Name | `instance_name` | Evolution instance identifier |
| API Key | `api_key` | Evolution API key (hidden by default) |
| Server URL | `server_url` | Evolution server host (without scheme) |
| Phone Number | `phone_e164` | WhatsApp phone number (E.164) |
| Display Name | `display_name` | Instance display label |

**Data Model:** `CrmInstanceSettings`  
**Location:** `fulltech_app/lib/features/crm/data/models/crm_instance_settings.dart`

**API Endpoints:**
- `GET /api/crm/instance/settings` - Fetch current settings
- `POST /api/crm/instance/settings` - Save settings
- `DELETE /api/crm/instance/settings` - Delete settings

### 4.3 State Management

**Provider:** Riverpod  
**State Files:** `fulltech_app/lib/features/crm/state/`

#### Main Providers

| Provider | Purpose |
|----------|---------|
| `crmThreadsControllerProvider` | Chat list state + pagination |
| `crmMessagesControllerProvider` | Message list for selected chat |
| `crmChatStatsControllerProvider` | CRM stats (counts by status) |
| `crmChatFiltersProvider` | Search/filter state |
| `crmRealtimeProvider` | SSE stream connection |
| `selectedThreadIdProvider` | Currently selected chat ID |

### 4.4 Repository Layer

**Location:** `fulltech_app/lib/features/crm/data/repositories/crm_repository.dart`

**Data Sources:**
- `CrmRemoteDataSource` - API calls
- `LocalDb` - SQLite cache

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `listThreads()` | Fetch chat list (paginated) |
| `readCachedThreads()` | Read from local cache |
| `cacheThreads()` | Write to local cache |
| `listMessages()` | Fetch messages for chat |
| `readCachedMessages()` | Read messages from cache |
| `cacheMessages()` | Cache messages locally |
| `sendTextMessage()` | Send text message |
| `markChatRead()` | Mark chat as read |
| `updateChatStatus()` | Update CRM status |

---

## 5. API Endpoints (Backend)

### 5.1 CRM Routes

**Router:** `fulltech_api/src/modules/crm/crm.routes.ts`  
**Base:** `/api/crm` (with auth middleware)

#### Chat Management

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/chats` | List chats (paginated, filtered) |
| `GET` | `/chats/stats` | Get CRM stats (counts by status) |
| `GET` | `/chats/:chatId` | Get single chat |
| `PATCH` | `/chats/:chatId` | Update chat (status, metadata) |
| `DELETE` | `/chats/:chatId` | Delete chat (admin only) |
| `PATCH` | `/chats/:chatId/read` | Mark chat as read |
| `POST` | `/chats/:chatId/status` | Update CRM status |
| `POST` | `/chats/:chatId/convert-to-customer` | Convert to customer |

#### Message Management

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/chats/:chatId/messages` | List messages for chat |
| `POST` | `/chats/:chatId/messages/text` | Send text message |
| `PATCH` | `/chats/:chatId/messages/:messageId` | Edit message |
| `DELETE` | `/chats/:chatId/messages/:messageId` | Delete message |

#### Outbound Messaging

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/chats/outbound/text` | Send text to new/arbitrary number |

#### Bought Clients (Purchased)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/chats/bought` | List bought clients (status=compro) |
| `GET` | `/chats/bought/inbox` | Inbox for purchased clients with pending messages |
| `PATCH` | `/chats/:chatId/bought/inbox/clear` | Clear bought inbox flag |
| `PATCH` | `/chats/:chatId/post-sale-state` | Update post-sale state |
| `GET` | `/purchased-clients` | List purchased clients |
| `GET` | `/purchased-clients/:clientId` | Get purchased client detail |
| `PATCH` | `/purchased-clients/:clientId` | Update purchased client |
| `DELETE` | `/purchased-clients/:clientId` | Delete purchased client |

#### Quick Replies

| Method | Endpoint | Purpose | Permissions |
|--------|----------|---------|-------------|
| `GET` | `/quick-replies` | List templates | All |
| `POST` | `/quick-replies` | Create template | Admin only |
| `PUT` | `/quick-replies/:id` | Update template | Admin only |
| `DELETE` | `/quick-replies/:id` | Delete template | Admin only |

#### Realtime Stream

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/stream` | SSE stream for realtime events |

#### Legacy Threads (Old CRM)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/threads` | List legacy threads |
| `GET` | `/threads/:id` | Get legacy thread |
| `POST` | `/threads` | Create legacy thread |
| `PATCH` | `/threads/:id` | Update legacy thread |
| `GET` | `/threads/:id/messages` | List legacy messages |
| `POST` | `/threads/:id/messages` | Post legacy message |
| `POST` | `/threads/:id/send` | Send via Evolution |
| `POST` | `/threads/:id/convert-to-customer` | Convert to customer |

---

## 6. User/Instance Management

### 6.1 Multi-Tenancy

**Model:** Single Evolution instance per `empresa_id`

**Environment Variable:**
```env
DEFAULT_EMPRESA_ID=78b649eb-eaca-4e98-8790-0d67fee0cf7a
```

**Behavior:**
- All `/api/auth/register` users attach to `DEFAULT_EMPRESA_ID`
- `crm_chats` and `crm_messages` are filtered by `empresa_id`
- Each empresa has one Evolution instance configuration

### 6.2 Instance Configuration Storage

**Current:** Environment variables (server-wide)  
**Future:** Database table for per-user/per-empresa instances (partially implemented in Flutter model)

**Model:** `CrmInstanceSettings`

```typescript
{
  instance_name: string;
  api_key: string;
  server_url?: string;
  phone_e164?: string;
  display_name?: string;
  is_active: boolean;
}
```

**Note:** Backend endpoints for instance CRUD exist in API but may not be fully wired to database storage yet (currently reading from env vars).

---

## 7. CRM Status/Stage Flow

### 7.1 Default Statuses

**Defined in:** `fulltech_app/lib/features/crm/constants/crm_statuses.dart`

| Status | Label | Color | Order |
|--------|-------|-------|-------|
| `primer_contacto` | Primer Contacto | Blue | 0 |
| `en_conversacion` | En Conversación | Orange | 1 |
| `reunion_agendada` | Reunión Agendada | Purple | 2 |
| `propuesta_enviada` | Propuesta Enviada | Teal | 3 |
| `negociacion` | Negociación | Indigo | 4 |
| `compro` | Compró | Green | 5 |
| `no_interesado` | No Interesado | Grey | 6 |
| `perdido` | Perdido | Red | 7 |

### 7.2 Post-Sale States

**Enum:** `CrmPostSaleState` (in schema.prisma)

```typescript
enum CrmPostSaleState {
  NORMAL
  GARANTIA              // Warranty case
  SOLUCION_GARANTIA     // Warranty resolution
  CLIENTE_MOLESTO       // Upset customer
  VIP                   // VIP customer
}
```

**Usage:** Applied to chats with status = `compro` to track post-purchase state

---

## 8. Key Implementation Notes

### 8.1 Phone Number Normalization

**Function:** `normalizeWhatsAppIdentity()` in `fulltech_api/src/utils/whatsapp_identity.ts`

**Strategy:**
1. Extract digits from phone and waId
2. Apply country code if 10 digits (default: `1` for NANP)
3. Generate canonical waId: `{digits}@s.whatsapp.net`
4. Store E.164 digits in `crm_chats.phone`

### 8.2 Message Deduplication

**Problem:** Evolution/Baileys can emit duplicate events for same message (e.g., `@lid` and `@s.whatsapp.net`)

**Solution:** Check `crm_messages.remote_message_id` before creating new message (in webhook controller transaction)

### 8.3 Realtime Updates

**Technology:** Server-Sent Events (SSE)  
**Endpoint:** `GET /api/crm/stream`  
**Emitter:** `emitCrmEvent()` in `fulltech_api/src/modules/crm/crm_stream.ts`

**Event Types:**
- `message.new` - New message created
- `message.status` - Message status updated
- `chat.updated` - Chat metadata updated

---

## 9. Summary

### Current State

✅ **Working:**
- WhatsApp webhook ingestion (Evolution API)
- Chat and message storage in PostgreSQL
- Multi-tenant support via `empresa_id`
- Flutter UI for chat list, detail, and customer management
- CRM status/stage tracking
- Quick replies (templates)
- SSE realtime updates
- Bought client inbox workflow
- Post-sale state tracking

📋 **Partially Implemented:**
- Per-user instance settings (model exists, API endpoints partially wired)
- Outbound media sending (client method exists, currently disabled in UI)

🔄 **Needs Review:**
- Webhook authentication (currently public endpoint)
- Instance configuration storage (env vars vs database)
- Media message handling (placeholders in place)

### Architecture Strengths

- Clean separation: Backend (Node.js/Prisma) ↔ Frontend (Flutter/Riverpod)
- Robust webhook system with audit trail
- Deduplication and normalization logic
- Multi-tenant ready
- Realtime updates via SSE
- Local caching in Flutter (SQLite)

### Recommended Next Steps (If Implementing Changes)

1. **Instance Management:** Wire up instance settings CRUD to database
2. **Webhook Auth:** Implement secret validation for Evolution webhooks
3. **Media Support:** Enable outbound media sending (currently disabled)
4. **Multi-Instance:** Support multiple Evolution instances per empresa
5. **Analytics:** Dashboard with CRM conversion funnel
6. **Automation:** Auto-responses, chatbot integration

---

**End of Documentation**

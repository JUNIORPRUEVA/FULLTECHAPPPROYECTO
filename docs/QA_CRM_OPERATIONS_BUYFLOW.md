# QA Checklist — CRM ↔ Operations ↔ Bought Clients Flow

## Preconditions
- Backend migrations applied (run SQL migrations in `fulltech_api/sql/`).
- At least one active Service exists in catalog (`GET /api/settings/services`).
- A technician user exists (for `assigned_tech_id`).

## 1) New inbound chat defaults to PRIMER_CONTACTO
1. Send an inbound WhatsApp message to a new number (via Evolution webhook).
2. Verify CRM chat is created with `status = primer_contacto`.

## 2) Set status to POR_LEVANTAMIENTO (required form)
1. In CRM, set chat status to `por_levantamiento`.
2. Verify backend enforces required payload:
   - `scheduled_at`, `location_text`, `lat`, `lng`, `assigned_tech_id`, `service_id`
3. Verify an Operations job is upserted with:
   - `crm_chat_id = chatId`, `crm_task_type = LEVANTAMIENTO`
   - `scheduled_at`, `location_text`, `lat`, `lng`, `assigned_tech_id`, `service_id`

## 3) Set status to SERVICIO_RESERVADO (required form)
1. In CRM, set chat status to `servicio_reservado` (aliases `agendado`/`reservado` also accepted).
2. Verify backend enforces required payload (same as above).
3. Verify Operations job exists with:
   - `crm_task_type = SERVICIO_RESERVADO`
   - `scheduled_at` populated and `operations_schedule` upserted for the job.

## 4) Operations filtering
1. Call `GET /api/operations/jobs?type=SERVICIO_RESERVADO` and verify scheduled tasks appear.
2. Call `GET /api/operations/jobs?type=LEVANTAMIENTO` and verify surveys appear.
3. Confirm response includes:
   - `crm_chat` basic info
   - `assigned_tech` basic info
   - `service` `{id,name}` when `service_id` is present

## 5) COMPRO irreversibility + separation
1. Set CRM chat status to `compro`.
2. Verify `GET /api/crm/chats` does NOT return the chat.
3. Verify `GET /api/crm/chats/bought` DOES return the chat.
4. Attempt to change status away from `compro`:
   - `POST /api/crm/chats/:chatId/status` => expect 422
   - `PATCH /api/crm/chats/:chatId` => expect 422

## 6) Bought inbox flag on new inbound message
1. With a purchased chat (`status=compro`), send a new inbound message.
2. Verify chat appears in `GET /api/crm/chats/bought/inbox`.
3. Call `PATCH /api/crm/chats/:chatId/bought/inbox/clear`.
4. Verify it no longer appears in bought inbox list.

## 7) Post-sale state updates
1. For a purchased chat, call:
   - `PATCH /api/crm/chats/:chatId/post-sale-state` with `{ "state": "GARANTIA" }`
2. Verify it succeeds only when `status=compro` and state is stored.

## 8) VIP rule
1. Ensure the sales module has records in `sales` with `customer_phone` matching the chat phone.
2. Verify the bought list returns `vip=true` when:
   - purchases_count > 3 OR total_spent >= 60000
3. Verify `postSaleState` is returned as `VIP` when `vip=true`.


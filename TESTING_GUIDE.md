# TESTING GUIDE - CRM/CLIENTS/OPERATIONS FIXES
**Date:** January 8, 2026

## 🧪 TEST PLAN

### Prerequisites
1. Backend server running (`fulltech_api`)
2. Flutter app running on Windows Desktop
3. Valid user authentication (admin or vendedor role)
4. At least one WhatsApp chat in CRM module

---

## TEST 1: Clientes Activos - Status "Activo"

### Objective
Verify that marking a chat as "Activo" creates a customer that appears in the Clientes Activos list immediately.

### Steps:
1. **Open CRM Module**
   - Navigate to CRM section
   - Find a chat that is NOT yet converted to customer

2. **Check Initial State**
   - Go to "Clientes" or "Clientes Activos" menu
   - Note the counter (e.g., "Total Clientes: 6", "Clientes Activos: 3")
   - Note if the chat's phone number appears in the list

3. **Change Status to "Activo"**
   - Return to CRM
   - Select the chat
   - In right panel, find "Cambiar estado" dropdown
   - Select "Activo"
   - Confirm the dialog if prompted

4. **Verify Backend Logs**
   - Check backend console for:
     ```
     [CRM] Converting chat to customer with status=activo, tags=activo
     [CRM] Created new customer {id} with tags: activo
     ```
   - OR if customer existed:
     ```
     [CRM] Updated existing customer {id} with merged tags: activo
     ```

5. **Verify Frontend Logs**
   - Check Flutter console for:
     ```
     [CRM] Converting chat to customer with status: activo
     ```

6. **Verify Clientes Activos List**
   - Go to "Clientes Activos" screen
   - **Expected:** Counter increased by 1 (or stayed same if updating existing)
   - **Expected:** Chat's contact now appears in the list
   - **Expected:** List shows same count as counter

### ✅ Pass Criteria:
- [ ] Backend logs show tag assignment
- [ ] Frontend logs show status parameter
- [ ] Customer appears in "Clientes Activos" list immediately (no reload needed)
- [ ] Counter and list show consistent numbers
- [ ] No duplicate customers created (if ran twice)

### ❌ Fail Indicators:
- Counter shows number but list is empty
- Customer not appearing after status change
- Duplicate customers created
- Error messages in console

---

## TEST 2: Status "Compró" Creates Customer with Correct Tags

### Objective
Verify that "Compró" status creates customer with 'compro' tag.

### Steps:
1. Select different chat in CRM
2. Change status to "Compró"
3. Check backend logs for: `tags=compro`
4. Go to Clientes list
5. Find the customer
6. Verify they appear in "Clientes Activos" filter

### ✅ Pass Criteria:
- [ ] Backend assigns tags=['compro']
- [ ] Customer appears in activos list
- [ ] Counter matches list

---

## TEST 3: Mandatory Dialog - Reserva

### Objective
Verify that "Reserva" status REQUIRES dialog and cancellation prevents status change.

### Steps:
1. **Setup**
   - Select a chat
   - Note current status (e.g., "Pendiente")

2. **Test Cancellation**
   - Click "Cambiar estado" dropdown
   - Select "Reserva"
   - **Expected:** Dialog opens with title "Reservar Producto/Servicio"
   - Click "Cancelar" button
   - **Expected:** Dialog closes
   - **Expected:** Status dropdown shows ORIGINAL status (not "Reserva")

3. **Test X Button**
   - Select "Reserva" again
   - Click X button on dialog
   - **Expected:** Status unchanged

4. **Test Validation**
   - Select "Reserva" again
   - Leave "Producto/Servicio" field empty
   - Leave "Nota" field empty
   - Click "Confirmar Reserva"
   - **Expected:** Validation errors shown
   - **Expected:** Dialog remains open
   - **Expected:** Status NOT changed

5. **Test Successful Submission**
   - Fill all required fields:
     - Fecha: Tomorrow
     - Hora: 10:00 AM
     - Producto/Servicio: "Laptop Dell"
     - Nota: "Cliente necesita laptop para trabajo"
   - Click "Confirmar Reserva"
   - **Expected:** Dialog closes
   - **Expected:** Status changes to "Reserva"
   - **Expected:** SnackBar shows success message

### ✅ Pass Criteria:
- [ ] Dialog cannot be bypassed
- [ ] Cancel button prevents status change
- [ ] X button prevents status change
- [ ] Validation prevents empty submission
- [ ] Successful submission changes status

---

## TEST 4: Mandatory Dialog - Servicio Reservado

### Similar to Test 3, but:
- Select "Servicio reservado" status
- Dialog title: "Agendar Servicio"
- Required: Fecha, Hora, Tipo de servicio
- Optional: Ubicación, Técnico, Notas

### ✅ Pass Criteria:
- [ ] Same as Test 3

---

## TEST 5: Mandatory Dialog - En Garantía

### Steps:
1. Select "En garantía" status
2. Dialog should show: "Registrar Caso de Garantía"
3. Test cancellation → status unchanged
4. Test validation:
   - Producto: required
   - Número de serie: required
   - Tiempo de garantía: required
   - Detalles: required (min 10 chars)
5. Submit with valid data → status changes

### ✅ Pass Criteria:
- [ ] Dialog mandatory
- [ ] All validations work
- [ ] Cancel prevents status change

---

## TEST 6: Mandatory Dialog - Solución de Garantía

### Steps:
1. Select "Solución de garantía" status
2. Dialog: "Registrar Solución de Garantía"
3. Note: Fecha/hora are OPTIONAL
4. Required fields:
   - Producto/Servicio
   - Detalles (min 10 chars)
5. Test with date empty → should still submit
6. Test with empty required fields → validation error

### ✅ Pass Criteria:
- [ ] Dialog mandatory
- [ ] Optional date/time work
- [ ] Required fields validated

---

## TEST 7: No Duplicate Customers (Idempotency)

### Objective
Verify that changing status multiple times doesn't create duplicate customers.

### Steps:
1. Find a chat with phone "+18091234567"
2. Note if customer with this phone already exists
3. Change status to "Activo"
4. Check Clientes list → should have 1 customer with that phone
5. Change same chat status to "Compró"
6. Check Clientes list → should STILL have only 1 customer with that phone
7. Check backend logs → should see "Updated existing customer" not "Created new customer"
8. Verify customer has merged tags: ['activo', 'compro']

### ✅ Pass Criteria:
- [ ] Only one customer per phone number
- [ ] Tags are merged (not replaced)
- [ ] Backend logs show "updated" not "created" on second conversion

---

## TEST 8: Multi-Tenant Isolation

### Objective
Verify empresa_id filtering works correctly.

### Steps:
1. Login as user from empresa A
2. Create a customer (change chat status to Activo)
3. Logout
4. Login as user from empresa B
5. Go to Clientes Activos
6. **Expected:** Do NOT see empresa A's customer
7. Create customer for empresa B
8. **Expected:** Only see empresa B's customer

### ✅ Pass Criteria:
- [ ] Customers filtered by empresa_id
- [ ] No cross-empresa data leakage

---

## 📊 TEST RESULTS TEMPLATE

```markdown
## Test Execution Results
**Date:** [Date]
**Tester:** [Name]
**Environment:** [Dev/Staging/Prod]

### TEST 1: Clientes Activos - Status "Activo"
- [ ] PASS / [ ] FAIL
- Notes: 

### TEST 2: Status "Compró"
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 3: Mandatory Dialog - Reserva
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 4: Mandatory Dialog - Servicio Reservado
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 5: Mandatory Dialog - En Garantía
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 6: Mandatory Dialog - Solución de Garantía
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 7: No Duplicate Customers
- [ ] PASS / [ ] FAIL
- Notes:

### TEST 8: Multi-Tenant Isolation
- [ ] PASS / [ ] FAIL
- Notes:

### OVERALL RESULT
- [ ] ALL TESTS PASSED
- [ ] SOME FAILURES (see notes)
```

---

## 🐛 DEBUGGING TIPS

### If customers don't appear in list:

1. **Check backend logs:**
   ```
   grep "Converting chat to customer" backend.log
   ```
   Should show tags being assigned

2. **Check customer in database:**
   ```sql
   SELECT id, nombre, telefono, tags, is_active 
   FROM customers_legacy 
   WHERE telefono = '+18091234567';
   ```
   Verify tags column includes 'activo' or 'compro'

3. **Check frontend filter logic:**
   - File: `customers_page.dart`
   - Method: `_isActiveCustomer()`
   - Should return true for customers with 'compro' or 'activo' tags

4. **Check API response:**
   - Open browser DevTools Network tab
   - Filter for `/api/customers`
   - Check response JSON
   - Verify `isActiveCustomer: true` for your customer

### If dialogs can be bypassed:

1. **Check status change flow:**
   - File: `right_panel_crm.dart`
   - Lines ~370-480
   - Verify `if (result == null) return;` exists after each dialog

2. **Check dialog return values:**
   - Cancel button should call: `Navigator.of(context).pop()`
   - NOT: `Navigator.of(context).pop(result)`

### If duplicate customers appear:

1. **Check upsert logic:**
   - Backend file: `crm_whatsapp.controller.ts`
   - Look for `findFirst` before `create`
   - Should update if exists, not create new

2. **Check unique constraint:**
   ```sql
   SELECT * FROM customers_legacy 
   WHERE telefono = '+18091234567';
   ```
   Should return at most 1 row

---

## 🎯 CRITICAL SUCCESS INDICATORS

**If ALL of these work, the implementation is successful:**

1. ✅ Mark chat as "Activo" → Customer appears in "Clientes Activos" immediately
2. ✅ Counter and list show same numbers
3. ✅ Cannot change to "Reserva" without completing dialog
4. ✅ Cancel dialog → status doesn't change
5. ✅ No duplicate customers when converting same chat twice
6. ✅ Multi-tenant filtering works (can't see other company's customers)

---

## 📞 SUPPORT

If tests fail, gather:
1. Backend logs (console output)
2. Frontend logs (Flutter console)
3. Database query results
4. Screenshots of UI state
5. Steps to reproduce

Then refer to `FIXES_STATUS_REPORT.md` for implementation details.

# Auth Session Fix - Quick Verification Checklist

Use this checklist to verify the auth session persistence fix works correctly.

## Prerequisites
- [ ] Run a debug build (to see debug logs)
- [ ] Windows desktop is preferred (reported platform for the bug)
- [ ] Have valid login credentials ready

---

## Test 1: Session Persists After App Restart ✅
**This is the main bug fix - verify this works!**

1. [ ] Open the app
2. [ ] Login with valid credentials
3. [ ] Verify you reach the main screen (CRM page)
4. [ ] **Close the app completely** (not minimize - actually close)
5. [ ] Reopen the app
6. [ ] **Expected**: App shows splash screen briefly, then goes directly to main screen
7. [ ] **Expected**: You are still logged in (no login screen)

### Debug Logs to Check:
```
[AUTH] bootstrap()
[AUTH] bootstrap: token=…XXXXXX userId=... empresaId=... baseUrl=...
[AUTH] bootstrap: session found user=...@... role=...
[AUTH] Initial bootstrap complete
```

**❌ FAIL IF**: You see login screen after reopening
**❌ FAIL IF**: Session is lost or you're logged out

---

## Test 2: Single Bootstrap on Startup ✅

1. [ ] Close the app
2. [ ] Open the app (watch debug console closely)
3. [ ] Count how many times you see `[AUTH] bootstrap()`
4. [ ] **Expected**: See it **ONCE** only
5. [ ] **Expected**: See `[AUTH] Skipping bootstrap on initial settings load...`

### Debug Logs to Check:
```
[AUTH] bootstrap()
[AUTH] Skipping bootstrap on initial settings load to avoid race condition
[AUTH] Initial bootstrap complete
```

**❌ FAIL IF**: You see `[AUTH] bootstrap()` more than once
**❌ FAIL IF**: You see `[AUTH] bootstrap: already in progress, waiting...` on startup

---

## Test 3: No Immediate Logout After Login ✅

1. [ ] Logout (or start fresh)
2. [ ] Login with valid credentials
3. [ ] Watch the screen for 5-10 seconds
4. [ ] **Expected**: You stay logged in, no bounce back to login
5. [ ] **Expected**: App is stable on the main screen

**❌ FAIL IF**: You are immediately logged out after login
**❌ FAIL IF**: You see login screen again within 10 seconds

---

## Test 4: Navigate Without Logout ✅

1. [ ] Login
2. [ ] Navigate to different sections (CRM → Operaciones → Ventas → Configuración)
3. [ ] Wait a few seconds on each screen
4. [ ] **Expected**: No unexpected logout
5. [ ] **Expected**: No 401 errors in logs

**❌ FAIL IF**: You are logged out while navigating
**❌ FAIL IF**: You see repeated `[AUTH][HTTP] 401 ...` in logs

---

## Test 5: Server Change (Debug Mode Only) ✅
**Only if you have admin role and debug build**

1. [ ] Login to Server A (cloud or local)
2. [ ] Note that you're logged in
3. [ ] Go to: Configuración → Servidor
4. [ ] Change server to Server B
5. [ ] **Expected**: May need to login again for Server B (this is correct!)
6. [ ] Login to Server B
7. [ ] Change back to Server A
8. [ ] **Expected**: Automatically logged in (session restored for Server A)

### Debug Logs to Check:
```
[AUTH] Settings changed, reloading session for new server
[AUTH] bootstrap()
```

**❌ FAIL IF**: Server A session is lost when switching to Server B
**❌ FAIL IF**: Multiple bootstraps happen simultaneously

---

## Common Issues & Solutions

### Issue: "I see login screen after restarting app"
- **Check**: Are you closing the app completely (not just minimizing)?
- **Check**: Is this a debug or release build?
- **Check**: Do you see bootstrap logs? If not, the fix may not be deployed.

### Issue: "I see [AUTH] bootstrap() twice on startup"
- **Check**: Are you using the latest version with the fix?
- **Check**: Look for the "Skipping bootstrap" message - it should appear

### Issue: "I'm logged out immediately after login"
- **Check**: Backend logs for 401 errors - may be a backend issue
- **Check**: Token is being saved correctly (see bootstrap logs)
- **Check**: No unauthorized events in first few seconds

### Issue: "Session is lost when I change server"
- **Check**: This is expected! Each server has its own session
- **Check**: When you switch back, the original session should be restored
- **Check**: Look for "Settings changed, reloading session" log

---

## Success Criteria

All of these must be true:

✅ Session persists after closing and reopening app
✅ Only ONE bootstrap happens on app startup
✅ No immediate logout after successful login
✅ Can navigate around the app without random logouts
✅ Server changes work correctly (if applicable)
✅ Debug logs show proper flow and no race conditions

---

## If All Tests Pass

Congratulations! The auth session persistence fix is working correctly. The app now:
- ✅ Remembers your login between app restarts
- ✅ Doesn't have race conditions on startup
- ✅ Properly handles server changes (per-server sessions)
- ✅ Provides a smooth, production-ready experience

---

## If Any Test Fails

1. Check if you're running the latest version with the fix
2. Review debug logs for error messages
3. Check backend logs for 401 errors or token issues
4. Verify database schema is up to date (schema version 12+)
5. Try clearing app data and logging in fresh
6. Report the issue with debug logs attached

---

## For Developers

### Quick Test Command
```bash
# Run the new unit tests
cd fulltech_app
flutter test test/auth_bootstrap_race_test.dart

# Expected: All 4 tests pass
```

### Debug Mode Tips
```dart
// Look for these specific log messages in order:
[AUTH] bootstrap()                                          // Start
[AUTH] Skipping bootstrap on initial settings load...      // Skip race
[AUTH] bootstrap: token=…XXXXXX userId=...                 // Found session
[AUTH] bootstrap: session found user=...@...               // User details
[AUTH] Initial bootstrap complete                          // Done
```

### Common Debug Patterns

**Good Pattern (Single Bootstrap)**:
```
[AUTH] bootstrap()
[AUTH] Skipping bootstrap on initial settings load to avoid race condition
[AUTH] bootstrap: token=…123456 userId=u1 empresaId=e1 baseUrl=https://api.example.com
[AUTH] bootstrap: session found user=test@example.com role=admin
[AUTH] Initial bootstrap complete
```

**Bad Pattern (Double Bootstrap - OLD BUG)**:
```
[AUTH] bootstrap()
[AUTH] bootstrap()                                         // ❌ DUPLICATE!
[AUTH] bootstrap: already in progress, waiting...          // Race detected
```

**Good Pattern (Server Change)**:
```
[AUTH] Settings changed, reloading session for new server
[AUTH] bootstrap()
[AUTH] bootstrap: token=…789012 userId=u1 empresaId=e1 baseUrl=http://localhost:3000/api
[AUTH] bootstrap: session found user=test@example.com role=admin
```

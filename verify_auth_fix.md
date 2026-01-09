# Auth Session Fix - Verification Script

## Quick Verification Steps

### 1. Visual Test (5 minutes)

**Scenario A: Fresh Login**
```
1. Delete app data / clear storage
2. Launch app
3. Login with valid credentials
4. ✅ Should see home screen
5. Close app completely
6. Relaunch app
7. ✅ Should see home screen WITHOUT login
```

**Scenario B: Server Switch (Debug Mode Only)**
```
1. Login to app
2. Navigate to Settings → Configuration → Server
3. Switch from Cloud to Local (or vice versa)
4. Return to home screen
5. ✅ Should STAY logged in (not forced to login)
6. ✅ Next API call should work with new endpoint
```

### 2. Log Verification (2 minutes)

Open developer console and look for these patterns:

**✅ GOOD - Session Working:**
```
[AUTH] bootstrap()
[AUTH] bootstrap: session found user=xxx@example.com role=admin
[AUTH] login: saved session role=admin
```

**❌ BAD - Session Broken:**
```
[AUTH] AuthController.dispose() called  ← Appears immediately after login
[AUTH] bootstrap()  ← Called right after successful login
[AUTH] bootstrap: no session  ← After just logging in
```

### 3. SQLite Verification (Advanced)

**Windows:**
```bash
cd %APPDATA%\com.example\fulltech_app\databases
sqlite3 fulltech_app.db "SELECT * FROM auth_session;"
```

**Linux/Mac:**
```bash
cd ~/.local/share/com.example.fulltech_app/databases
sqlite3 fulltech_app.db "SELECT * FROM auth_session;"
```

**Expected Output:**
```
1|eyJhbGciOiJIUzI1NiIs...|{"id":"user-123","email":"admin@example.com",...}
```

---

## Detailed Test Cases

### Test 1: Login Persistence Across Restart ⭐ CRITICAL

**Purpose:** Verify session persists when app is completely closed and reopened.

**Steps:**
1. Start fresh (clear app data if needed)
2. Launch app
3. Login with valid credentials
4. Verify you see the home screen
5. **Close app completely** (not minimize - actually quit the process)
6. **Wait 5 seconds**
7. Relaunch app

**Expected Behavior:**
- ✅ Splash screen appears briefly (1-2 seconds)
- ✅ Automatically redirects to home screen
- ✅ NO login screen shown
- ✅ User data displayed correctly

**Console Logs Expected:**
```
[AUTH] bootstrap()
[AUTH] bootstrap: session found user=xxx role=xxx
```

**If This Fails:**
- ❌ Check if SQLite database has session stored
- ❌ Check file permissions on database
- ❌ Check if `LocalDb.init()` is being called
- ❌ Verify bootstrap() is reading from correct database path

---

### Test 2: Debug Server Switch ⭐ CRITICAL (Debug Mode Only)

**Purpose:** Verify session survives API endpoint configuration changes.

**Prerequisites:** App must be in DEBUG mode.

**Steps:**
1. Login successfully
2. Navigate to home screen
3. Go to Settings → Configuration → Server Settings
4. Note current server (Cloud or Local)
5. **Switch to the other option**
6. Tap "Save" or "Apply"
7. Return to home screen
8. Try navigating to different screens

**Expected Behavior:**
- ✅ User stays logged in (no redirect to login)
- ✅ All screens remain accessible
- ✅ Next API call succeeds with new endpoint
- ✅ No error messages about authentication

**Console Logs Expected:**
```
[AUTH] bootstrap: session found user=xxx role=xxx
(NO "[AUTH] AuthController.dispose() called" message)
```

**Console Logs NOT Expected:**
```
❌ [AUTH] AuthController.dispose() called
❌ [AUTH] bootstrap()  ← Multiple times
❌ [AUTH] bootstrap: no session
```

**If This Fails:**
- ❌ Provider chain still causing rebuilds
- ❌ `ref.keepAlive()` not working
- ❌ Controller being recreated on config change

---

### Test 3: Token Expiration Handling

**Purpose:** Verify 401 errors correctly logout user without loops.

**Steps:**
1. Login successfully
2. Manually invalidate token in backend (or wait for expiration)
3. Make any API request (e.g., navigate to a screen that loads data)

**Expected Behavior:**
- ✅ Request returns 401
- ✅ User logged out ONCE (no loop)
- ✅ Redirected to login screen
- ✅ Session cleared from database
- ✅ Can login again successfully

**Console Logs Expected:**
```
[AUTH][HTTP] 401 GET /some/endpoint hadAuthHeader=true
[AUTH] clearing local session due to 401 GET /some/endpoint
[AUTH] unauthorized event status=401
```

**Console Logs NOT Expected:**
```
❌ Repeated 401 logs for same endpoint
❌ Multiple "clearing local session" messages
❌ "[AUTH][HTTP] 401 ... hadAuthHeader=false" ← Should have header
```

---

### Test 4: Offline Mode

**Purpose:** Verify session persists when offline.

**Steps:**
1. Login successfully (with internet connection)
2. Close app
3. Disconnect internet/WiFi
4. Relaunch app

**Expected Behavior:**
- ✅ Shows splash screen briefly
- ✅ Bootstrap attempts validation, fails (offline)
- ✅ App preserves cached session (offline-first)
- ✅ User sees home screen
- ✅ Cached data displayed

**Console Logs Expected:**
```
[AUTH] bootstrap()
[AUTH] bootstrap: session found user=xxx role=xxx
[AUTH] bootstrap: validation error DioException, preserving session
```

---

### Test 5: Manual Logout

**Purpose:** Verify explicit logout works correctly.

**Steps:**
1. Login successfully
2. Navigate around the app
3. Go to profile/settings
4. Click logout button

**Expected Behavior:**
- ✅ Session cleared from SQLite
- ✅ Redirected to login screen immediately
- ✅ Cannot access protected screens
- ✅ Can login again successfully
- ✅ No errors or crashes

**Console Logs Expected:**
```
[AUTH] logout()
```

---

### Test 6: Multiple Config Changes

**Purpose:** Verify repeated server switches don't break auth.

**Steps (Debug Mode):**
1. Login successfully
2. Switch server: Cloud → Local
3. Wait 5 seconds
4. Switch server: Local → Cloud
5. Wait 5 seconds
6. Switch server: Cloud → Local
7. Return to home

**Expected Behavior:**
- ✅ User stays logged in throughout
- ✅ No authentication errors
- ✅ All API calls work (might fail if server unreachable)

**Console Logs Expected:**
```
(No controller dispose messages)
(No unexpected bootstrap calls)
```

---

## Automated Verification (If Flutter Tests Work)

### Unit Test: Provider Lifecycle

```dart
test('authControllerProvider survives API endpoint changes', () async {
  final container = ProviderContainer(
    overrides: [localDbProvider.overrideWithValue(mockDb)],
  );

  // Get initial controller instance
  final controller1 = container.read(authControllerProvider.notifier);
  
  // Trigger API endpoint change
  container.read(apiEndpointSettingsProvider.notifier)
    .setBackend(ApiBackend.local);
  
  // Get controller instance again
  final controller2 = container.read(authControllerProvider.notifier);
  
  // Should be SAME instance (not rebuilt)
  expect(identical(controller1, controller2), isTrue);
});
```

### Integration Test: Session Persistence

```dart
testWidgets('session persists across app restarts', (tester) async {
  // First launch: login
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Enter credentials and login
  await tester.enterText(find.byType(TextFormField).at(0), 'admin@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
  
  // Verify home screen shown
  expect(find.text('CRM'), findsOneWidget);
  
  // Simulate app restart
  await tester.pumpWidget(Container());
  await tester.pumpAndSettle();
  
  // Relaunch app
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Should show home screen, NOT login
  expect(find.text('CRM'), findsOneWidget);
  expect(find.text('Iniciar sesión'), findsNothing);
});
```

---

## Performance Checks

### Memory Leak Check

**Steps:**
1. Login
2. Switch server 10 times
3. Navigate to different screens
4. Check memory usage

**Expected:**
- ✅ Memory stays stable (no significant increase)
- ✅ No growing list of disposed controllers

### CPU Usage Check

**Steps:**
1. Login
2. Leave app idle for 2 minutes
3. Monitor CPU usage

**Expected:**
- ✅ CPU usage near 0% when idle
- ✅ No constant background work
- ✅ No infinite rebuild loops

---

## Troubleshooting Guide

### Issue: Session Not Persisting After Restart

**Symptoms:**
- Login works
- Closing and reopening shows login screen
- Console: `[AUTH] bootstrap: no session`

**Possible Causes:**
1. SQLite database not being saved
2. Database path changed between launches
3. App storage cleared by system
4. File permissions issue

**Debug Steps:**
```bash
# Check if database file exists
ls -la %APPDATA%\com.example\fulltech_app\databases\  # Windows
ls -la ~/.local/share/com.example.fulltech_app/databases/  # Linux/Mac

# Check database contents
sqlite3 fulltech_app.db "SELECT * FROM auth_session;"
```

**Solutions:**
- Verify `LocalDb.init()` is called before bootstrap
- Check database path is consistent
- Verify write permissions
- Check SQLite FFI is working on desktop

---

### Issue: Session Lost After Server Switch

**Symptoms:**
- Login works
- Switching server forces logout
- Console: `[AUTH] AuthController.dispose() called` after server change

**Possible Causes:**
1. `ref.keepAlive()` not working
2. Still using `ref.watch()` somewhere
3. Provider chain still causing rebuilds

**Debug Steps:**
```dart
// Add logging to provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    debugPrint('[AUTH PROVIDER] Creating auth controller');
    final keepAlive = ref.keepAlive();
    debugPrint('[AUTH PROVIDER] keepAlive created');
    
    return AuthController(
      db: db,
      getAuthApi: getAuthApi,
      onDispose: () {
        debugPrint('[AUTH PROVIDER] onDispose called - closing keepAlive');
        keepAlive.close();
      },
    );
  },
);
```

**Solutions:**
- Verify `auth_providers.dart` changes are applied
- Check for other code watching `authControllerProvider`
- Ensure no manual provider invalidation happening

---

### Issue: 401 Loop Still Occurring

**Symptoms:**
- Repeated 401 logs
- Console spam
- Cannot stay logged in

**Possible Causes:**
1. Sync operations still running without session check
2. Background timers making requests
3. Multiple instances of API client

**Debug Steps:**
- Check if previous fix (FIX_401_LOOP_FINAL.md) is still applied
- Verify all `syncPending()` methods check for session
- Look for timers/listeners starting before auth completes

**Solutions:**
- Re-apply session guards in sync operations
- Ensure no sync runs before `AuthAuthenticated` state
- Stop all timers on `AuthUnauthenticated`

---

## Success Criteria

The fix is successful if ALL of these are true:

1. ✅ **Login Once Works**
   - User can login successfully
   - Session saved to database
   - Redirected to home screen

2. ✅ **Session Persists on Restart**
   - Close app completely
   - Reopen app
   - Automatically shows home screen (no login required)

3. ✅ **Survives Config Changes (Debug)**
   - Login successfully
   - Switch server settings
   - User stays logged in

4. ✅ **Proper 401 Handling**
   - Expired token causes logout
   - No infinite loops
   - No log spam

5. ✅ **Manual Logout Works**
   - Logout clears session
   - Cannot access protected screens
   - Can login again

6. ✅ **No Memory Leaks**
   - Multiple config changes don't leak memory
   - Controller not recreated unnecessarily
   - Event listeners properly cleaned up

7. ✅ **Clean Console**
   - No unexpected dispose logs
   - No rebuild warnings
   - Clear, informative logging

---

## Final Checklist

Before marking this issue as **RESOLVED**, verify:

- [ ] Test 1: Login persistence across restart - PASSED
- [ ] Test 2: Debug server switch - PASSED
- [ ] Test 3: Token expiration handling - PASSED
- [ ] Test 4: Offline mode - PASSED
- [ ] Test 5: Manual logout - PASSED
- [ ] Test 6: Multiple config changes - PASSED
- [ ] No memory leaks observed
- [ ] No CPU usage spikes
- [ ] Console logs are clean
- [ ] All team members can reproduce success
- [ ] Tested on Windows Desktop ⭐ (primary platform)
- [ ] Tested on Mobile (Android/iOS)
- [ ] Tested on Web (if applicable)

---

**Document Version:** 1.0  
**Date:** January 9, 2026  
**Status:** Ready for Verification

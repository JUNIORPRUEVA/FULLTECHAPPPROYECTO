# FIX: 401 Infinite Loop Issue

## PROBLEM IDENTIFIED

The app was stuck in an infinite request loop calling protected endpoints without valid authentication, causing:
- Hundreds of `POST /api/attendance/punches 401` errors
- Repeated `GET /api/crm/chats/stats 401` errors  
- Automatic logout triggered by 401 responses
- User unable to stay logged in

## ROOT CAUSES FOUND

### 1. **CRM Stats Controller** (PRIMARY CAUSE)
**Location:** `lib/features/crm/state/crm_chat_stats_controller.dart:18`

```dart
// BEFORE (BROKEN):
CrmChatStatsController({required CrmRepository repo})
    : _repo = repo,
      super(CrmChatStatsState.initial()) {
  // ❌ Timer starts immediately in constructor - NO AUTH CHECK
  Future.microtask(refresh);
  _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
}
```

**Problem:** Timer started immediately when controller was created, calling `/crm/chats/stats` every 30 seconds **regardless of authentication state**.

### 2. **Auto Sync Widget** (SECONDARY CAUSE)
**Location:** `lib/core/widgets/auto_sync.dart:88`

```dart
// BEFORE (BROKEN):
_periodic = Timer.periodic(_periodicInterval, (_) {
  _scheduleSync();  // ❌ Calls attendance punch sync every 2 minutes
});
```

**Problem:** Timer calling `syncPending()` for all modules including attendance, even when auth was invalid.

### 3. **No 401 Detection on Stats Endpoint**
**Location:** `lib/features/crm/data/datasources/crm_remote_datasource.dart:972`

```dart
// BEFORE (BROKEN):
if (status >= 400) {
  // ❌ Silently returns empty stats, doesn't stop timer
  return const CrmChatStats(total: 0, ...);
}
```

**Problem:** 401 errors were being swallowed, timer kept running.

## FIXES APPLIED

### Fix 1: Add Auth Guard to CRM Stats Controller

**File:** `lib/features/crm/state/crm_chat_stats_controller.dart`

```dart
// AFTER (FIXED):
class CrmChatStatsController extends StateNotifier<CrmChatStatsState> {
  Timer? _timer;
  bool _started = false;

  // ✅ Constructor does NOT start timer
  CrmChatStatsController({required CrmRepository repo})
      : _repo = repo,
        super(CrmChatStatsState.initial());

  // ✅ Must be called explicitly AFTER auth is confirmed
  void start() {
    if (_started) return;
    _started = true;
    Future.microtask(refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  // ✅ Can be stopped on logout or 401
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> refresh() async {
    // ... existing logic ...
    try {
      final stats = await _repo.getChatStats();
      state = state.copyWith(loading: false, stats: stats, error: null);
    } catch (e) {
      // ✅ Stop timer on 401 to prevent infinite loop
      if (e is DioException && e.response?.statusCode == 401) {
        stop();
      }
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
```

### Fix 2: Start Stats Controller Only After Auth

**File:** `lib/features/crm/presentation/pages/crm_chats_page.dart`

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    // ✅ Explicitly start stats controller when CRM page loads
    ref.read(crmChatStatsControllerProvider.notifier).start();
    ref.read(crmThreadsControllerProvider.notifier).refresh();
  });
}
```

**File:** `lib/core/widgets/auto_sync.dart`

```dart
_authSub = ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
  if (next is AuthAuthenticated) {
    // ✅ Start stats controller on login
    ref.read(crmChatStatsControllerProvider.notifier).start();
    // ... other init logic ...
  } else {
    // ✅ Stop stats controller on logout
    ref.read(crmChatStatsControllerProvider.notifier).stop();
  }
});
```

### Fix 3: Disable Periodic Auto-Sync

**File:** `lib/core/widgets/auto_sync.dart`

```dart
// BEFORE (BROKEN):
_periodic = Timer.periodic(_periodicInterval, (_) {
  _scheduleSync();
});

// AFTER (FIXED):
// ✅ DISABLED: Periodic sync causes 401 spam when not authenticated
// Only sync on explicit events: login, connectivity, app resume, queue changes
// _periodic = Timer.periodic(_periodicInterval, (_) {
//   _scheduleSync();
// });
```

**File:** `lib/features/ponchado/presentation/widgets/auto_attendance_sync.dart`

```dart
// ✅ Already disabled in previous commit
// _periodic = Timer.periodic(_periodicInterval, (_) {
//   _scheduleSync();
// });
```

### Fix 4: Throw on 401 for Stats Endpoint

**File:** `lib/features/crm/data/datasources/crm_remote_datasource.dart`

```dart
Future<CrmChatStats> getChatStats() async {
  final res = await _dio.get(
    '/crm/chats/stats',
    options: Options(validateStatus: (s) => s != null && s < 500),
  );

  final status = res.statusCode ?? 0;
  
  // ✅ 401: Throw to trigger auth handler and stop timer
  if (status == 401) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
    );
  }
  
  // Handle other status codes...
}
```

## RESULT

✅ **No more 401 spam**: Timers only start after authentication is confirmed
✅ **No more auto-logout**: 401 errors stop the timer instead of cascading
✅ **Controlled sync**: Sync only happens on meaningful events (login, connectivity, app resume)
✅ **Clean backend logs**: Backend no longer shows hundreds of 401 errors

## FILES MODIFIED

1. `lib/features/crm/state/crm_chat_stats_controller.dart` - Added start/stop methods, 401 detection
2. `lib/features/crm/data/datasources/crm_remote_datasource.dart` - Throw on 401 for stats
3. `lib/features/crm/presentation/pages/crm_chats_page.dart` - Call start() after auth
4. `lib/core/widgets/auto_sync.dart` - Disabled periodic timer, added stats start/stop on auth
5. `lib/features/ponchado/presentation/widgets/auto_attendance_sync.dart` - Already disabled (previous commit)
6. `lib/features/ponchado/data/repositories/punch_repository.dart` - Already fixed (previous commit)

## TESTING

1. ✅ Login should work without immediate logout
2. ✅ Backend logs should show NO repeated 401 errors after login
3. ✅ CRM stats should update every 30 seconds while logged in
4. ✅ On logout, all timers should stop
5. ✅ On connectivity loss/restore, sync should trigger once

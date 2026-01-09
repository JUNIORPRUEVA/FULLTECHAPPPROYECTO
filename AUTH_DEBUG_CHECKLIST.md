# Auth Debug Checklist (Windows)

Use this to reproduce and verify the login → logout loop fix.

## Preconditions
- Run a debug build on Windows.
- If you use manual server selection (Configuración → Servidor), choose the target backend first.

## Expected debug logs (high-signal)
- On login success:
  - `[AUTH] login: success token=…XXXXXX userId=... empresaId=... role=...`
- On startup:
  - `[AUTH] bootstrap()`
  - `[AUTH] bootstrap: no session` OR `[AUTH] bootstrap: token=…XXXXXX ... baseUrl=...`
- On any 401/403 from API:
  - `[AUTH][HTTP] 401|403 METHOD /path ... baseUrl=...`
  - Optional: `[AUTH][HTTP] response=...`
- On logout triggered by code:
  - `[AUTH] logout()` and a stack trace

## Repro steps
1. Start the app (debug) and login.
2. Confirm you land on the main screen (CRM) without bouncing back.
3. Navigate to Configuración.
4. If your role allows it, open “Permisos de usuarios”.
5. Observe console logs for any `[AUTH][HTTP] 401`.

## Verification steps (persistence)
1. Login.
2. Close the app completely.
3. Re-open the app.
4. Expected: you go to the app (not login), and `[AUTH] bootstrap: token=…` appears.

## Verification steps (manual server switching)
1. Login on Backend A.
2. Switch server to Backend B (Configuración → Servidor).
3. Expected: you may need to login for Backend B, but your Backend A session should NOT be wiped.
4. Switch back to Backend A.
5. Expected: auto-restores the previous session for Backend A.

## If it still loops
- Find the first `[AUTH][HTTP] 401 ...` after login.
- Note `baseUrl=...` and the path.
- If the unauthorized event is ignored, you should see:
  - `[AUTH] unauthorized event ignored after /auth/me ok ...`
- If the token is invalid, you should see:
  - `[AUTH] token invalid after /auth/me 401 -> logout`

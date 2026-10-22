# Gringott Open Banking Sandbox

Standalone fictional bank API for testing GeoBridge. Synthetic data only. Not an official TBC/BOG service and not a certified implementation of Georgian Open Banking. No real money moves.

## Contents

```text
gringott-sandbox/
  server.js               # HTTP API and private administration
  public/                 # API console with protected OFF/ON controls
  tests/smoke.cjs          # Actual HTTP workflow and outage tests
  scripts/create-secret.sh
  docs/API_REFERENCE.md
  docs/DEPLOYMENT.md
  Dockerfile
  compose.yaml            # Private Docker network; loopback-only port
  .github/workflows/test.yml
  .gitignore
  .dockerignore
  package.json
```

No third-party npm dependencies. Local: Node 18+; recommended/tested runtime Node 24. Docker uses Node 24.

## Run locally on Windows

Open PowerShell in this folder:

```powershell
$env:GRINGOTT_ADMIN_KEY = node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
$env:GRINGOTT_ADMIN_KEY | Set-Clipboard
npm start
```

Open http://127.0.0.1:4173. Paste the copied key into Private administration to unlock logs, resets, faults and API OFF/ON. Do not send the key in chat or commit it. Ctrl+C stops the server. Without a configured key, normal synthetic APIs still work but admin endpoints return 503.

```powershell
npm test
```

Tests start/stop an isolated mock on port 14173 and verify consent, token replay denial, AIS, pagination faults, revocation, admin authorization, silent outage, 503 outage and recovery.

## What you can test

- Synthetic accounts, balances and paginated transactions.
- Simulated consent -> authorization code -> access token -> revocation.
- Optional repeated pagination, revoked-consent bypass, malformed errors and slow responses.
- API OFF: health/AIS/OAuth stop responding until the client's timeout. Admin controls remain reachable.
- API ON: subsequent requests respond again. Pending outage requests may fail; clients should retry.
- Reports in GeoBridge: availability checks, repeated outage detection and recovery require deploying the separate GeoBridge availability-monitoring update.

## Publish and host

Follow [GitHub and DigitalOcean deployment](docs/DEPLOYMENT.md). This folder is the repository root: upload only its contents. Secrets are generated on the server, not shipped with the project. No Git repository or cloud resource is created automatically.

Use a private Docker network on the same server as GeoBridge. The Compose port mapping exposes the console only on 127.0.0.1; access it through an SSH tunnel. Do not open port 4173 publicly. Default 128 MiB/0.25 CPU limits are starting limits; observe actual resource usage.

## API and environment

See [API reference](docs/API_REFERENCE.md).

| Variable | Default | Purpose |
|---|---|---|
| HOST | 127.0.0.1 | Local binding; Docker uses 0.0.0.0 inside container |
| PORT | 4173 | HTTP listener |
| GRINGOTT_ADMIN_KEY | empty | Private admin key, at least 32 bytes |
| GRINGOTT_ADMIN_KEY_FILE | unset | Read key from secret file; preferred for Docker |

Admin calls require X-Gringott-Admin-Key. GET/POST /api/admin/availability reads/sets `online` and optional `mode` (`no_response` or `http_503`). Faults are separate from outage mode. Reset clears synthetic test state/faults; restore availability explicitly with API ON. Restart resets all state, including availability to ON.

## Boundaries

OAuth is simulated, without production client registration, callback validation, PKCE, mTLS or JWS. Wire transactions intentionally remain a flat list; GeoBridge's common AIS mapping needs an explicit adapter. The OpenAPI schema is a subset. Same-host timings are synthetic and do not establish real bank performance or SLA. Admin scenario summaries are illustrative; validate behavior with actual API requests. No license or third-party bank endorsement is implied.

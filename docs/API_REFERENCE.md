# Gringott Open Banking Sandbox — Mock Bank A (Georgian Open Banking test mock)

**Developer sandbox with a visual API console. No customer banking website or real banking service is provided.** Gringott is a fictional bank for GeoBridge to send HTTP requests to and evaluate responses.

- Synthetic accounts, balances and transaction history.
- Consent creation, simulated authorization-code flow, bearer tokens and revocation.
- Account information (AIS) endpoints and simulated payment initiation (PIS).
- JSON responses, `X-Request-ID` correlation, request audit log and OpenAPI document.
- Target profile: Georgian Open Banking integration concepts, using the Bank of Georgia public XS2A API documentation / NextGenPSD2 XS2A Framework 0.8 as a reference point. This is a mock subset, not a full implementation of every Georgian profile requirement.
- Optional, reproducible fault injection is available for validator testing: revoked-consent bypass, repeated pagination, malformed error payloads and slow responses. These defects are OFF by default; enable them deliberately for negative testing.
- No real accounts, customer data, credentials or money movement.

The API is designed to resemble the relevant Georgian Open Banking / NextGenPSD2-style contract, but it is intentionally a bounded mock and is not certified or guaranteed fully conformant to any complete Georgian profile. Confirm the exact profile/version and compare schemas, headers, OAuth/security requirements, consent lifecycle and error mappings before using formal conformance scoring. The optional defects are for testing GeoBridge detection, not claimed requirements of the standard. OAuth is simulated, not production OAuth/OIDC, mTLS or JWS.

## Requirements

Node.js 18+; no third-party npm dependencies are required.

## Run on Windows

1. Extract the ZIP.
2. Open the extracted `gringott-open-banking-sandbox` folder in File Explorer.
3. Click the address bar, type `cmd`, and press Enter.
4. Run `npm start`.

The visual developer console and API listen at `http://localhost:4173`. Open that URL in a browser to use the API Explorer and request console.

## API quick checks

```bash
curl -i http://localhost:4173/api/health
curl -i http://localhost:4173/api/metadata
curl -i http://localhost:4173/openapi.json
```

## Consent and authorization flow

1. Create consent:

```bash
curl -s -X POST http://localhost:4173/api/v1/consents -H "Content-Type: application/json" -H "X-Request-ID: gb-test-001" -d '{"permissions":["accounts","balances","transactions"]}'
```

2. Copy `consentId` from the response and open the returned `/oauth/authorize?consentId=...` URL in a browser. This simulates the authorization redirect and returns a one-time code in the redirect URL. No customer UI is served by the sandbox; the redirect is a test mechanism only.

3. Exchange the code:

```bash
curl -s -X POST http://localhost:4173/oauth/token -H "Content-Type: application/json" -d '{"code":"PASTE_AUTHORIZATION_CODE"}'
```

4. Use the returned access token:

```bash
curl -i http://localhost:4173/api/v1/accounts -H "Authorization: Bearer PASTE_ACCESS_TOKEN" -H "X-Request-ID: gb-test-002"
```

## Implemented endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/health` | Health check |
| GET | `/api/metadata` | Bank identity and capabilities |
| GET | `/openapi.json` | OpenAPI 3.0.3 description of the implemented subset |
| POST | `/api/v1/consents` | Create consent |
| GET | `/api/v1/consents/{consentId}/status` | Consent status |
| DELETE | `/api/v1/consents/{consentId}` | Revoke consent |
| GET | `/oauth/authorize?consentId=...` | Simulated authorization and redirect |
| POST | `/oauth/token` | Exchange one-time code for access token |
| GET | `/api/v1/accounts` | List accounts |
| GET | `/api/v1/accounts/{accountId}` | Account details |
| GET | `/api/v1/accounts/{accountId}/balances` | Balances |
| GET | `/api/v1/accounts/{accountId}/transactions?limit=3&offset=0` | Paginated transactions |
| POST | `/api/v1/payments/payments/domestic` | Create simulated payment instruction |
| GET | `/api/v1/payments/{service}/{product}/{paymentId}/status` | Payment status |

## Synthetic fixture details

- `acc_1001`: GEL everyday account
- `acc_1002`: GEL savings account
- `acc_1003`: EUR travel account

The in-memory state resets when the server restarts. Payments are simulated and never move funds. Keep this sandbox on localhost or behind appropriate access controls; do not expose it publicly without adding authentication, rate limits and network restrictions to administrative routes.


## Fault injection (negative tests)

Use the API Explorer to POST JSON to `/api/admin/defects`. Example body:

```json
{
  "revokedConsentBypass": true,
  "repeatPagination": true,
  "malformedErrors": true,
  "slowResponse": true
}
```

Set any flag to `false` to disable that fault. `POST /api/admin/reset` clears test state and disables all faults. Administrative endpoints require X-Gringott-Admin-Key. They are disabled unless GRINGOTT_ADMIN_KEY (32+ bytes) or GRINGOTT_ADMIN_KEY_FILE is configured. Never expose this sandbox publicly.




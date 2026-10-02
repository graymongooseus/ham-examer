# Companion website sync contract

The iOS app is fully offline-capable. Its local state and deterministic mock-exam generator are aligned with the companion website's verified v2 state so the same seed, original answer indices, and timestamps can be exchanged safely when native authentication is available.

Verified website contract (read-only inspection on 2026-10-01):

- `GET /api/progress` returns `{ revision, updatedAt, state, user: { email } }`.
- `PUT /api/progress` accepts `{ baseRevision, state }` and returns HTTP 409 plus the latest state on revision conflict.
- The state is version 2 with per-question timestamps, absolute exam start time, a 32-bit exam seed, and `examUpdatedAt` tombstones.
- Account ownership comes exclusively from the hosting layer's verified `oai-authenticated-user-id` header. A client must never set or imitate that header.
- The hosted web login routes are `/signin-with-chatgpt?return_to=/` and `/signout-with-chatgpt?return_to=/`.

## Remaining native-auth block

The current hosting contract does not expose a documented native bearer-token or callback handoff. `ASWebAuthenticationSession` cannot safely transfer the website's authenticated cookie into an app-owned `URLSession`, and the app must not scrape cookies or extract browser credentials. Therefore live account sync is intentionally disabled until the hosted service supplies an officially supported native authentication handoff. No endpoint, header, token, or credential has been invented.

Once that capability exists, add a sync transport behind the local store using the contract-ready `WebProgressState`, handle 401 by returning to local/offline mode, and resolve 409 responses using the website's timestamp merge rules.

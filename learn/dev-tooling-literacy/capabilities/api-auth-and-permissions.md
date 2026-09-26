---
title: API credentials, authentication, and permissions
module_id: dev-tooling-literacy
capabilities:
  - api-auth-and-permissions
context7_library:
context7_queries:
official_sources:
  - https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: practice-guidance-with-official-anchors
---

## What it is

When an app or an AI coding agent talks to an external service (a payment provider, an email service, a data source), two separate checks happen:

- **Authentication** — "Who are you?" The service confirms the identity of the caller, usually via a credential such as an API key or token. The API key acts like a username-and-password combined into one string the app presents on every request.
- **Authorization (permissions)** — "Are you allowed to do this?" Even a verified identity may only be permitted to read, or to read some things and not others, or to take certain actions.

These are distinct gates. A credential being *valid* does not mean the caller is allowed to do everything. Many services let you create keys with scoped, limited permissions (for example, "read-only"), and a well-configured integration should receive only the access it actually needs — nothing more.

## When it is useful

This recognition matters when:

- An agent asks you for an API key, token, or other credential so it can wire up an integration.
- An agent proposes code that embeds credentials directly in application files, rather than loading them from configuration.
- A request to a service fails with an error you need to interpret — was the credential rejected (authentication) or was the credential fine but the action not permitted (authorization)?
- You are deciding how much access to grant a new integration, or reviewing what an existing one has.

## Prerequisites

- Recognition of HTTP requests and responses (methods, headers, status codes) — credentials travel inside requests, and many auth/permission failures show up as HTTP status codes.
- Awareness that `.env` files and environment variables are a common configuration convention — and that they are not a secure vault.
- The general tooling literacy of recognizing what an agent is configuring, without needing to write the integration yourself.

## Current syntax

There is no single syntax to learn at recognition level. What you will recognize in agent-provided code or config:

- A credential being supplied as a **header** on an HTTP request (common patterns include an `Authorization` header, often carrying a token such as a "bearer" token, or a vendor-specific header carrying an API key).
- A credential being read from an **environment variable** or `.env` entry (e.g. something like `MY_SERVICE_API_KEY=...`) rather than typed directly into code.
- A **scoped key** created in a service's dashboard, where you tick what the key may do (read, write, admin) before copying it into your project.
- An HTTP **status code** in a response that signals the failure type: `401` for failed/unrecognized authentication, `403` for authenticated-but-not-allowed (authorization).

## What happens (local and remote)

- **Locally:** the integration code loads a credential (from environment/config, ideally) and attaches it to outgoing requests. Nothing about the credential is "used up" locally; the local code just presents it.
- **Remotely:** the service first checks the credential (authentication). If it passes, the service checks whether that identity may perform the specific requested action (authorization). Only then does the actual work happen.
- **Consequences:** a leaked or over-privileged key can allow someone else to act as you against that service — reading data, sending messages, or charging accounts. This is why credentials are treated as secrets: same discipline as `.env` hygiene, but with the added rule of requesting *minimal* access.

## Practical example

An annotated, recognition-level sketch of what an agent might produce:

```
# .env  (kept out of the codebase; loaded at runtime)
MAIL_SERVICE_API_KEY=abc123...        # the credential — a secret, not to be shared or committed

# in the app's request to the service (agent-written, you just recognize it):
GET /v1/emails
Authorization: Bearer abc123...       # authentication: "this caller is the account the key belongs to"
                                      # the service then checks authorization:
                                      #   reading email list → allowed for this key → 200 OK
                                      #   DELETE /v1/emails/42 → this key is read-only → 403 Forbidden
```

What to notice:

- The key is stored in configuration, not pasted into the code that runs the request.
- The same valid credential produced both a success (`200`) and a rejection (`403`) — that is the difference between authentication and authorization in action.
- When creating the key in the service's dashboard, choosing "read-only" is what made the `403` possible — the key only had the access it needed.

## Explanation guidance

### Essential

- Authentication answers "who are you"; authorization answers "what are you allowed to do." Both must pass for a request to succeed.
- An API key or token is a credential: a secret that stands in for your identity. Treat it like a password.
- When an agent asks for a credential, note *which* credential, for *which* service, and with *what* scope — not just "give me a key."
- Prefer keys limited to what the integration actually does. A read-only key cannot delete data, no matter what code (or attacker) sends.

### Experienced-user note

- `401` vs `403` is the diagnostic pair: `401` usually means the credential itself was missing, malformed, expired, or rejected; `403` usually means the credential was accepted but the action is outside its permissions. Knowing which one you got tells you whether to fix the credential or the key's scope.
- Scoped or limited-scope keys (created with only the permissions an integration needs) are the standard practice for third-party integrations — the principle that an integration should receive only the access it needs is a recurring theme in REST security guidance.
- If an agent proposes embedding a credential directly in code, that is a recognizable anti-pattern: credentials belong in environment/config, following the same discipline as the `.env` lesson — with the additional rule that they are never casually shared or committed.

### Optional deeper context

- Larger systems separate *who* (identity), *what they may do* (permissions/scopes), and *what a particular token is allowed to carry* (token scope) — the same credential can carry narrower rights than its owner. This is why a service can accept your key but still refuse an action.
- Credential rotation (replacing a key periodically or after suspected exposure) and revocation (killing a key in the dashboard) are the operational counterpart of treating keys as sensitive.
- The OWASP REST Security Cheat Sheet covers these practices — including authorization checks and minimizing exposure of services and credentials — as applied security guidance for real-world API integrations.

## Cautions and common failures

- **Do not paste credentials into chat, code, screenshots, or commit messages.** A key shared casually is a key that must be treated as compromised.
- **Do not approve a request for a full-access ("admin" or "all permissions") key when the integration only reads or sends.** Ask what the integration actually does; grant that.
- **Confusing `401` with `403`:** re-creating the key won't fix a permissions problem, and re-scoping the key won't fix a bad credential. Match the fix to the failure type.
- **Assuming a valid key means "everything works":** authentication passing is only the first gate; authorization failures come after it and look like normal errors.
- **Assuming the service is the only risk:** an over-privileged key in your project is a liability even if your code is never malicious — accidents, bugs, or leaked files can trigger it.
- **Storing credentials in code files that get committed:** this pairs with the `.env`/secrets lesson; environment/config loading is the recognizable correct pattern.

## Related capabilities

- .env files and secrets — where credentials live and why they are not a vault
- HTTP requests and responses — the transport that carries credentials and status codes
- APIs, endpoints, REST — what the integration is actually talking to
- Database connections and connection strings — connection settings can carry credentials too
- Containers and sandboxes — what an isolated environment can and cannot make safe

## Official sources

- OWASP REST Security Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html

## Provenance

- Module: dev-tooling-literacy (D32 frozen page contract). Cross-language, cross-tool recognition-level content; no programming-language fundamentals.
- Anchor source: OWASP REST Security Cheat Sheet (authentication vs. authorization, least-privilege integrations), from the module's verified grounding facts.
- Status: current as of 2026-09-20; claim class everyday; safety class normal; version fall-2026-0.1.0.
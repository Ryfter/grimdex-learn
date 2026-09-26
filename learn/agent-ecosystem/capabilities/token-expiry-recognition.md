---
title: When tokens expire (and how it looks)
module_id: agent-ecosystem
capabilities:
  - token-expiry-recognition
context7_library: /websites/platform_claude_en
context7_queries:
  - "OAuth access token expiry and refresh tokens in the Claude platform docs"
  - "why does an agent tool suddenly fail to connect to a third-party service"
  - "distinguishing expired vs revoked vs insufficient-scope OAuth errors"
  - "how OAuth authorization works for remote MCP servers"
official_sources:
  - https://oauth.net/2/
  - https://datatracker.ietf.org/doc/html/rfc6749
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
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

When an agent tool connects to a third-party service (GitHub, Google Drive, Slack, or a remote MCP server) via OAuth, the connection is not permanent. OAuth **access tokens** are typically **short-lived by design**: the service hands out a credential that is only valid for a limited window, plus a longer-lived **refresh token** that lets the application obtain a new access token without re-prompting you for consent every time.

The practical consequence: at some point, an agent connection that worked yesterday will stop working. This page is about recognizing that moment for what it usually is -- an expired token -- and telling it apart from the two other common causes of "the agent suddenly can't connect": a **revoked** connection and an **insufficient-scope** error.

## When it is useful

- An agent that was working fine starts failing to reach a third-party service, and nothing changed on your side.
- You're deciding whether to re-run a login/consent flow, check a settings page, or fix a configuration -- these are three different fixes for three different problems.
- You're teaching new agent users why "it just stopped working" is normal, expected behavior of a delegated-credential system rather than a bug or a breach.
- You're connecting a remote MCP server that uses OAuth-based authorization, and the connection drops after some time.

## Prerequisites

- Familiarity with the agent-ecosystem concepts in `oauth-vs-api-keys` (delegated, scoped, revocable access) and `oauth-scopes` (what a consent screen decides).
- No programming required; the recognition skill is about reading error messages and knowing where the fix lives.

## Current syntax

There is no syntax on this page -- it's diagnostic reasoning. The "inputs" are:

- The **error message** the agent or tool reports (an auth error, a permission error, or a network/connection error).
- The **location of control**: for OAuth connections, revocation and consent live with the **third-party provider** (e.g. GitHub's "Authorized OAuth Apps" settings page, a Google Account's third-party access page, a Slack workspace's app management page) -- not with the agent tool itself.

## What happens (local and remote)

**The normal lifecycle.** You consent once; the application gets a short-lived access token plus a refresh token. While things work, the refresh token quietly keeps the access token fresh. Nothing is visibly "running."

**When the access token expires and refresh fails or isn't happening**, the next request the agent makes fails with an authentication-style error. This is the most common cause of "the agent suddenly can't connect" -- the system is working as designed; the credential simply ran out.

**The three failure modes, distinguished by the error returned:**

| Symptom | Likely cause | Where the fix lives |
|---|---|---|
| Auth error after a period of working; re-running the connect/login flow fixes it | **Expired token** | Re-run the agent tool's connect/login flow |
| Auth or permission error that persists even after reconnecting, or the app no longer appears in the provider's authorized-apps list | **Revoked connection** (by you or an admin at the provider) | The third-party provider's authorized-apps settings page -- re-authorize there or via the tool |
| The connection "works" but specific actions fail with permission/forbidden errors | **Insufficient scope** | Re-consent with the narrower-or-wider scopes actually needed |

Note that uninstalling a plugin or deleting a local config line does **not** revoke a previously granted third-party connection -- so if you "removed the tool" but the connection errors persist, the grant is probably still live at the provider. Conversely, a revocation done at the provider (or expiry) explains failures even when the agent tool's local config looks untouched.

## Practical example

You have an agent connected to GitHub. For two weeks it opens issues and reads repositories without trouble. Today it reports an authentication failure on every GitHub call.

1. **Check what the error says.** An auth/token error points at the credential; a "forbidden"/"not permitted" error on one specific action while others succeed points at scopes.
2. **Assume expiry first** -- it's the most common case. Re-run the tool's connect flow (the same OAuth consent screen you saw originally). If it works again, it was an expired token.
3. **If reconnecting doesn't help**, check the provider: GitHub's "Authorized OAuth Apps" page shows whether the connection still exists. If it was revoked there, re-authorize.
4. **If the connection works but a specific action is denied**, the granted scopes are too narrow for that action -- re-consent with the scope that task needs (narrowest that works).

## Explanation guidance

### Essential

- Access tokens are short-lived **by design**; a refresh token exists so you don't re-consent constantly.
- "The agent suddenly can't connect" is most often just an expired token. Re-running the connect flow is the first move.
- The three failure modes -- expired, revoked, insufficient-scope -- are distinguished by the **specific error returned**, and each has a different fix in a different place.
- Revocation lives with the **third-party provider**, not the agent tool. Removing the tool locally does not revoke the grant.

### Experienced-user note

- When debugging, capture the exact error text before acting: distinguishing an auth error from a forbidden error is the whole diagnostic, and providers phrase these differently.
- A token that keeps expiring faster than expected, or refresh failures repeating, can indicate the app was re-authorized elsewhere or an admin policy changed -- check the provider's app management page.
- For remote MCP servers using OAuth-based authorization, the same recognition applies: an expired token surfaces the same way as any other OAuth-connected tool (the exact MCP spec revision adding this authorization should be verified against the current MCP specification before being cited precisely).

### Optional deeper context

- OAuth 2.0's core specification (RFC 6749) is where the access-token/refresh-token model is formally defined; reading it is optional but explains *why* the design favors expiring credentials over static ones (contrast with the API keys covered in `oauth-vs-api-keys`).
- In team settings, an org admin can revoke grants for everyone from the provider side -- a whole team's agent connections can break simultaneously with no local change, and the diagnosis is the same.

## Cautions and common failures

- **Don't assume a hack or a bug.** Most sudden connection failures are routine expiry. But do read the error: a persistent failure after reconnecting deserves a look at the provider's settings page.
- **Don't fix scope problems by reconnecting alone.** If the consent flow grants the same narrow scopes, the action will still fail -- you need to consent to the (narrowest sufficient) scope for that action.
- **Don't expect local cleanup to revoke anything.** Deleting config lines or uninstalling a plugin leaves the third-party grant live at the provider until revoked there.
- **Don't hard-code assumptions about error strings.** Providers phrase expiry/revocation/scope errors differently and change wording over time; treat the *category* (auth vs. forbidden vs. not-found) as the signal, not exact text.
- **Repeated re-consenting is a signal, not a nuisance.** If you're re-authorizing far more often than the token lifetime implies, something is interfering with refresh -- check the provider page before clicking through consent again.

## Related capabilities

- `oauth-vs-api-keys` -- why delegated OAuth is used for third-party connections at all, versus static API keys.
- `oauth-scopes` -- the consent screen's scope list is the actual privacy decision; expiry diagnosis often ends in a scope fix.
- `mcp-remote-servers` -- remote MCP servers can surface the same OAuth consent and expiry behavior as any third-party connection.
- `token-revocation-hygiene` -- the deliberate counterpart: where to go (the provider's settings) to revoke a connection you no longer want.
- `tools-and-agent-actions` (prompt-engineering module) -- permission prompts and allowlists for local agent actions; a separate safety layer from OAuth consent.

## Official sources

- OAuth 2.0 overview: https://oauth.net/2/
- RFC 6749 (The OAuth 2.0 Authorization Framework): https://datatracker.ietf.org/doc/html/rfc6749
- Anthropic platform docs, agent skills overview (Skills/plugins context referenced above): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Provenance

The access-token/refresh-token lifecycle, the expired/revoked/insufficient-scope distinction, the location of revocation with the third-party provider, and the non-effect of local uninstall on live grants are all from the module's grounding facts (research synthesis independently converged on by two models, consistent with OAuth 2.0's documented design in RFC 6749 / oauth.net). The general point that remote MCP servers can use OAuth-based authorization is real and current per the grounding facts, but the **exact MCP spec revision date** for that authorization was flagged as needing live verification -- it is deliberately not cited precisely here. Error-message wording varies by provider and is described by category rather than by quoted string. Page drafted fall-2026; re-verify provider-specific settings-page names and the MCP authorization spec revision before public release.
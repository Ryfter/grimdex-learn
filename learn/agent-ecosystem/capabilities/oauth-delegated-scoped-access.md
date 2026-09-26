---
title: "OAuth: borrowed, scoped, revocable access"
module_id: agent-ecosystem
capabilities:
  - oauth-delegated-scoped-access
context7_library: /websites/platform_claude_en
context7_queries:
  - "Why does connecting an agent tool to GitHub or Google Drive show an OAuth consent screen instead of asking for an API key?"
  - "What do OAuth scopes mean on a consent screen when granting an agent access to a third-party service?"
  - "Where do I revoke an OAuth connection an agent has to a third-party service?"
official_sources:
  - https://oauth.net/2/
  - https://datatracker.ietf.org/doc/html/rfc6749
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

OAuth is the standard mechanism for **delegated, scoped, revocable** third-party access. It answers a specific question: *how can an application act on a user's behalf at another service (GitHub, Google Drive, Slack, etc.) without the user handing over their password or a full-access key?*

The three properties matter together:

- **Delegated** — the access belongs to the user, but is exercised by a different application (here, often an agent or agent tool) at a third-party service.
- **Scoped** — the grant covers specific permissions, not the whole account. The scope list on the consent screen is the actual privacy decision: what the connected application can read, write, and act on.
- **Revocable** — the user (or an administrator) can end the grant later, from the service's own settings.

This contrasts with an **API key**, which is typically a static, long-lived, often broad-scope credential: whoever holds it can act as the key's owner. OAuth exists precisely because that model is a poor fit for "let this one app read my repos for a while, and let me take it away when I change my mind."

## When it is useful

Any time you connect an agent (or an agent's tool) to a third-party service on your behalf. This is why the connection flow for GitHub, Google Drive, Slack, and similar services so often surfaces an **OAuth consent screen** rather than a "paste your API key" box: the connection needs scoped, revocable delegated access, not a raw credential.

Typical situations:

- Connecting an agent tool to read or write a specific repository, calendar, or document store.
- Connecting to a **remote MCP server** over HTTP — MCP's specification added OAuth-based authorization for remote servers, so the same kind of consent flow can appear there as with any other third-party connection.
- Reviewing what an already-connected agent integration is allowed to do, or shutting one off.

## Prerequisites

- An account at the third-party service being connected.
- No programming required to *use* an OAuth consent flow — but understanding the consent screen itself (scopes, approval, revocation) is the actual skill.
- Basic familiarity with what an API key is, so the contrast is meaningful.

## Current syntax

There is nothing to type here — OAuth is a protocol your tools implement, not a command you run. The artifacts you actually interact with are:

- A **consent screen** listing scopes, with an explicit Approve/Allow action.
- The third-party service's own management page listing your granted connections (e.g. GitHub's "Authorized OAuth Apps" settings page, a Google Account's third-party access page, a Slack workspace's app management page).

Mechanically, OAuth issues short-lived **access tokens**; a longer-lived **refresh token** obtains new access tokens without re-prompting you for consent each time. You do not manage these tokens directly in everyday use.

## What happens (local and remote)

1. Your agent tool asks to connect to a service (GitHub, Drive, Slack, a remote MCP server).
2. The service shows a consent screen naming the application and the scopes it requests.
3. On approval, the service issues a scoped access token (plus a refresh token) to the tool — not your password, and not a full-access key.
4. The tool acts within those scopes, refreshing the token as it expires.
5. The grant remains live until it is **revoked at the third-party provider's own settings page** — or until the connection fails for another reason (expired token, insufficient scope).

Important: revocation lives with the provider, not with your agent tool. Uninstalling a plugin or deleting a local config line does **not** revoke a previously granted third-party connection.

## Practical example

You connect an agent tool to GitHub so it can open pull requests on your behalf. A consent screen appears requesting repo-related scopes for that specific application.

- The narrow scope that covers "read and push to repositories I choose" is the right grant; a request for full account access deserves more scrutiny.
- You approve. The agent now works within those scopes.
- Weeks later the agent "suddenly can't connect." You check the failure: an expired access token (which the refresh token normally handles transparently) is different from a revoked connection or an insufficient-scope error — the specific error message distinguishes them.
- When you're done with the tool, you revoke the grant on GitHub's own "Authorized OAuth Apps" page. Uninstalling the tool locally would not have done this.

## Explanation guidance

### Essential

- OAuth solves a different problem than API keys: **delegated, scoped, revocable** access on a user's behalf — not "who holds a static credential."
- The consent screen's **scope list is the privacy decision**. Grant the narrowest scope that still works; treat "full account access" requests with more scrutiny than narrow ones like "read this one repository."
- Access tokens are typically **short-lived by design**; refresh tokens keep the connection working without re-prompting you.
- Revocation happens at the **third-party provider**, not in the agent tool. Removing the tool locally does not undo a grant.

### Experienced-user note

- Distinguish three failure modes that look identical ("the agent can't connect"): an **expired token**, a **revoked connection**, and an **insufficient-scope** error. The specific error returned tells you which — and they have different fixes (wait for refresh vs. re-authorize vs. re-connect with broader scopes).
- When connecting a remote MCP server over HTTP, expect the same OAuth consent flow as any other third-party service; the grant is scoped the same way.

### Optional deeper context

- OAuth 2.0 is standardized in RFC 6749; oauth.net/2 is the protocol's home page. Reading the spec is optional for everyday use — the consent screen and the provider's app-management page are the surfaces that matter.
- MCP's specification added OAuth-based authorization for remote servers in a documented spec revision; the concept is current, but cite the exact revision date only after checking the current MCP specification site.

## Cautions and common failures

- **Treating "approve" as a formality.** The scope list is the actual grant. Read it.
- **Assuming uninstalling a tool revokes access.** It does not. Revoke at the provider's settings page.
- **Misdiagnosing connection failures.** Expired token ≠ revoked grant ≠ wrong scope; the error message is the differentiator.
- **Granting broad scopes "because it's easier."** A full-access grant converts a scoped delegation into something much closer to handing over a key.
- **Hard-coding assumptions about spec details.** Exact MCP OAuth spec revision dates and beta header strings shift; verify before relying on them.

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering module) — permission prompts and allowlists for agent actions, the safety lever for what an agent may do locally.
- `mcp-remote-servers` — remote MCP servers can surface OAuth consent flows for their authorization.
- `api-keys-and-credentials` — the static-credential model OAuth contrasts with.

## Official sources

- OAuth 2.0 protocol home: https://oauth.net/2/
- OAuth 2.0 authorization framework (RFC 6749): https://datatracker.ietf.org/doc/html/rfc6749
- MCP specification (for OAuth-based authorization of remote servers — verify exact revision before citing): https://modelcontextprotocol.io

## Provenance

- Core OAuth framing (delegated, scoped, revocable; API-key contrast; scopes as the privacy decision; token expiry/refresh; revocation living with the provider; expired/revoked/insufficient-scope distinction) is the module's research synthesis, independently converged on by two research models and anchored to OAuth's own public documentation (oauth.net/2, RFC 6749).
- The claim that remote MCP servers use OAuth-based authorization per a spec revision is real and current, but the **exact revision date was not verified in this session** — check the current MCP specification site before citing a precise date.
- Provider-specific settings pages (GitHub "Authorized OAuth Apps", Google third-party access, Slack app management) are cited as illustrative examples of where revocation lives; verify exact page names if quoting them verbatim.
- No CLI commands, API flags, or vendor-specific OAuth configuration details are claimed here beyond the grounding facts.
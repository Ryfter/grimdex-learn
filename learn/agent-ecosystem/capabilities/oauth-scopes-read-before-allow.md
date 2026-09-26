---
title: "Scopes: read before you click Allow"
module_id: agent-ecosystem
capabilities:
  - oauth-scopes-read-before-allow
context7_library: /websites/platform_claude_en
context7_queries:
  - How do OAuth consent screens and scopes work when connecting an agent tool to a third-party service?
  - What is the difference between an API key and OAuth delegated access?
  - Where do users revoke third-party OAuth connections for services like GitHub?
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

When you connect an agent tool to a third-party service -- GitHub, Google Drive, Slack, or a remote MCP server -- you are most often shown an **OAuth consent screen**. The central element of that screen is the **scope list**: the specific set of permissions the application is requesting.

The scope list is the actual privacy decision you are making. It defines what the connected application can read, write, and act on your behalf. Everything else on the screen (logos, descriptions, "Continue" buttons) is presentation; the scopes are the substance.

An API key is a static, usually long-lived, often broad-scope credential: whoever holds it can act as its owner. OAuth exists for a different problem -- **delegated, scoped, revocable** access, where an application gets limited permission to act on a user's behalf without ever receiving the user's password or a full-access key. Scopes are how that limitation is expressed.

## When it is useful

Read scopes carefully whenever:

- An agent tool or plugin asks to connect to a third-party service and a consent screen appears.
- You are setting up a remote MCP server connection that surfaces an OAuth flow (MCP's specification added OAuth-based authorization for remote HTTP servers).
- You are choosing between connecting via OAuth and pasting in an API key -- if the task only needs scoped, revocable access, OAuth with narrow scopes is the safer shape.

The discipline applies at two moments: **before** clicking Allow (is this scope set appropriate?) and **later** (can I narrow this, or revoke it entirely?).

## Prerequisites

- Basic familiarity with what an agent tool is and how it gains capabilities (see the agent-ecosystem module's coverage of CLI tools and MCP).
- No coding required. This is a decision-making discipline, not a programming task.
- Access to the third-party provider's account settings page, since revocation lives there.

## Current syntax

There is no command syntax for this capability. The "interface" is the consent screen itself. The practical pattern is:

1. Pause at the consent screen; do not click Allow reflexively.
2. Read each scope line. Ask: what could this application do with this permission?
3. Compare broad scopes ("full account access") against narrow ones ("read this one repository").
4. If a narrower option exists that still accomplishes the task, prefer it.
5. Note where you would go to revoke this connection later (the provider's settings, not the agent tool).

## What happens (local and remote)

**When you click Allow**, the third-party provider issues the application a delegated grant. OAuth access tokens are typically **short-lived by design**; a longer-lived **refresh token** lets the application get a new access token without re-prompting you for consent each time. This is why a connection can keep working across sessions without repeated prompts.

**Scoping happens server-side.** The provider enforces the scopes you granted: a token with "read repository contents" scope simply cannot perform write actions, no matter what the requesting application tries.

**Revocation lives with the provider.** GitHub's "Authorized OAuth Apps" settings page, a Google Account's third-party access page, a Slack workspace's app management page -- these are where a granted connection is revoked. Uninstalling a plugin or deleting a local config line does **not** revoke a previously granted third-party connection.

**When the agent suddenly can't connect**, the cause is often simply an expired access token -- distinguishable from a revoked connection or an insufficient-scope error by the specific error returned.

## Practical example

Suppose you connect a coding agent to GitHub so it can open pull requests on your behalf.

- A consent screen requesting **read access to a single repository** is a narrow, task-appropriate scope. Clicking Allow is a small, reversible decision.
- A consent screen requesting **full control of all repositories, plus access to your account profile and email** is a broad scope. It may still be legitimate -- some tools genuinely need it -- but it deserves more scrutiny: can the tool do its job with less? Is the requester what it claims to be?

After granting either, if you later stop using the tool, the correct cleanup is visiting GitHub's authorized-apps page and revoking there. Deleting the agent's local configuration removes the *plumbing* but leaves the *grant* standing.

## Explanation guidance

### Essential

- The scope list on a consent screen is the privacy decision. Read it before clicking Allow.
- The core discipline: choose (or accept) the **narrowest scope that still works** for the task. Treat broad scopes with more scrutiny than narrow ones.
- OAuth grants are delegated, scoped, and revocable -- that is their entire point versus an API key.
- Revocation happens at the third-party provider's settings, not by uninstalling the agent tool or plugin.

### Experienced-user note

- Short-lived access tokens plus long-lived refresh tokens are the normal OAuth design; an "expired token" error is routine maintenance, not a security event. Distinguish it from revocation and insufficient-scope errors by the error text.
- When wiring an agent to a remote MCP server over HTTP, expect the same OAuth consent mechanics as any other third-party connection -- the scope-reading discipline applies identically.
- If a tool demands a broad scope for a narrow job, that mismatch is itself information about the tool's design (or trustworthiness).

### Optional deeper context

- OAuth 2.0 is standardized in RFC 6749; oauth.net/2/ is the canonical community reference for the flow and terminology.
- MCP's specification added OAuth-based authorization for remote (HTTP) MCP servers in a documented revision; the exact revision date should be verified against the current MCP specification before citing it precisely.
- The Claude API and Claude Code both have mechanisms (the skills container feature, Skill loading) that are unrelated to OAuth scoping -- do not conflate authorization for third-party services with capability packaging.

## Cautions and common failures

- **Clicking Allow reflexively.** Consent screens appear mid-flow and invite momentum; the scope list deserves a deliberate read every time.
- **Assuming uninstall equals revoke.** Removing a plugin or config line does not revoke a third-party connection. Revoke at the provider.
- **Confusing error types.** An expired token, a revoked connection, and an insufficient-scope error all look like "it stopped working." Read the specific error rather than re-authorizing blindly with broader scopes.
- **Granting broad scopes "to make it work."** If a task fails with a narrow scope, diagnose whether a slightly different narrow scope suffices before escalating to broad access.
- **Treating the agent tool as the security boundary.** The enforcement of what the token can do lives with the provider, per the scopes granted -- but everything within those scopes is available to the connected application.

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering module) -- permission prompts and allowlists for local agent actions; the local-side counterpart to consent-screen scoping.
- `mcp-remote-oauth-connect` (agent-ecosystem module) -- the mechanics of connecting to remote MCP servers, where this scope discipline is applied in practice.

## Official sources

- OAuth 2.0 framework: https://datatracker.ietf.org/doc/html/rfc6749
- OAuth community overview: https://oauth.net/2/
- Claude Code Skill discovery context: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Provenance

The OAuth-vs-API-key framing, scope list as the privacy decision, narrowest-scope discipline, short-lived access tokens with refresh tokens, provider-side revocation, and the expired-token-vs-revoked-vs-insufficient-scope distinction all come from the module's grounding facts (research synthesis where both contributing models converged on the same shape). The OAuth 2.0 spec (RFC 6749) and oauth.net are cited as OAuth's own authoritative references. MCP's OAuth-based authorization for remote servers is real and current, but the **exact spec revision date was not pinned in this session's research** and should be verified against the current MCP specification site before being cited precisely. Plugin bundle contents were not relevant to this page's claims and were not asserted.
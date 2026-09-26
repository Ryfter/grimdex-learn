---
title: "Where it meets: OAuth, MCP, and your agent's own login"
module_id: agent-ecosystem
capabilities:
  - oauth-mcp-and-agent-login
context7_library: /websites/platform_claude_en
context7_queries:
  - How does OAuth authorization work for remote MCP servers?
  - What happens when an agent connects to a third-party service via OAuth?
  - How are access tokens refreshed and revoked for connected agent tools?
official_sources:
  - https://modelcontextprotocol.io
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

OAuth and MCP meet in one specific place: remote MCP servers. MCP's specification added OAuth-based authorization for remote (HTTP) MCP servers, so that connecting an agent to a remote server can go through the same kind of consent flow you already know from "Sign in with GitHub" style prompts -- a consent screen listing scopes, followed by short-lived access tokens backed by refresh tokens. The concept is real and current; the exact spec revision and date should be verified against the current MCP specification site before being cited precisely (see Provenance).

There is a second, often-overlooked place you have likely already met this pattern: logging into a coding agent itself with a subscription account. That login is, from the user's point of view, the same kind of OAuth-style delegated flow -- the agent application asks the identity provider for limited access on your behalf, you approve it in a browser, and the tool holds a token rather than your password.

## When it is useful

- You are connecting an agent or coding tool to a **remote (HTTP) MCP server** and a browser window opens asking you to authorize the connection.
- A third-party connection (GitHub, Google Drive, Slack, etc.) stops working and you need to tell an expired token apart from a revoked connection or an insufficient-scope error.
- You want to understand or revoke what an agent can still access on some third-party service.
- You are explaining to someone why an agent tool asks for a browser-based sign-in rather than asking them to paste in an API key.

## Prerequisites

- Basic understanding of what an MCP server is (see the module's MCP capability page).
- Basic understanding of OAuth vs API keys: an API key is a static, long-lived, often broad-scope credential; OAuth exists for delegated, scoped, revocable third-party access.

## Current syntax

There is no syntax to learn on the user side for OAuth itself -- it is a browser consent flow, not a command. The relevant "surface" is:

- The **consent screen's scope list**, which is the actual privacy decision: what the connected application can read, write, and act on.
- The **provider's own settings page** where a granted connection lives: for example GitHub's "Authorized OAuth Apps" settings, a Google Account's third-party access page, or a Slack workspace's app management page.

For remote MCP servers, the OAuth authorization is defined in the MCP specification itself for HTTP-based transports; consult the current spec at modelcontextprotocol.io for the precise requirements.

## What happens (local and remote)

When an agent connects to a service that uses OAuth:

1. The agent application (acting as the OAuth client) redirects you to the provider's consent screen.
2. You review the **scopes** being requested and approve or deny.
3. The agent receives a short-lived **access token**, plus a longer-lived **refresh token** so it can get new access tokens without re-prompting you every time.
4. Subsequent agent actions against that service use the access token, within the approved scopes.

Crucially, **revocation lives with the third-party provider, not the agent tool**. Uninstalling a plugin, deleting a local config line, or removing an MCP server from your config does not revoke a previously granted third-party connection. To truly cut access, go to the provider's own authorized-apps page and revoke it there.

The same shape applies when you log into a coding agent with your subscription: the tool never sees your password; it holds a token it can use on your behalf, within whatever access that flow grants.

## Practical example

A common sequence, and how to read it:

- You configure an agent to use a remote MCP server. On first use, a browser window opens: "This application wants access to your repositories (read)." You approve. The agent works.
- Weeks later, the agent "suddenly can't connect." Before assuming the tool is broken, check the specific error:
  - **Expired token** -- the access token simply ran out and the refresh step failed or hasn't run; re-authenticating usually fixes it.
  - **Revoked connection** -- someone removed the app at the provider (perhaps you, on the provider's authorized-apps page); you'll need to reconnect from scratch.
  - **Insufficient scope** -- the connection works but the task needs permissions you never granted; you need to reconnect with narrower-but-sufficient scopes.

These are three different problems with three different fixes, and the error message is what distinguishes them.

## Explanation guidance

### Essential

- OAuth is for **delegated, scoped, revocable** access; API keys are static, long-lived, and broad. Agent connections to third-party services surface OAuth consent screens because scoped revocability is what's actually needed.
- The **scope list is the privacy decision**. Choose the narrowest scope that works; treat "full account access" with far more scrutiny than "read this one repository."
- **Uninstalling an agent tool does not revoke its access.** Revocation happens at the provider's own settings page.
- Logging into your coding agent with a subscription is the same OAuth-style flow you've used elsewhere -- the agent holds a token, not your password.

### Experienced-user note

- Access tokens are short-lived by design; refresh tokens exist so you aren't re-consenting constantly. If a refresh token is lost or invalidated, you'll be re-prompted -- that's expected behavior, not a bug.
- When a connection fails, train yourself to read the error class first (expired vs revoked vs insufficient scope) before changing configuration. All three look like "the agent is broken" from the outside.
- MCP's OAuth authorization applies to remote (HTTP) servers; the exact spec revision that introduced it should be verified against the current spec before you cite it precisely.

### Optional deeper context

- OAuth 2.0's core framework is standardized in RFC 6749 (datatracker.ietf.org); oauth.net/2/ is the friendlier overview. Reading either will make consent-screen vocabulary (client, scope, access token, refresh token) feel less arbitrary.
- The convergence of MCP on OAuth for remote servers is a good example of an ecosystem reusing existing, well-understood standards rather than inventing a new credential scheme -- the same reasoning explains why agent subscription logins feel familiar.

## Cautions and common failures

- **Don't treat broad scopes as fine because the tool is popular.** "Full account access" grants whatever the app (including your agent acting through it) can do with that account.
- **Don't assume deleting config revokes access.** The grant persists at the provider until revoked there.
- **Don't hard-code assumptions about the exact MCP OAuth spec revision or date** in documentation or lessons -- verify against the current spec site.
- **Expired tokens are routine, not alarming.** Distinguish them from revocations and scope errors before troubleshooting anything else.
- **Re-consenting with new scopes usually means re-running the consent flow**; a previously approved narrower grant does not automatically expand.

## Related capabilities

- `mcp-servers-basics` -- what MCP servers and their transports are.
- `cli-as-agent-tooling` -- shelling out to local CLIs, which spreads local credentials across CLI configs; OAuth-scoped MCP connections are one alternative shape.
- `oauth-vs-api-keys` (same module) -- the full API key vs OAuth comparison.

## Official sources

- MCP specification and documentation: https://modelcontextprotocol.io
- OAuth 2.0 overview: https://oauth.net/2/
- RFC 6749 (OAuth 2.0 Authorization Framework): https://datatracker.ietf.org/doc/html/rfc6749

## Provenance

- The existence of OAuth-based authorization for remote MCP servers in the MCP spec is real and current, but **the exact spec revision and date were flagged as needing live verification** in this module's research; verify against modelcontextprotocol.io before citing a specific version.
- OAuth vs API keys, scopes, token expiry/refresh, and provider-side revocation are grounded in standard OAuth concepts (oauth.net, RFC 6749); the named provider examples (GitHub "Authorized OAuth Apps", Google third-party access page, Slack app management) reflect common, widely documented provider surfaces.
- The observation that agent subscription logins follow the same OAuth-style delegated flow is a practical synthesis from this module's research (both research passes converged on it), not a quoted vendor claim.
- Provenance class: practice-guidance-with-official-anchors. Last reviewed 2026-09-20.
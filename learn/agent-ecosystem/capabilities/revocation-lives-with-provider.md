---
title: Revocation lives with the provider, not the agent
module_id: agent-ecosystem
capabilities:
  - revocation-lives-with-provider
context7_library: /websites/platform_claude_en
context7_queries:
  - Where does a user revoke an OAuth connection granted to an agent tool?
  - Does uninstalling a plugin or deleting a config entry revoke a third-party OAuth grant?
  - Why does an agent tool lose connection when an access token expires or is revoked?
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

When an agent tool connects to a third-party service (GitHub, Google Drive, Slack, etc.) via OAuth, the user grants that connection through a consent screen. The authority to revoke that grant lives with the **third-party provider**, in its own account settings -- not with the agent tool. Each provider has its own management surface for this:

- **GitHub**: the "Authorized OAuth Apps" page in the user's GitHub settings.
- **Google**: the third-party access page within the Google Account settings.
- **Slack**: the app management page for the workspace.

Revoking there cuts off the granted access at the source.

## When it is useful

Use this when an agent tool's connection to a service should be terminated permanently -- for example, after finishing a project, changing which account an agent uses, or removing access after a tool is no longer trusted. It also answers a common confusion: a user uninstalling a Claude Code plugin or deleting a local config line may assume the underlying third-party grant is gone. It is not. The provider-side settings page is the actual lever.

## Prerequisites

- An agent tool (or MCP server connection) that has been connected to a third-party service via OAuth, i.e. a consent screen was previously completed.
- The ability to log in to the third-party provider's own website/account settings (GitHub, Google, Slack, etc.).

## Current syntax

There is no command syntax for revocation itself -- it is a settings-page action at the provider. The relevant touchpoints in an agent workflow are the ones that *create* the connection (e.g. an OAuth consent screen presented by the provider when connecting a tool), and the provider-specific settings pages named above, which are reached by logging in to the provider's account settings and finding the section for authorized/connected applications.

## What happens (local and remote)

- **Local action (agent side)**: Uninstalling a plugin or deleting a config line removes the agent's local reference to the connection. It does **not** contact the provider and does **not** invalidate the grant.
- **Remote action (provider side)**: Revoking in the provider's settings (e.g. GitHub's Authorized OAuth Apps page) invalidates the grant at the source. The agent tool will then fail to connect until a new consent flow is completed.
- **Token expiry**: OAuth access tokens are typically short-lived; a refresh token obtains new access tokens without re-prompting for consent. A connection can also stop working simply because a token expired -- a different situation from a revoked grant or an insufficient-scope error, distinguishable by the specific error returned.

## Practical example

A user connects an agent tool to their GitHub account via an OAuth consent screen, granting repository-read scope. Weeks later they remove the tool locally by uninstalling the relevant plugin and deleting the local config entry. The grant still exists: GitHub's "Authorized OAuth Apps" page continues to list the application. To actually terminate access, the user must go to that GitHub settings page and revoke the application there. Only then does the provider-side grant disappear.

Conversely, if the same user wants to cut access from the provider side at any time (for instance, after noticing unexpected activity), revoking the application in GitHub's settings immediately prevents the agent tool from connecting, regardless of what remains in local configuration.

## Explanation guidance

### Essential

- Revoking a granted OAuth connection is done at the third-party provider's own settings, not in the agent tool.
- Uninstalling a plugin or deleting a local config line does not revoke the connection.
- Concrete provider surfaces: GitHub's "Authorized OAuth Apps" page, Google Account's third-party access page, Slack's workspace app management page.
- Distinguish three related but distinct failure modes by the error returned: expired token, revoked connection, insufficient scope.

### Experienced-user note

- When auditing or cleaning up agent-tool connections, check the provider-side settings pages directly rather than assuming local cleanup is sufficient -- the provider's list of authorized applications is the authoritative record of live grants.
- Token expiry vs. revocation vs. insufficient scope produce different errors; reading the error text tells you which situation you're in and whether re-consent, re-scoping, or provider-side revocation is the right response.

### Optional deeper context

- OAuth's delegated, scoped, revocable model (see RFC 6749) is what makes provider-side revocation possible in the first place: because the grant is scoped and held at the provider, the provider can honor or terminate it independently of any client-side state.
- Remote MCP servers can surface OAuth consent flows like any other third-party connection (the MCP spec added OAuth-based authorization for HTTP servers in a documented revision; verify the exact revision date against the current MCP specification site before citing it precisely).

## Cautions and common failures

- **False sense of removal**: Deleting a local config entry or uninstalling a plugin feels like "un-connecting," but the grant persists at the provider until revoked there.
- **Stale grants accumulate**: Old OAuth grants to agent tools may remain live in provider settings long after the tool itself was removed locally.
- **Confusing failure causes**: A connection that "suddenly stops working" may be an expired token rather than a revocation -- check the specific error before assuming.
- **Scope changes**: Changing the scope a tool needs may require a new consent flow at the provider; existing grants don't automatically widen.

## Related capabilities

- `oauth-scopes-are-the-privacy-decision` (this module) -- the scope list on a consent screen is the actual privacy decision; choosing the narrowest workable scope is the core discipline.
- `tools-and-agent-actions` (prompt-engineering module) -- permission prompts and allowlists govern what an agent can do with tools locally.

## Official sources

- https://oauth.net/2/
- https://datatracker.ietf.org/doc/html/rfc6749
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Provenance

The core claim -- that revocation of a granted OAuth connection lives with the third-party provider (GitHub's Authorized OAuth Apps page, Google Account's third-party access page, Slack's workspace app management page), and that uninstalling a plugin or deleting a local config line does not revoke the connection -- comes directly from the module's grounding facts on OAuth vs. API keys, token expiry, and revocation. OAuth's delegated/revocable design is anchored in oauth.net and RFC 6749. The related note on remote MCP servers surfacing OAuth consent flows is real and current, but the exact MCP specification revision date for OAuth-based authorization was flagged in the module's original research as needing live verification against the current MCP specification site; readers should check modelcontextprotocol.io before citing a precise revision date. Provider-specific settings-page names (GitHub's "Authorized OAuth Apps," etc.) reflect the providers' own account-settings surfaces as described in the grounding facts and are standard, long-standing provider features, but exact labels/placement can shift over time.
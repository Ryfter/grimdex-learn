---
title: "API keys: the static master key"
module_id: agent-ecosystem
capabilities:
  - api-keys-static-credential
context7_library: /websites/platform_claude_en
context7_queries:
  - How are API keys used to authenticate requests to the Claude API?
  - What does an API key authorize the holder to do?
  - How should API keys be stored and kept out of agent reach?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
  - https://oauth.net/2/
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

An API key is a static credential: a string issued by a service that authenticates whoever presents it as the key's owner. Three properties define the model:

- **Static** -- it does not change unless you deliberately rotate or revoke it. There is no built-in expiry, consent step, or per-use negotiation.
- **Usually broad-scope** -- a key typically carries whatever powers its owner's account has, not a narrow, task-specific slice of them.
- **Often long-lived** -- keys can stay valid for months or years, silently, until someone notices something is wrong.

The practical consequence: **whoever holds the key acts as the key's owner.** If an agent (or anything else) gets hold of a raw GitHub token, a cloud provider key, or an API key for a paid service, it can act with the full authority of whoever issued that key. There is no intermediate "this app may do X on my behalf" layer -- the key *is* the identity, at full strength.

This is not a design flaw; API keys are a perfectly good solution to a specific problem: authenticating *your own* programmatic access to a service you control or pay for. The problem this lesson sets up is that people reach for them in the wrong second scenario -- connecting a tool or agent to a *third-party* service on a user's behalf. That scenario is what OAuth (covered in the next lessons) was designed for.

## When it is useful

API keys are the right tool when:

- You are authenticating access to a service **you own or directly pay for** -- e.g. an API key for the Claude API for your own application.
- The access is machine-to-machine under your own authority, not delegated from another user.
- You control rotation and can treat the key like a password-grade secret.

They are the wrong (or at least risky) tool when:

- An agent tool needs to act on a **user's behalf** at a third-party service (GitHub, Google Drive, Slack). A raw key gives the tool the user's full account power with no scoping, no consent screen, and no revocation path separate from deleting the key itself.
- You would have to **spread the same credential across many local tool configs** to let an agent reach several services -- each copy is another place to leak it.

## Prerequisites

- General familiarity with command-line tools and environment variables.
- The tools-and-agent-actions lesson in the prompt-engineering module (for how agents acquire and use credentials once they can run commands).

## Current syntax

There is no syntax to learn in this lesson -- an API key is just a string passed with a request, conventionally in an `Authorization` header or an environment variable. The skill worth stating concretely: keep keys in environment variables or a secrets manager, never in files an agent can read (shell history, dotfiles, committed configs). Because a coding agent that can run a shell can read whatever a user can read, any key in a readable config is effectively in the agent's hands.

## What happens (local and remote)

When a program -- or an agent acting through a CLI or SDK -- presents an API key to a service:

1. The service checks the key is valid.
2. The service treats the caller as the key's owner, with the owner's full permissions and (often) billing.
3. Every action taken is attributed to the key's owner, not to "an application the owner delegated to."

There is no consent step, no scope negotiation, and no expiry by default. The failure modes follow directly: a leaked key keeps working until someone notices and rotates it, and an agent using a raw key can do anything the owner could do -- not just what the task needed.

## Practical example

A team gives a coding agent a raw cloud-provider API key in an environment variable so it can deploy. The key has the maintainer's full account scope. When the agent is asked to "clean up temp resources," a misread instruction causes it to delete more than intended -- and every deleted resource is attributed to the maintainer, because the key *was* the maintainer as far as the service was concerned. The fix is not more careful prompting; it is using a credential model with narrower, revocable delegation -- which is what the OAuth lessons cover next.

## Explanation guidance

### Essential

- An API key = static, broad-scope, long-lived. Whoever holds it acts as its owner.
- It is the right credential for *your own* access to a service you pay for.
- It is the wrong credential for delegated third-party access -- no scoping, no consent, no independent revocation.
- Because an agent with shell access can read anything its user can, a key sitting in a readable config is a key the agent holds.

### Experienced-user note

- Distinguish the credential model from the transport: MCP servers, CLI configs, and plugins all *carry* credentials; the question of whether a static key or a delegated OAuth grant is inside them is independent of the packaging.
- When auditing a setup, inventory where raw keys live versus where delegated (OAuth) connections live -- the two fail differently and revoke differently.

### Optional deeper context

- OAuth is defined in its own specification (OAuth 2.0, RFC 6749); it exists precisely to solve delegated, scoped, revocable access. Framing API keys as "the thing OAuth was invented to replace in the delegation case" is a fair mental model.
- Key rotation policies and secret-scanning tooling are mitigations for the static-key model, not reasons to prefer it for delegation.

## Cautions and common failures

- **Leaked key = full account compromise until rotated.** There is no expiry to save you; detection is your only defense.
- **Using a raw key where an OAuth grant belongs.** The tool gets full account power instead of a narrow slice, and the user gets no consent screen and no revocation page.
- **Assuming deleting a config line revokes anything.** A static key must be revoked at the issuing service. (Delegated OAuth connections, covered next, revoke at the *third-party provider*, not locally either.)
- **Spreading one key across many tool configs** to wire an agent up to several services -- each copy widens the leak surface. Structured access via an MCP server can avoid spreading local credentials across many CLI configs.

## Related capabilities

- `oauth-delegated-access` -- the contrast case: delegated, scoped, revocable access, and why consent screens exist.
- `mcp-remote-oauth` -- where MCP and OAuth meet: remote MCP servers can surface the same OAuth consent flow as any third-party connection.
- `mcp-servers-typed-tools` -- structured, self-described agent tools, including credential handling for remote servers.
- `tools-and-agent-actions` (prompt-engineering module) -- permission prompts and allowlists for what an agent may do with shell access and the credentials it finds.

## Official sources

- Claude API skill plugin install flow (example of a real API-key-authenticated integration): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
- OAuth 2.0 specification (the delegated-access model contrasted here): https://oauth.net/2/ and https://datatracker.ietf.org/doc/html/rfc6749

## Provenance

The API-key characterization (static, broad-scope, long-lived; holder acts as owner) is the module's own research synthesis, independently converged on by two models and anchored against the OAuth 2.0 specification, which defines delegated access as its explicit alternative problem. The plugin install example is Context7-verified against platform.claude.com docs. No vendor-specific claims about key rotation policies or provider dashboards are asserted here. This lesson intentionally sets up (rather than covers) the OAuth material in subsequent lessons of the module.
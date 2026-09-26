---
title: "Practicum: name that component from a real config"
module_id: agent-ecosystem
capabilities:
  - name-that-component-practicum
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Claude Code Skills work and where are they discovered from?
  - How are Claude Code plugins installed via marketplace?
  - How does the Messages API MCP connector declare mcp_servers?
  - What is the difference between an MCP server and shelling out to a CLI?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://modelcontextprotocol.io
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

A short self-test for reading real-shaped agent configuration. You are shown a config snippet or filesystem artifact and asked two things:

1. **Which component is this?** — a CLI command the agent shells out to, an MCP server, a Skill, or a plugin.
2. **What are the trust questions?** — what can it see, who maintains it, and how do I turn it off?

The snippets below are **illustrative shapes**, not authoritative file-format documentation. The goal is pattern recognition, not memorizing exact schemas.

## When it is useful

Use this when:

- You inherit a machine or repo with agent config already in it and need to know what will actually run.
- Someone shares a tool config in a README and you want to assess it before installing.
- You are writing your own config and want to confirm you've picked the right mechanism (CLI vs MCP vs Skill vs plugin) for the job.

## Prerequisites

- The agent-ecosystem concepts: what CLI tools, MCP servers, Skills, and plugins each are (see Related capabilities below).
- Basic familiarity with permission allowlists (cross-reference: `tools-and-agent-actions` in prompt-engineering).

## Current syntax

There is no syntax to learn in this lesson — only recognition. The four component shapes you will meet:

| Shape | Typical tell |
|---|---|
| CLI capability | A permission allowlist entry naming a shell command (`Bash(gh pr view:*)`) |
| MCP server | A config entry with a URL or command plus a server `name`, sometimes an auth token |
| Skill | A directory containing a `SKILL.md` file on the local filesystem |
| Plugin | An install command of the form `/plugin install <name>@<marketplace>` |

## What happens (local and remote)

- A **CLI allowlist entry** means the agent may invoke that program with your local credentials, whatever the program can reach.
- An **MCP server entry** means the agent's host runs a client that connects to that server — locally over stdio, or remotely over HTTP. Remote servers can surface OAuth consent flows; the connection and its scopes live partly at the third-party provider.
- A **SKILL.md folder** is discovered from the local filesystem and loaded by the model when it judges the skill relevant — it shapes behavior, not just tool access.
- A **plugin install** pulls a bundle that can package one or more of the above. Installing it is a packaging step; it does not itself revoke or grant third-party OAuth connections.

## Practical example

Classify each of these (answers below — try first).

**Snippet A**
```
Bash(aws s3 ls:*), Bash(jq:*)
```

**Snippet B**
```
{
  "mcpServers": {
    "docs-search": { "type": "http", "url": "https://mcp.example.com/v1" }
  }
}
```

**Snippet C**
```
my-skill/
└── SKILL.md
```

**Snippet D**
```
/plugin marketplace add some-org/some-plugins
/plugin install review-tools@some-plugins
```

**Answers**

- **A — CLI capability.** Two shell programs the agent may now run. Trust check: `aws s3 ls` can list S3 buckets using *your* credentials; `jq` is mostly inert but confirm the allowlist pattern's scope. Turn off: remove the allowlist entry.
- **B — MCP server (remote, HTTP).** Trust check: what tools does it expose, who runs `mcp.example.com`, and — because it's remote — expect an OAuth-style consent flow on first connect; the granted scopes live at the provider, not in this file. Turn off: remove the entry from config **and** revoke the connection at the provider's authorized-apps page if you granted one.
- **C — Skill.** A folder with a `SKILL.md` at a discovered path. Trust check: read the file — it's instructions the model may follow; whoever wrote it is shaping agent behavior. Turn off: remove the folder from the discovery path.
- **D — Plugin.** Marketplace + install lines. Trust check: a plugin is packaging — find out what it bundles (possibly skills, MCP servers, hooks, commands) before installing, since each bundled piece carries its own trust profile. Turn off: uninstall the plugin — but note this does not revoke any third-party OAuth connections made along the way.

## Explanation guidance

### Essential

- **Classify first, trust second.** The component type tells you *where* to look for the trust answers. CLI → local credentials and allowlists. MCP → server maintainer plus, for remote servers, OAuth scopes at the provider. Skill → the file contents. Plugin → the bundle contents.
- **The three questions, every time:** what can it see, who maintains it, how do I turn it off.
- **Removing config ≠ revoking access.** Deleting a line or uninstalling a plugin stops *future* use; OAuth connections granted to a third party are revoked at the provider's own settings pages.

### Experienced-user note

The hardest distinctions are the deliberate ones. A CLI and an MCP server can expose the same capability — `gh` via the shell vs. a GitHub MCP server — and the choice is a practical tradeoff (structured typed tools and per-server control vs. simplicity of an established CLI), not a correctness question. A plugin is never a *fourth capability type* competing with the others; it's packaging for them. And a Claude Code Skill on disk is a distinct mechanism from the Claude API's `skills` container feature — same name, different layers.

### Optional deeper context

The MCP architecture terms can mislead: the *host* application (e.g. Claude Code) runs one client per configured server; you, the user, only ever configure servers. The "client" is invisible plumbing. Similarly, MCP's Messages-API connector (`mcp_servers` with a `mcp_toolset`, behind a beta header) shows MCP is wired into the core API, not a Claude-Code-only add-on — though exact beta strings shift and shouldn't be hard-coded.

## Cautions and common failures

- **Trusting a snippet because it looks official.** An illustrative `.mcp.json` entry pointing at a plausible URL is exactly what a supply-chain attack looks like. Verify the server's operator before connecting.
- **Confusing "turn off" with "revoke."** Removing local config stops the agent using the tool; it does not revoke OAuth grants at GitHub/Google/Slack. Do both.
- **Reading a scope screen too fast.** On any OAuth consent flow — including ones surfaced by remote MCP servers — the scope list is the privacy decision. Prefer the narrowest scope that works.
- **Assuming a plugin is safe because its parts are known.** The trust question applies to the bundle as a whole and each bundled piece.
- **Memorizing exact file formats from this page.** The snippets here are shapes for recognition; check current docs for authoritative schemas.

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering) — permission prompts and allowlists, the safety lever for CLI access.
- `mcp-basics` (agent-ecosystem) — MCP architecture, host/client/server, and transports in depth.
- `oauth-vs-api-keys` (agent-ecosystem) — delegated, scoped, revocable access and the consent screen.

## Official sources

- Claude Code Skills overview (SKILL.md discovery, model-invoked): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Model Context Protocol (concept, spec, transports): https://modelcontextprotocol.io
- OAuth 2.0 (delegated authorization framework): https://oauth.net/2/
- OAuth 2.0 RFC 6749: https://datatracker.ietf.org/doc/html/rfc6749

## Provenance

The four-way classification (CLI / MCP / Skill / plugin) and the plugin-as-packaging concept are consistent across this module's research synthesis and Context7-verified Anthropic platform docs. Skill-as-SKILL.md-directory and the `/plugin marketplace add` / `/plugin install` flow are verified against the platform docs pages listed above; the same docs page demonstrates the install flow with a real shipped skill plugin.

Two deliberate imprecision flags, per the module's research: (1) the **exact full list of what a plugin can bundle** was not pinned to a single current reference page in this session — the examples in Snippet D's trust check are the commonly cited candidates (skills, MCP servers, hooks, slash commands, subagents) and should be checked against the current Claude Code plugins reference rather than treated as exhaustive. (2) MCP's **OAuth authorization spec revision date** needs verification against the current MCP specification site before being cited precisely; this page asserts only the concept (remote MCP servers can surface OAuth consent) which is current. All config snippets on this page are illustrative shapes, not literal format guarantees.
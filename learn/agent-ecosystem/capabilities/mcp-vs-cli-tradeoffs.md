---
title: "MCP vs. shelling out: when each wins"
module_id: agent-ecosystem
capabilities:
  - mcp-vs-cli-tradeoffs
context7_library: /websites/platform_claude_en
context7_queries:
  - When should an agent use MCP servers instead of running CLI commands?
  - How does the MCP connector expose typed tools to a model?
  - What are the tradeoffs between structured MCP tools and unstructured CLI output?
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

A coding agent that can run a shell already has access to every command-line program installed on the machine — `gh`, `aws`, `curl`, `jq`, and so on. The Model Context Protocol (MCP) is a separate, documented standard for giving an agent structured access to external tools and data, and it is wired into the core Anthropic Messages API via the MCP connector (a request can declare `mcp_servers` and an `mcp_toolset` tool, gated behind a beta header).

This page is about the practical choice between those two paths: when does an agent benefit from an MCP server, and when is simply shelling out to a CLI the better answer?

The core difference:

- **A CLI gives the agent unstructured text.** The agent runs a command, receives whatever the program prints, and has to interpret it — inferring success, failure, and meaning from prose, tables, or JSON the tool happens to emit.
- **An MCP server gives the agent typed, self-described tools.** The server advertises what tools exist, what parameters they take, and what they do; the agent's client discovers and calls them. Control is per-server (allow/deny a whole server's toolset), and remote servers can be reached over HTTP without local credentials.

## When it is useful

This tradeoff comes up the moment you configure an agent's capabilities:

- You already have a mature CLI for a service and are wondering whether you also need (or should write) an MCP server for it.
- You want an agent to talk to a remote service where no good CLI exists, or where installing a CLI would mean spreading API keys across many local config files.
- You want coarser, simpler safety control: allowing or blocking one MCP server as a unit, versus enumerating individual shell commands on an allowlist.

## Prerequisites

- General familiarity with what an agent's tools are and how permission prompts work (see `tools-and-agent-actions` in the prompt-engineering module — that lesson covers the allowlist/safety side and is not repeated here).
- For the MCP side: a configured MCP server (local stdio or remote HTTP/URL-based transport), declared wherever your agent host supports configuration.

## Current syntax

There is no single command here — this is a decision, not a feature. The two sides look like:

- **CLI path:** the agent invokes the shell tool it already has; no extra configuration beyond whatever permission rules govern shell use.
- **MCP path:** you configure a server (name, transport, and for remote servers an authorization token). In the Messages API connector this appears as an `mcp_servers` entry plus an `mcp_toolset` tool type, behind a beta header. The exact beta string changes over time — treat any specific value you see (e.g. `mcp-client-2025-11-20`) as illustrative, not something to hard-code as permanent.

Note on architecture: as a user you only ever configure *servers*. The MCP "client" is invisible plumbing the agent host runs — one per configured server. You never install a client separately, despite wording that sometimes suggests otherwise in docs.

## What happens (local and remote)

**CLI execution.** The agent runs a local process. Output is plain text the model must interpret. Credentials are whatever the CLI itself reads from its own local config (`gh` uses your GitHub CLI auth, `aws` uses your AWS profile, etc.).

**MCP server call.** The host's client connects to the server (spawning a local stdio process or making an HTTP connection), discovers the tool list, and exposes those typed tools to the model. For remote servers, MCP's specification added OAuth-based authorization — so connecting can surface the same kind of consent flow as any other third-party connection, which keeps scoped credentials out of your local config files entirely.

## Practical example

The honest, useful version of this tradeoff is GitHub:

- `gh` is a well-established, capable CLI. An agent with shell access can already run `gh pr view`, `gh issue list`, and so on, and interpret the output. Wrapping the same capability in a brand-new MCP server adds maintenance for little gain.
- Connecting an agent to a *remote* service with no mature CLI — or one where you don't want a long-lived API key sitting in a local dotfile — favors MCP: the server describes its own tools, and a remote MCP server can use OAuth so nothing sensitive is stored locally.

The right answer in the first case is "use the CLI." The right answer in the second is often "use MCP." Neither tool always wins.

## Explanation guidance

### Essential

- The agent already has your CLIs — that's where its shell power comes from, and also where the "wait, how did it do that?" moments come from.
- CLI output is unstructured text the model interprets; MCP tools are typed and self-described, with per-server allow/deny control.
- A mature CLI is often simpler than an MCP wrapper for the same capability. Don't wrap `gh` in MCP just because MCP exists.
- MCP earns its keep especially for remote services, where it avoids spreading local credentials across many CLI configs and can use OAuth instead.

### Experienced-user note

- Per-server allow/deny on MCP is a different granularity than shell allowlists: you gate a whole toolset as a unit rather than individual commands.
- The MCP connector in the Messages API means MCP is first-class at the API level, not a Claude-Code-only idea — but it's behind a beta header whose exact string shifts.
- "MCP client" is plumbing the host runs, one per configured server; you only ever configure servers.

### Optional deeper context

- MCP servers can expose resources and prompts in addition to tools, not just callable functions.
- The same decision pattern generalizes: for any capability, ask whether you want the agent to *interpret text* (CLI) or *call a described interface* (MCP).
- Remote MCP servers with OAuth authorization sit at the intersection of this page and the module's OAuth material — the consent screen you see connecting to one is the same delegated-access mechanism described in `oauth-vs-api-keys`.

## Cautions and common failures

- **Don't assume MCP is strictly better.** A new MCP server wrapping a mature CLI can be more maintenance than value.
- **Don't assume the CLI is strictly better either.** For remote services, shelling out can mean copying credentials into local configs that MCP + OAuth would have kept out of them.
- **Unstructured CLI output is a real failure mode.** An agent can misread exit-context from prose output; typed tools reduce but do not eliminate misinterpretation.
- **Beta-header drift.** If you wire MCP in at the API level, the beta header string changes over time; check current docs rather than caching one.
- **Granting an MCP server is not revoking anything else.** Removing a server or uninstalling a plugin does not revoke an OAuth grant you already made to a third-party provider — revocation lives with the provider (see `oauth-vs-api-keys`).

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering module) — permission prompts and allowlists, the safety lever for shell access.
- `oauth-vs-api-keys` — why third-party connections surface consent screens, scopes, and revocation.
- `skills-and-plugins` — the other capability-distribution mechanisms, and how plugins package capabilities like MCP servers and skills together.

## Official sources

- Anthropic platform docs — Agent Skills overview: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Model Context Protocol (concept and specification): https://modelcontextprotocol.io
- OAuth 2.0 (delegated authorization framework): https://oauth.net/2/

## Provenance

The CLI-vs-MCP tradeoff framing here is a research synthesis that two independent research passes (openrouter-glm and gemini-antigravity) converged on, anchored by Context7-verified Anthropic platform-docs facts: MCP's existence as a documented standard, the Messages API MCP connector (`mcp_servers` / `mcp_toolset` behind a beta header), stdio and HTTP transports, and the host/client/server architecture. The beta header date string is treated as illustrative, not stable. Two items were flagged as needing live verification and are therefore presented at concept level only: the exact MCP spec revision that introduced OAuth for remote servers (verify against the current MCP specification site before citing a precise date), and — though it mostly lives on other pages — the complete current list of what Claude Code plugins can bundle (check the Claude Code plugins reference). OAuth framing follows the OAuth 2.0 framework as described at oauth.net and RFC 6749.
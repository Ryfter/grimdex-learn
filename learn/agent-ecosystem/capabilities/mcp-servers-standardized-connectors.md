---
title: "MCP servers: standardized connectors"
module_id: agent-ecosystem
capabilities:
  - mcp-servers-standardized-connectors
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I declare mcp_servers and an mcp_toolset in a Messages API request?
  - What beta header gates the MCP connector on the Claude API?
  - What transports does MCP support (local stdio vs remote HTTP/URL)?
  - What is the host/client/server architecture in MCP?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://modelcontextprotocol.io
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

The Model Context Protocol (MCP) is a real, current, documented standard for giving an agent structured access to external tools and data. Instead of an agent improvising with raw shell commands, an MCP server exposes self-described, typed tools (and can also expose resources and prompts) that a client discovers and calls.

Two things make MCP worth demystifying:

- **It is not a Claude-Code-only concept.** Anthropic's own platform docs show an MCP connector wired into the core Messages API itself: a request can declare `mcp_servers` (with fields like type, url, name, and authorization_token) and use an `mcp_toolset` tool type. This is gated behind a beta header (for example `mcp-client-2025-11-20` -- beta header names and dates shift over time, so treat that exact string as illustrative, not something to hard-code as permanent). The point is that MCP is first-class at the API level, not just a feature of one CLI tool.
- **Both major transports are real and documented:** local servers launched over stdio, and remote servers reached over HTTP/URL.

## When it is useful

Use an MCP server when you want an agent to interact with an external service or data source through a well-defined, discoverable set of typed tools -- especially for remote services, or when you want per-server allow/deny control rather than a broad shell allowlist. When a mature CLI already exists (like `gh` for GitHub), shelling out may be simpler than wrapping the same capability in a new MCP server; neither approach universally wins. See the sibling capability `cli-tools-as-agent-capabilities` for the shell side of that tradeoff.

## Prerequisites

- A working agent host (for example Claude Code, or your own application calling the Messages API).
- Either a locally configured MCP server (stdio) or the URL of a remote MCP server (HTTP), plus any credentials that server requires.
- If using the Messages API connector directly: awareness that the feature is beta-gated and the exact header must be checked against current docs.

## Current syntax

There is no single "MCP syntax" -- the standard shows up in a few places:

- **In an agent host:** you configure servers; you never write a "client." The client is invisible plumbing the host runs -- one per configured server. Docs that mention "MCP client" refer to that internal piece, not something extra to install.
- **In the Messages API:** a request includes an `mcp_servers` declaration (type, url, name, authorization_token) and can use the `mcp_toolset` tool type, behind the current MCP beta header.

## What happens (local and remote)

- **Local (stdio):** the host launches the server process locally and communicates over standard input/output. The server's tools appear to the agent as callable tools.
- **Remote (HTTP/URL):** the host connects to a URL-hosted server. Remote servers increasingly use OAuth-based authorization (see `oauth-api-keys-and-scopes`), so connecting can surface a familiar consent screen.
- In both cases, the host's per-server client discovers the tools the server exposes and relays the agent's calls to them.

## Practical example

Conceptually, configuring a remote server in Claude Code means adding a server entry (name + URL) to your MCP configuration; the agent then discovers that server's tools and can call them like any other tool. At the API level, a Messages API request with the beta header would declare an `mcp_servers` array entry and reference the `mcp_toolset` tool type so the model can use those server tools in the same conversation. Exact field spelling is version-sensitive; verify against the current docs before hard-coding.

## Explanation guidance

### Essential

- MCP is a documented standard, and it is first-class in Anthropic's core API -- not a Claude-Code-only idea.
- A user configures *servers*; the "client" is internal plumbing the host runs, one per server. Nobody needs to "install an MCP client."
- Local (stdio) and remote (HTTP) transports both exist and are documented.
- An MCP server gives agents self-described, typed tools; a CLI gives unstructured text the agent must interpret. Choose per situation.

### Experienced-user note

The Messages API connector uses an `mcp_servers` request field plus an `mcp_toolset` tool type, gated by a beta header. Beta identifiers change; check the current docs rather than memorizing the header string. Remote MCP servers commonly use OAuth authorization (added in a documented MCP spec revision -- verify the exact revision on the current spec site before citing a date).

### Optional deeper context

MCP servers can expose resources and prompts in addition to tools, and the protocol's authorization story for HTTP servers means a remote connection can present a scoped, revocable OAuth consent flow -- the same model as connecting any third-party service.

## Cautions and common failures

- **Hard-coding the beta header string.** It shifts; treat documented examples as illustrative.
- **Thinking you need to install an "MCP client."** You don't -- you configure servers; the host handles clients.
- **Assuming MCP always beats CLI.** A well-established CLI is often simpler than a new MCP server for the same capability.
- **Confusing MCP with Skills or plugins.** Skills are model-invoked capability bundles (see `skills-model-invoked-capabilities`); plugins are packaging (see `plugins-packaging-capabilities`); MCP is a connector protocol.
- **Remote-server auth surprises.** Expired or revoked OAuth tokens on a remote MCP server look like "the agent can't connect" -- diagnose by the specific error, not by re-installing things.

## Related capabilities

- `cli-tools-as-agent-capabilities` -- the unstructured shell-output alternative and its permission-prompt safety lever (cross-referenced from the prompt-engineering module's tools-and-agent-actions lesson).
- `skills-model-invoked-capabilities` -- SKILL.md-based, model-invoked capability bundles.
- `plugins-packaging-capabilities` -- plugins as a packaging mechanism that can bundle MCP servers, skills, and more.
- `oauth-api-keys-and-scopes` -- why remote MCP connections surface OAuth consent screens.

## Official sources

- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- https://modelcontextprotocol.io

## Provenance

MCP's status as a current, documented standard, the Messages API `mcp_servers`/`mcp_toolset` connector with its beta gate, and both stdio and HTTP transports are Context7-verified against Anthropic platform docs. The host/client/server architecture point is from MCP's own documented architecture. The MCP spec's OAuth authorization for remote servers is real and current, but the exact spec revision date was not pinned in this session's research -- verify against the current MCP specification site before citing a precise version. `last_checked` reflects the draft date; beta header strings and field names should be re-verified at publication time.
---
title: "Host, client, server: who talks to whom in MCP"
module_id: agent-ecosystem
capabilities:
  - mcp-host-client-server
context7_library: /websites/platform_claude_en
context7_queries:
  - What are the host, client, and server roles in MCP architecture?
  - Does the user need to install a separate MCP client?
  - How does an agent application connect to configured MCP servers?
official_sources:
  - https://modelcontextprotocol.io
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

The Model Context Protocol (MCP) describes three roles: a **host**, a **client**, and a **server**.

- The **host** is the application the user actually runs — for this course's purposes, usually a coding agent or assistant app. The host is what you install and configure.
- The **server** is an external process or remote endpoint that exposes tools (and possibly resources/prompts) the agent can use. This is what the user configures and names.
- The **client** is the piece of plumbing *inside the host* that manages the connection to one server. It is not a separate program a user installs.

The key architectural rule: the host runs **one client per configured server**. If you configure three MCP servers, your host quietly spins up three clients — one per connection — and you never see or manage any of them directly.

## When it is useful

This distinction matters most when reading MCP documentation or troubleshooting a connection. Docs and error messages frequently say "the MCP client" (e.g., "the client discovers tools", "the client sends the request"). Beginners routinely read this as "I need to install an MCP client" and go hunting for a separate download that doesn't exist. Understanding that the client is invisible, internal plumbing saves that detour.

It also clarifies *where* problems live: a tool not appearing is usually a server-side configuration or connection issue, not something to fix by "installing a client".

## Prerequisites

- A host application that supports MCP (e.g., Claude Code, or an app using the Messages API's MCP connector).
- At least one MCP server configured — local (stdio) or remote (HTTP/URL-based). Both transports are documented, real options.

## Current syntax

There is no syntax for the client — that's the point. The user's only interface is **server configuration**. For example, in an API-based host, a request can declare `mcp_servers` entries (with type, url, name, and optionally an authorization token); in Claude Code, servers are configured in the app's own configuration. Exact config formats vary by host; always check that host's current docs.

## What happens (local and remote)

1. The user configures one or more **servers** in the host.
2. The host starts one **client** per configured server. This happens automatically and invisibly.
3. Each client connects to its server (via stdio for a local process, or HTTP for a remote URL) and **discovers** what the server exposes — its tools and any resources/prompts.
4. When the agent decides to use one of those tools, the host's corresponding client relays the call to the server and returns the result.

The agent (and the user) only ever experiences two visible layers: the host application and the servers the user named. The client layer is entirely internal.

## Practical example

Suppose you configure two MCP servers in your coding agent: a filesystem server (local, stdio) and a remote documentation-search server (HTTP URL). You wrote no clients and installed no client software — but behind the scenes your agent is now running two clients, one holding the stdio connection, one holding the HTTP session. When the agent later searches documentation, the request flows through the *second* client to the remote server. If the filesystem tools never appear, you debug the filesystem server's config — not a missing client.

## Explanation guidance

### Essential

- Three roles: host (the app you run), server (what you configure), client (invisible plumbing inside the host, one per server).
- You never install a client. If docs say "the MCP client", they mean the host's internal connection manager.
- Users configure servers; that is the whole user-facing surface of MCP connection management.

### Experienced-user note

- One-client-per-server isolation is deliberate: each server connection is independent, which maps cleanly onto per-server allow/deny control for tools (a practical advantage over unstructured CLI shelling-out, though neither approach replaces the other).
- Remote MCP servers may add an OAuth consent flow on top of this architecture; the client still handles the transport, and authorization happens between you, the host, and the server.

### Optional deeper context

- The same host/client/server framing appears throughout MCP's specification and helps when reading client-capability negotiation and tool-discovery sections of the spec.
- Claude Code also has Skills (directories containing a SKILL.md) and plugins (a packaging mechanism that can bundle capabilities) — distinct mechanisms from the MCP host/client/server architecture described here; see `mcp-vs-cli-tradeoff`, `skills-model-invoked`, and `plugins-packaging` in this module.

## Cautions and common failures

- **"Do I need to install an MCP client?"** No. The client is part of the host. If you're looking for a client download, you've misread the docs' role names.
- **Debugging in the wrong place.** A tool not showing up is almost always a server configuration or connection issue, since the client layer isn't user-manageable.
- **Count confusion.** Multiple configured servers means multiple clients; a failure in one server's connection doesn't necessarily indicate a problem with the others.

## Related capabilities

- `mcp-vs-cli-tradeoff` — when structured MCP tools beat (or lose to) letting the agent shell out to a CLI.
- `mcp-oauth-remote-servers` — OAuth consent when connecting to remote MCP servers.
- `skills-model-invoked` — Skills as a separate, model-invoked capability mechanism.
- `plugins-packaging` — plugins as a packaging/distribution mechanism for bundled capabilities.

## Official sources

- MCP project documentation and specification: https://modelcontextprotocol.io
- Anthropic platform docs — Agent Skills overview (host-side context): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Provenance

The host/client/server role distinction is a real, documented part of MCP's own architecture description (see modelcontextprotocol.io) and was independently confirmed by both research passes for this module. The core claim — users configure servers, and the client is internal plumbing the host manages — is conceptual and stable. This page deliberately avoids citing a specific MCP specification version number for the architecture section; verify against the current spec site if a precise revision citation is needed. The Claude Code / Claude API specifics referenced here (MCP connector in the Messages API, Skills as SKILL.md directories) were verified against platform.claude.com docs in this session; beta feature names and exact config syntax should be re-checked at delivery time.
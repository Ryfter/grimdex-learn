---
title: "Which one when: a routing table for CLI/MCP/Skill/plugin"
module_id: agent-ecosystem
capabilities:
  - choosing-the-right-component
context7_library: /websites/platform_claude_en
context7_queries:
  - When should an agent use an MCP server instead of shelling out to a CLI tool?
  - What is a Claude Code Skill and how is it discovered and invoked?
  - What does a Claude Code plugin package and how is it installed?
  - How does the MCP connector work in the Messages API?
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

A routing table for deciding which agent-ecosystem component fits a given need. The agent ecosystem offers several overlapping-seeming mechanisms -- running CLI tools directly, connecting MCP servers, using Skills, and installing plugins -- and beginners often stall on "which one do I use?" The honest answer is that these are not competitors; each solves a different problem, and one of them (the plugin) is explicitly a packaging layer over the others.

The routing table:

| Your need | Reach for |
|---|---|
| The agent needs knowledge or a how-to procedure | A **Skill** (a directory with a `SKILL.md`, model-invoked when relevant) |
| The agent needs access to an external system or service | An **MCP server** (typed, self-described tools) or an existing **CLI** (e.g. `gh`, `aws`, `curl`) |
| You want to bundle and distribute several of the above as one installable unit | A **plugin** (installed via `/plugin marketplace add <org>/<repo>` and `/plugin install <plugin>@<marketplace>`) |
| It's a one-off task the agent can already do | **Just run it directly** -- no new component needed |

## When it is useful

- You are setting up an agent for a new task and wondering whether you need to install anything at all.
- You see a capability gap ("the agent can't reach our issue tracker") and need to pick between wrapping a CLI, adding an MCP server, or writing a Skill.
- Someone shares a plugin and you want to understand what problem it solves relative to the pieces you already have.

## Prerequisites

- Basic familiarity with what a coding agent is and that it can run shell commands.
- No installation required for this lesson itself; the components it routes between are covered in their own lessons.

## Current syntax

There is no syntax for the routing decision itself. The component-specific entry points you will encounter, for orientation only:

- **CLI:** nothing to install -- any program on the machine (`gh`, `aws`, `curl`, `jq`, ...) is already available to an agent that can run a shell.
- **MCP:** an MCP server is configured (by URL for remote HTTP servers, or as a local stdio process); Anthropic's Messages API also accepts `mcp_servers` and an `mcp_toolset` tool type behind a beta header.
- **Skill:** a directory containing a `SKILL.md`, discovered automatically from local filesystem paths in Claude Code.
- **Plugin:** `/plugin marketplace add <org>/<repo>` then `/plugin install <plugin>@<marketplace>`.

## What happens (local and remote)

- **CLI:** the agent issues a shell command; the tool returns unstructured text the agent must interpret. Safety comes from permission prompts and allowlists.
- **MCP:** the host application runs one client per configured server (invisible plumbing -- you only ever configure servers). The server exposes typed, self-described tools the agent discovers and calls. Local stdio and remote HTTP transports both exist.
- **Skill:** the agent decides on its own to load the Skill when the task matches -- model-invoked, not user-invoked like a slash command.
- **Plugin:** installing one unit can bring in several of the above together; it is packaging, not a new capability type.

## Practical example

Suppose you want your agent to help with GitHub work:

- If the agent already has shell access and `gh` is installed, that may be all you need -- a well-established CLI like `gh` is often simpler than wrapping the same capability in a new MCP server.
- If you want typed, per-server controllable access to GitHub from a remote context, an MCP server is the fit.
- If your team has accumulated house rules for writing PR descriptions, that's knowledge/how-to -- a Skill.
- If a colleague has packaged their MCP server plus Skills into one distributable, that's a plugin; install it with the `/plugin` commands rather than assembling pieces by hand.

## Explanation guidance

### Essential

- Route by need: knowledge/how-to → Skill; external-system access → MCP server or CLI; bundling/distribution → plugin; one-off → nothing.
- CLI and MCP are a real tradeoff, not a rule. A CLI gives unstructured text the agent interprets; an MCP server gives typed, self-described tools with per-server allow/deny control, and works for remote services without spreading local credentials across many CLI configs. Neither always wins.
- A plugin is fundamentally a packaging mechanism -- installing one can bring multiple components bundled together. It is not a fourth capability competing with the other three.
- Skills are model-invoked (the agent loads them when relevant), which distinguishes them from user-invoked slash commands.

### Experienced-user note

- In MCP's architecture, the "client" is invisible plumbing: the host application runs one client per configured server, and a user only ever configures servers. If docs mention "MCP clients," you don't need to install one separately.
- Anthropic's Messages API has a first-class MCP connector (`mcp_servers` plus an `mcp_toolset` tool type, behind a beta header), confirming MCP is wired into the core API, not just a Claude Code feature. Beta header strings shift; treat any exact value as illustrative.
- The Claude API separately supports a "skills" container feature for bundling skills into a single request -- related to but distinct from Claude Code's Skill-loading. Don't conflate the two.
- If external access involves a third-party service, the connection will usually surface an OAuth consent screen -- see `oauth-vs-api-keys` for that half of the decision.

### Optional deeper context

- Remote MCP servers can use OAuth-based authorization per the MCP specification, meaning connecting to one can look like connecting to any other third-party service.
- When a component "suddenly stops working," expired OAuth tokens are a common cause -- revocation and expiry live with the third-party provider, not with the agent tool or plugin.
- If a task needs no new knowledge, no new system access, and no distribution, the correct answer is to add nothing; the ecosystem's components all exist to fill specific gaps.

## Cautions and common failures

- **Over-building.** Reaching for an MCP server when an installed CLI would do adds configuration and credential spread for no benefit. Check the simple option first.
- **Confusing plugin with capability.** Installing a plugin brings components in; the components still do the work. Removing the plugin removes the packaging, but revoking any third-party OAuth connection it set up is a separate step at the provider (e.g. GitHub's "Authorized OAuth Apps" settings), not a local uninstall.
- **Conflating the two "skills" mechanisms.** Claude Code's Skill directories and the Claude API's skills container feature are distinct; verify which one a document means.
- **Hard-coding beta strings.** MCP beta header names and dates shift; don't bake an exact value into anything permanent.

## Related capabilities

- `tools-and-agent-actions` -- permission prompts and allowlists are the safety lever for CLI access; cross-referenced rather than repeated here.
- `oauth-vs-api-keys` -- the credentialing half of "external-system access," covering delegated, scoped, revocable third-party connections.

## Official sources

- Anthropic platform docs, Agent Skills overview: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- MCP specification and concept pages: https://modelcontextprotocol.io
- OAuth 2.0 framework: https://oauth.net/2/

## Provenance

This page is a **synthesis lesson**, not a doc citation: the routing table and the CLI-vs-MCP tradeoff framing are the module's original research synthesis (both research models independently converged on the same shape), anchored to real documented facts about the components being routed between. Component facts (Skill directories with `SKILL.md`, plugin install commands, the Messages API MCP connector, MCP host/client/server architecture) come from Context7-verified Anthropic platform docs and MCP documentation. Two items are flagged as needing live verification rather than asserted precisely here: the complete current list of what a plugin can bundle (packaging concept is real and demonstrated by shipped examples, but no single current reference page pinned the full enumeration), and the exact MCP spec revision that added OAuth authorization for remote servers (the concept is real and current; cite the date only after checking the current MCP specification site).
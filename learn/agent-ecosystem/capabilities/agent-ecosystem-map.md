---
title: "One map: CLIs, MCP, Skills, and plugins"
module_id: agent-ecosystem
capabilities:
  - agent-ecosystem-map
context7_library: /websites/platform_claude_en
context7_queries:
  - How do CLIs, MCP servers, Skills, and plugins relate as ways to extend an agent?
  - What is a Skill in Claude Code and how is it discovered?
  - What is the MCP host/client/server architecture?
  - What does a Claude Code plugin package?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
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

This is the orientation page for the agent-ecosystem module: a single map of the four main ways an agent gains capabilities, before any of the module's other lessons zoom in on one of them.

Put the agent at the center. Around it, four extension paths:

**1. CLIs — programs already on the machine.**
The moment a coding agent can run a shell, every command-line program installed on that machine (`gh`, `aws`, `curl`, `jq`, and so on) becomes something the agent can use. No installation step for the agent, no new protocol — the capability was already there. This is the source of both the power and the "wait, how did it do that?" moments. The safety lever is permission prompts and allowlists, covered in depth by the `tools-and-agent-actions` lesson in prompt-engineering (see Related capabilities).

**2. MCP servers — standardized connectors.**
The Model Context Protocol (MCP) is a real, current, documented standard for giving an agent structured access to external tools and data. An MCP server exposes tools (and can also expose resources and prompts) that a client discovers and calls. Both local (stdio) and remote (HTTP/URL-based) transports exist. MCP is first-class, not a Claude-Code-only concept: Anthropic's own Messages API supports an MCP connector — a request can declare `mcp_servers` (with type, url, name, authorization_token) and an `mcp_toolset` tool type, gated behind a beta header (the exact beta string shifts over time; don't hard-code it as permanent).

One architectural point worth demystifying early: in MCP's terms, the agent (the "host" application) runs one client per configured server. The client is invisible plumbing the host manages — a user only ever configures *servers*, never installs a separate "MCP client," despite wording that sometimes suggests otherwise.

**3. Skills — packaged know-how.**
In Claude Code, a Skill is a directory containing a `SKILL.md` file, discovered automatically from the local filesystem. Skills are model-invoked: the agent decides to load one when it's relevant to the task — distinct from a user-invoked slash command, which the human triggers. (Separately, the Claude API has a "skills" container feature for bundling skills into a single API request — related, but a different mechanism from Claude Code's Skill-loading; don't conflate the two.)

**4. Plugins — packages, not a competing capability.**
A Claude Code plugin is a distribution/packaging mechanism, installed via documented commands like `/plugin marketplace add <org>/<repo>` and `/plugin install <plugin>@<marketplace>`. The key point: a plugin is not a fifth category competing with CLIs, MCP, and Skills — it's a wrapper that can bring several of the above bundled together in one install. (The exact, complete list of what a plugin can currently bundle isn't pinned here; check the current Claude Code plugins reference rather than treating any enumeration as exhaustive.)

## When it is useful

Use this map whenever you're deciding how to give an agent a new capability, or trying to understand how an agent did something:

- "Can the agent talk to GitHub?" — first ask whether `gh` is already installed (CLI path), whether an MCP server exists for it (MCP path), or whether a plugin/skill already bundles it.
- "Why did the agent just run that command?" — usually the CLI path: the program was on the machine and the shell was available.
- "Should I build an MCP server or just let the agent use the existing CLI?" — that's a genuine tradeoff, not a rule (see Current syntax / tradeoff section below).
- "How do I hand my team a bundle of agent setup?" — that's the plugin path.

This page is the map the other lessons in this module build on; each of the other 14 zooms into one region of it.

## Prerequisites

- An agent that can run tools (e.g., a coding agent with shell access).
- For the CLI path: whatever programs you want the agent to use, already installed.
- For the MCP path: one or more MCP servers configured with your agent (local or remote).
- For Skills: a Claude Code setup where local Skill directories are discoverable.
- No programming beyond ordinary configuration is required to *use* any of these paths.

## Current syntax

There is no single syntax for the map, but the concrete touchpoints are:

- **MCP via the Messages API** (illustrative shape; beta header strings shift):
  - a request can carry `mcp_servers` entries with `type`, `url`, `name`, and `authorization_token`
  - and an `mcp_toolset` tool type
- **Skills in Claude Code**: a directory containing a `SKILL.md` file, placed where Claude Code discovers local skills; model-invoked, not slash-invoked.
- **Plugins in Claude Code**:
  - `/plugin marketplace add <org>/<repo>`
  - `/plugin install <plugin>@<marketplace>`

The exact strings above come from Anthropic's platform docs; verify against the live docs before relying on precise field names or beta headers in production code.

## What happens (local and remote)

- **CLI path (local):** the agent composes a shell command and runs it on your machine, using programs already installed. Output is unstructured text the agent must interpret. Local credentials for those CLIs (in their own config files) are what the agent effectively operates through.
- **MCP path (local or remote):** the agent's host application runs one MCP client per configured server. Local servers communicate over stdio; remote servers over HTTP. Tools are self-described and typed, and per-server allow/deny control is possible. Remote servers avoid spreading local credentials across many CLI configs — and, since MCP's spec added OAuth-based authorization for remote servers, connecting to one can surface the same OAuth consent flow as any other third-party service (verify the exact spec revision date against the current MCP specification before citing it precisely).
- **Skills path (local):** Claude Code scans configured local paths for `SKILL.md` directories; when a task matches, the agent loads the skill's know-how itself.
- **Plugin path (local):** installing a plugin pulls a bundle — potentially MCP servers, Skills, and other pieces — into your Claude Code setup in one step.

## Practical example

Suppose you want an agent to work with GitHub:

1. **Check the CLI first.** If `gh` is installed and permitted, the agent can already create PRs, read issues, and review diffs by shelling out. For a well-established CLI like `gh`, this is often simpler than wrapping the same capability in a new MCP server.
2. **Consider MCP instead when you want structure and control.** An MCP server gives the agent self-described, typed tools instead of raw text output to interpret, plus per-server allow/deny control, and works for remote services without the agent operating through your local `gh` credentials.
3. **Check whether a Skill or plugin already exists.** A plugin installed via `/plugin marketplace add` and `/plugin install` might bring the relevant skill, MCP server, or both in one install.
4. **When connecting to a third-party service (GitHub, Google Drive, Slack), expect OAuth.** The consent screen and its scope list — not an API key — is the normal way delegated, scoped, revocable access gets granted. That's its own lesson (see Related capabilities).

Neither CLI nor MCP always wins: it's a practical tradeoff, judged per capability.

## Explanation guidance

### Essential

- The agent is the center; CLIs, MCP servers, Skills, and plugins are four ways capabilities reach it.
- CLIs are free extensions: if it's on the machine and the agent can run a shell, the agent can use it — output is unstructured text, and permission allowlists are the safety lever.
- MCP servers are standardized, typed, discoverable tool providers — you configure *servers*; the "client" is invisible plumbing inside the agent host.
- Skills are `SKILL.md` directories the model invokes on its own when relevant.
- Plugins are packaging, not a capability category: one install can bundle several of the above.
- CLI vs MCP is a real tradeoff: unstructured-text-plus-existing-tool vs typed-tools-plus-control; established CLIs are often the simpler choice.

### Experienced-user note

- The Messages API itself has an MCP connector (`mcp_servers` + `mcp_toolset`, behind a beta header) — MCP is wired into the core API, not only into coding agents. Treat exact beta strings as illustrative.
- Distinguish Claude Code Skills (local `SKILL.md` directories, model-invoked) from the Claude API's separate "skills" container feature — related names, different mechanisms.
- Remote MCP servers can use OAuth for authorization per the MCP spec — same consent flow shape as any third-party connection; verify the exact spec revision against modelcontextprotocol.io before citing a version.

### Optional deeper context

- Why OAuth appears so often in this ecosystem: an API key is a static, long-lived, broad credential; OAuth exists for delegated, scoped, revocable third-party access. Connecting an agent to GitHub, Drive, or Slack usually surfaces an OAuth consent screen because that's the access model those connections need. The scope list on the consent screen is the real privacy decision — prefer the narrowest scope that works. Access tokens are typically short-lived, refreshed via refresh tokens; "the agent suddenly can't connect" is often just an expired token, distinguishable from revocation or insufficient scope by the specific error. Revocation lives with the third-party provider (e.g., GitHub's "Authorized OAuth Apps" settings), not with the agent tool — uninstalling a plugin does not revoke a granted connection.
- Transports: MCP servers can be local (stdio, running on your machine alongside the agent) or remote (HTTP/URL-based, run by someone else) — the remote case is where OAuth-based authorization matters most.

## Cautions and common failures

- **"Wait, how did it do that?"** — usually the CLI path. Audit what's installed on the machine; shell access turns all of it into agent capabilities. Permission allowlists are the control (see `tools-and-agent-actions`).
- **Don't conflate the two "skills" mechanisms.** Claude Code Skills (SKILL.md directories) and the Claude API's skills container feature are distinct.
- **Don't treat plugin bundle contents as fixed.** The packaging concept is real and demonstrated; the exact complete list of bundleable pieces changes — check the current plugins reference.
- **Don't hard-code MCP beta headers** as permanent; they shift.
- **Uninstalling a plugin or deleting a config line does not revoke OAuth grants.** Third-party connections must be revoked at the provider (GitHub, Google, Slack settings).
- **Expired tokens look like broken integrations.** An agent suddenly failing to connect is often just a short-lived access token expiring — check the error type before debugging the setup.
- **Don't reflexively build an MCP server around an established CLI** — the CLI may already be the simpler, better path.

## Related capabilities

- `tools-and-agent-actions` (prompt-engineering module) — permission prompts and allowlists, the safety lever for the CLI path; this page defers to it rather than repeating it.
- `oauth-api-keys` — the delegated-access vs static-key distinction in depth.
- Other lessons in this module zoom into each region of this map: MCP servers in detail, Skills in detail, plugins in detail, and OAuth-scoped connections.

## Official sources

- Anthropic platform docs — Agent Skills overview (Claude Code Skills as SKILL.md directories): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Anthropic platform docs — skill plugin install flow (`/plugin marketplace add`, `/plugin install`): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
- MCP specification and concept pages (host/client/server architecture, transports, OAuth authorization for remote servers): https://modelcontextprotocol.io
- OAuth 2.0 framework (delegated, scoped, revocable authorization): https://datatracker.ietf.org/doc/html/rfc6749

## Provenance

- MCP's first-class status (Messages API `mcp_servers`/`mcp_toolset` connector) and the Skills-as-SKILL.md-directories fact are grounded in Anthropic's platform docs as verified this session via Context7.
- The plugin install commands come from a real documented flow in the platform docs. The **complete list of what a plugin can bundle** could not be pinned to a single current reference page this session — the packaging concept is presented as fact, with readers directed to the live Claude Code plugins reference for the exhaustive list.
- MCP's OAuth-based authorization for remote servers is real and current, but the **exact spec revision date needs live verification** against modelcontextprotocol.io before being cited precisely.
- The CLI-vs-MCP tradeoff framing and the plugin-as-packaging demystification reflect the module's original research synthesis, on which two independent research tracks converged.
- Beta header strings are presented as illustrative; the CLI-path safety discussion is cross-referenced to, not duplicated from, the `tools-and-agent-actions` lesson.
- last_checked 2026-09-20; exact beta header values, plugin bundle contents, and the MCP OAuth spec revision date should be re-verified on any future material update.
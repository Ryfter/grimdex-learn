---
title: "Plugins: packaging, not a rival to MCP"
module_id: agent-ecosystem
capabilities:
  - plugins-are-packaging-not-rivals
context7_library: /websites/platform_claude_en
context7_queries:
  - What is a Claude Code plugin and how do I install one?
  - Can a Claude Code plugin bundle MCP servers and skills together?
  - What does /plugin marketplace add and /plugin install do?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
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

A Claude Code **plugin** is a real, current distribution and packaging mechanism. It is installed via documented commands:

- `/plugin marketplace add <org>/<repo>` — register a marketplace (a repository hosting installable plugins)
- `/plugin install <plugin>@<marketplace>` — install a specific plugin from that marketplace

The key demystification point: a plugin is **not a competing capability** to CLI tools, MCP servers, or Skills. It is a **packaging** mechanism — a way to bundle one or more of those capabilities together and distribute them as a single installable unit. Installing one plugin can bring in multiple capabilities at once (for example, a shipped skill plugin delivered through the marketplace install flow shown in Anthropic's own docs).

## When it is useful

- When you want to share a set of agent capabilities (e.g. a skill plus supporting MCP server configuration) as one installable package rather than asking each user to configure each piece separately.
- When you want to consume someone else's packaged agent tooling via a marketplace instead of manually copying files and configs.
- When reasoning about the ecosystem: if you're wondering "should I use a plugin or MCP?", you're often asking the wrong question — a plugin may *contain* MCP servers and skills.

## Prerequisites

- Claude Code installed and running.
- Access to the marketplace repository hosting the plugin you want (e.g. a GitHub org/repo).
- Awareness of the underlying capabilities being bundled (CLI tools, MCP servers, Skills — covered elsewhere in this module), since installing a plugin activates those capabilities for your agent.

## Current syntax

```
/plugin marketplace add <org>/<repo>
/plugin install <plugin>@<marketplace>
```

Both are real, documented commands demonstrated in Anthropic's platform docs for a shipped skill plugin.

## What happens (local and remote)

- `marketplace add` registers a plugin source locally by pointing at a repository.
- `install` pulls the named plugin from that marketplace and makes its bundled contents available to your Claude Code session.
- Whatever the plugin packages — skills, MCP server configurations, or other capability definitions — becomes discoverable to the agent through the normal mechanisms for those capability types (e.g. Skills are model-invoked; MCP servers' tools are discovered by the client).
- The plugin is a delivery vehicle: after installation, the bundled capabilities behave exactly as they would if you had configured them yourself.

## Practical example

Anthropic's own documentation shows the exact flow for a real shipped skill plugin:

1. Add the marketplace: `/plugin marketplace add <org>/<repo>`
2. Install the plugin: `/plugin install <plugin>@<marketplace>`
3. The bundled skill becomes available to the agent, which can invoke it when relevant to the task — no separate manual skill-directory setup required.

## Explanation guidance

### Essential

- **Plugins are packaging, not a rival capability.** The ecosystem has capabilities (CLI tools the agent can shell out to, MCP servers providing typed tools, Skills providing loaded instructions) and a *distribution* layer (plugins). A plugin bundles capabilities; it doesn't compete with them.
- **Installing one plugin can bring multiple capabilities at once.** That's the point of the mechanism.
- **The install flow is two commands**: add a marketplace, then install from it. Both are real and documented.

### Experienced-user note

- When evaluating a plugin, look at what's inside the package rather than treating "plugin" as a single capability: does it bundle a skill, an MCP server, or several things? The bundle composition determines what permissions and connections (including OAuth grants to third-party services) the plugin's use will involve.
- Uninstalling a plugin removes its bundled configuration from your session, but it does **not** revoke any third-party OAuth connections granted during use — those live with the provider (see `oauth-scopes-and-consent` in this module).

### Optional deeper context

- The exact, complete list of what a plugin can currently bundle (e.g. MCP servers, skills, hooks, slash commands, subagents) was not pinned to a single current reference page during research for this lesson. Treat the *packaging concept* as established fact — it is real and demonstrated by the working install flow above — but check the current Claude Code plugins reference for the complete, up-to-date bundle-content list rather than treating any specific enumeration here as exhaustive.

## Cautions and common failures

- **Category error**: describing plugins as "an alternative to MCP" muddles the mental model. Plugins are a distribution mechanism *over* capabilities like MCP and Skills.
- **Assumed exhaustiveness**: don't assume any enumerated list of bundleable content types is complete; verify against the live plugins reference.
- **Marketplace trust**: installing a plugin from a third-party marketplace activates whatever capabilities it bundles, including tool access — apply the same scrutiny (permission prompts, allowlists) you would to configuring those capabilities directly.
- **Revocation confusion**: removing a plugin is not the same as revoking a granted third-party connection; revocation happens at the provider's settings pages.

## Related capabilities

- `mcp-servers-structured-tools` — MCP servers are a capability type that plugins can package.
- `skills-as-model-invoked-instructions` — Skills are another bundleable capability type.
- `oauth-scopes-and-consent` — third-party connections granted through bundled tools are revoked at the provider, not by uninstalling the plugin.

## Official sources

- Anthropic platform docs — Agent Skills / Claude API skill (shows the real `/plugin marketplace add` / `/plugin install` flow): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill
- Claude Code plugins reference — consult the current live page for the complete bundle-content list.

## Provenance

- The install commands (`/plugin marketplace add`, `/plugin install`) are real, documented, and verified in Anthropic's platform docs via Context7 during this session's research.
- The packaging-not-rival framing was independently converged on by both research models (openrouter-glm and gemini-antigravity) and is the core demystification lesson.
- **Needs live verification**: the exact full list of bundleable content types in a plugin was not pinned to one current reference page in this session. The packaging concept itself is fact; the enumeration is not asserted here.
- last_checked / last_material_update: 2026-09-20; version_stamp fall-2026-0.1.0; beta names and bundle contents shift — re-verify against live docs before citing precisely.
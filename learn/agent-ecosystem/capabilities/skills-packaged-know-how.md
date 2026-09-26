---
title: "Skills: packaged know-how the agent loads on demand"
module_id: agent-ecosystem
capabilities:
  - skills-packaged-know-how
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Skills work in Claude Code and how are they discovered?
  - What is a SKILL.md file and where does Claude Code look for Skills?
  - Are Skills invoked by the model or by the user?
official_sources:
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

In Claude Code, a **Skill** is a directory containing a `SKILL.md` file. The directory may also hold whatever supporting material the skill needs, but the defining piece is that markdown file. Skills are discovered automatically from local filesystem paths -- you place the directory where Claude Code looks, and the skill becomes available; there is no separate registration step to perform.

Skills are **model-invoked**: the agent itself decides to load a skill when the task at hand makes it relevant. This is the key distinction from a **slash command**, which is user-invoked -- you type the command, the agent runs it. With a skill, you describe what you want in ordinary language, and the agent recognizes the packaged know-how applies and pulls it in.

Think of a skill as packaged know-how: procedures, conventions, or domain-specific instructions the agent doesn't need in every conversation, but should have ready access to when the situation calls for it.

## When it is useful

- **Recurring workflows with house conventions.** If your team has a specific way of doing code review, release notes, or migrations, a skill packages that so the agent follows it whenever the work comes up -- without you re-explaining each time.
- **Domain knowledge that's only sometimes relevant.** Instructions for working with a particular internal service or format don't belong in every prompt; a skill loads them only when the task touches that domain.
- **Turning documented procedures into agent-usable form.** Anything you'd otherwise paste into a prompt as background ("here's how we deploy...") is a candidate for a skill.

Skills are less useful for one-off tasks (just write the prompt) or for access to external systems (that's the territory of CLI tools and MCP servers -- see `tools-and-agent-actions` and `mcp-connect-external-tools`).

## Prerequisites

- Claude Code running locally, with access to the filesystem paths where skills are discovered.
- A task domain stable enough to be worth writing down.
- No programming beyond writing markdown is required to create a basic skill.

## Current syntax

The core artifact is a directory containing a `SKILL.md` file:

```
my-skill/
  SKILL.md
```

The `SKILL.md` file is markdown describing what the skill covers and how to perform the associated work. Claude Code discovers skill directories automatically from its documented local filesystem paths (see the official overview page under "Where Skills work > Claude Code" for the current exact locations). There is no install command needed for a local skill -- placing it in a discovered path is the mechanism.

## What happens (local and remote)

**Locally:** at session time, Claude Code scans its skill discovery paths and makes the available skills known to the agent. When a user request matches what a skill covers, the agent loads that skill's content into its context and follows it. Loading is on demand -- skill content is not necessarily in context from the start; the agent pulls it in when relevant.

**Remotely / via the API:** the Claude API separately supports a "skills" container feature for bundling Anthropic-provided or custom skills into a single API request. This is a related but **distinct** mechanism from Claude Code's filesystem-based skill loading. Don't conflate the two: Claude Code discovers skills from local directories; the API feature packages skills into requests programmatically.

## Practical example

Suppose your team has a strict convention for database migrations: always reversible, always with a rollback note, named with a date prefix. You create:

```
migration-conventions/
  SKILL.md
```

with `SKILL.md` describing the naming rule, the reversibility requirement, and a checklist. Once the directory sits in a discovered path, a later request like "add a migration to track user preferences" leads the agent to load the skill and produce a migration matching the convention -- unprompted. You never invoked anything by name; the agent recognized the fit.

Contrast: if you'd written it as a slash command, you would have to remember to type `/migration-check` yourself. The skill fires on relevance.

## Explanation guidance

### Essential

- A Skill in Claude Code is a directory with a `SKILL.md` file, discovered automatically from local paths.
- Skills are **model-invoked** -- the agent loads them when relevant -- versus slash commands, which are **user-invoked**.
- Skills package know-how (procedures, conventions, domain instructions) so it's available on demand rather than pasted into every prompt.

### Experienced-user note

- The Claude API has its own "skills" container feature for bundling skills into requests -- a related but distinct mechanism from Claude Code's skill loading. When reading docs, check which one a page is describing.
- Skills compose with the rest of the ecosystem: a skill can describe *how* to use a CLI tool or an MCP tool well; it doesn't replace those tools. A plugin (see the agent-ecosystem module's packaging discussion) can bundle skills alongside other capability types.

### Optional deeper context

- The distinction between model-invoked and user-invoked mirrors a broader design tension: explicit control (slash commands) versus ambient availability (skills). Skills trade a little predictability for the agent exercising judgment about when guidance applies.
- For how skills can be distributed at scale -- marketplaces and plugins -- see the plugins material in this module, and verify the current plugin documentation for what bundles can contain.

## Cautions and common failures

- **Skill not discovered.** Most often the directory isn't in a path Claude Code actually scans, or the file isn't named `SKILL.md` exactly. Check the current official docs for the exact discovery locations rather than guessing.
- **Conflating the two "skills" mechanisms.** Claude Code's filesystem-based skills and the API's "skills" container feature are different. Describing one as the other will confuse learners and produce wrong setups.
- **Overly broad skills.** A skill that tries to cover everything loads noise into context when any fragment might be relevant. Narrow, well-scoped skills behave better.
- **Stale know-how.** A skill is only as current as its `SKILL.md`. If team conventions change, the skill silently teaches the old way until someone updates it.

## Related capabilities

- `tools-and-agent-actions` -- permission prompts and allowlists govern what the agent may do, including when following skill instructions.
- `mcp-connect-external-tools` -- structured access to external tools and data, a complement to skills' packaged procedures.
- `oauth-vs-api-keys` -- when a skill's workflow connects to third-party services, scoped delegated access applies.

## Official sources

- [Agent Skills overview -- Claude platform docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)

## Provenance

- The core facts here -- Skill as a directory containing `SKILL.md`, automatic discovery from local filesystem paths in Claude Code, and model-invoked versus user-invoked (slash command) behavior -- are Context7-verified against Anthropic's platform docs ("Where Skills work > Claude Code").
- The Claude API's separate "skills" container feature is also documented on the platform docs; this page deliberately presents it as related-but-distinct and does not describe its usage details.
- No claim on this page depends on the exact bundle contents of plugins or on MCP's OAuth spec revision date; those items need live verification and are treated elsewhere in the module.
- `last_checked: 2026-09-20` reflects the module's verification pass; beta names and discovery-path specifics can shift, so treat exact strings as illustrative and confirm against current docs when precision matters.
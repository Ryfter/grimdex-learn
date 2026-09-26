---
title: "Repo instruction files: AGENTS.md, CLAUDE.md, and rules files"
module_id: agentic-ai-development
capabilities:
  - repo-instruction-files
context7_library: /websites/platform_claude_en
context7_queries:
  - How do coding agents read project conventions from an instructions file in the repo?
  - What is AGENTS.md and which tools adopt it?
  - How does CLAUDE.md work in Claude Code?
  - How do Cursor rules files compare to AGENTS.md and CLAUDE.md?
official_sources:
  - https://agents.md/
  - https://code.claude.com/docs
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

A repo instruction file is a plain-Markdown file placed at the root of a project repository (or another well-known location) that a coding agent reads automatically before it starts working. Instead of re-explaining your project's conventions to the agent every session -- which framework you use, how to run tests, naming style, what not to touch -- you write those conventions once in a file the agent picks up on its own.

Several specific flavors of this pattern exist today:

- **AGENTS.md** is a real, published open format (agents.md) adopted across multiple vendors, designed so the same file can work with several different tools.
- **CLAUDE.md** is Claude Code's own convention for the same idea -- a markdown instructions file Claude Code reads automatically at the start of a session.
- **.cursor/rules** is Cursor's own mechanism for supplying persistent project rules to its agent.

These are variations on one shared pattern: put durable project context in a file at a predictable location, and let the tool read it. It is real, current, cross-tool practice -- but it is **not** one universal standard. No single file format supersedes the vendor-specific mechanisms, so teams commonly maintain the file (or files) their chosen tool expects, sometimes keeping an AGENTS.md alongside a vendor-specific file with overlapping content.

## When it is useful

- **Recurring conventions.** Any project where the same guidance would otherwise be re-typed every session: how to run the build and tests, folder layout, code style, commit message conventions.
- **Team consistency.** Multiple people using agents on the same repo should get the same conventions applied, and the file makes those conventions visible and reviewable in version control like any other change.
- **Onboarding the agent, not just humans.** The file doubles as lightweight documentation of decisions an agent can't infer from code alone ("use library X, not Y, for historical reason Z").
- **Reducing drift.** Without a written convention, an agent may guess differently in different sessions; the file anchors its behavior.

## Prerequisites

- A git repository (or similar) where the file can live at the repo root and be version-controlled.
- An agent tool that reads one of these files -- AGENTS.md-adopting tools, Claude Code (CLAUDE.md), or Cursor (.cursor/rules).
- Basic familiarity with editing Markdown files.

## Current syntax

There is no command syntax -- this is a plain-Markdown file convention, not an API.

- **AGENTS.md**: a Markdown file named `AGENTS.md`, typically at the repository root. The published format is deliberately simple Markdown; sections commonly include build/test commands and project conventions. See agents.md for the published format details.
- **CLAUDE.md**: a Markdown file named `CLAUDE.md`, conventionally at the repo root, read automatically by Claude Code. Content is free-form Markdown instructions.
- **.cursor/rules**: Cursor's rules mechanism, configured via files/settings under the `.cursor/rules` location in the project. **Unverified in this session** — Cursor's exact current file format and location should be confirmed against Cursor's own docs before being taught as fact (same caution this product already applies to other Cursor/Codex-CLI claims elsewhere).

Because exact file naming and lookup locations vary by tool and change over time, check the vendor's official docs for the precise path and any nested/per-directory options before writing instructions.

## What happens (local and remote)

**Locally:** when a session starts, the agent tool looks for its instructions file in the repo (and, for some tools, in parent directories or user-level locations) and loads it into the agent's context before the agent acts. From that point, the agent treats the file's contents as standing instructions alongside your prompts.

**In version control:** the file is an ordinary tracked file. Changes to it go through normal review -- meaning your team reviews changes to agent behavior the same way it reviews code. It also gets pushed/pulled like any file, so clones on other machines carry the same agent instructions.

## Practical example

A team's repo root contains:

```markdown
# AGENTS.md

## Build and test
- Run tests with the project's standard test command before claiming success.
- Never commit directly to `main`.

## Conventions
- Use TypeScript strict mode; no `any`.
- All API routes live under `src/routes/`; do not create new top-level directories.
- Prefer editing existing files over creating new ones.
```

With this file present, an agent starting a fresh session already knows how tests are run and where routes belong. A developer can ask "add an endpoint for password reset" without re-explaining that routes go in `src/routes/` and that tests must pass -- and the file documents those rules for the whole team at once.

## Explanation guidance

### Essential

- The pattern: one plain-Markdown file in the repo that your coding agent reads automatically, so you stop re-explaining conventions every session.
- AGENTS.md is an open, cross-vendor format; CLAUDE.md and .cursor/rules are vendor-specific equivalents of the same idea.
- Keep it version-controlled: conventions become reviewable, shared, and consistent across the team.
- Write conventions the agent can act on (commands to run, paths, style rules), not vague aspirations.

### Experienced-user note

- Don't assume one file serves every tool. If your team uses more than one agent tool, you may maintain an AGENTS.md plus a vendor-specific file; some teams keep content minimal in one and cross-reference.
- Treat edits to the file like config changes: a line in the instructions file changes agent behavior across every future session, for everyone, so review edits with the same care as build configuration.
- Very long instruction files dilute attention -- keep them focused on durable, high-value conventions rather than exhaustive prose.

### Optional deeper context

- Instruction files are one layer of a broader "context engineering" discipline: what you put in the agent's context before it acts shapes everything it does afterward. They pair naturally with verification loops (the file can instruct the agent to run the test suite itself) and with plan-first workflows (the file can ask the agent to propose a plan before large changes).
- Some tools support multiple levels of these files (per-directory or user-level) in addition to the repo root; consult the vendor docs for what your tool supports.

## Cautions and common failures

- **Assuming a universal standard.** AGENTS.md, CLAUDE.md, and .cursor/rules coexist; none supersedes the others. Using the wrong filename for your tool means the agent reads nothing.
- **Vague instructions.** "Write good code" doesn't steer an agent. Concrete, checkable conventions ("run the linter before finishing") do.
- **Contradictions with reality.** If the file says tests run with one command but the repo actually uses another, the agent may follow the file and fail -- keep the file accurate as the project evolves.
- **Treating the file as security.** Instructions in the file shape the agent's behavior but are not a security boundary; they do not replace permission modes, sandboxing, or review of the agent's changes.
- **Silent accumulation.** Long-lived files grow stale cruft. Prune instructions that no longer apply.

## Related capabilities

- **Verifying agent work** (existing lesson): instruction files can tell the agent to verify its own work, but the discipline of checking outputs against real diffs and test runs is covered there.
- **Plan-first / spec-driven development**: an instructions file can request a plan before implementation, complementing that lesson's pattern.
- **Secrets and data hygiene for agent context**: an instructions file is read into context every session -- don't put secrets or credentials in it.

## Official sources

- AGENTS.md open format: https://agents.md/ (a published open spec, not vendor documentation from Anthropic or Cursor)
- Claude Code documentation (CLAUDE.md convention): https://code.claude.com/docs

## Provenance

This page describes a real, current, cross-vendor practice. AGENTS.md is cited as a published open format adopted across multiple vendors; CLAUDE.md is Claude Code's own convention per Claude Code's documentation. Cursor's `.cursor/rules` mechanism is described at the concept level only and flagged unverified in this session -- confirm its exact current file format and lookup path against Cursor's own docs before teaching specifics. The page deliberately does not claim that any one of these files is a universal standard superseding the vendor-specific mechanisms -- they coexist today.
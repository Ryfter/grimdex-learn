---
title: Tools and agent actions
module_id: prompt-engineering
capabilities:
  - tools-and-agent-actions
context7_library: /websites/platform_claude_en
context7_queries:
  - prompt engineering overview success criteria test empirically first draft
  - prompting best practices clear direct scope constraints over-engineering
  - context windows accumulate tokens tool results conversation history
  - working with messages stateless request history re-sent
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - https://platform.claude.com/docs/en/build-with-claude/context-windows
  - https://platform.claude.com/docs/en/build-with-claude/working-with-messages
last_checked: 2026-08-02
last_material_update: 2026-08-02
status: current
claim_class: everyday
safety_class: destructive
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: practice-guidance-with-official-anchors
---

## What it is

A **tool-using coding agent** is a model that can do more than reply with text:
it can read project files, apply edits, run shell commands, and call other
integrations the host exposes. The conversation is no longer only advice; steps
in the plan can change the real working tree and process state on your machine.

That shift has a **blast radius**. A wrong assumption in chat is embarrassing; a
wrong assumption executed as `rm`, a broad reformat, or a dependency bump is a
recovery problem. Permission prompts, allow-lists, and sandboxes exist because
actions are not free. This page is about that difference and how to instruct and
supervise agents when tools are on.

Most of what follows is **craft guidance** about agent workflows. Official docs
still anchor related ideas: define success criteria before you iterate, keep
instructions clear and scoped, remember that tool output and history consume a
finite context window, and treat request payloads as data that leaves the
machine.

## When it is useful

Use this model whenever you enable file edit, terminal, or browser tools on an
assistant:

- Multi-step implementation ("add the endpoint and wire the test").
- Investigation that needs to read the real tree, not a paste.
- Refactors where you must limit which paths may change.
- Any task where a mistaken command is costly (migrations, force pushes,
  production configs — usually out of scope for casual agent runs).

If the product is chat-only, tools-and-actions risk is mostly limited to what
you copy-paste; with tools, the agent can act before you re-read every line.

## Prerequisites

- A coding agent or IDE assistant with tools enabled (file read/write, terminal,
  or similar), and you know how to deny or approve tool calls in that product.
- Version control available so you can inspect diffs and revert (strongly
  recommended before large agent edits).
- Clear and direct instructions: outcome, success criteria, and scope for paths
  and commands.
- Awareness that context is finite and accumulates (including tool traces).

## Current syntax

Instruction shape that bounds tools and blast radius:

```
Goal: Fix the failing test in tests/billing/invoice.test.ts

Success criteria:
- That test file passes
- No other test files modified
- No dependency or CI config changes

Tool permissions you may use:
- Read any file under src/ and tests/
- Edit only: src/billing/invoice.ts and tests/billing/invoice.test.ts
- Run: the single test command for that file (project standard)

Do not:
- Run destructive git commands (reset --hard, push --force, clean -fd)
- Install packages or change lockfiles
- Open network calls to production systems

If a change needs a wider path or a different command, stop and ask.
```

Adjust the allow-list to your product's permission model; the transferable idea
is explicit **may / must not** for paths and commands.

## What happens (local and remote)

**Locally**, approved tool calls can read your disk, overwrite files, create
branches, run builds, and execute whatever the shell can reach with your user
permissions. Blast radius is your account on that machine (and anything those
commands can touch: local databases, mounted drives, cloud CLIs already logged
in). Denying a tool call keeps that step from running; approving it is a real
action, not a preview.

**Remotely**, the model still receives prompts and often receives **tool
results** (file excerpts, command stdout, errors) as part of later turns. Those
results occupy the accumulating context window and are sent to the provider like
any other message content. Secrets printed by a command, `.env` contents the
agent was allowed to read, or proprietary code in a diff can leave the machine
through that channel. Stateless message APIs re-send history; long agent traces
grow the payload over time.

Permission gates are a local control plane; they do not encrypt or redact what
you already allowed the agent to load into context.

## Practical example

You ask: "Clean up the repo." An unbounded agent might delete ignored build
artifacts, reformat the entire tree, and "helpfully" rewrite CI. A bounded turn
looks like:

```
$ git status
$ git diff
# review before committing anything the agent wrote
```

And the prompt constrained:

```
Remove only untracked files under tmp/preview/ that match *.log
Do not delete source, tests, or git metadata
Show the file list before deleting; wait for my OK if your tool supports it
```

If the agent already edited the wrong files, prefer `git checkout -- <path>` /
`git restore` (or your VCS equivalent) for tracked paths, and restore from
backup for untracked losses. Treat "the agent said it worked" as a claim to
verify, not a commit reason.

## Explanation guidance

### Essential

Tools turn suggestions into actions with real blast radius. Scope paths and
commands. Prefer the minimum permissions needed for the task. Review diffs and
command output yourself. Tool traces consume context and can ship sensitive
content to the provider. Clear success criteria still apply; agents do not get
a free pass because they "did something."

### Experienced-user note

A useful habit is to separate **read-only investigation** (list, search, test
in dry modes) from **write** steps, and to keep high-risk commands off the
default allow-list. After a large agent session, prune or restate goals so stale
tool logs do not drown the constraints (context hygiene). Never imply that a
paid agent product has a guaranteed free tier; capability and billing are
product-specific.

### Optional deeper context

Products differ in how they expose tools (function calling, MCP, IDE actions).
The essentials stay the same: each tool has inputs, side effects, and an
approval story. Official prompt-engineering docs do not replace reading your
agent's security settings; they only remind you to define success and keep
instructions tight before you let tools run.

## Cautions and common failures

- **Approving tool calls without reading them.** The summary line can hide a
  destructive flag or the wrong directory.
- **Unbounded "fix everything" prompts.** Wide scope plus write tools is how
  surprise refactors land.
- **Secrets via tool output.** Commands that print env vars or config files feed
  those values into context and then to the provider.
- **Trusting the agent that a command succeeded.** Exit codes and local re-runs
  are the check; narrative confidence is not.
- **No VCS safety net.** Without commits or a clean branch, undoing agent edits
  is harder.
- **Force pushes and hard resets via agent.** Keep them off the allow-list unless
  you are deliberately supervising a recovery.

## Related capabilities

- Clear and direct instructions — success criteria and scope before tools run.
- Context and working memory — tool results fill the window; restate constraints.
- Verifying agent work — read the diff, re-run tests, check claims against
  artifacts.

## Official sources

- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview>
  — success criteria and empirical testing as prerequisites for prompt work.
- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>
  — clear, direct, scoped instructions that reduce over-building.
- <https://platform.claude.com/docs/en/build-with-claude/context-windows> —
  accumulating context across turns (including material fed back from tools).
- <https://platform.claude.com/docs/en/build-with-claude/working-with-messages> —
  stateless requests; history and payloads re-sent to the provider.

## Provenance

Authored 2026-08-02. **Most of this page is practice guidance** for tool-using
coding agents (blast radius, permission gates, allow-lists, local recovery).
Official Anthropic platform docs cited above — retrieved via Context7
(`/websites/platform_claude_en`) — anchor success criteria, instruction clarity,
context accumulation, and the fact that request content is sent to the provider.
They are not a full vendor manual for every agent product's tool runtime. Module
policy: `../provenance.md` and `../source-registry.md`.

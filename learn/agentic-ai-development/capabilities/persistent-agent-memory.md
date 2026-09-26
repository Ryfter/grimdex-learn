---
title: Persistent agent memory vs. working context
module_id: agentic-ai-development
capabilities:
  - persistent-agent-memory
context7_library: /websites/platform_claude_en
context7_queries:
  - How does an AI coding agent retain context between sessions?
  - What is the difference between an agent's working context and persistent memory?
  - How do agents save notes or summaries so a future session can pick up where one left off?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/compaction
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

Persistent agent memory is the practice of deliberately saving information from an agent session so a future session can use it, as opposed to relying on the agent's working context, which disappears when the session ends.

The distinction is simple but important:

- **Working context** is everything the agent has loaded right now: the conversation so far, files it has read, tool results, its own reasoning. It's what the agent "knows" during the session. When the session ends, this is gone.
- **Persistent memory** is anything you or the agent deliberately save outside that ephemeral context — a summary file, a notes file, an instructions file, or output written by a memory feature a tool provides — so the next session can pick up context it would otherwise lose.

**An honest caveat up front: this is an emerging, unsettled area.** There is no single canonical "agent memory architecture" that the industry has agreed on. Different tools implement memory differently (some offer built-in memory features, some rely on convention files like AGENTS.md or CLAUDE.md, some leave it entirely to the user to manage files). This page teaches the *distinction* and the *practices*, not a standard.

## When it is useful

- **Long or multi-session projects.** A project spanning days or weeks outlives any single session. Without saved memory, every new session starts nearly from scratch.
- **Onboarding an agent to a codebase once, not repeatedly.** Conventions, quirks, and decisions are exactly the kind of context worth persisting so they don't have to be re-explained every session.
- **Handoffs between people or sessions.** If a colleague (or your own future self) picks up the work, persistent memory is what makes the agent's earlier reasoning recoverable.
- **After compaction or long sessions.** Even within one session, older context may be summarized or dropped as the window fills; saved notes survive that.

It is less useful for short, one-shot tasks where the session ends when the task does — there's nothing worth persisting.

## Prerequisites

- Basic familiarity with running an AI coding agent against a project (see this module's earlier lessons).
- Awareness of repo instruction files (AGENTS.md / CLAUDE.md) — covered elsewhere in this module — since these are one of the most common de facto memory mechanisms.
- Ordinary file/git literacy: persistent memory in practice usually means ordinary files in the repo or workspace.

## Current syntax

There is no standard syntax for agent memory — that is part of what makes this an emerging area. What exists today falls into a few recognizable shapes:

- **Repo instruction files** (AGENTS.md, CLAUDE.md, Cursor's .cursor/rules): plain-Markdown files an agent reads automatically at session start. Effectively long-lived memory of project conventions.
- **Deliberately written summary/notes files**: you (or the agent, on request) write a file capturing decisions, open questions, and state before a session ends.
- **Vendor-specific memory features**: some tools offer built-in memory or auto-summary mechanisms. These exist and are evolving; check your specific tool's documentation rather than assuming a universal behavior.

## What happens (local and remote)

All of this is local in the common coding-agent case:

- Working context lives in the session itself and is discarded when it ends (some tools also compact/summarize older context mid-session — see the context engineering lesson).
- Persistent memory is just files: written to your repo or workspace, readable by the next session like any other file, and (if committed) shared with teammates through normal version control.

For hosted or cloud agents, memory features may be stored server-side by the vendor. Be mindful of what gets persisted where — anything the agent "remembers" may be stored outside your machine, which matters for the secrets-and-data-hygiene concerns covered elsewhere in this module.

## Practical example

A typical pattern at the end of a substantial working session:

1. Ask the agent to write a short `NOTES.md` (or update the project's AGENTS.md/CLAUDE.md) capturing: what was done, key decisions and why, what's unfinished, and any gotchas discovered.
2. Review the file briefly — it should read like a handoff note to a competent colleague, not a transcript.
3. Commit it with the work (or leave it untracked if it's purely personal working notes).
4. In the next session, the agent reads that file as part of its normal context and starts warm instead of cold.

Contrast: without this step, the next session re-derives (or mis-derives) all of that context from scratch, and you re-explain conventions you've already explained twice.

## Explanation guidance

### Essential

- **Working context = this session. Persistent memory = saved for next time.** That's the whole core distinction.
- Working context evaporates when the session ends; anything not deliberately saved is lost.
- The most common de facto memory mechanisms are plain files: repo instruction files and hand-written summary notes. No exotic technology is required.
- This is an emerging area with no settled standard — expect different tools to behave differently, and check your tool's docs.

### Experienced-user note

- Treat memory files like any other code artifact: review what the agent writes into them before trusting it, and keep them concise. A bloated memory file pollutes the context of every future session — the opposite of what it's for.
- Distinguish shared project memory (conventions, decisions — belongs in committed files like AGENTS.md) from personal working memory (scratch notes — often better untracked).
- Memory interacts with context management: as sessions get long, compaction may summarize away details you'd rather keep; a notes file is your insurance.
- Be cautious about what persists: secrets or sensitive data written into memory files can leak into future sessions and, if committed, into the repository. Keep the module's data-hygiene guidance in mind.

### Optional deeper context

- There's active experimentation in the field — dedicated memory tools, auto-generated session summaries, retrieval over past sessions — but none of it has consolidated into a canonical architecture. Treat vendor memory features as convenient conveniences to evaluate, not as guarantees.
- The mental model that generalizes: an agent is stateless between sessions unless you give it a place to persist state. Every "memory" mechanism is ultimately some variation of "write it down somewhere the next session reads."

## Cautions and common failures

- **Assuming the agent remembers.** The most common failure: assuming last session's context carries over. It doesn't, unless it was saved somewhere the new session reads.
- **Memory files going stale.** An instruction or notes file describing an approach you've since abandoned will actively mislead future sessions. Prune memory files as decisions change.
- **Over-stuffed memory.** Cramming everything into memory files bloats every future session's context and degrades performance (context rot) rather than helping.
- **Sensitive data in persistent files.** Anything written into memory files can be committed, shared, or re-read indefinitely. Keep secrets and credentials out entirely.
- **Trusting a vendor's "memory" feature blindly.** Features vary and are still evolving; verify what's actually saved, where, and how to inspect or delete it.

## Related capabilities

- **Repo instruction files (AGENTS.md / CLAUDE.md)** — the most common de facto persistent-memory mechanism for project conventions; see the corresponding lesson in this module.
- **Context engineering and context window management** — compaction and working-context behavior within a session; persistent memory complements it across sessions.
- **Checkpoints, diffs, and rollback for agent work** — committing reviewed work pairs naturally with committing reviewed session notes.
- **Secrets and data hygiene for agent context** — what should never end up in files an agent (or its future sessions) will read.

## Official sources

- <https://platform.claude.com/docs/en/build-with-claude/compaction> -- Anthropic's real, current context-management/compaction feature, the closest official anchor for "what happens to context over a long session." It does not itself describe a persistent-memory architecture -- no canonical source for that specific topic exists.

This page otherwise covers emerging practice without a settled canonical source. There is no single authoritative specification for agent memory to cite. The repo instruction-file conventions it references (such as AGENTS.md) are real published formats — see <https://agents.md/> — and specific vendors document their own memory features in their own product docs. Simon Willison's writing on agent context management is a useful practitioner reference, though no single post is cited here as canonical.

## Provenance

The working-context vs. persistent-memory distinction taught here is real and useful, but it is explicitly an **emerging, unsettled area with no canonical source**: there is no standard memory architecture for agents, and no vendor-neutral specification to anchor this page to. Accordingly, `context7_library` and `official_sources` are intentionally empty rather than filled with an invented citation. The page presents the distinction and the common file-based practices as current practitioner practice, and plainly flags that vendor memory features are evolving and non-uniform.
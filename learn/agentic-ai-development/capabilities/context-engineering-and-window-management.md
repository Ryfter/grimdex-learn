---
title: Context engineering and window management
module_id: agentic-ai-development
capabilities:
  - context-engineering-and-window-management
context7_library: /websites/platform_claude_en
context7_queries:
  - How does Claude's compaction/context management feature work for long-running agent sessions?
  - What is Anthropic's official guidance on when to delegate work to subagents?
  - How should I manage an agent's context window over a long coding session?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/compaction
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
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

An agent's **context window** is the working memory it can hold at once: your instructions, the files it has read, the tool calls it has made and their results, and the conversation so far. It is finite. Over a long agent session, that window fills up with earlier turns, file contents, and tool output — and what fills it matters as much as how much space is left.

**Context engineering** is the practice of deliberately managing what is in that window: keeping it current, trimming what no longer matters, and delegating bulky work out of the main session. Anthropic's platform documentation describes a real, current **context management / compaction** feature for this: when a conversation approaches a token threshold, a compaction event summarizes older turns while preserving recent ones, so a long-running agent session doesn't silently lose earlier context or blow the context window. This is a documented API feature, not informal folklore.

A second documented lever is **subagent delegation**: handing a large, self-contained chunk of work to a separate agent whose bulky exploration happens in its own context, with only the result coming back to yours.

## When it is useful

- Long agent sessions: multi-file changes, extended debugging, or any run that stretches past a handful of tool calls.
- Research-style or multi-step investigation tasks that would otherwise flood the main session's window with intermediate output.
- Any time an agent starts repeating earlier reasoning, losing track of earlier decisions, or producing output that ignores something it handled correctly an hour ago — classic signs the working context is degraded or nearly full.

## Prerequisites

- Basic familiarity with what a coding agent is and how a session proceeds through tool calls (see this module's introductory material).
- For compaction specifically: access to a platform/API plan that includes the context management feature; consult the official docs below for availability.

## Current syntax

There is no command syntax for this capability in the everyday sense. What exists:

- **Compaction/context management** is a documented, current API feature (see Anthropic's compaction docs). It is triggered automatically when a conversation approaches a token threshold; check the official docs for exact invocation options.
- **Subagent delegation** is a prompting/behavioral practice, not a syntax. Anthropic's prompt-engineering guidance describes how to instruct the agent to delegate.

Do not assume specific flag names or settings beyond what the official docs state.

## What happens (local and remote)

- **Compaction:** when the session nears the token threshold, older turns are summarized and recent turns are preserved. The session continues with a condensed version of its own history instead of failing or silently dropping context. This happens on the platform side as a documented feature of the conversation lifecycle.
- **Subagent delegation:** the main agent hands a task to a sub-agent, which does its own reading, searching, and reasoning in a separate context. The result returns to the main session. The main window stays lean because the bulky intermediate work never occupies it.
- Locally, the visible effect is that your agent can keep working productively across a long session rather than degrading or stopping.

## Practical example

A practitioner asks an agent to audit twelve independent modules for a specific pattern. A poorly managed approach: the agent reads all twelve files into its main context one after another; by module nine, its reasoning is cluttered, it contradicts its earlier findings, and it may hit the window limit.

A context-aware approach: the agent delegates each module audit to a sub-agent (they are independent, so this fits the delegation guidance), each sub-agent reads and analyzes in its own context, and only a concise per-module finding returns to the main session. The main window stays small enough to hold the cross-module comparison and the final report — the part that actually needs shared context.

Along the way, if the session runs long, compaction ensures earlier findings from the first modules aren't silently lost: older turns are summarized while recent ones stay verbatim.

## Explanation guidance

### Essential

- A context window is finite working memory. It fills up as a session progresses; a full or cluttered window degrades results.
- Compaction is a real, documented feature: near the token threshold, older turns get summarized and recent turns preserved, so long sessions don't fail or silently lose earlier context.
- Delegate only large, genuinely independent or parallelizable tasks. Don't delegate small work you could finish directly, don't use subagents just to double-check your own work, and keep the number of sub-agents low — these are Anthropic's own documented guidelines.
- If you teach only one habit: keep bulky, throwaway exploration out of the main context; keep the main context for the work that needs to see everything.

### Experienced-user note

- **"Context rot"** — performance degradation as context grows large and cluttered with irrelevant history — is a widely observed phenomenon across tools, but it is a practitioner observation, not a formal term from any vendor's documentation. Use the phrase with that caveat.
- Compaction summarizes; it does not perfectly preserve. Detailed specifics from early turns may survive only in condensed form, so it is worth capturing critical decisions or constraints in a durable artifact (a plan file, notes, or the repo's instruction file) rather than relying on session memory alone.
- Delegation is a context-management tool as much as a parallelism tool: its main benefit in a long session is that intermediate exploration never occupies the window you're reasoning in.

### Optional deeper context

- Context engineering generalizes beyond compaction and delegation: deciding what instructions, files, and history belong in the window at all is the same discipline behind repo instruction files and careful tool-result handling — see Related capabilities.
- The compaction threshold behavior is a platform feature; teams building on the API should read the official compaction documentation rather than reverse-engineering thresholds empirically, since details may change.

## Cautions and common failures

- **Assuming a full window behaves like a partially full one.** Degradation as context grows is real and commonly observed, even before a hard limit is hit.
- **Over-delegating.** Spawning sub-agents for small or tightly-coupled work fragments shared context and adds coordination cost for no benefit. Anthropic's guidance explicitly warns against this.
- **Trusting summaries implicitly.** Compaction preserves recent turns verbatim and summarizes the rest; the summary is a compression, not an archive. Critical constraints should live somewhere durable.
- **Treating context rot as a vendor term.** It is an observed phenomenon, useful shorthand, but not formal doctrine — say so if you use the term with others.

## Related capabilities

- Repo instruction files (AGENTS.md / CLAUDE.md) — keeping standing project conventions in the window without re-explaining them each session.
- Verifying agent work — for the general discipline of checking what an agent actually did rather than what it claims.
- Multi-agent orchestration — for the honest trade-offs of fanning work out to parallel sub-agents, including the shared-context failure mode.
- Secrets and data hygiene for agent context — what should never enter the window in the first place.

## Official sources

- Anthropic platform docs — compaction / context management: https://platform.claude.com/docs/en/build-with-claude/compaction
- Anthropic platform docs — prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Anthropic platform docs — prompting Claude Opus 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5

## Provenance

- The compaction / context-management feature and the subagent-delegation guidance are Context7-verified from Anthropic's own platform documentation (sources listed above).
- "Context rot" is presented as a widely observed practitioner phenomenon across tools, not a formal Anthropic term; no vendor citation is claimed for it.
- All content is drawn from the grounding facts for this module; no commands, flags, statistics, or citations beyond those facts have been invented.

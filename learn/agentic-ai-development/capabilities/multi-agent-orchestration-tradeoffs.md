---
title: Multi-agent orchestration -- the honest tradeoffs
module_id: agentic-ai-development
capabilities:
  - multi-agent-orchestration-tradeoffs
context7_library: /websites/platform_claude_en
context7_queries:
  - When should a Claude agent delegate work to subagents?
  - How many subagents should be spawned for parallel tasks?
  - What tasks should not be delegated to subagents?
  - How does subagent delegation relate to context window management?
official_sources:
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

Multi-agent orchestration means splitting a piece of work among several AI agents (or "sub-agents") that run alongside each other, each handling part of the task, with their results combined at the end. It sounds powerful, and sometimes it is -- but it is also an actively-debated practice, not a settled technique with one right answer. The honest summary:

- **Where it helps:** fanning work out to parallel sub-agents genuinely helps for tasks that are *independent and parallelizable* -- multiple things to look up or investigate that don't depend on each other. Think "check these five documentation pages" or "investigate these three unrelated bug reports."
- **Where it fails:** it breaks down when the tasks need *shared context*. Splitting work across agents fragments that context -- each agent can only see its own slice, not the others' findings. A decision that should have been informed by everything discovered so far gets made by an agent that only knows a fraction of it.

Anthropic's own prompt-engineering docs take a deliberately conservative position on this: delegate to sub-agents only large, genuinely independent tasks; don't delegate small work you could finish directly; don't use sub-agents just to double-check your own work; and keep the number of spawned sub-agents low.

## When it is useful

Consider orchestration when:

- The work naturally decomposes into chunks that truly don't depend on one another (parallel research, independent lookups, scanning separate files or systems).
- Each chunk is *large enough to be worth the overhead* -- spawning and coordinating agents has its own cost, as the Anthropic delegation guidance emphasizes.
- Combining the results afterward is straightforward, because the pieces don't need to inform each other mid-flight.

Be skeptical of orchestration when:

- Later steps depend on earlier findings -- the agents doing later steps can't see what earlier agents learned.
- The task requires one coherent, evolving picture of the problem.
- The work is small; a single agent (or you) doing it directly is faster and keeps context intact.

## Prerequisites

Before using this capability, a reader should be comfortable with:

- Basic agent sessions and tool use (see the module's earlier agentic-coding capabilities).
- Context-window basics, including that context management/compaction (a documented Anthropic API feature) handles long single-agent sessions -- which is often the *better* alternative to splitting work across agents just to "save context."

## Current syntax

There is no single syntax for multi-agent orchestration; it appears as a pattern across tools (for example, sub-agent delegation features in coding-agent harnesses). Exact invocation differs by tool, so this page describes the concepts rather than specific commands. Anthropic's platform docs cover the delegation guidance referenced above; check your own tool's official documentation for its specific sub-agent mechanism.

## What happens (local and remote)

In a typical fan-out:

1. A lead agent (or the human operator) identifies several independent sub-tasks.
2. Each sub-task is handed to a sub-agent with a self-contained brief. Each sub-agent works only with what it was given.
3. Results come back and are combined -- by the lead agent or by the human.

Locally, each sub-agent consumes its own context window; remotely, each incurs its own model calls. The coordination cost is invisible in the output but real in time and tokens. Crucially, step 3 is where the shared-context failure mode bites: if the sub-tasks weren't truly independent, combining partial results can produce a confident but incoherent whole.

## Practical example

**Good fit:** "Investigate whether these three unrelated legacy modules still have any callers." Three parallel lookups, no shared reasoning needed, combine the yes/no lists at the end.

**Bad fit:** "Research our API, then design a migration plan for it." The design depends heavily on what the research turns up. Fanning these out means the planning agent never sees the research agent's findings -- a single agent (or a sequential handoff where the plan agent receives the research results) preserves the shared context the task actually needs.

## Explanation guidance

### Essential

- Parallel agents help when sub-tasks are genuinely independent; they actively hurt when sub-tasks need shared context, because splitting work fragments that context across agents that can't see each other's findings.
- This is a real, current disagreement among practitioners -- not a solved problem with one right answer. Present it as a tradeoff to weigh per task, not a rule.
- Delegate large, independent work; do small or interdependent work directly (Anthropic's documented guidance).
- Keep sub-agent counts low; spawning more agents isn't free.

### Experienced-user note

- A hybrid works well: run independent investigation in parallel, then bring the findings back into a single agent's context for the dependent reasoning phase. The point is to *sequence* the shared-context work, not to eliminate parallelism.
- Watch for the failure signature: results that look plausible individually but contradict each other or leave unexplained gaps when combined -- usually a sign the tasks weren't independent after all.

### Optional deeper context

- The shared-context problem connects to "context rot": as any single agent's context grows large and cluttered, performance degrades -- a widely-observed practitioner observation across tools, not a formal vendor term. That pressure toward smaller contexts is one reason orchestration is tempting, but it trades a gradual problem for an abrupt one (fragmentation).
- Anthropic's compaction feature (a documented API capability that summarizes older turns while preserving recent ones) offers another route to long tasks that keeps one agent's context coherent, instead of splitting the work.

## Cautions and common failures

- **Fragmented context:** the most common failure. Sub-agents make locally reasonable choices that are globally wrong because no one agent saw the whole picture.
- **Over-delegation:** using sub-agents for small tasks, for double-checking your own work, or for anything finishable directly -- explicitly warned against in Anthropic's prompting best practices.
- **Too many spawns:** high sub-agent counts add coordination cost and failure surface without adding insight.
- **Treating orchestration as a solved best practice:** it is actively debated; what works for one team's task mix fails for another's. Stay honest about that when recommending it.

## Related capabilities

- *Verifying agent work* -- whether one agent or many produced output, verify claims against actual results, not agent narration.
- *Context engineering and context window management* -- compaction as an alternative to splitting work.
- *Planning before implementation (plan mode)* -- for dependent work, a single sequential plan usually beats parallel fan-out.
- *Human-in-the-loop interruption and steering* -- orchestration multiplies the places a run can drift; steering checkpoints matter more, not less.

## Official sources

- Anthropic platform docs, "Claude Prompting Best Practices" (sub-agent delegation guidance): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Anthropic platform docs, "Prompting Claude Opus 5" (delegation guidance): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5

## Provenance

The benefit/failure-mode framing here follows Anthropic's documented sub-agent delegation guidance (Context7-verified against platform.claude.com docs) combined with well-established cross-tool practitioner experience. The claim that fan-out fails for shared-context tasks is presented as real, current, actively-debated practice -- not vendor doctrine and not a solved problem. "Context rot" is described as a widely-observed practitioner phenomenon, not a formal Anthropic term. Anthropic's compaction feature is a documented API capability (platform.claude.com/docs/en/build-with-claude/compaction). No commands, flags, or statistics beyond the grounding facts are cited.
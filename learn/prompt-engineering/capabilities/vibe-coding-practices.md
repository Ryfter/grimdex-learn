---
title: Session habits for agentic coding
module_id: prompt-engineering
capabilities:
  - vibe-coding-practices
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I define success criteria and empirically test a prompt or task?
  - What are common success criteria and metrics for evaluating Claude outputs?
  - How should I grade evaluations: code-based, human, or LLM-based?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
  - https://platform.claude.com/docs/en/test-and-evaluate/develop-tests
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

A set of session-level habits for working with an agentic coding assistant: how you *start* a session and how you *steer* it while it runs. This page covers four habits that happen before and during the agent's work:

1. **Start from a clean branch.** Begin each session from a known-good state so a bad session can be thrown away entirely, not untangled.
2. **Keep each task small and scoped from the outset.** Decide the task boundary before the agent starts, not just while reviewing afterward.
3. **Watch for drift.** Notice the signs that a session has wandered off-task.
4. **Interrupt and redirect mid-session.** Know when to stop a drifted session rather than let it run to completion.

A note on the term "vibe coding": used positively, it means fast, AI-assisted building — describing what you want and letting the agent handle the details. That speed is fine *if* you keep enough structure and attention in the loop. The failure mode this page helps you avoid is the other sense of the term: **accepting agent output without review**. The habits below are what keep fast building from turning into unreviewed building.

This page is cross-tool practice guidance, anchored by a few official platform-docs citations rather than presented as direct platform claims.

## When it is useful

- Any session where an agent will make multiple file changes, run commands, or take actions on your behalf.
- Especially when the agent works through several steps before you see results — the longer the unsupervised run, the more these habits matter.
- When you plan to iterate: these habits make each iteration cheap (small, disposable chunks) instead of expensive (large, entangled changes).

## Prerequisites

- A working environment where you can create a branch or otherwise snapshot your starting state (any version control system, or even a copied folder).
- A rough idea of what "done" looks like for the task. The platform's prompt-engineering docs emphasize defining **clear success criteria and an initial draft prompt before you begin refining** — the same principle applies to an agentic coding session: know what you're testing against before the agent starts. (See the official sources below.)
- Familiarity with the cross-referenced pages: how to give clear instructions, how to verify work after the fact, and what tools the agent may use.

## Current syntax

There is no syntax for this capability — it is a set of working habits, not a command or API. The platform-docs anchor that applies here is conceptual: the recommended engineering loop is *define success criteria → draft → empirically test → refine*. The habits below are the session-level version of that loop: scope the task, let the agent draft, check against your criteria, and either accept or redirect.

## What happens (local and remote)

**Local:** You create a fresh branch (or snapshot), state a small scoped task, and the agent works. You observe its intermediate behavior — files touched, commands run, whether its narration matches the task — and either let it finish or stop it and redirect. At the end, the work sits on a disposable branch where it's easy to accept, roll back, or discard.

**Remote/cloud agents:** The same logic applies when the agent runs in a hosted environment. Scope and drift still matter; what changes is that you may observe through summaries or pull requests rather than live, so mid-session redirection may be less available — which makes the *up-front scoping* and *clean starting point* habits even more important.

## Practical example

Suppose you ask an agent to "add a export button to the reports page."

**Without these habits:** you're on your main working branch with uncommitted half-finished changes. You give the broad task, walk away, and come back to changes across eleven files — some for the button, some for a "refactor" the agent decided was needed, some for a second feature it noticed. The changes are entangled with your own uncommitted work. Rolling back means losing everything.

**With these habits:**

1. **Clean branch:** You commit or stash your in-progress work and create a branch like `add-export-button`. Whatever happens, your main state is untouched.
2. **Small scope up front:** Instead of the broad ask, you say: "On the reports page, add a button labeled 'Export CSV' that downloads the currently filtered rows. Don't change anything else; if you think a refactor is needed, mention it in your summary instead of doing it." The reason for the "don't change anything else" rule is stated, not just asserted.
3. **Watch for drift:** Midway, you notice the agent's narration: "First, let me restructure the data layer for cleaner exports…" You never asked for a data-layer restructure — that's a drift signal.
4. **Interrupt:** You stop the session and redirect: "Stop — don't restructure anything. Revert any changes outside the reports page component and continue with only the button."

The session ends with a small, reviewable diff on a throwaway branch — cheap to accept, cheap to discard.

## Explanation guidance

### Essential

- **Clean starting point.** Before an agentic session, get to a state you can restore: a fresh branch off a known-good commit, or at minimum a snapshot. This costs seconds and converts a catastrophic session into a discarded branch. (The *verification* of what the agent produced afterward is covered in `verifying-agent-work.md`; this page is about making sure the session starts somewhere safe.)
- **Scope the task small before it starts.** Small, well-bounded tasks produce small, well-bounded changes. This is not the same as reviewing small chunks after the fact — it's choosing the chunk size yourself, in the initial prompt. A good scoping statement includes the desired outcome, an explicit boundary ("only touch X"), and a reason for the boundary (e.g., "so the diff stays reviewable").
- **Drift signs to watch for:**
  - The agent's narration mentions files, modules, or goals you never asked about.
  - It starts "fixing" or "improving" adjacent things.
  - Its stated plan no longer matches your original task.
  - The change footprint grows well past what the task needs.
- **Interrupt early.** A drifted session that runs to completion produces more drift to unwind. Stopping and redirecting with specific failure facts is cheaper than reviewing and rejecting a large off-task result. Redirect, don't just re-explain the whole task: point at the specific deviation and instruct it to revert or refocus.
- **The failure mode:** "Vibe coding" as unreviewed acceptance. If the agent's output is never checked — by you or by tests — the speed of the session is borrowed against problems you'll find later, at higher cost. The discipline on this page is what lets you build fast *and* stay in control.

### Experienced-user note

- The scoping habit pairs naturally with the platform docs' emphasis on **empirical success criteria**: if you can state a checkable criterion ("button appears only when rows are selected; clicking downloads a CSV of exactly those rows"), you can test the result mechanically rather than by vibes — even a quick manual check counts as an empirical test against a criterion.
- On longer sessions, consider checkpoints: if the agent completes a coherent, in-scope chunk, let it commit so a later drift can be rolled back to that point. (The commit-and-verify rhythm itself is detailed in `verifying-agent-work.md`.)
- Drift is often a symptom of an underspecified prompt. If you find yourself interrupting the same session repeatedly, the initial scoping statement — not the agent — is usually the thing to fix.

### Optional deeper context

- The platform's testing docs list common success-criteria dimensions — task fidelity, consistency, relevance, coherence, and so on — and measurement methods from quantitative metrics to qualitative review. For coding sessions, "task fidelity" (did it do the task and only the task?) is usually the criterion most threatened by drift, and "relevance" maps directly to the drift signs above.
- The same docs describe a cost/speed spectrum of grading methods: code-based checks (fastest, most reliable for objective rules), human review (highest quality, slowest), and LLM-based grading (a scalable middle ground that needs its own rubric and testing). A session habit that maps onto this: automate the objective checks (tests, lint) so your human attention is reserved for the judgment calls.
- For long-running autonomous agents, mid-session observation becomes a supervision problem — what the agent is *allowed* to do while live is covered in `tools-and-agent-actions.md`.

## Cautions and common failures

- **Skipping the clean branch because "it's a small task."** Small tasks drift too, and a small unreviewed change on your main state is still an unreviewed change.
- **Bread-and-butter scope creep accepted silently.** An agent that helpfully "also fixed" three other things has produced a diff you can't cleanly evaluate. If it happens, either revert the extras or explicitly re-review them as new work — don't let them ride along.
- **Interrupting too vaguely.** "Stop, that's wrong" gives the agent nothing to work with. Name the deviation specifically and say what to do with the off-task work (revert it, or leave it and continue).
- **Letting a drifted session finish "because it's almost done."** Completion bias. A finished off-task result costs more to unwind than an interrupted one.
- **Confusing speed with the failure mode.** Fast sessions are fine. The failure is accepting output without review — which the *verification* habits address after the fact, and the *scoping and steering* habits on this page reduce the need for.
- **Treating drift as the agent's fault only.** Recurrent drift usually traces back to an ambiguous initial task. Fix the scoping, not just the session.

## Related capabilities

- `tools-and-agent-actions.md` — what the agent may *do* with tools while working: blast radius, permission prompts, allow-lists, and sandboxing. This page covers steering; that page covers the guardrails around the agent's actions.
- `verifying-agent-work.md` — the after-the-fact checklist: reviewing diffs, running tests, accepting or rejecting chunks, and committing good work in small pieces. This page's habits make that verification cheaper; that page's habits make each session's output trustworthy.
- `clear-and-direct-instructions.md` — how to state the outcome and give reasons for rules; the scoping statements on this page are an application of it.

## Official sources

- Prompt engineering overview (define success criteria, draft, test, refine): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
- Developing tests and evaluations (common success criteria, metrics, grading methods): https://platform.claude.com/docs/en/test-and-evaluate/develop-tests

## Provenance

- **Grounding:** Context7 retrieval from `/websites/platform_claude_en`, 2026-09-20. The success-criteria/empirical-loop framing, success-criteria dimensions, and grading-method spectrum come from the two official sources above. The session-level habits (clean branch, up-front scoping, drift watching, mid-session redirection) are cross-tool practice guidance consistent with those anchors, not verbatim platform-doc claims.
- **Scope boundaries:** Deliberately does not repeat content from `tools-and-agent-actions.md` or `verifying-agent-work.md`; cross-references instead.
- **Last checked:** 2026-09-20.
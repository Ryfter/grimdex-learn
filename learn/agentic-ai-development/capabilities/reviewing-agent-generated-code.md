---
title: Reviewing agent-generated code and staying accountable
module_id: agentic-ai-development
capabilities:
  - reviewing-agent-generated-code
context7_library: /websites/platform_claude_en
context7_queries:
  - How is reviewing AI-generated code different from reviewing human-written code?
  - How do I spot hallucinated APIs in agent-generated code?
  - How do I verify an agent's claims against the actual diff and test runs?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
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

Reviewing agent-generated code is the discipline of treating an AI coding agent's output as an unreviewed contribution from an eager junior developer: fluent, fast, plausible — and not automatically correct.

This is an **emerging practice with no single canonical source**. There is no one authoritative guide for "how reviewing AI-generated code differs from reviewing human code," so what follows is a plain statement of practitioner-reported differences, not vendor doctrine:

- **Hallucinated APIs.** Agents can produce code that reads beautifully but calls a plausible-sounding function, method, or parameter that does not actually exist — in your codebase or in a library. Fluency is not evidence the API is real.
- **Missed edge cases.** Agent code often handles the obvious, happy-path case correctly but misses the corner case a careful human reviewer would ask about: empty input, unusual formats, concurrent access, partial failure.

The core accountability principle is unchanged from ordinary review: **you are accountable for what you merge, regardless of who or what wrote it.** "The agent said it worked" is not a review.

## When it is useful

- Any time an agent opens a pull request, edits files, or hands back a "done" claim — in an IDE, a terminal session, or a CI-driven issue-to-PR workflow.
- Especially when you are not deeply familiar with the code being touched: agent output can look more confident (and more polished) than a human's first draft, which makes skipping review tempting precisely when it is riskiest.
- When deciding whether to accept, redirect, or reject an agent's approach — ideally early, before a large diff exists.

## Prerequisites

- Familiarity with normal code review practice and with the repository being changed.
- The verification habits covered in the existing **verifying-agent-work** lesson — this page builds on that discipline rather than replacing it (see Related capabilities).
- Ideally, a plan-first workflow: catching a wrong approach in a short plan costs minutes; catching it after implementation costs a rewrite.

## Current syntax

Not applicable — this capability is a review practice, not a syntax or feature.

## What happens (local and remote)

- **Locally:** you read the actual diff (not the agent's narration), run the tests and other checks yourself, and confirm the change does what was asked — and nothing extra.
- **Remote / CI:** when an agent is assigned an issue and opens a draft pull request (a real, shipped pattern, e.g. GitHub's Copilot coding agent), human review and approval via branch protection is the gate before merge. The same review discipline applies.

## Practical example

An agent says: "Done — added the `normalizePhoneNumbers` helper and all tests pass."

A review that keeps you accountable:

1. Read the actual diff, not the summary. Confirm `normalizePhoneNumbers` exists and does what the name suggests — agents can invent a function that sounds right but does not exist anywhere.
2. Check it was only called where appropriate, and nothing unrelated was changed along the way.
3. Run the test suite and type-checker yourself and read the real output.
4. Ask the corner-case question the agent may not have: what happens with an empty list, an international format, a null value?
5. Accept, redirect, or reject — then commit/checkpoint the good chunk so rollback stays cheap if later agent work goes wrong.

## Explanation guidance

### Essential

- An agent's output is non-deterministic and is optimized to look plausible; a confident, fluent diff can still be wrong.
- Two characteristic failure modes to look for specifically in agent code: **hallucinated APIs** (plausible-sounding but nonexistent functions, methods, or parameters) and **missed edge cases** (obvious case handled, corner case not).
- Never accept "it works" as a claim — verify against the actual diff and actual test runs.
- You remain accountable for merged code no matter who wrote it. Review is not optional because the author was fast and free.

### Experienced-user note

- Reviewing a plan before code is written is cheaper than reviewing a large diff afterward — catch the wrong approach early.
- An agent is only as trustworthy as the feedback signal it can see: if the repo has tests, linters, and a build the agent runs itself (a closed loop), its claims are more likely to survive your review. If there is no objective check, expect output that looks right rather than is right.
- Commit or checkpoint each reviewed chunk of agent work; unpicking one giant diff at the end of a long session is far more painful.

### Optional deeper context

- The reason fluent-but-wrong code is common: models generate what is statistically plausible, and plausible naming patterns ("this must have a `validate` method somewhere") produce confident calls into functions that were never defined.
- Hallucinated APIs are easiest to catch mechanically: a failed type-check, a failing import, or a test run will expose a nonexistent symbol quickly — another argument for keeping the verification loop in place before review, not after.

## Cautions and common failures

- **Trusting the narration.** The agent's summary of its own work is the least reliable input to review. Read the diff and the test output.
- **Reviewing by fluency.** Clean, well-commented code creates an illusion of correctness. Judge behavior, not prose.
- **Skipping review because "it's only a small change."** Small hallucinated fixes can be the hardest to notice and the most costly later.
- **Rubber-stamping under volume.** When an agent produces many diffs quickly, the temptation is to approve in batches. Batch approval is batch accountability — for everything in them.
- **No stated canonical source.** This page is emerging-practice guidance: there is no settled, citable framework for agent-code review specifically. The recommendations here are practitioner consensus, and the underlying verification discipline is covered canonically elsewhere (see verifying-agent-work).

## Related capabilities

- **verifying-agent-work** — the core discipline of verifying agent claims against the actual diff and actual test runs. This page covers what's *different* about agent-generated code; that lesson covers the verification loop itself. Cross-reference it rather than re-deriving it here.
- Spec-driven / plan-first development — reviewing the plan catches wrong approaches cheaply.
- Checkpoints, diffs, and rollback for agent work — commit reviewed chunks so later failures are cheap to undo.

## Official sources

- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview> -- success criteria and empirical testing, the discipline this page's review habit applies to agent-generated code specifically. It does not itself describe "how to review AI code" -- no canonical source for that specific practice exists; this is the closest related official anchor, not a direct citation for the page's core claim.

## Provenance

- **Emerging practice, no canonical source:** there is no single authoritative guide for how reviewing AI-generated code differs from reviewing human code. The two practitioner-reported differences taught here (hallucinated APIs, missed edge cases) and the accountability principle are real and consistently reported, but they are practitioner consensus, not vendor doctrine — and this page says so plainly rather than attaching a citation.
- The core verification discipline is not repeated here; it is cross-referenced to the existing verifying-agent-work lesson in this module.
- Part of this page overlaps with other capabilities in this module (plan-first review, checkpointing) and defers to them rather than re-teaching them.
- last_checked / last_material_update: 2026-09-20
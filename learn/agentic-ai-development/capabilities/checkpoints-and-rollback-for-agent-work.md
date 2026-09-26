---
title: Checkpoints, diffs, and rollback for agent work
module_id: agentic-ai-development
capabilities:
  - checkpoints-and-rollback-for-agent-work
context7_library: /websites/git-scm
context7_queries: []
official_sources:
  - https://git-scm.com/docs/git-commit
  - https://git-scm.com/docs/git-stash
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

Checkpointing agent work means committing (or otherwise saving) after each good, reviewed chunk of an agent session, rather than letting one long session accumulate a single giant change. Because agent sessions run fast and can produce large amounts of code quickly, small, frequent checkpoints make rollback cheap: if a later chunk goes wrong, you discard just that chunk. Without checkpoints, recovering from a bad stretch means hand-unpicking one enormous diff at the end of the session — slow, error-prone, and often easier to abandon than to fix.

This is agent-specific hygiene layered on top of ordinary git use. The underlying mechanics are standard version control; what's new is the pacing — checkpoints after each reviewed chunk instead of one big commit at the end. For the git mechanics themselves, see this module's git-and-github content rather than this page.

## When it is useful

- Any multi-step agent session where changes accumulate: refactors, feature work, migration scripts, bug hunts.
- When an agent is iterating — try, check, revise — and you want the ability to back up to the last known-good point cheaply.
- When a session is long enough that "what the agent did" is hard to reconstruct from memory; a sequence of small commits is itself a readable record of the session.
- Whenever you review agent work in chunks: checkpoint right after each chunk passes review, so review and rollback align.

## Prerequisites

- Basic familiarity with version control (see this module's git-and-github content for the mechanics — this page does not re-teach git).
- A habit of reviewing each chunk of agent output before checkpointing it (see the related verifying-agent-work capability).

## Current syntax

There is no new syntax or command set for this practice — it uses whatever commit/checkpoint mechanism your tooling already provides. The guidance is about cadence, not commands: checkpoint after each good, reviewed chunk; let the agent know when a point is "safe" if your tool supports communicating that; avoid checkpointing unreviewed work just to keep the sequence moving.

## What happens (local and remote)

Locally, each checkpoint is a small, self-contained commit: one reviewed, working chunk. If a later chunk turns out badly, you roll back to the last checkpoint and lose minutes of agent work, not the whole session. The diff between checkpoints stays small enough to actually read during review.

Remotely, the same habit applies when agent work lands via branches or pull requests: small, reviewable units rather than one sprawling change. If your tooling offers automatic session checkpoints or history snapshots, they serve the same purpose — a cheap "go back to before that bad idea" point — but deliberate commits after review remain the durable, shareable record.

## Practical example

An agent refactors a module and then starts rewriting the calling code. The refactor chunk reviews clean, so you checkpoint it. Ten minutes later, the agent's rewrite of the callers is a mess. You roll back to the post-refactor checkpoint, re-prompt with a clearer instruction, and keep the good refactor. Total cost: minutes. If instead you had let the whole session run and committed at the end, you'd face one giant mixed diff — good refactor and bad rewrite entangled — and pulling them apart by hand could take longer than redoing the work.

## Explanation guidance

### Essential

The core idea: agents move fast, so make going backwards cheap. Commit after each reviewed chunk; if the next chunk goes wrong, discard it and continue from the last good point. Compare that to the alternative — one big commit at the end, and a bad chunk means hand-unpicking a giant diff. Small checkpoints are cheap insurance bought with a few seconds of commit discipline.

### Experienced-user note

Checkpoints double as a debugging surface: a clean sequence of commits shows you exactly where a session went off track, which pairs naturally with reading the agent's trace. If your workflow uses automatic checkpointing features, treat them as a convenience layer — reviewed, deliberate commits are still what make rollback trustworthy, because you know what state you're returning to. Keep diffs review-sized; if a chunk is too big to review, it's too big to checkpoint safely.

### Optional deeper context

The principle generalizes: any fast-acting automated process benefits from frequent, verified save points, for the same reason transactional systems commit incrementally rather than one monolithic write. The agent-adjacent pattern here — act, verify, checkpoint — is a natural fit with verification-first loops: the verification step is what makes a chunk "good enough" to checkpoint, and the checkpoint is what makes experimentation afterward low-risk.

## Cautions and common failures

- **Checkpointing unreviewed work.** A checkpoint of a broken chunk isn't a safety point; it just saves the problem. Review first, then commit.
- **One giant commit at session end.** The failure mode this practice exists to prevent — a diff too large to review and too entangled to unpick.
- **Assuming checkpointing replaces verification.** Checkpoints limit blast radius; they don't tell you whether code is correct. Pair them with real checks (see the related capability below).
- **Forgetting the remote side.** Long-running work that exists only in a local session or an unsaved agent workspace can vanish entirely; push or otherwise preserve checkpoints when the work matters.

## Related capabilities

- The module's git-and-github content: for the underlying commit/diff/rollback mechanics this practice builds on — cross-reference rather than re-learning here.
- Verifying-agent-work: the discipline of checking claims against actual diffs and test runs, which is what makes each checkpoint trustworthy before you commit it.

## Official sources

- <https://git-scm.com/docs/git-commit> -- the underlying commit mechanism this page's checkpoint cadence builds on.
- <https://git-scm.com/docs/git-stash> -- for shelving in-progress work as a lighter-weight checkpoint than a commit.

This page describes well-established, cross-tool practitioner practice for agentic coding sessions on top of that git mechanism, not a single vendor's documented "agent checkpoint" feature. There is no one canonical official document for the cadence guidance itself; see this module's git-and-github content for the underlying git commands in full depth.

## Provenance

The checkpointing-and-rollback guidance here is real, current, cross-tool practitioner practice: agent-specific hygiene layered on top of ordinary git use, widely reported by teams working with coding agents rather than drawn from a single vendor's official documentation. No official vendor source is cited for the cadence practice itself, per the grounding for this page; git mechanics are cross-referenced to this module's git-and-github content instead of re-taught.
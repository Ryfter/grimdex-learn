---
title: Iterating on a Prompt
module_id: prompt-engineering
capabilities:
  - iterating-on-a-prompt
context7_library: /websites/platform_claude_en
context7_queries:
  - How should I refine and test a prompt against success criteria?
  - How do I iterate on a prompt without losing track of what changed?
  - What are fast ways to re-check prompt quality between iterations?
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

Iterating on a prompt is the empirical loop of improving a prompt: define success criteria first, write (or keep) a draft prompt, test it against those criteria, make a change, and re-test. The platform's own prompt-engineering overview frames it exactly this way: before prompt engineering, "ensure you have clearly defined success criteria, a method to empirically test against those criteria, and an initial draft prompt to refine."

Two disciplines make the loop actually work:

- **Change one variable at a time.** If you tweak the instructions, add an example, and switch the output format all in one pass, you can't tell which change caused the improvement (or the regression). One change per iteration means each result is attributable.
- **Re-check against the SAME criteria every time.** The criteria are the fixed target. If you quietly redefine "good" after each test, you're not iterating toward a goal — you're rationalizing whatever the latest output looks like.

## When it is useful

- Any prompt you'll reuse more than a couple of times, especially in a workflow other people depend on.
- Prompts that work "mostly" but fail on specific inputs — iteration with edge cases is how you find and fix the pattern.
- Deciding whether a change (extra instructions, an example, a persona, a format constraint) actually helped, rather than just feeling like it did.

It's less useful for one-off throwaway prompts where "good enough on the first try" is fine.

## Prerequisites

- A draft prompt (see `clear-and-direct-instructions.md` for writing one).
- Success criteria written down before you start testing — a short list of what a good output must do. The platform's testing docs group these into dimensions like task fidelity, consistency, relevance, coherence, tone, privacy preservation, context utilization, latency, and cost. You don't need all of them; pick the few that matter for your task.
- A small set of test inputs, including a few tricky edge cases, not just the happy-path example.

## Current syntax

There is no syntax to learn — this is a process. The loop is:

1. Write down the success criteria.
2. Run the draft prompt on your test inputs.
3. Judge the outputs against the criteria.
4. Change exactly one thing in the prompt.
5. Re-run the same test inputs.
6. Compare: did the criteria-passing rate go up, down, or stay flat?
7. Keep the change if it helped, revert if it hurt, and repeat.

## What happens (local and remote)

Locally, you're just running the prompt repeatedly with small edits and recording results. If you graduate to a repeatable evaluation harness, the same loop runs programmatically: fixed test set, prompt version, graded outputs, and a score you can compare across versions. Nothing changes on Claude's side between iterations except the prompt text you send — so any behavior difference is caused by your edit, which is exactly why one-variable-at-a-time matters.

## Practical example

Suppose the task is: turn customer support emails into short ticket summaries.

**Success criteria (fixed):**
- Includes the customer's main problem in one sentence
- Includes urgency level (low / medium / high)
- Under 50 words
- No invented facts

**Test set:** 10 real emails, including one with two problems and one with no clear problem.

**Iteration log:**

| Version | Change | Passes (of 10) |
|---|---|---|
| v1 | draft | 6 |
| v2 | added "list exactly one urgency level" | 8 |
| v3 | added "if multiple problems, list each on its own line" | 9 |
| v4 | tried adding a persona ("You are a senior support lead") | 8 — regressed, reverted |

v4 dropped back to 8, so the persona was reverted. Without the log and the one-change rule, you'd never know the persona was the problem.

**Cheap re-checking per iteration:** hand-grading 10 outputs every iteration gets old fast. Use the grading-method tradeoff from the platform's evaluation docs:

- **Code-based grading** — fastest and cheapest. If a criterion is objectively checkable (word count < 50, urgency is one of three values, output parses as JSON), a simple script can grade it instantly on every run.
- **LLM-based grading** — a scalable middle ground for criteria that don't reduce to a rule, like "does the summary capture the main problem without inventing facts?" Give the grader a clear rubric, have it reason before giving a verdict, use a scale or binary output rather than vague language, and ideally use a different model to grade than the one that produced the output. (An LLM grader is itself a prompt — test that it grades reliably before trusting it.)
- **Human grading** — highest-quality judgment but slow and expensive. Reserve it for a small random sample, final acceptance before shipping, and spot-checking that the automated graders aren't drifting.

In practice: automate what's rule-checkable, LLM-grade the judgment calls, and eyeball a few outputs yourself each iteration to keep the graders honest.

## Explanation guidance

### Essential

- Write the criteria BEFORE testing; otherwise you'll grade on vibes.
- Change one thing per iteration so improvements are attributable.
- Always re-test against the same criteria and the same test inputs.
- Automate re-checking where possible (script for rules, a rubric-driven LLM grader for judgment), so per-iteration checking is nearly free.
- Keep a simple log: version, change, result. A table like the one above is enough.

### Experienced-user note

- Keep test inputs in a fixed file so every version runs on the identical set; add a failing case to the set once you find it in the wild.
- If an automated grader disagrees with your judgment on a sample, fix the grader's rubric before trusting its scores.
- Track more than pass-rate when relevant — latency and cost are legitimate criteria too (the platform's testing docs list them among common success criteria), and a prompt change can trade quality for tokens.

### Optional deeper context

- The platform's testing docs describe measurement methods beyond simple pass/fail: A/B comparison against a baseline, user feedback, and edge-case analysis. Edge-case analysis is often the highest-yield during iteration, since it surfaces exactly which criteria fail under which inputs.
- Binary or scaled LLM-grader outputs make results comparable across versions; vague qualitative verdicts ("mostly good") don't support an iteration log.
- If two changes seem independent, you can sometimes batch them — but only if you're willing to lose attribution if the combined result regresses. When in doubt, one at a time.

## Cautions and common failures

- **Shifting the target.** Relaxing a criterion after a failure ("well, an 80-word summary is fine actually") makes the loop meaningless. If a criterion is wrong, change it deliberately and note it — don't drift.
- **Changing multiple things at once.** Improvements you can't attribute are improvements you can't keep safely.
- **Overfitting to the test set.** A prompt tuned until it nails 10 specific emails may fail on the next 10. Keep some held-out inputs you never iterate against.
- **Trusting an untested LLM grader.** The platform docs note LLM-based grading must itself be tested for reliability. Verify your grader agrees with human judgment on a sample before relying on it.
- **Iteration fatigue.** If three versions pass with no improvement, the bottleneck may be the criteria, the test inputs, or the task framing — not the prompt wording.

## Related capabilities

- `clear-and-direct-instructions.md` — writing the draft prompt this loop refines; states the outcome and gives reasons for rules.
- `verifying-agent-work.md` — the analogous accept/reject-and-re-prompt loop for agent output on live tasks.
- `tools-and-agent-actions.md` — bounding the blast radius when the prompt drives a tool-using agent.

## Official sources

- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
- https://platform.claude.com/docs/en/test-and-evaluate/develop-tests

## Provenance

Grounded in the platform's prompt-engineering overview (success criteria → draft → test sequence) and its test-and-evaluate pages (success-criteria dimensions, grading methods and their speed/cost tradeoffs, LLM-grader reliability guidance), retrieved from /websites/platform_claude_en on 2026-09-20. The one-variable-at-a-time discipline, iteration logging, held-out test sets, and grading-automation patterns are cross-tool practice guidance consistent with those anchors, not verbatim platform-doc claims.
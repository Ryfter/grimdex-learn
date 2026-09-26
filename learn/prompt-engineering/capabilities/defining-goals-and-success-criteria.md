---
title: Defining goals and success criteria
module_id: prompt-engineering
capabilities:
  - defining-goals-and-success-criteria
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I define success criteria before prompt engineering?
  - What dimensions can I use to evaluate AI outputs?
  - What are the tradeoffs between code-based, human, and LLM-based grading?
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

Before handing a task to an AI coding assistant, define what "done" means. A success criterion is a concrete, checkable statement of what a good result looks like — not a vibe ("make it good") but a test ("all existing tests still pass, and the new function returns a sorted list for the three sample inputs I wrote down"). The Claude platform docs put this first in their prompt-engineering overview: before beginning, ensure you have clearly defined success criteria, a way to empirically test against them, and an initial draft to refine. This page is about the first of those three, and about *how* you'd actually check each criterion once you have it.

## When it is useful

Any non-trivial task. It matters most when:

- The task is vague enough that you and the assistant could disagree about what "finished" means ("clean up this script," "add error handling").
- You plan to iterate. Without criteria, each round of re-prompting becomes a fresh opinion; with criteria, it becomes a measurement loop.
- You'll ask for several similar things over time and want consistent results.

For a one-line fix you already understand, writing criteria is overkill. For everything that takes more than one prompt, it usually pays for itself.

## Prerequisites

- A task you can articulate, even roughly.
- Access to the environment where the output will be checked (a terminal for running tests, or the app where the result is used).
- No special tools or APIs required.

## Current syntax

This is a working practice, not a command. Write criteria before the first prompt, in three parts:

1. **The goal** — one sentence stating the outcome.
2. **The "done" definition** — 2–5 checkable statements. "Checkable" means you can say yes or no to each one without arguing.
3. **The check method per criterion** — which of the three grading tiers (below) you'll use for each.

## What happens (local and remote)

Nothing happens automatically — this is planning discipline. The criteria live wherever you keep notes (a scratch file, a ticket, the top of your prompt). Their effect is indirect but real:

- They shape the prompt itself: a "done" list almost always reveals instructions you'd otherwise forget.
- They give you an objective referee during iteration: after each response, check against the list, and re-prompt with the specific failures (see Related capabilities for that loop).
- They protect against scope creep: if a suggested change isn't in the criteria, you can decline it confidently.

## Practical example

Task: "Add a discount-code feature to the checkout script."

**Goal:** The script accepts an optional discount code argument and applies the right discount.

**"Done" definition:**

1. The script runs without errors on the three sample inputs I listed.
2. A valid code reduces the total by the correct amount (I'll compute the expected numbers myself).
3. An invalid code prints a clear message and exits with a nonzero status.
4. All existing tests still pass.

**Check method per criterion:**

| Criterion | Grading tier |
|---|---|
| 1, 2, 4 | Code-based: run the script and the test suite, compare against my hand-computed numbers |
| 3 | Code-based on behavior (exit code, message text); human judgment only for whether the message is *clear enough* |
| Tone/wording of the message | Code-based regex or plain eyeball — no LLM grader needed at this scale |

Note how most criteria collapse into code-based checks: does it run, do tests pass, are the numbers right. That's typical for everyday coding tasks.

## Explanation guidance

### Essential

**Pick the relevant dimensions, then turn each into a check.** The platform's testing docs list common success-criteria dimensions: task fidelity, consistency, relevance, coherence, tone, privacy preservation, context utilization, latency, and cost. You don't evaluate all nine every time — pick the ones that matter for the task. For a typical coding task:

- **Task fidelity** — does it do the thing you asked? (Usually: tests pass, behavior matches your sample cases.)
- **Consistency** — does it behave the same way across the cases you care about, or repeated runs?
- **Latency and cost** — roughly how long and how much (tokens/money) it takes. Usually a soft constraint, but worth knowing when you iterate.
- **Privacy** — if the code touches real data, did anything sensitive get copied into logs, comments, or test fixtures it shouldn't be in?

Tone and coherence matter more for written output than code; relevance and context utilization matter when the assistant has to work from documents or a codebase you provided.

**Know the three grading tiers, and pick the cheapest one that's reliable.** The platform's evaluation docs grade on a speed/cost tradeoff:

1. **Code-based grading** — fastest and most reliable for rule-based, objectively checkable things. In coding work, this is your default: does it compile, do the tests pass, does the output match expected values, does the diff touch files it shouldn't. Write it down as "run X and check Y."
2. **Human grading** — highest-quality judgment, but slow and expensive (your time). Reserve it for things only a person can judge: "is this error message actually helpful?" For most everyday coding tasks this shrinks to a few spot-checks.
3. **LLM-based grading** — a scalable middle ground for judgments that don't reduce to a simple rule ("does this summary capture the key point?"). It needs a clear, detailed rubric, works best when the grader reasons before giving a verdict, should use scales or binary outputs rather than vague language, and ideally uses a different model than the one that produced the output. It also has to be tested itself for reliability. For everyday coding tasks, you rarely need this tier — reach for it only when neither scripts nor a quick eyeball can fairly judge the criterion.

The habit to build: for every criterion you write, ask "who or what checks this — a script, me, or another model?" If the answer is "vibes," the criterion isn't done yet.

### Experienced-user note

If you already write tests, you're most of the way there — a criterion backed by a test *is* code-based grading, and it beats prose. Two refinements:

- **Binary beats vague even outside LLM grading.** "Exit code 0 and stdout contains 'applied'" is a better criterion than "handles errors nicely." The platform's advice about scales/binary outputs for LLM graders generalizes: crisp outputs make any tier more reliable.
- **When you do reach for LLM-based grading** (e.g., "review this refactor for readability"), write the rubric with specific anchors, let the grader model reason first, and — per the docs — prefer a different model as grader than the one that did the work. And calibrate it: run it on a couple of outputs you already know are good or bad, and fix the rubric until it agrees with you.

### Optional deeper context

The platform docs treat success criteria as the entry point to a broader empirical loop: define criteria → draft a prompt → test → measure → refine. Quantitative measurement (accuracy, response time, F1 where applicable) suits code-based grading; qualitative methods (Likert scales, expert rubrics) suit human judgment. Measurement approaches include A/B testing against a baseline, user feedback, and edge-case analysis — edge-case analysis being the one most coding tasks should borrow: deliberately try the weird inputs (empty string, huge file, malicious-looking code) and see whether the criteria still hold.

## Cautions and common failures

- **"Make it good" isn't a criterion.** If you can't picture the yes/no check, it isn't done.
- **Criteria written after seeing the output.** That's rationalization, not evaluation. Write them first, even crudely.
- **Over-engineering.** Five checkable criteria beat twenty aspirational ones. If you catch yourself planning an LLM-grader pipeline for "did the tests pass," you've skipped a tier.
- **Trusting an LLM grader you never tested.** The platform docs flag this directly: LLM-based grading must itself be checked for reliability before you rely on it.
- **Forgetting privacy as a criterion.** Agents working with real data can surface it in logs, fixtures, or comments. If the task touches sensitive data, that's a criterion: "no real names, keys, or customer data appear in the diff or output."
- **Criteria nobody can check.** If checking requires knowledge only the assistant has, the criterion is on the wrong side of the table.

## Related capabilities

- **clear-and-direct-instructions** — states the outcome and gives reasons for rules; this page deepens the "define success criteria and check empirically" thread that page touches briefly.
- **verifying-agent-work** — the verify-as-you-go workflow: reading diffs, running tests, accepting/rejecting chunks; your code-based criteria are what you verify with.
- **tools-and-agent-actions** — bounding the blast radius of a tool-using agent; safety constraints you set there belong in your criteria too.

## Official sources

- Prompt engineering overview (success criteria as a prerequisite): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
- Developing tests and evaluations (criteria dimensions, metrics, grading tiers): https://platform.claude.com/docs/en/test-and-evaluate/develop-tests

## Provenance

Cross-tool practice guidance anchored by official platform documentation (retrieved 2026-09-20 via Context7, /websites/platform_claude_en). The success-criteria prerequisite and the prompt-engineering loop come from the platform's prompt-engineering overview; the criteria dimensions, example metrics/measurement methods, and the code-based/human/LLM-based grading tier tradeoffs come from the platform's test-and-evaluate docs. The framing of criteria as a pre-task "done" definition for everyday coding tasks, and the advice to prefer the cheapest reliable grading tier, are established cross-tool practice, not direct quotes from any vendor's docs. No commands, APIs, or vendor claims beyond the grounding facts are asserted.
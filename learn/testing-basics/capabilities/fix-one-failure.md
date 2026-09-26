---
title: Fixing one failing test at a time
module_id: testing-basics
capabilities:
  - fix-one-failure
context7_library:
context7_queries:
  - test-driven development red green refactor
  - pytest running a single failing test
  - debugging multiple failing tests attribution
official_sources:
  - https://docs.pytest.org/en/stable/how-to/usage.html
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

A discipline for working through failing tests: when several tests fail, fix and re-run **one failure at a time**, rather than changing many things at once and re-running the whole suite a single time. The payoff is attribution — after each cycle, you know exactly which change fixed (or broke) which test.

Closely related is **TDD (test-driven development)**, a well-known (but not universally practiced) way to structure the same loop: write a failing test for the behavior you want *first*, then write the code that makes it pass.

## When it is useful

- A change broke several tests at once and you're tempted to "fix everything" in one big edit.
- You're not sure which of your recent edits caused or resolved a given failure.
- You're adding new behavior and want a clear target: a failing test that defines "done."
- You're pairing with an agent or teammate and want each round of changes to be verifiable and attributable.

## Prerequisites

- A runnable test suite you can execute locally (see run-tests-locally).
- Basic familiarity with tests as save points and what a regression is (see why-tests-exist).
- Reading individual failure output from your test runner's summary.

## Current syntax

No new commands are introduced here — this page is a working discipline applied with your existing test runner (e.g. `pytest` for Python or `Invoke-Pester` for PowerShell, per run-tests-locally). The "syntax" is the loop itself:

1. Run the suite; note the failures.
2. Pick **one** failing test.
3. Make the smallest change you believe fixes it.
4. Re-run (ideally just that test first, then the suite).
5. Confirm that test passes and no others newly broke.
6. Repeat with the next failure.

For TDD, the loop is: write the failing test (red) → write just enough code to pass it (green) → then clean up if needed.

## What happens (local and remote)

This is a local, iterative workflow — nothing remote or special happens. Each run of your test runner produces a summary and failure details; exit codes (pytest's documented 0 = all passed, 1 = some failed, etc.) let you and any automation tell at a glance whether the current cycle succeeded. The discipline matters most in environments where an agent or CI pipeline acts on your behalf: one attributed change per cycle keeps the feedback legible for everyone — human or machine.

## Practical example

Suppose a suite reports `2 failed, 1 error in 0.12s`. Rather than editing three functions at once:

1. Pick the first failing test and read only its failure output.
2. Make one small fix.
3. Re-run. Summary shows `1 failed` — and the fixed test stays green.
4. Pick the next failure, repeat.

Because each fix landed separately, when the suite finally reports `2 passed`, you can say *which* change fixed *which* failure — and if a fix accidentally broke a previously passing test, you know exactly which edit did it.

TDD version: before implementing a helper, write a test asserting the behavior you want (e.g. "this function returns 4 for input 2+2"). Run it, watch it fail, then write the code. The failing-first step proves the test actually checks something.

## Explanation guidance

### Essential

- Fix one failure, re-run, repeat — never batch multiple fixes between runs.
- The reason is attribution: you can connect each change to the failure it fixed.
- TDD is one well-known way to run this loop: failing test first, then passing code.
- This is the same "change one variable at a time" discipline used elsewhere in engineering; see Related capabilities for the cross-reference.

### Experienced-user note

- Most runners let you execute a single test or a filtered subset, so you can iterate on one failure quickly and run the full suite only to confirm no regressions.
- When an agent is making the edits, require one fix per cycle with a test run between edits — this keeps the agent's changes attributable instead of accumulated.
- If a "fix" for one test breaks another, that itself is diagnostic information: the two tests likely encode conflicting expectations worth reconciling.

### Optional deeper context

- TDD's red-green loop is one named practice within the broader family of test-first approaches; it is popular but not universally practiced, and teams adapt it in varying degrees.
- The attribution discipline generalizes beyond testing to any debugging: minimize the diff between "known-bad" and "known-good" states so causes are easy to isolate (compare git bisect for narrowing down *which commit* introduced a problem).

## Cautions and common failures

- **Batch fixing.** Changing several things then running the suite once leaves you unable to tell which change mattered — or which one broke something else.
- **Fixing the test to match the bug.** If the test captured the *intended* behavior, change the code; only change a test when the expectation itself was wrong.
- **Skipping the re-run.** A fix without a confirming run is an unverified claim, not a fix.
- **Writing TDD tests that can't fail.** If you never see the test fail first, you don't know it's actually checking the behavior.

## Related capabilities

- iterating-on-a-prompt (prompt-engineering module) — the source of the "change one variable at a time" discipline; cross-referenced rather than repeated here.
- run-tests-locally (testing-basics) — the concrete commands and exit codes this loop relies on.
- why-tests-exist (testing-basics) — tests as save points and what counts as a regression.
- debugging-recovery module (read-error-messages, bisect-and-blame, ask-for-help) — adjacent debugging disciplines.

## Official sources

- <https://docs.pytest.org/en/stable/how-to/usage.html> -- pytest's own usage docs, which document invoking pytest against a specific test target, one real anchor for "run a single test." The one-at-a-time attribution discipline itself is cross-tool practice with no single vendor document; see run-tests-locally for further tool-specific anchors.

## Provenance

- Capability drafted from well-established, real cross-tool/cross-language engineering practice: one-change-at-a-time debugging and test-driven development as a named (not universal) practice.
- No vendor-specific flags, exit codes, or commands introduced; tool specifics defer to the run-tests-locally capability.
- last_checked: 2026-09-20
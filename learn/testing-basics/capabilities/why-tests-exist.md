---
title: Tests as save points for behavior
module_id: testing-basics
capabilities:
  - why-tests-exist
context7_library: 
context7_queries:
  - what is a software test
  - test assertion definition
  - regression testing purpose
official_sources:
  - https://docs.pytest.org/en/stable/
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

A test is a small, automated, repeatable check that a specific piece of behavior still works. Each test targets one piece of behavior -- for example, "this function returns the right value for this input" -- and can be run again and again by the computer without a human manually re-checking anything.

A useful framing: a test suite is like a set of save points for behavior. In a game, a save point records a state you know is good, so you can return to it if something goes wrong. Tests do the same for code:

- **Before a change**, running the tests establishes the last known-good state -- proof that the behavior worked as of that moment.
- **After a change**, re-running the tests confirms that nothing that used to work has broken.

When a change breaks something that previously worked, that break is called a **regression**. Re-running an existing test suite is the standard way to detect regressions quickly, before they reach users.

Inside a test, an **assertion** is a single checkable statement -- a claim about behavior that is either true or false when the test runs. For example: "this function returns 4 for the input 2+2." A test typically contains one or more assertions; if any assertion fails, the test fails.

## When it is useful

- Before making any change to code, so you know what already worked.
- After making a change, to confirm no existing behavior regressed.
- When fixing a bug: a test can capture the broken behavior first, then confirm the fix.
- When working with others or with AI agents: a passing test suite is shared, objective evidence that the current state is good.
- Any time you would otherwise re-check behavior by hand -- a test automates that re-check.

## Prerequisites

- Basic familiarity with running commands in a terminal.
- Awareness that projects may have a test suite already written, or may need tests added.
- No specific framework knowledge is required for this concept page; see Related capabilities for running tests.

## Current syntax

This is a concept page; there is no syntax of its own. The building blocks are:

- A **test**: a small unit of code that exercises one behavior.
- An **assertion**: one checkable statement inside a test, e.g. "the result of calling this function with `2+2` equals `4`".
- A **test suite**: the collection of all tests, which can be re-run as a whole.

Concrete commands for executing tests are covered in the Running tests locally capability.

## What happens (local and remote)

Locally, running a test suite executes each test's assertions against the current code and reports pass/fail per test. Because tests are automated and repeatable, the same suite can be run:

- before and after any change, on the developer's machine;
- again later by anyone else (a teammate, a reviewer, an automated pipeline) to confirm the same behavior still holds.

The save-point property comes from this repeatability: "the tests passed" is a state you can return to and re-verify at any time, just like returning to a save point. Remotely (e.g., in automated pipelines), the same principle applies -- the suite is re-run on every change to catch regressions -- but this page focuses on the concept, not pipeline configuration.

## Practical example

Suppose a function `add(a, b)` currently works, and you are about to refactor it.

1. **Establish the save point (before the change).** Run the existing test suite, which includes a test containing an assertion like: "`add(2, 2)` returns `4`." All tests pass -- this is the known-good state.
2. **Make the change.** Refactor `add` internally.
3. **Re-run the suite (after the change).** If all tests pass again, nothing that used to work has broken -- no regression. If the "`add(2, 2)` returns `4`" assertion now fails, the suite has caught the regression immediately, at the exact moment the change was made, when it is easiest to fix.

Each passing test is a save point confirming one piece of behavior is still intact.

## Explanation guidance

### Essential

- A test = a small, automated, repeatable check that one specific behavior still works.
- Save-point framing: tests before a change establish the last known-good state; re-running them after a change confirms nothing broke.
- A regression is something that used to work and no longer does; test suites exist largely to catch regressions.
- An assertion is a single checkable statement inside a test (e.g. "this function returns 4 for input 2+2"); a test fails when one of its assertions is false.

### Experienced-user note

- The value of tests compounds: the same suite that validated today's change validates every future change, which is why mature projects treat a failing suite as a stop-everything signal.
- Tests are most useful when each targets a specific behavior; a vague test that "mostly checks things" is a weak save point because it cannot tell you which behavior broke.
- When a bug is reported, a common pattern is to write a test that reproduces the bug first, then fix the code until that test passes -- the test then guards against the bug returning.

### Optional deeper context

- Tests encode intent: a well-written test documents what the author believed the behavior should be, which helps future maintainers (and AI agents) distinguish intended behavior from accidental behavior.
- The save-point idea scales from a single assertion up to thousands of tests; large codebases rely on the suite, not human memory, to know what is safe to change.

## Cautions and common failures

- **No tests before the change.** If you change code with no existing tests, you have no save point -- you cannot easily confirm nothing broke. Establish at least a minimal suite first when possible.
- **Skipping the re-run.** The save point only helps if you actually re-run the tests after the change; passing tests from before a change say nothing about the current state.
- **Confusing "tests pass" with "code is correct."** Tests check specific behaviors; untested behavior can still be broken. A save point covers what it covers.
- **Vague assertions.** An assertion must be a concrete, checkable statement. "It seems to work" is not an assertion and cannot be automated.
- **Assuming one failure means one bug.** A single broken behavior can fail several tests; conversely, fixing one test's failure does not guarantee others pass. Re-run the whole suite after each fix (see Fixing one failing test at a time).

## Related capabilities

- **run-tests-locally** (testing-basics) -- how to actually execute a test suite and read pass/fail results (pytest, Pester).
- **fix-one-failure** (testing-basics) -- the change-one-thing-at-a-time discipline for working through failing tests.
- **iterating-on-a-prompt** (prompt-engineering) -- the same "change one variable at a time" principle, applied to prompt iteration.
- **bisect-and-blame** (debugging-recovery) -- `git bisect`, which uses repeated testing of behavior to find the commit that broke it.
- **why-tests-exist pairs naturally with read-error-messages** (debugging-recovery) -- tests report failures as errors; reading them is the companion skill.

## Official sources

- <https://docs.pytest.org/en/stable/> -- pytest's own docs, used as one real, well-known worked example of a test framework; the save-point/regression framing itself is a generic testing concept with no single vendor document. Framework-specific commands and behaviors are documented in the run-tests-locally capability with its own sources.

## Provenance

- Concept content reflects long-established, cross-language software engineering practice: tests as automated, repeatable behavior checks; regression detection via re-running suites; assertions as checkable statements.
- Save-point framing is an illustrative teaching analogy, not a formal term of art.
- No framework-specific commands, flags, or exit codes are claimed on this page; see run-tests-locally for verified framework details (pytest exit codes, Pester output formats).
- last_checked: 2026-09-20; version_stamp: fall-2026-0.1.0.
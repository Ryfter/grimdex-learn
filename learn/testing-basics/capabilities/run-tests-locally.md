---
title: Running pytest/Pester and reading pass-fail
module_id: testing-basics
capabilities:
  - run-tests-locally
context7_library: /websites/pytest_en_stable
context7_queries:
  - pytest command line exit codes
  - pytest summary output dot F failing tests
  - Invoke-Pester -Output Detailed summary format
  - Pester -CI switch automated pipelines
official_sources:
  - https://docs.pytest.org/en/stable/reference/exit-codes.html
  - https://pester.dev/docs/quick-start
  - https://pester.dev/docs/commands/Invoke-Pester
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

Running tests locally means invoking a test runner from your own machine's command line and reading its output to see which checks passed and which failed. Two widely used examples from different ecosystems:

- **pytest** (Python): running `pytest` from the command line shows a dot (`.`) per passing test and an `F` per failing test in the default summary line, followed by detailed failure output for each failure, and a final summary line such as `2 passed in 0.12s` or `2 failed, 1 error in 0.12s`.
- **Pester** (PowerShell): `Invoke-Pester` runs tests, and the `-Output Detailed` flag gives verbose per-test results. Pester prints a real summary line of the form `Tests Passed: N, Failed: N, Skipped: N NotRun: N`.

The pattern is the same in both: run a command, get a compact pass/fail summary, then dig into details for failures. You should learn to recognize this pattern, not memorize both tools exhaustively.

## When it is useful

- After changing code, to confirm nothing that used to work still works (see Tests as save points in this module).
- Before committing or handing work to someone else.
- When diagnosing a regression: the runner tells you exactly which behavior broke.
- In scripts or pipelines, where the runner's exit code is what machines read.

## Prerequisites

- Tests written and discoverable by the runner (conventions for that belong to each tool's docs).
- The runner installed and available on your PATH (`pytest` for Python, Pester for PowerShell).
- Basic command-line familiarity.

## Current syntax

pytest (Python):

```
pytest
```

Pester (PowerShell):

```powershell
Invoke-Pester
Invoke-Pester -Output Detailed
```

Both tools also have documented options for automated/CI contexts. pytest exposes its outcome through documented exit codes; Pester documents a `-CI` switch and `EnableExit`/exit-code behavior for pipelines.

## What happens (local and remote)

When you run the runner, it collects tests, executes them, prints a compact summary line (dots/`F` for pytest; the `Tests Passed: N, Failed: N, Skipped: N NotRun: N` format for Pester, or verbose detail with `-Output Detailed`), and then detailed failure output. The process's **exit code** summarizes the run for anything that invoked it (a script, a pipeline, an AI agent).

pytest's documented exit codes (source: docs.pytest.org):

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Some tests failed |
| 2 | Test execution was interrupted by the user |
| 3 | Internal error occurred |
| 4 | pytest command line usage error |
| 5 | No tests were collected |
| 6 | Internal pytest warning threshold exceeded (max warnings exceeded) |

Note that exit code 5 (no tests collected) is a distinct outcome from "all passed" -- a silent empty run looks like success to a human but is a documented failure-to-run signal.

## Practical example

pytest:

```
$ pytest
test_math.py .F
==================== FAILURES ====================
...
==================== short test summary info ====================
FAILED test_math.py::test_add
==================== 1 failed, 1 passed in 0.12s ====================
$ echo $?
1
```

The `F` in the summary line and the final `1 failed, 1 passed` tell you one behavior broke; exit code `1` tells any script or pipeline the same thing.

Pester:

```powershell
Invoke-Pester -Output Detailed
```

Output ends with a summary in the documented form:

```
Tests Passed: 3, Failed: 1, Skipped: 0 NotRun: 0
```

In both cases the workflow is identical: run, glance at the summary, read the detailed failure output for anything not passing.

## Explanation guidance

### Essential

- A runner gives you (1) a compact pass/fail summary and (2) detail for failures. Read the summary first, then the details.
- The exit code is the machine-readable version of the summary: pytest documents 0 = all passed, 1 = some failed, plus distinct codes for interruption, internal error, usage error, no tests collected, and max warnings exceeded.
- pytest marks passing tests with `.` and failing tests with `F`; Pester's summary counts Passed/Failed/Skipped/NotRun explicitly.
- Don't panic at long failure output -- locate the actual assertion failure, the same skill as finding the real error in a long stack trace.

### Experienced-user note

- Exit code 5 ("no tests collected") from pytest is a common trap: if your test files aren't matched by the collection conventions, pytest "passes" vacuously. Check the collected-count, not just the exit code.
- Pester's `-CI` switch and `EnableExit` exit-code behavior exist specifically so pipeline steps can fail correctly; use them when the runner is invoked by automation rather than a human.
- `Invoke-Pester -Output Detailed` is the fastest way to see per-test results when the default summary isn't enough.

### Optional deeper context

- Different ecosystems express the same pattern differently -- dots vs. named counts, generic exit codes vs. `EnableExit` switches -- but the contract (summary + detail + exit code) is stable across tools, which is why you can move between pytest and Pester without relearning everything.
- `pytest -x` (stop at first failure) and similar stop-early options pair well with the fix-one-failure discipline covered elsewhere in this module.

## Cautions and common failures

- **Misreading exit code 5 as success.** "No tests collected" means nothing ran; verify tests were actually found.
- **Reading only the last line of failure output.** The detailed failure section contains the assertion and actual-vs-expected values; the summary alone won't tell you why.
- **Running the whole suite after changing many things at once.** You can't attribute which change fixed which failure; fix one test at a time (see fix-one-failure).
- **Forgetting Pester's flags in automation.** Without the documented exit-code options (`-CI`/`EnableExit` behavior), a pipeline step may not fail when tests do.
- **Assuming the runner is wrong.** A failing test is usually a real signal about behavior; verify manually before dismissing it.

## Related capabilities

- fix-one-failure (this module) -- one-change-at-a-time fixing loop
- why-tests-exist (this module) -- tests as save points, assertions, regressions
- bisect-and-blame (debugging-recovery module) -- binary-searching history for the commit that broke behavior
- ask-for-help (debugging-recovery module) -- what context to include when escalating; redact secrets before pasting test output

## Official sources

- pytest exit codes: https://docs.pytest.org/en/stable/reference/exit-codes.html
- Pester quick start: https://pester.dev/docs/quick-start
- Invoke-Pester command reference: https://pester.dev/docs/commands/Invoke-Pester

## Provenance

- pytest command-line summary output (`.`/`F`, final summary line) and the seven documented exit codes (0-6) verified against docs.pytest.org via Context7 (`/websites/pytest_en_stable`).
- `Invoke-Pester`, `-Output Detailed`, the `Tests Passed: N, Failed: N, Skipped: N NotRun: N` summary format, and the `-CI`/`EnableExit` exit-code options verified against pester.dev via Context7.
- Framing (recognize the pattern across tools rather than memorizing each) is practice guidance anchored to the official documentation above.
- Last verified: 2026-09-20.
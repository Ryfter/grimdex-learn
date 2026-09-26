---
title: When to bisect vs revert
module_id: debugging-recovery
capabilities:
  - bisect-and-blame
context7_library: /websites/git-scm
context7_queries:
  - git bisect start bad good workflow
  - git bisect run automated binary search
  - git bisect skip untestable commit
official_sources:
  - https://git-scm.com/docs/git-bisect
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

`git bisect` is a built-in git workflow that performs a binary search across your commit history to find the exact commit where a problem was introduced. You tell git one commit that is "bad" (shows the bug) and one that is "good" (does not), and git checks out a midpoint commit for you to test. Each time you report `good` or `bad`, git halves the remaining range of suspects, so even long histories converge in a handful of test rounds.

## When it is useful

- A bug exists now, but you know (or suspect) the code worked at some earlier commit -- and you don't know which change broke it.
- The repo has many commits since the last known-good state, and reading each diff one by one would be slow.
- A regression appears "out of nowhere" and the culprit isn't obvious from error messages alone.
- You want a precise answer ("this commit") before you decide how to fix it -- which then lets you either revert that commit (see Related capabilities) or apply a hotfix, where "hotfix" simply means a small, urgent, targeted fix, not a new git command.

It is not the right tool when you already know which commit caused the problem -- at that point you go straight to undoing it.

## Prerequisites

- A git repository with commit history containing at least one known-good state and a known-bad state.
- A way to test whether the bug is present at a given commit (a failing command, a test, or manual verification).
- Basic comfort with checking out commits and recognizing error output from stderr and stack traces (see the read-error-messages capability in this module).

## Current syntax

Verified against git-scm.com and Context7 for the git-scm website:

```bash
git bisect start
git bisect bad                 # current version is bad
git bisect good <commit>       # last known good revision

# git then checks out a midpoint commit; you test it and report:
git bisect good                # or
git bisect bad

# If a commit cannot be tested:
git bisect skip

# To automate the whole search using a command's exit code:
git bisect run <command>

# When finished:
git bisect reset
```

## What happens (local and remote)

- Everything happens locally in your repository; bisect does not touch any remote.
- `git bisect start` begins the search session. Marking `bad` (typically your current HEAD) and `good <commit>` defines the search range.
- Git repeatedly checks out midpoint commits inside that range. You test each one and report `good` or `bad`; each report halves the remaining candidates.
- When the range narrows to one commit, git identifies the first bad commit and tells you.
- `git bisect skip` marks a commit that cannot be tested (e.g. it doesn't build); git works around it in the search.
- `git bisect run <command>` automates the loop: git uses the command's exit code to decide good/bad automatically -- no manual reporting per step.
- `git bisect reset` returns you to your original branch (the docs' standard way to end a session).

## Practical example

Manual bisect:

```bash
git bisect start
git bisect bad                          # HEAD currently shows the bug
git bisect good v1.4.0                  # this release was known to work
# git checks out a midpoint, e.g. 200 commits in
# ... build and test this checkout ...
git bisect bad                          # bug still present here
# git checks out another midpoint
# ... build and test ...
git bisect good                         # bug absent here
# git narrows again ... until:
# "<sha> is the first bad commit"
git bisect reset
```

Automated with `bisect run`:

```bash
git bisect start
git bisect bad
git bisect good v1.4.0
git bisect run pytest            # exit code decides good/bad each step
```

## Explanation guidance

### Essential

- Binary search means each report halves the search space: 1,000 suspect commits take roughly ten rounds, not a thousand checks.
- You must supply one genuinely bad commit and one genuinely good commit; a wrong "good" mark poisons the whole search.
- Bisect finds the culprit; it does not fix it. Once identified, the fix is a separate decision -- cross-reference the git-and-github module's undoing-and-recovering-work lesson for `git revert`.
- Always `git bisect reset` when done so you're back on your original branch.

### Experienced-user note

- `git bisect run <command>` turns the manual loop into a single automated step. It works best when you already have a repeatable test (see the run-tests-locally capability): a command whose exit code reliably reflects good vs. bad. Note pytest's documented exit codes: 0 = all passed, 1 = some tests failed -- which maps cleanly onto good/bad.
- Use `git bisect skip` for commits that can't build or can't be tested, so the search isn't derailed.
- Reading the actual error message and stack trace at each checkpoint (not just "it looks broken") makes your good/bad calls trustworthy -- see read-error-messages.

### Optional deeper context

- Bisect works on any describable regression, not only test failures: a crash, wrong output, even a documentation mistake, as long as you can check for it at each commit.
- You can bisect into ranges using commit hashes, tags, or branch names for the `good`/`bad` endpoints.
- Pester users in PowerShell pipelines can wire `Invoke-Pester` (with its documented exit-code behavior via `-CI`/`EnableExit`) as the `bisect run` command, so the same automated bisect pattern works cross-language.

## Cautions and common failures

- Marking a commit `good` when the bug was actually present (or vice versa) sends the binary search in the wrong direction; re-verify your endpoints.
- Forgetting `git bisect reset` leaves you on a detached checkout in the middle of history.
- Long build/test times per checkpoint are the real cost -- automating with `bisect run` is usually worth it.
- Not being able to test a midpoint is normal; use `git bisect skip` rather than guessing.
- Bisect tells you *which* commit broke things, not *what to do about it* -- don't confuse finding with fixing.

## Related capabilities

- debugging-recovery / read-error-messages -- reading stack traces and stderr to judge good/bad at each checkpoint.
- testing-basics / run-tests-locally -- pytest and Pester exit-code behavior that makes `git bisect run` automation reliable.
- testing-basics / fix-one-failure -- fixing one thing at a time once the culprit commit is known.
- git-and-github / undoing-and-recovering-work -- `git revert` and related undo tools for acting on the bad commit bisect finds (cross-referenced, not repeated here).
- agentic-ai-development / secrets-and-data-hygiene-for-agent-context and dev-tooling-literacy / dotenv-and-secrets -- redact secrets before sharing bisect logs when escalating (see ask-for-help in this module).

## Official sources

- https://git-scm.com/docs/git-bisect

## Provenance

Workflow commands (`start`, `bad`, `good`, `skip`, `run`) and their semantics are verified against git-scm.com and Context7 for the git-scm website. pytest exit codes are per docs.pytest.org; Pester flags and exit behavior are per pester.dev docs. `git revert` content and secrets-hygiene content are cross-referenced to their own lessons rather than restated. The bisect-vs-revert framing and the "hotfix = small urgent targeted fix" clarification are practice guidance with official anchors.
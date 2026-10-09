---
title: Recovering when it breaks
workflow: recovering-when-it-breaks
time_minutes: 60
level: 3
---

## Goal

By the end of this exercise, you will have deliberately broken a small practice project on purpose, then practiced every stop on the recovery path: reading the real error, reproducing it reliably, checking the exit code, reading a log excerpt for its real signal, finding which commit caused it with `git bisect`, undoing it safely, recovering from a too-far reset with the reflog, shelving in-progress work with `git stash`, resolving a merge conflict, fixing failing tests one at a time, and writing a good escalation report. Everything happens in a throwaway practice repository — breaking things there is the point.

## You will need

- Git 2.28 or later installed and available in a terminal (`git init -b` needs it).
- Python installed, with **pytest** available: `python -m pip install pytest`. On Windows, the launcher may be `py` instead of `python` (`py -m pip install pytest`). On macOS and Linux, if your system only provides `python3`, substitute it throughout (`python3 -m pip install pytest`, `python3 -m pytest`).
- A terminal and a text editor. On Windows, use PowerShell 7 (`pwsh`).

## Steps

### Step 1: Create the practice repository with a working baseline

Create a folder named `practice-recovering-when-it-breaks` and run `git init -b main` inside it. This is your throwaway practice repo — nothing here is a real project.

Create a file `calc.py`:

```python
def add(a, b):
    return a + b
```

Create `test_calc.py`:

```python
from calc import add


def test_add():
    assert add(2, 3) == 5
```

Stage and commit:

```
git add calc.py test_calc.py
git commit -m "Add a working add function"
```

Now add a second function to `calc.py`:

```python
def subtract(a, b):
    return a - b
```

The second test needs `subtract` too, so update the import line in `test_calc.py` and add a second test:

```python
from calc import add, subtract


def test_add():
    assert add(2, 3) == 5


def test_subtract():
    assert subtract(5, 2) == 3
```

Stage and commit again:

```
git add calc.py test_calc.py
git commit -m "Add a working subtract function"
```

**Checkpoint:** `python -m pytest` reports 2 passed, and `git log --oneline` shows two commits.

### Step 2: Break something on purpose, and write a reproduction recipe

Edit `calc.py` so that `add` returns `a - b` instead of `a + b`. This change looks small and reads innocently in a diff — which is exactly how real regressions often look. Commit it with a plausible, non-revealing message:

```
git add calc.py
git commit -m "Simplify add"
```

Run `python -m pytest`. It should now report 1 failed, 1 passed. Run `python -m pytest` a second time to confirm the failure is consistent, not a fluke.

Then, following the reproducing-a-bug lesson's three-part structure, write down (in a scratch file or on paper):

- **Starting conditions** — a fresh checkout of this repo, on this branch.
- **Steps** — run `python -m pytest`.
- **Expected vs. observed** — expected 2 passed; observed 1 failed, 1 passed — both times you ran it, i.e. "2 out of 2 tries".

**Checkpoint:** your written recipe names the starting conditions, the exact step, and expected-vs-observed, matching what you actually saw twice in a row.

### Step 3: Read the real error, and check the exit code

In the `pytest` output, find the actual failing-test line and the assertion message nearest your own code — not the pytest internals above it. This is the stack-trace-reading skill: scan for the real error line first, then the frame that's your code.

Then check the exit code instead of trusting the printed text alone. In bash, run:

```
python -m pytest; echo $?
```

In PowerShell, run:

```
python -m pytest; echo $LASTEXITCODE
```

By convention 0 means all passed and non-zero means something failed — pytest documents this split, which is why an agent (or you) can trust the number over the look of the output.

**Checkpoint:** you can point to the specific assertion line `python -m pytest` printed for the failing test, and you saw a non-zero exit code after the failing run.

### Step 4: Read a log stream for signal, not noise (written)

This step is a reading exercise, not a command — recognizing severity levels in log output is a recognition skill, not something to implement yourself. Read this log excerpt (the shape real dev tools print, from the logs-and-severity-levels lesson):

```
2026-09-20 14:02:11 INFO  Starting development server...
2026-09-20 14:02:11 INFO  Server listening on http://localhost:3000
2026-09-20 14:02:40 WARN  Deprecation: config option "assets.prefix" is deprecated
2026-09-20 14:02:55 INFO  GET / 200 15ms
2026-09-20 14:03:01 INFO  GET /about 200 18ms
2026-09-20 14:03:09 ERROR Failed to save upload: permission denied
```

On paper or in your scratch file, answer:

- Which single line is the one that needs action, and why are the `INFO` lines not a problem even though there are several of them?
- What does the `WARN` line tell you, and does it mean the app stopped?

**Checkpoint:** your written answer identifies the `ERROR` line as the one needing action, explains that the `INFO` lines are routine narration (not failures), and correctly states the app kept running after the `WARN` line.

### Step 5: Find which commit broke it with `git bisect`

Run `git log --oneline` and note the hash of your first commit ("Add a working add function"). Start a bisect:

```
git bisect start
git bisect bad
git bisect good <first-commit-hash>
```

`git bisect bad` marks the current tip as failing; `git bisect good <first-commit-hash>` marks the first commit as known good. Git checks out a midpoint commit for you. Run `python -m pytest` there: it should pass (2 passed), since the bug was introduced after this point — report that with `git bisect good`. Git should now report the first bad commit by name (it should be your "Simplify add" commit). Finish with:

```
git bisect reset
```

**Checkpoint:** `git bisect` names "Simplify add" as the first bad commit, and after `git bisect reset` you're back on your original branch with the bad commit still at the tip.

### Step 6: Undo the bad commit safely with `git revert`

You're undoing a specific past commit while keeping history intact — the generally safe choice, especially once anything is shared or pushed. Use:

```
git revert <bad-commit-hash>
```

Use the hash from the "Simplify add" commit. This records a new commit that reverses it. Run `python -m pytest` again.

**Checkpoint:** `python -m pytest` reports 2 passed again, `git log --oneline` shows a new commit on top that undoes "Simplify add", and the original "Simplify add" commit is still visible further down the history (nothing was deleted).

### Step 7: Recover from a too-far reset using the reflog

Now deliberately go too far. Run `git log --oneline` to see the current order, then:

```
git reset --hard HEAD~2
```

This moves the branch tip back two commits — past both the revert and the "Simplify add" commit. Run `git log --oneline` again to see it changed.

Now recover: run `git reflog` and find the entry showing where the branch tip was immediately before that reset (often `HEAD@{1}`, or you can use `ORIG_HEAD`, which names the tip from immediately before the last reset). Then run:

```
git reset --hard ORIG_HEAD
```

**Checkpoint:** after the recovery, `git log --oneline` matches exactly what it showed right before the mistaken `--hard` reset (the revert commit is back on top).

### Step 8: Shelve a half-finished fix with `git stash`

Start editing `calc.py` to add a new, unfinished function — for example, begin typing a `multiply` function but don't finish or test it. Leave it uncommitted. Run `git status` to see it listed as changed.

Now shelve it:

```
git stash push -m "wip multiply function"
```

Run `git status` again to confirm the working tree is clean, then `git stash list` to see the saved entry. Bring it back:

```
git stash pop
```

**Checkpoint:** right after the push, `git status` reports a clean working tree and `git stash list` shows one entry; after `git stash pop`, your unfinished edit is back in `calc.py` and the stash list is empty again.

### Step 9: Create and resolve a merge conflict

Before branching, make sure you're starting from a clean working tree. Run `git status`. If the unfinished `multiply` edit from Step 8 is still sitting in `calc.py` (the `git stash pop` brought it back), you don't need it for this step — discard it:

```
git restore calc.py
```

**Checkpoint:** `git status` reports a clean working tree.

From your default branch (run `git branch` if you're not sure of its name — it's usually `main`), create a topic branch:

```
git switch -c topic
```

Edit a comment or docstring line in `calc.py` to say one thing, then:

```
git add calc.py
git commit -m "Update calc.py comment from topic"
```

Switch back to your default branch:

```
git switch main
```

Edit the **same** line in `calc.py` to say something different, then:

```
git add calc.py
git commit -m "Update calc.py comment from main"
```

Now merge:

```
git merge topic
```

Git stops with a conflict — this is normal, not a broken repository: both sides changed the same region since they diverged. Run `git status` to see the conflicted path. Open `calc.py` and find the markers `<<<<<<<`, `=======`, and `>>>>>>>`. Edit the line to the one result you want to keep, and remove all three markers. Then:

```
git add calc.py
git commit
```

(or `git merge --continue`).

**Checkpoint:** `git status` shows no more conflicts, `calc.py` contains no leftover `<<<<<<<` / `=======` / `>>>>>>>` markers, and `git log --oneline` shows a merge commit.

### Step 10: Fix the failing tests one at a time

Without committing, break both functions at once: edit `add` to return the wrong value and edit `subtract` to return the wrong value too. Run `python -m pytest` — it should report 2 failed.

Resist fixing both at once. Fix only `add` first, then re-run `python -m pytest`: the summary should now show exactly 1 failed (subtract) — the fix you just made is directly attributable to the test that went from failing to passing. Now fix `subtract`, and re-run `python -m pytest` once more.

**Checkpoint:** after fixing only `add`, `python -m pytest` reports exactly 1 failed (subtract) and 1 passed (add) — proving which fix did what; after fixing `subtract` too, `python -m pytest` reports 2 passed.

### Step 11: Ask for help well

Imagine you're still stuck on one of the failures from this exercise and need to hand it to a teammate or an AI agent. Write a short escalation report (in your scratch file) with three parts:

- **The actual error** — copy the real failing-test line and assertion message from Step 3's output, not a paraphrase.
- **What you tried** — the concrete steps you already took, e.g. "ran pytest twice, confirmed the failure was consistent, then ran git bisect to find the commit".
- **What you expected** — that `add` would return the sum.

Now add one more line to your report as if a configuration value had leaked into your terminal output, for example a line reading `MY_API_KEY=replace-me-not-a-real-key`. Rewrite that line with the secret replaced by a clearly marked placeholder, such as `MY_API_KEY=[REDACTED]`, before anything would leave your machine.

**Checkpoint:** your written report has all three parts (actual error, what you tried, what you expected), and the example secret line is replaced with a `[REDACTED]`-style placeholder rather than the real-looking value.

## What good looks like

- The bug was introduced and found, not guessed at — you broke it on purpose and then located it with evidence.
- `git bisect` correctly named the real culprit commit ("Simplify add").
- The undo used `git revert` (not a destructive reset on shared history), and history stayed intact — the original commit is still visible.
- A mistaken hard reset was recovered using the reflog, and `git log --oneline` matched exactly what it showed before.
- `git stash` returned the unfinished work intact, and the stash list ended empty.
- The merge conflict was resolved by choosing content, not by guessing or deleting markers blindly.
- Both test fixes were attributed to the correct fix because they were applied one at a time.
- The escalation report had all three parts (actual error, what you tried, what you expected) and no real-looking secret in it.

## If you get stuck

- **The stack trace looks like a wall of text.** Don't be intimidated by length — a long trace usually means a deep call chain, not a complex problem. Find the error line first, then the frame nearest your own code.
- **The command "finished" so it must have worked.** A returned prompt is not a verdict, and visible output is not a verdict either. Check the exit code: 0 means success, non-zero means something went wrong.
- **A wall of INFO log lines looks alarming — or the absence of ERROR lines looks reassuring.** Judge by severity level, not by volume. INFO lines are routine narration, and a silent log does not prove success — cross-check with exit codes.
- **The bisect pointed at the wrong commit.** A wrong `good` or `bad` mark sends the binary search in the wrong direction — re-verify your endpoints. And always run `git bisect reset` when done, or you'll be left on a detached checkout in the middle of history.
- **Tempted to reset shared history instead of reverting.** `git revert` keeps history intact and is the safe choice for anything shared or pushed; a hard reset on shared work rewrites history others may depend on.
- **Uncommitted edits are gone after `--hard` or `git restore`.** The reflog recovers committed work, but uncommitted edits discarded by `git reset --hard` or a discarding `git restore` are not recoverable by Git — only committed work is.
- **A stash seems to have vanished — or a stash pop conflicted.** Run `git stash list` regularly; forgotten stashes are a common source of "where did my work go?" confusion. After a conflicted `git stash pop`, the entry stays on the list until you resolve the conflict and `git stash drop` it.
- **Conflict markers appeared and it feels like the repo is broken.** Conflicts are normal, not corruption — don't force-reset out of panic. And don't delete the markers without actually deciding the content: edit to the intended result first, then remove the markers, then `git add`.
- **Several tests were failing and you fixed them all at once.** Batch fixing loses attribution — you can't tell which change fixed which test. Fix one failure, re-run, repeat.
- **About to paste raw error output or logs to get help.** Redact secrets **before** sharing, not after — once shared, you generally can't un-share it. Replace secrets with clearly marked placeholders but keep the diagnostic signal.

## Lessons used

- git-and-github/branches-and-switching — Branches and switching
- debugging-recovery/read-error-messages — Reading stack traces and agent error output
- debugging-recovery/ask-for-help — Escalating without leaking secrets
- debugging-recovery/bisect-and-blame — When to bisect vs revert
- dev-tooling-literacy/reproducing-a-bug — Reproducing a bug: making a symptom repeatable
- dev-tooling-literacy/exit-codes — Exit codes: how commands signal outcomes
- dev-tooling-literacy/logs-and-severity-levels — Application logs and severity levels
- git-and-github/undoing-and-recovering-work — Undoing and recovering work
- git-and-github/git-stash — Shelving work in progress with git stash
- git-and-github/merge-conflicts — Merge conflicts
- testing-basics/fix-one-failure — Fixing one failing test at a time
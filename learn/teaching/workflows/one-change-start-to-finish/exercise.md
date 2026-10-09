---
title: One change, start to finish
workflow: one-change-start-to-finish
time_minutes: 45
level: 6
---

## Goal

By the end, you will have taken one small change through its whole life in a throwaway practice repository: branch, prompt an agent, review the diff, run the tests, commit, push, open a pull request, and clean up after merge.

## You will need

- Git 2.28 or later installed and available in a terminal (`git init -b` needs it). Check with `git --version`.
- A terminal you can type commands into. On Windows, use PowerShell 7 (`pwsh`), not Windows PowerShell 5.1 — 5.1 writes `>>` output as UTF-16, which breaks the diffs this exercise checks.
- A test runner for the test step: **pytest** (Python) or **Pester** (PowerShell). Pick one and stay with it for this exercise.
- Optional, for the push and pull-request steps: a GitHub account, a remote repository, and the GitHub CLI (`gh`) installed and authenticated. If you do not have these, those steps are described so you can read them and note what you would do — you can complete the exercise without them.

## Steps

### Step 1: Create the practice repository with one commit

Create a folder named `practice-one-change-start-to-finish` (with your file manager or your terminal), move into it, and turn it into a Git repository. A branch tip needs at least one commit to point at, so make the first commit right away.

```
git init -b main
echo "Draft note" >> notes.txt
git add notes.txt
git commit -m "Add a draft note"
```

**Checkpoint:** `git log --oneline` shows one commit, and `git status` reports a clean working tree.

### Step 2: Create and switch to a branch

A branch is a movable pointer to a commit, not a copy of the project. `git switch -c` creates a new branch at the current commit and switches to it in one step.

```
git switch -c add-greeting
git branch
```

**Checkpoint:** `git branch` lists `add-greeting` with an asterisk (`*`) marking it as the current branch.

### Step 3: Make a small edit and inspect status

Edit `notes.txt` (add a line such as `Hello from the branch`). Then look at where your change sits. Git has three areas: the working tree (files on disk), the staging area (what the next commit will record), and the repository (committed history).

```
git status
```

**Checkpoint:** `git status` lists `notes.txt` under "changes not staged for commit" — the edit is in the working tree, not yet staged.

### Step 4: Write a clear prompt with success criteria

This step is a written exercise — you do not need to call an agent. On paper or in a scratch file, write a prompt for the change you just made (or a similar one), following the clear-and-direct pattern: state the outcome, the success criteria, the scope, and the reason behind any sharp rule.

```
Task: Add a greeting line to notes.txt.

Success criteria:
- notes.txt contains the new greeting line
- The existing lines are unchanged
- No other files are touched

Scope constraints:
- Change only notes.txt
- Do not add features, docs, or refactors beyond this

Why the scope limit:
- This is a small, reviewable practice change
```

General practice advice: define what "done" looks like **before** you ask, so you can check the result against it later, and a short "why" improves compliance with rules that would otherwise look arbitrary.

**Checkpoint:** Your written prompt has a goal, at least two checkable success criteria, a scope limit, and a reason for that limit.

### Step 5: Review the diff

Whether you or an agent made the edit, review the actual change, not a summary. `git diff` compares the working tree against the staging area. Read the diff for scope creep, debug junk, and anything that was not asked for. You are accountable for what you commit, no matter who or what wrote it.

```
git diff
```

**Checkpoint:** The diff shows only the greeting line added to `notes.txt` — nothing else changed.

### Step 6: Run the tests locally

Run your chosen test runner and read the summary. pytest shows a dot (`.`) per passing test and an `F` per failing test, then a final line such as `1 failed, 1 passed in 0.12s`. Pester prints a summary like `Tests Passed: N, Failed: N, Skipped: N NotRun: N`.

If you picked pytest:

```
pytest
```

If you picked Pester:

```
Invoke-Pester
```

This practice repository has no test files, so pytest may report that no tests were collected (exit code 5) — that is a distinct outcome from "all passed," and a good thing to recognize now. In a real project, you would run the suite and read the failure details before moving on.

**Checkpoint:** You ran the runner and can state what the summary line said (including "no tests collected," if that happened).

### Step 7: Stage and commit

Staging copies the change into the index; committing records it as a snapshot. Phrase the commit message in the imperative mood — "Add a greeting line," not "Added a greeting line."

```
git add notes.txt
git diff --staged
git commit -m "Add a greeting line"
```

**Checkpoint:** `git diff --staged` showed the change before the commit, and `git log --oneline` now shows the new commit at the top.

### Step 8: Push the branch and set upstream

Local branch names stay local until you push them. If you have a GitHub remote configured (for example, an empty repository you created for practice), push `main` first — a freshly created empty repository has no `main` on the remote yet, and both the pull request's base branch and the later `git pull` on `main` need it there. Then push your topic branch and record its upstream:

```
git push -u origin main
git push -u origin add-greeting
```

If you do not have a remote, skip both commands and note it: the first push of a branch name creates that branch on the remote, and `-u` sets the upstream tracking that `git status` and later pushes use.

**Checkpoint:** With a remote: both pushes succeed, and `git status` on `add-greeting` can report ahead/behind against its upstream. Without a remote: you can explain what `git push -u origin main` and `git push -u origin add-greeting` would each do.

### Step 9: Open a pull request

A pull request is a feature of a hosting site such as GitHub — a proposal to merge one branch (the **head**) into another (the **base**, often the default branch). It is not the Git command `git pull`. Nothing to review exists on the host until the branch is pushed.

If you have GitHub and the `gh` CLI, from your clone:

```
gh pr create --base main --title "Add a greeting line" --body "Adds one greeting line to notes.txt."
gh pr view
```

If you do not, note the flow instead: push the branch, then in the web UI choose base `main` and compare `add-greeting`, then open the pull request. Reviewers leave comments or a formal review (Comment, Approve, or Request changes); when it is approved, someone merges it on the host.

**Checkpoint:** With GitHub: `gh pr view` shows your open pull request. Without: you can name the base branch and the head branch of the pull request you would open.

### Step 10: Clean up after merge

After the pull request merges on the host, the remote base branch has moved — but your clone has not changed by itself. Update the default branch, retire the topic branch, and prune stale remote-tracking names.

```
git switch main
git pull
git branch -d add-greeting
git push origin --delete add-greeting
git fetch --prune
```

Prefer `git branch -d` over `-D`: `-d` only deletes when Git believes the branch is fully merged, which is the safety rail. If the repository auto-deleted the remote branch after merge, the `git push origin --delete` step may fail — that is expected; `git fetch --prune` still clears the stale `origin/add-greeting` name.

If you skipped the remote steps, there was no pull request to merge your change into `main` — stand in for that merge locally, then clean up the same way:

```
git switch main
git merge add-greeting
git branch -d add-greeting
```

**Checkpoint:** `git branch` shows only `main`, and `git status` reports a clean working tree on the updated default branch.

## What good looks like

- One small change went from branch to merged (or to a noted simulated merge) without touching anything outside `notes.txt`.
- The prompt you wrote had a goal, checkable success criteria, a scope limit, and a reason — written before checking the result.
- You reviewed the real diff, not a summary, before committing.
- You ran the test runner yourself and read its summary line.
- The commit message is in the imperative mood.
- After cleanup, `git branch` shows only `main` and the working tree is clean.

## If you get stuck

- **`git branch <name>` did not switch.** It only creates the pointer. Use `git switch -c <name>` to create and move in one step.
- **Switch refused because of local changes.** If switching would overwrite your edits, Git aborts and keeps you on the current branch. Commit the work or resolve it before switching.
- **Nothing staged, nothing committed.** `git commit` records only what is staged. Check `git diff --staged` first if a commit looks empty.
- **`git diff` alone can mislead.** Plain `git diff` shows working tree versus staging area only. Use `git diff --staged` to see what a commit right now would record.
- **pytest exit code 5 is not success.** "No tests collected" means nothing ran; check that your test files were found.
- **Trusting the agent's story.** "Tests passed" is not evidence. Read the diff and run the tests yourself; agents can invent plausible-sounding functions and miss edge cases.
- **`git branch -d` refuses.** After a squash merge, the branch can look unmerged even though the change landed. Verify the content is on the default branch first, then use `-D` only after that check.
- **Cannot delete the branch you are on.** Switch to `main` before `git branch -d`.
- **Stale `origin/<branch>` names.** Run `git fetch --prune` so remote-tracking names match reality.
- **Pull request is not `git pull`.** Opening or merging a pull request never runs `git pull` on your machine; you fetch or pull yourself to see the result.

## Lessons used

- git-and-github/branches-and-switching — Branches and switching
- git-and-github/working-tree-staging-and-status — Working tree, staging, and status
- git-and-github/commits-and-history — Commits and history
- git-and-github/push-and-upstream-branches — Push and upstream branches
- git-and-github/pull-requests-and-review — Pull requests and review
- git-and-github/post-merge-synchronization-and-cleanup — Post-merge synchronization and cleanup
- prompt-engineering/clear-and-direct-instructions — Clear and direct instructions
- prompt-engineering/defining-goals-and-success-criteria — Defining goals and success criteria
- prompt-engineering/verifying-agent-work — Verifying agent work
- testing-basics/run-tests-locally — Running pytest/Pester and reading pass-fail
- agentic-ai-development/reviewing-agent-generated-code — Reviewing agent-generated code and staying accountable

---
title: Starting a project safely
workflow: starting-a-project-safely
time_minutes: 75
level: 3
---

## Goal

In this exercise you will start a brand-new, throwaway practice project from scratch, the safe way. You will create a fresh folder named `practice-starting-a-project-safely`, turn it into a Git repository, set up a `.gitignore` before your first commit, create a `.env` file with a fake placeholder secret, and verify that the `.env` file is ignored **before** you commit anything. You will also install one dependency, look at the files it creates, and run a tiny program.

This project is practice-only. It stays on your machine, is never pushed anywhere, and never touches any real project. If you make a mistake, you can delete the folder and start over.

## You will need

- A terminal (Terminal on macOS/Linux, PowerShell 7 (`pwsh`) or Terminal in your editor on Windows).
- **Git** 2.28 or later installed (`git init -b` needs it). Check with `git --version`.
- **Node.js and npm** installed. Check with `node --version` and `npm --version`. npm is the package manager this exercise uses — it is the same example toolchain the cited lessons use (they also mention pip for Python, but this exercise sticks to npm throughout).
- A plain text editor (any editor is fine).

## Steps

### Step 1: Open a terminal and confirm where you are

Every command runs "somewhere" — a folder called the **current working directory**. A **relative path** (like `my-folder/file.txt`) is resolved from that folder; an **absolute path** (like `/home/you/...` or `C:\Users\you\...`) is the full address from the root of the file system.

Check where you are:

macOS/Linux:

```bash
pwd
```

Windows (PowerShell):

```powershell
Get-Location
```

Both print your current folder. Then list what is in it:

macOS/Linux:

```bash
ls
```

Windows (PowerShell):

```powershell
Get-ChildItem
```

**Checkpoint:** The output of `pwd` (or `Get-Location`) shows a real folder path on your machine, and the listing command prints the contents of that folder without an error.

### Step 2: Create the practice folder and make it a Git repository

A **Git repository** is a project folder plus a hidden `.git` folder that records the project's history. `git init` creates that history store in the current folder.

Create the folder, go into it, and initialize the repository (the same commands work on macOS/Linux and in Windows PowerShell):

```
mkdir practice-starting-a-project-safely
cd practice-starting-a-project-safely
git init -b main
```

A **branch** is a line of history. `-b main` tells `git init` to name the starting branch `main` right away, instead of leaving it unnamed until the first commit.

**Checkpoint:** `git init` prints a message like "Initialized empty Git repository in ..." and the path it prints ends in `practice-starting-a-project-safely/.git/`.

### Step 3: Set a local Git identity

Every commit records an author name and email. These come from Git **configuration**. You will set them with **local** scope, meaning they apply only to this one throwaway repository — not to every repository on your machine (that would be `--global` scope).

```
git config user.name "Practice Student"
git config user.email "practice@example.com"
git config user.name
```

The last command prints the value back so you can confirm it was saved.

**Checkpoint:** `git config user.name` prints `Practice Student`, and `git config user.email` prints `practice@example.com`.

### Step 4: Write a `.gitignore` before the first commit

A **`.gitignore`** file lists patterns for files Git should leave alone — never track, never commit. It only affects files that are not yet tracked, so it must exist **before** your first commit to be effective.

Create a file named `.gitignore` in the project folder with exactly this content:

```
.env
node_modules/
*.log
```

- `.env` — your secrets file (you will create it in the next step).
- `node_modules/` — the folder where npm puts installed dependencies; it is huge and rebuildable, so it is never committed.
- `*.log` — log files, which are machine-generated noise.

**Checkpoint:** Run `ls -a` (macOS/Linux) or `Get-ChildItem -Force` (Windows PowerShell). The listing shows the `.gitignore` file. (The `-a` / `-Force` flags are needed because files starting with a dot are hidden by default.)

### Step 5: Create `.env` and `.env.example`

An **environment variable** is a named setting a program reads from its surroundings, outside the source code. A **`.env`** file is a plain text file listing `NAME=value` pairs that some tools load as environment variables. It is a common place for secrets like API keys — which is exactly why it must never be committed. It is unencrypted text, not a safe.

Create a file named `.env` with this content:

```
APP_SECRET=replace-me-not-a-real-key
```

Then create a second file named `.env.example` — a template committed to the repo so teammates know which names the project expects, with only placeholder values:

```
APP_SECRET=replace-me-not-a-real-key
```

Both files use an obvious placeholder. Never put a real key in either file during this exercise.

**Checkpoint:** Run `ls -a` (macOS/Linux) or `Get-ChildItem -Force` (Windows PowerShell). Both `.env` and `.env.example` appear in the listing.

### Step 6: Verify `.env` is ignored — before any commit

This is the most important step in the exercise. Do not stage or commit anything until this check passes.

Ask Git directly whether the path is ignored:

```
git check-ignore .env
```

If `.env` is ignored, the command prints `.env` back to you. Then confirm it does not show up as a file worth committing:

```
git status
```

`git status` lists files Git sees as new or changed. You should see `.gitignore` and `.env.example` listed as untracked, but **no `.env` anywhere** in the output.

**Checkpoint:** `git check-ignore .env` prints `.env`, and `git status` output contains `.gitignore` and `.env.example` but does **not** contain `.env`. If `.env` appears in `git status`, stop and fix `.gitignore` before continuing.

(As general knowledge: even if a secret ever did slip into a commit, a hosting service like GitHub has a feature called **push protection** that can block the push before the secret reaches the server. That is a server-side safety net — this exercise's repo stays local, so you will never rely on it. The local `.gitignore` check you just did is the first line of defense.)

### Step 7: Make the first commit

A **commit** is a recorded snapshot of the project. **Staging** (with `git add`) chooses which changes go into the next commit.

Stage the safe files and commit:

```
git add .gitignore .env.example
git commit -m "Start practice project with gitignore and env template"
git status
git log --oneline
```

`git log --oneline` shows the commit history, one line per commit.

**Checkpoint:** `git log --oneline` shows one commit, and `git status` after the commit says something like "nothing to commit, working tree clean" — with no mention of `.env`. To be extra sure, run `git ls-files` and confirm `.env` is not in the list (`.gitignore` and `.env.example` are).

### Step 8: Install one dependency and inspect the manifest and lockfile

A **dependency** is third-party software your project uses. A **package manager** (here: npm) downloads and organizes dependencies. npm keeps installed packages in the project's own `node_modules` folder, which is npm's built-in per-project isolation — so unlike Python projects, no separate virtual-environment step is needed.

Install a small, real date-handling package:

```
npm install date-fns
```

This changes two files:

- **`package.json`** — the **manifest**: what the project **declares** it needs (like a shopping list).
- **`package-lock.json`** — the **lockfile**: the exact versions actually installed, including dependencies of dependencies (like a receipt).

Look at both:

macOS/Linux:

```bash
cat package.json
head -20 package-lock.json
```

Windows (PowerShell):

```powershell
Get-Content package.json
Get-Content package-lock.json -TotalCount 20
```

Notice the lockfile is much longer — it records exact versions for the whole dependency tree. Both files belong in the repository; `node_modules/` does not (your `.gitignore` already excludes it).

**Checkpoint:** `package.json` contains a `"dependencies"` section listing `date-fns`, and `ls` (or `Get-ChildItem`) shows that both `package.json` and `package-lock.json` now exist, along with a `node_modules` folder.

### Step 9: Build (sort of) and run — and actually verify the result

Install, build, and run are three conceptually separate steps: **install** fetches dependencies, **build** generates runnable output, **run** starts the program. npm compresses these for a tiny script — there is no separate build step for plain JavaScript, so here install and run are all you need. That is an honest compression of the pattern, not a contradiction: the steps are still conceptually distinct even when one tool skips one.

Create a file named `index.js` with this content:

```javascript
const { format } = require("date-fns");
console.log("Today is " + format(new Date(), "yyyy-MM-dd"));
console.log("Secret value loaded from env would go here, not in code.");
```

Then run it:

```
node index.js
```

**Checkpoint:** The command prints a line like `Today is 2026-01-15` (with today's actual date). That printed output is your proof the dependency is installed and the program actually ran — a successful install alone would not have proven anything.

### Step 10: Check for a license file

A **license** file states the conditions under which software may be used, modified, and shared. Nearly every package npm installs comes with one. Common identifiers include `MIT` and `Apache-2.0` (**permissive** licenses, which mostly require keeping the attribution notice) and the `GPL` family (**copyleft** licenses, which carry stronger sharing obligations). "Free to install" never means "free of conditions."

Look at the license that came with your dependency:

macOS/Linux:

```bash
ls node_modules/date-fns/LICENSE*
head -5 node_modules/date-fns/LICENSE*
```

Windows (PowerShell):

```powershell
Get-ChildItem node_modules/date-fns/LICENSE*
Get-Content node_modules/date-fns/LICENSE* -TotalCount 5
```

You should see the MIT license text. For this throwaway practice project, you may add any permissive license text (for example, the MIT text) as a `LICENSE` file placeholder — or simply note that a real project you intend to share would include one.

**Checkpoint:** The listing command shows a `LICENSE` file inside `node_modules/date-fns`, and the first lines of the file name a license (MIT). If you added a `LICENSE` file to your project root, `git status` shows it as a new untracked file you could commit.

## What good looks like

- `git check-ignore .env` prints `.env`, and `.env` never appears in `git status` or `git ls-files`.
- The first commit contains `.gitignore` and `.env.example` but never `.env`.
- `package.json` and `package-lock.json` both exist and both changed together when you installed the dependency.
- `node index.js` prints today's date — you reached the running result, not just a finished install.
- You can name the license your dependency ships with and say whether it is permissive or copyleft.

## If you get stuck

- **`git check-ignore .env` prints nothing.** Check the `.gitignore` spelling: the line must be exactly `.env`, and the file must be in the project root. Re-run after fixing.
- **`.env` shows up in `git status`.** Same fix — and importantly, you have not committed yet, so nothing is lost. Fix `.gitignore`, re-verify, then commit.
- **On Windows, `.gitignore` or `.env` doesn't seem to exist, or `git check-ignore` finds nothing.** Notepad and some other editors hide known file extensions by default, so a file saved as `.gitignore` can actually be named `.gitignore.txt`, and `.env` can become `.env.txt`. Turn on "File name extensions" in File Explorer's View tab, or run `Get-ChildItem -Force` and check the names carefully, to confirm.
- **`git: command not found`** (or PowerShell says the command is not recognized). Git is not installed or not on your PATH. Install Git and open a new terminal, then try again.
- **`npm: command not found`.** Node.js/npm is not installed. Same as above.
- **`node index.js` prints an error about `date-fns`.** The install in Step 8 may not have completed. Re-run `npm install date-fns` and check for errors in its output.
- **Anything else confusing:** you can always delete the whole `practice-starting-a-project-safely` folder and start over from Step 2. That is the point of a throwaway practice project.

## Lessons used

- dev-tooling-literacy/terminal-shell-commands — Terminal, shell, and commands
- dev-tooling-literacy/working-directories-and-paths — Working directories and paths
- git-and-github/creating-and-cloning-repositories — Creating and cloning repositories
- git-and-github/setup-configuration-and-authentication — Setup, configuration, and authentication
- git-and-github/gitignore-essentials — .gitignore essentials
- dev-tooling-literacy/environment-variables — Environment variables
- dev-tooling-literacy/dotenv-and-secrets — .env files and keeping secrets out of code
- git-and-github/secret-scanning-push-protection — Responding to secret-scanning and push-protection alerts
- dev-tooling-literacy/dependencies-and-package-managers — Dependencies and package managers
- dev-tooling-literacy/manifests-vs-lockfiles — Dependency manifests vs. lockfiles
- dev-tooling-literacy/virtual-environments — Virtual environments: keeping dependencies separate
- dev-tooling-literacy/install-build-run — Install, build, and run are different steps
- dev-tooling-literacy/license-files — License files and third-party obligations
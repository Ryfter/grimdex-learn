---
title: Terminal, shell, and commands
module_id: dev-tooling-literacy
capabilities:
  - terminal-shell-commands
context7_library:
context7_queries:
official_sources:
  - https://www.gnu.org/software/bash/manual/
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

Three distinct things often get lumped together under "the command line":

- **The terminal** is the window — the visual container where text input and output appear.
- **The shell** is the program running inside that window that interprets what you type. It reads a command, figures out what it means, and arranges for it to run.
- **The program being invoked** is whatever command the shell hands off to — for example, a file listing tool, a package installer, or a development server.

When a coding agent runs commands on your behalf, it is asking a shell to invoke programs. Recognizing these three layers helps you read what an agent is doing: *where* the text appears (terminal), *who interprets it* (shell), and *what actually runs* (the invoked program).

## When it is useful

- Reviewing commands an agent proposes before approving them.
- Understanding why the same command behaves differently in different places.
- Recognizing the shape of a command — a program name, some arguments, and some options — without needing to learn shell scripting.
- Following along when an agent reports that "the shell" reported an error, versus the program it ran.

## Prerequisites

None. This is a starting point for recognizing tooling, not a scripting course.

## Current syntax

There is nothing to install here; this is recognition vocabulary. The typical shape of a shell command is:

```
program-name   --option   value   target
```

- The **program name** is what the shell will run (e.g., `ls`, `npm`, `python`).
- **Options** (often starting with `-` or `--`) modify how the program behaves — for example, requesting more detail or a different output format.
- **Arguments** are the things the program acts on, such as a file name or a search term.

Being able to point at "that's the program, those are options, that's the target" is usually enough to follow what an agent is doing. This is distinct from shell *scripting* — writing multi-line logic, conditionals, or loops — which is not needed at this level.

## What happens (local and remote)

When an agent proposes a command, the shell is what interprets it. A few practical consequences:

- The shell may expand things (like file-name patterns) before the program runs, so what the program receives can differ from what you saw typed.
- Options are interpreted by the *program*, not the terminal — so two different programs can treat the same flag very differently.
- If the shell itself doesn't recognize a command name, you'll typically see something like "command not found" — a shell-level report, not a program error.

Remotely (for example, in a cloud terminal or container), the same three-layer picture applies: a terminal window, a shell inside it, and the programs the shell invokes. The layers are the same even when the window looks different.

## Practical example

An agent proposes this command and asks for approval:

```
npm install --save-dev some-package
```

Annotated:

- `npm` — the **program** the shell will invoke; it is the Node.js package manager.
- `install` — an **argument** telling npm what action to take.
- `--save-dev` — an **option** (a flag) modifying the action; here it records the package as a development-time dependency rather than a production one.
- `some-package` — the **target** of the action, the package to install.

Reading the command this way — without needing to run it or write scripts — is the skill. You can now ask a useful question: "Why is this being saved as a dev dependency instead of a regular one?" even if you would not type the command yourself.

## Explanation guidance

### Essential

- The terminal is the window; the shell is the interpreter inside it; the command is a program the shell starts.
- Recognizing the parts of a command — program, options, arguments — is enough to review what an agent proposes.
- No shell scripting is required at this level; do not turn this into a scripting lesson.

### Experienced-user note

- The shell does some interpretation of its own (for example, expanding patterns) before the program runs, so the program may receive slightly different text than what was typed.
- Different shells exist (for example, `bash` is one widely used shell), and details of interpretation can differ between them — but the terminal/shell/program layering holds across them.

### Optional deeper context

- The GNU Bash manual's "Introduction" and "Shell Commands" sections formally describe the shell as the interpreter and describe how commands are structured. Reading them is optional; the recognition-level picture above is what matters for collaborating with an agent.

## Cautions and common failures

- **Approving commands you can't read at all.** If you can't identify at least the program name and the target, it's reasonable to ask the agent what the command does before approving.
- **Treating the terminal window as "the shell."** The window is just a view; errors about "command not found" or "permission denied" come from the shell or the invoked program, and knowing which layer complained helps in asking good follow-up questions.
- **Assuming options are universal.** `--force` or `-f` means different things to different programs. Recognition includes noticing that a flag's meaning depends on which program it belongs to.
- **Drifting into scripting territory.** You don't need loops, conditionals, or script files to collaborate effectively at this level.

## Related capabilities

- working-directory-paths — why the same command can behave differently depending on where it is run
- running-processes-stopping-servers — a command can start something that keeps running after the shell prompt returns
- exit-codes — how programs report success or failure back to the shell
- environment-variables — how the shell's context shapes program behavior

## Official sources

- GNU Bash manual — "Introduction" and "Shell Commands" sections: https://www.gnu.org/software/bash/manual/

## Provenance

- Grounded in the GNU Bash manual (gnu.org/software/bash/manual/), "Introduction" and "Shell Commands" sections, as verified in this module's research phase.
- Recognition-level framing (terminal vs. shell vs. invoked program; command anatomy without scripting) is practice guidance anchored to that official documentation.
- Cross-references: debugging-recovery module's read-error-messages lesson is referenced conceptually; no content is duplicated here.
- No Context7 library mapping is used for this module by design; official sources above serve as the anchors.
---
title: Environment variables
module_id: dev-tooling-literacy
capabilities:
  - environment-variables
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

Environment variables are named values that the shell and the programs it runs can read from their surroundings. They live outside your project's source files. When a program starts, it inherits a set of these variables from the environment that launched it — a terminal session, a script, or a deployment platform.

The practical consequence for someone collaborating with an AI coding agent: the same project, with exactly the same files, can behave differently depending on which variables are set in the environment where it runs. A settings value like "which database to talk to" or "which mode to run in" can be supplied by the environment rather than written into the code.

Related recognition points, kept at awareness level:

- A **shell variable** exists only inside one shell session; an **environment variable** is one that gets passed along to programs the shell starts.
- Programs typically read environment variables by their ALL-CAPS names, such as `PORT`, `NODE_ENV`, or `DATABASE_URL`.
- Names you choose yourself usually follow the same convention.

## When it is useful

Recognizing environment variables is useful whenever:

- An agent says it will "set an environment variable" or reads one to decide how a program behaves — for example, switching between a development mode and a production mode.
- A project works on one machine or terminal but not another, and no source file changed in between. Different terminals or machines can have different variables set.
- A deployed version of the project behaves differently from your local copy — deployment environments typically supply their own variable values.
- You see a value being read from the environment rather than hard-coded into a file, which is a common (and generally good) pattern for settings that vary by location, such as API keys or connection details.

## Prerequisites

- Awareness of what a terminal and shell are (see the terminal-and-shell capability in this module).
- Awareness that a project is a set of files in a working directory.
- No programming knowledge required; this is recognition of a mechanism, not how to write code that uses it.

## Current syntax

There is no syntax to learn at recognition level, but there are shapes worth recognizing when an agent works in a terminal:

- **Setting a variable in the shell** so it applies to programs started from that session. The exact command differs between shells (for example, `export NAME=value` is the common Bash form); the point is that the agent types a shell command, not a code change.
- **Reading a variable** — a program or command refers to it by name, often shown in shell text with a `$` prefix (e.g., `$PORT`).
- **A prefixed command** — a variable assignment placed immediately before a command applies to that one command only. Recognizing this shape ("the agent ran a command with `NAME=value` in front of it") is enough.
- **A `.env` file** — a plain text file listing `NAME=value` pairs that some tools load into the environment. See the cautions section and the related `.env`-and-secrets topic.

Do not memorize shell-specific commands; recognize that these are shell actions, distinct from editing project source files.

## What happens (local and remote)

Everything in this lesson happens locally on the machine (or within the deployment platform) where the project runs — no remote service is involved in environment variables themselves.

- When an agent sets a variable in a terminal, it affects the programs launched from that session. A different terminal, opened separately, does not automatically see it.
- When a program starts, it copies the values it inherits; changing a variable afterward does not retroactively change a program that is already running. If an agent changes a variable, the affected program usually needs to be restarted for the change to take effect.
- On deployed environments (a hosted server, a cloud platform), variables are typically set through that platform's own configuration — not by editing files in the repository. That is why a project can behave differently in production without any code difference.

## Practical example

An annotated recognition example — not something to run.

Suppose an agent is starting a project's dev server and types something like:

```
PORT=4000 npm run dev
```

What to recognize here:

- `PORT=4000` — a variable named `PORT` with the value `4000`, supplied to this one command.
- `npm run dev` — a command (a script step) that will start the server; the program it launches can read `PORT` from its environment.
- The agent has not edited any file. The same project files, started with `PORT=3000` instead, would (if the program supports it) listen on a different port — the environment, not the source, supplied the difference.
- If you open a new terminal afterward and start the server again without that prefix, the variable may not be set there at all — illustrating why "it works in one terminal but not another" is a classic environment-variable symptom.

A second recognizable pattern: an agent says it is "configuring the connection string via an environment variable" rather than pasting a database address into the code. That is the environment supplying per-location settings — the same mechanism at work.

## Explanation guidance

### Essential

- Environment variables are named settings supplied by the surroundings a program runs in, outside the source files.
- They explain the same project behaving differently in different terminals, machines, or deployments — nothing in the code changed; the environment did.
- Setting one is a shell/environment action, not a code edit; a running program usually needs restarting to pick up a change.
- If a project "mysteriously" differs between two contexts, differences in environment variables are one of the first things to consider.

### Experienced-user note

- Environment variables are one layer of configuration; manifests, config files, and command-line options are other layers, and a project may mix them. Knowing which layer an agent is touching helps you review its changes.
- Values inherited by a program are copied at startup — long-running servers hold the old values until restarted. If an agent reports "I set the variable," ask whether the relevant process was restarted.
- Some variables influence tooling behavior as well as the application (for example, variables that package managers or shells consult). An agent may set or read variables whose names you don't recognize; it's reasonable to ask what a given variable does before approving.

### Optional deeper context

- The Bash manual documents the distinction between shell variables and the exported environment passed to programs, and how a shell's environment is initialized (see Official sources).
- Deployment platforms expose their own mechanisms for setting variables for hosted applications; each platform documents this separately, which is why the same repository can behave differently across hosts.
- `.env` files bridge this mechanism and configuration files: they are a tool-dependent convention for loading variable values, not a secure storage mechanism — see the `.env`-and-secrets topic in this module for that caution in full.

## Cautions and common failures

- **Secrets in variables are still secrets.** The environment-variable mechanism is not a security feature by itself. Values such as API keys or database passwords must not be hard-coded into source files or casually shared — see the `.env`-and-secrets capability in this module.
- **Scope confusion.** A variable set in one terminal does not exist in another; a variable set on one machine does not exist on another. If an agent reports success in one context, do not assume it carries over.
- **Stale processes.** A change to a variable does not affect a program already running until it is restarted. A "fix" that only changed the environment may appear not to work for this reason.
- **Wrong-place behavior.** Because variables can select modes or destinations (e.g., which database to connect to), an agent running a command with different environment settings may be pointing the project somewhere other than you expect — worth confirming before approving consequential actions.
- **Assuming a variable is set.** If a program fails because an expected variable is missing, the error may not say so plainly. Recognizing that "unset expected variable" is a common failure class helps you ask the right question.

## Related capabilities

- terminal-and-shell — where environment variables are set and read
- env-files-and-secrets — the .env convention and its security limits
- working-directories-and-paths — the other context a shell session carries
- install-build-run-steps — restarting/relaunching steps where new variable values take effect

## Official sources

- GNU Bash manual, "Environment": https://www.gnu.org/software/bash/manual/

## Provenance

- Content is recognition-level practice guidance anchored to the GNU Bash manual's "Environment" section, as verified in this module's research. Scoped to tooling/workflow recognition for beginners collaborating with an AI coding agent; explicitly not programming-language fundamentals. No vendor claims beyond the cited source. Version context: fall-2026-0.1.0.
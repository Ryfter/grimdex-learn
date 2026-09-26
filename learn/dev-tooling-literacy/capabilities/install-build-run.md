---
title: Install, build, and run are different steps
module_id: dev-tooling-literacy
capabilities:
  - install-build-run
context7_library:
context7_queries:
official_sources:
  - https://docs.npmjs.com/cli/v11/using-npm/scripts
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

Setting up and starting a software project is not one action but three distinct steps:

- **Install** — fetch and set up the third-party software the project depends on (its dependencies).
- **Build** — generate the actual runnable artifacts from the project's source files (compiled code, bundled assets, optimized output).
- **Run** — execute the built application so it is actually serving, working, or available.

An AI coding agent may perform these steps in sequence, and it is important to recognize them as separate: **a successful build does not mean the app is running.** A build can finish cleanly while the application itself was never started — or was started and then stopped.

## When it is useful

This recognition matters whenever an agent reports progress on a project, for example:

- An agent says "dependencies installed and build succeeded" — that tells you the pieces were fetched and assembled, but **not** that you can open a browser and use the app.
- An agent says "the app is running" — that is the run step; you should be able to actually reach the application (typically at a local address such as localhost on some port).
- An agent proposes to "rebuild" after changes — a rebuild regenerates artifacts; it may or may not restart or affect a running instance.

Distinguishing the steps lets you ask the right follow-up question: "Build done — is it running now, and where can I reach it?"

## Prerequisites

- Basic recognition of a terminal and commands (see the terminal/shell capability in this module).
- Awareness of dependencies and package managers (see the dependency-managers capability) — the install step is where those are fetched.

## Current syntax

Recognition-level only — no commands to memorize. In many JavaScript/Node.js projects, these steps appear as named scripts in a `package.json` file (for example, common script names like `install`, `build`, and `start`), and an agent will typically run each as a separate command. Other ecosystems use equivalent tooling (for Python, the package installer plus running the program directly). What to recognize is the **pattern**: a sequence of separate commands, each reported separately by the agent, corresponding to install → build → run.

## What happens (local and remote)

- **Local:** The agent runs install, then build, then run, usually as separate terminal commands with separate outputs. Each step can succeed or fail independently. A local dev server, once run, may keep occupying the terminal or continue in the background until stopped (see the running-processes capability).
- **Remote / deployment:** The same three steps exist on servers and deployment pipelines — code is installed, built, and then executed there. A pipeline report that says "build passed" means the artifact was generated, not that the deployed service is healthy.

In both settings, an agent's summary may compress these steps; asking which step is being described (or whether all three are done) keeps the picture accurate.

## Practical example

An annotated, recognition-only example of how an agent's progress might read:

```text
> npm install
added 214 packages in 12s        ← INSTALL step: dependencies fetched successfully

> npm run build
✓ built in 8.3s                  ← BUILD step: artifacts generated successfully

> npm run start
App listening on http://localhost:3000   ← RUN step: the app is now actually serving
```

Reading it step by step:

- The first two lines confirm preparation. If the session ended here, **nothing is running** — there is no app to open in a browser yet.
- The third line is the one that indicates a live application, and even then, the way to confirm is to actually visit the address shown (here `http://localhost:3000`) or ask the agent which address/port the app is on.
- If any step had printed an error, the steps after it likely never ran — install failure means nothing to build; build failure means nothing to run.

The same pattern appears in an agent's prose: "I installed the packages and the build passed" describes two steps, not three.

## Explanation guidance

### Essential

- Install, build, and run are three separate steps, each able to succeed or fail on its own.
- A successful build means artifacts were generated — it is **not** proof that the application is running.
- "The app is running" is only confirmed by reaching it (for example, opening the local address it reports, such as a localhost URL on a specific port).
- When an agent reports progress, identify which step it is describing before drawing conclusions.

### Experienced-user note

- In npm-based projects, these steps correspond to lifecycle scripts (`npm install`, `npm run build`, `npm start`); a rebuild does not automatically restart an already-running server — if you change code, ask whether the running instance needs restarting or whether it picks up changes automatically (some dev servers do).
- A step can also be **skipped**: an agent may assume a previous install is still valid and go straight to build. That is usually fine, but worth noticing if behavior seems inconsistent with recent changes.

### Optional deeper context

- Build tools differ by ecosystem (bundlers, compilers, framework-specific CLIs), and some "build" steps combine multiple sub-steps; the useful invariant is the conceptual separation, not any specific tool.
- In CI/CD pipelines (used when deploying to remote environments), install/build/run appear as pipeline stages; a green pipeline badge typically reflects build passing, and a separate deployment/health check reflects the run side.
- Some runtimes blur the lines for development convenience — a dev server may build and run in one command during development, while production deployments keep the steps separate for reliability.

## Cautions and common failures

- **Assuming build success = working app.** The most common misread. A clean build with nothing running produces no usable application.
- **Approving a long command chain without noticing the steps.** Agents sometimes run install/build/run in one combined command; if it fails midway, know which step failed from the output.
- **Stale state.** An app left running from earlier keeps running in the background; "it's running" may reflect an old process, not the latest changes.
- **Confusing a stopped server with a failed build.** If the app "was working and now isn't," the failure may be in the run step (server stopped, port conflict) rather than the build.
- **Not verifying the run claim.** Ask for or check the address/port the app should be reachable at, and actually reach it, before treating "running" as true.

## Related capabilities

- `dependencies-package-managers` — what the install step actually fetches and manages.
- `running-processes-server-stopping` — what happens once the run step starts a server, and how it is stopped.
- `localhost-ports-exposed-services` — how to reach the app once it is running.
- `application-logs-severity` — interpreting the output produced while the app runs.
- `exit-codes` — how tools report success or failure for each step beyond visible output.

## Official sources

- npm docs, "Scripts and lifecycle": https://docs.npmjs.com/cli/v11/using-npm/scripts

## Provenance

- Capability drawn from the dev-tooling-literacy module grounding facts (D32 page contract), anchored to the npm docs "Scripts and lifecycle" page as the official source for the install/build/run distinction.
- Recognition-level framing: annotated example only, no implementation exercise, no invented vendor claims beyond the grounding facts.
- Cross-references stay within the dev-tooling-literacy module; runtime behavior details (stopping servers, ports) are covered by their own capability pages rather than repeated here.
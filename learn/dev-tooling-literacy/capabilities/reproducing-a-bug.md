---
title: "Reproducing a bug: making a symptom repeatable"
module_id: dev-tooling-literacy
capabilities:
  - reproducing-a-bug
context7_library:
context7_queries:
official_sources:
  - https://www.chromium.org/for-testers/bug-reporting-guidelines/
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

Reproducing a bug means establishing a set of **repeatable starting conditions, inputs, and actions** that reliably make a symptom appear. Instead of telling an AI coding agent "it crashed once, I don't know why," you hand it a concrete, repeatable recipe: what state the project was in, what you did, and what happened.

This is a **workflow literacy** skill, not a diagnosis skill. You are not expected to figure out *why* the bug happens or to export logs and evidence files — that belongs to the debugging-recovery module. Your job here is narrower and more valuable: turn a one-time impression into something the agent can see happen again and again.

The value is simple: **a symptom the agent can reproduce, it can investigate. A symptom it cannot reproduce, it can only guess at.**

## When it is useful

- You clicked a button, the app misbehaved, and you want to describe it well enough that an agent can see it too.
- An agent "fixed" something, but you're not sure the fix addressed the actual situation you hit — a repeatable recipe lets you check.
- An agent asks "can you show me how to trigger this?" — this skill is exactly how you answer.
- You're working with anyone else (human or AI) on a problem and need a shared, unambiguous description of it.

Well-run software projects treat this as standard practice; for example, Chromium's public bug-reporting guidelines ask reporters to include concrete, repeatable steps rather than a general impression. It's one well-known real-world example of the practice, not a universal standard.

## Prerequisites

Recognition-level familiarity with a few tooling concepts from this module:

- **Working directories and paths** — knowing roughly where the project lives, since "run it the way I did" depends on starting in the right place.
- **Running processes and stopping a server** — a dev server left in a strange state can be part of the starting conditions.
- **Environment variables and .env files** — some symptoms depend on configuration, not code.
- **Application logs and severity levels** — helpful for *recognizing* the symptom recur, though reading error messages in depth is covered in the debugging-recovery module.

## Current syntax

There is no syntax for this capability — it's a habit, typically captured as a short written recipe with three parts:

1. **Starting conditions** — a fresh/restartable state: which branch or file version, which server (if any) was running, any configuration or environment differences.
2. **Inputs and actions** — the exact steps, in order, e.g. "open the app at the local address, enter X in field A, click button B."
3. **Expected vs. observed** — what should have happened, and what actually happened.

This mirrors the structure you'll recognize in professional bug reports, where "steps to reproduce" is a standard, expected section.

## What happens (local and remote)

**Locally, for you:** preparing the recipe means getting the project back to a known state — restarting a stopped dev server, noting which terminal and directory you were in, re-running the same steps. You'll often find the bug is *not* consistent on the second try, which is itself useful information.

**With the agent:** the agent may re-run your steps itself, restart the server, request fresh inputs, or watch logs while the symptom occurs. A repeatable recipe lets it do this efficiently; a vague description forces it to ask clarifying questions or attempt blind fixes. Note that the agent may modify files or state while investigating — a known-good recipe means you can always get back to a state where the symptom appears again.

**Remote:** if the symptom involves a deployed or networked service, the recipe should note which environment it occurred in, since configuration differences across environments are common causes of "works on my machine" confusion.

## Practical example

An annotated, recognition-level recipe — read it to recognize the pattern, not to copy into a project:

```text
Bug recipe: "Save button does nothing on the second save"

Starting conditions:
  - Fresh copy of the project, on the main version
  - Dev server started the usual way, running in a terminal
  - One test account exists; logged in as that user

Inputs and actions:
  1. Open the app at the local address the agent gave me
  2. Log in with the test account
  3. Edit the "Notes" field, click Save
     -> this save works as expected
  4. Edit the same field again, click Save a second time
     -> nothing visibly happens; button appears to do nothing

Expected: the second save updates and shows a confirmation.
Observed: no visible response on the second save. Happened 3 out of 3 tries.
```

What to recognize in this example:

- **"3 out of 3 tries"** — the repeat count turns an impression into a reliable symptom. Even "2 out of 5" is valuable, because it tells the agent the bug is intermittent.
- **"Fresh copy / started the usual way"** — the starting conditions are stated so the agent (or a colleague) can recreate the same state.
- **Steps are numbered and ordered** — the *sequence* matters; "saving sometimes fails" is much weaker than "the first save works, the second doesn't."
- **Expected vs. observed are separate** — the agent learns both the intent and the failure, not just a complaint.

## Explanation guidance

### Essential

- A bug you can repeat on demand is a bug an agent can work with; a one-time impression leaves it guessing.
- Write down starting conditions, exact steps in order, and what you expected versus what you saw.
- Try the steps again before reporting: if the symptom doesn't recur, say so honestly — that's useful information, not a failed report.

### Experienced-user note

- Notice what varies between attempts: a fresh restart vs. a long-running server, a different working directory, a different configuration, or "works the first time, fails after" patterns. Noting *when it works vs. when it doesn't* often narrows the situation considerably before any diagnosis begins.
- If a symptom only appears after a specific prior action (a first save, a page refresh, a login), include that prior action in the recipe — starting conditions include history.

### Optional deeper context

- Public bug-tracking communities (like Chromium's contributor/tester guidelines) formalize this as "steps to reproduce" plus expected/actual behavior; reading a few real bug reports is a good way to internalize the shape of a good recipe.
- Reproducibility connects to the tooling concepts earlier in this module: state held by running processes, environment differences, and configuration can all be part of what makes a symptom appear or disappear.

## Cautions and common failures

- **Don't drift into diagnosis.** Describing *why* you think the bug happens, exporting logs, or interpreting error messages is the debugging-recovery module's territory — cross-reference it instead of attempting it here.
- **"It's broken" is not a recipe.** Descriptions like "the app is slow" or "it crashed" without steps give the agent nothing to re-run.
- **Don't assume it's consistent.** A bug that appears intermittently should be labeled as such; claiming certainty you don't have misleads the agent.
- **Don't leave out the state.** "It fails when I click Save" may only be true after a login, a prior save, or with a particular file open — the missing prior condition is often the whole story.
- **Don't treat a failed reproduction as wasted effort.** If you can't make it happen again, record what was different; that observation is real data.
- **Don't share secrets as part of the recipe.** Omit passwords, tokens, or .env contents from steps; refer to configuration generically ("using the project's environment settings").

## Related capabilities

- **dev-tooling-literacy:** running-processes-and-stopping-a-server (dev servers as part of starting conditions), environment-variables, .env-files-and-secrets, working-directories-and-paths, application-logs-and-severity-levels.
- **debugging-recovery (other module):** read-error-messages — the cross-reference for what to do once you *have* a repeatable symptom and error output in hand; this page covers only the reproduction workflow.

## Official sources

- Chromium bug-reporting guidelines — one well-known real-world example of structured, repeatable bug reporting practice: https://www.chromium.org/for-testers/bug-reporting-guidelines/

## Provenance

- **Scope:** workflow literacy only — establishing repeatable starting conditions, inputs, and actions for an AI coding agent. Diagnosis, evidence collection, and log interpretation are explicitly out of scope for this page (cross-referenced to the debugging-recovery module).
- **Depth:** recognition level throughout; the annotated recipe is an example to recognize, not an implementation exercise.
- **Sources:** grounded in this session's verified research; the single official source is a real URL from the grounding facts for this topic.
- **Not covered:** programming-language fundamentals (variables, loops, data types, OOP) — per the module's frozen scope, this page teaches tooling/workflow recognition, never code-writing.
- **Status anchors:** last checked 2026-09-20; version stamp fall-2026-0.1.0; claim class everyday; safety class normal.
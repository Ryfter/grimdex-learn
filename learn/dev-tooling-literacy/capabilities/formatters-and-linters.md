---
title: "Formatters and linters: different kinds of cleanup"
module_id: dev-tooling-literacy
capabilities:
  - formatters-and-linters
context7_library:
context7_queries:
official_sources:
  - https://prettier.io/docs/comparison
  - https://eslint.org/docs/latest/use/core-concepts/
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

Formatters and linters are two common automated tools that keep a codebase tidy -- and they do different jobs.

- A **formatter** automatically changes the layout of code: spacing, indentation, line breaks, quoting style. The code's meaning is supposed to stay exactly the same; only its appearance changes. Prettier is a well-known formatter.
- A **linter** statically checks code -- it reads the code and flags patterns that may indicate mistakes, questionable style, or risks, without running the program. It reports; it does not usually fix things by itself (many linters can offer automatic fixes for some rules). ESLint is a well-known linter.

The key recognition point: **neither tool establishes that the application behaves correctly.** A formatter passing and a linter coming back clean are encouraging signals about consistency and common pitfalls -- not proof that the feature works.

## When it is useful

You'll recognize these tools when:

- An agent says it will "run the formatter" and the diff shows many files changed with tiny whitespace or layout differences. That is expected formatter behavior -- large-looking diffs for cosmetic reasons.
- An agent reports "linting passed" or "lint checks clean" as part of its summary. This is a check on specific rules, not a verification that the program does what you asked.
- An agent proposes adding a formatter or linter to the project as part of setup. This is normal, common tooling, not a sign something is wrong.

## Prerequisites

- Basic recognition of a project's file tree and of an agent making changes to multiple files (see the dependency-manifests lesson in this module for how multi-file changes arise).
- Awareness that "the tool ran successfully" and "the application is correct" are different claims (see the exit-codes lesson: a clean run doesn't by itself establish success).

## Current syntax

Recognition-level only -- you don't need to write or run anything. You'll see these tools appear as:

- Config files in the project root (e.g. a formatter or linter configuration file, possibly in JSON or YAML form -- see the config-file-formats lesson).
- Agent output such as "formatting complete", "formatted 12 files", or a lint report listing file names, line numbers, and rule names.
- Entries in a dependency manifest (see the dependencies lesson) -- formatters and linters are themselves installed software.

## What happens (local and remote)

Locally: a formatter rewrites files in place (layout only); a linter reads files and produces a report of findings. Neither executes your application, so neither can observe what the app actually does when run.

Remotely: these same checks are very often run automatically on shared platforms (for example, when code is submitted for review on a team's code-hosting service). A green automated check there means the same thing it does locally: layout and rule checks passed -- still not a behavior guarantee.

## Practical example

An annotated snippet of the kind of output you might recognize:

```
> prettier --write .
✔ Formatted 14 files                    ← formatter: layout changes applied
> eslint .
src/api/client.js
  12:5  warning  Unused variable 'x'   ← linter: finding a suspicious pattern
✖ 1 warning, 0 errors                   ← linter summary; it reported, not fixed
```

Reading it:

- The first line: many files "changed" because of layout, not logic. Don't panic at the diff size.
- The middle: a linter finding is a flagged *pattern* with a location -- "something to look at", not a verdict that the program is broken or working.
- The last line: "0 errors" means no flagged patterns. It does not mean the feature works. Only actually running the app (see the install-build-run lesson) shows behavior.

## Explanation guidance

### Essential

- Formatter = automatic layout cleanup; linter = static checks that flag suspicious patterns.
- Both are ordinary, routine tools -- an agent using them is normal good practice.
- Neither proves the application behaves correctly. "It passes lint" is not "it works."

### Experienced-user note

- Teams treat these as consistency tools: they remove arguments about style and catch a known class of slips early, so human and agent attention can go to behavior and design.
- Some linter rules overlap with formatter territory, and many tools can auto-fix some findings -- the categories blur at the edges, but the core distinction (rewrite layout vs. report findings) holds.

### Optional deeper context

- The distinction is documented by the tools themselves: Prettier explicitly positions itself against linters ("comparison with linters"), and ESLint's core-concepts documentation describes linting as static analysis of code for problems -- both worth a skim if you want the vendors' own framing.
- This module stays at recognition level; how to configure rules or write custom lint checks is implementation territory, out of scope here.

## Cautions and common failures

- **Mistaking clean checks for correctness.** The most common over-trust: "lint passed, so it's done." Formatters and linters cannot observe runtime behavior.
- **Mistaking formatter churn for meaningful change.** Huge diffs that turn out to be pure formatting can hide -- or be confused with -- real logic changes. Ask the agent to confirm which changes are cosmetic.
- **Trusting every linter finding as a real bug.** Findings are pattern-based flags; some are stylistic or false positives. Treat them as "look here," not "this is broken."
- **Noting that neither tool checks security.** A clean lint run says nothing about vulnerabilities; see the module's security-adjacent lessons (.env files, permissions, containers) for those cautions.

## Related capabilities

- exit-codes -- tool success signals vs. behavior
- install-build-run -- actually running the app to see behavior
- config-file-formats -- recognizing the configuration files these tools use
- dependency-manifests -- where these tools are declared and installed from

## Official sources

- Prettier docs, "Comparison with linters": https://prettier.io/docs/comparison
- ESLint docs, "Core concepts": https://eslint.org/docs/latest/use/core-concepts/

## Provenance

Anchored to vendor documentation from the two reference tools (Prettier and ESLint), cross-checked in the module's earlier verified research. Recognition-level, grounded in the tools' own positioning of formatter vs. linter roles. No vendor claims beyond those sources; no code-writing instruction; tooling/workflow literacy only.
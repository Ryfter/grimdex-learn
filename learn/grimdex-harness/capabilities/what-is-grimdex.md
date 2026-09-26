---
title: What Grimdex is (and is not)
module_id: grimdex-harness
capabilities:
  - what-is-grimdex
context7_library:
context7_queries:
official_sources:
  - https://github.com/Ryfter/Grimdex
  - https://github.com/Ryfter/grimdex-learn
last_checked: 2026-09-18
last_material_update: 2026-09-18
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-product-decision-record
---

## What it is

Grimdex is an open-source coding harness. Grimdex-edu, also called **Learn**, is its education module. Learn does exactly two things:

- **Pass-through:** points readers to a wiki and/or other documentation when they want more than the essentials.
- **Verbosity:** gives more verbose, educational responses where stock Grimdex gives simpler ones.

Learn explains essentials in place while you work. It is not a classroom install, a course delivery system, or an "education edition" of Grimdex. Course content belongs to a separate class wiki project, not to Learn.

## When it is useful

Learn is useful when you want a short explanation of what something is, why it matters, and a little about how it works — rather than only a simpler response.

It is also useful when you need a pointer to deeper documentation without having the whole topic explained in place. This applies whether you are coding, managing IT work, or approaching a technical task from a non-programming role.

## Prerequisites

A wiki is not required. Learn must function fully without one; a missing wiki is a normal state, not an error.

This introductory concept requires no special command or course material.

## Current syntax

There is no special command or literal syntax for this concept.

Recognize Learn's role through its responses: more educational explanation than stock Grimdex, with pointers to further reading when appropriate. These are behaviors to look for, not a required label or exact response format.

A wiki link is not required evidence that Learn is active. Without a wiki, Learn can point directly to official documentation. If no onward destination is available, the explanation must still stand on its own.

## What happens (local and remote)

Learn adds explanation within the working interaction, then hands off to further reading when more depth is needed:

**Grimdex → Learn → Wiki → official docs**

Grimdex is the base harness. Learn supplies essentials in place. A wiki can provide deeper learning, while official documentation is where readers go for real expertise.

This is a learning-depth ladder, not a required route through every destination. Learn can skip the wiki and link directly to official docs.

The locked product decisions define explanation and pass-through behavior, not local execution, network requests, or data handling. An onward link alone does not establish any of those behaviors.

## Practical example

Suppose a reader asks what Grimdex-edu adds to Grimdex. An essentials-level explanation could be:

> Learn gives more educational explanations than stock Grimdex and points you to further documentation when you need more depth. It is not a course system. You can use it without a wiki; official docs can be the next stop instead.

That answers the immediate what and why without turning the response into a full lesson. A relevant wiki or documentation link can follow when available.

## Explanation guidance

### Essential

Explain the distinction first: Grimdex is the base coding harness; Learn adds educational verbosity and pass-through to documentation.

Keep the explanation to what, why, and a little how. Link out rather than exhaust the topic.

### Experienced-user note

Do not treat Learn as a separate education edition of the engine. Its defined scope is the two behaviors above, not course delivery or classroom installation.

### Optional deeper context

The wiki is a separate destination for deeper learning, not a dependency of Learn. When no wiki is present, official documentation can serve as the direct destination. When no suitable destination is available, Learn must still function without an onward link.

## Cautions and common failures

- **Confusing Learn with course content:** a separate class wiki project covers course content. Grimdex-edu does not deliver it.
- **Requiring a wiki:** missing wiki content must not block Learn or be treated as an error.
- **Explaining too much in place:** Learn stops at essentials, then points outward for depth.
- **Inventing a command or activation marker:** this concept has no special command or specified response marker.
- **Treating a reserved path as a created feature:** in the four-owner path contract (`base/learn/course/student`), `course/` is reserved and unpopulated. Nothing in Grimdex-edu creates it.
- **Assuming classroom or grading features:** those are not part of Learn's two defined functions.

## Related capabilities

This introductory capability, `what-is-grimdex`, establishes how to interpret Learn's explanations and onward documentation pointers. The other `grimdex-harness` lessons (how Learn's verbosity shows up in responses, the student-zone layout, and install/bootstrap) build on it directly.

## Official sources

- <https://github.com/Ryfter/Grimdex> — public, open-source Grimdex engine repository, licensed under MIT.
- <https://github.com/Ryfter/grimdex-learn> — public release snapshot repository for the Learn module, licensed under MIT.

## Provenance

Drafted 2026-09-18 by the `unbiased/pareto` model (via Baton's `openrouter-pareto` fleet row) against this product's own locked decision record — D41 (`docs/2026-08-03-d41-what-grimdex-edu-is.md`) and D36 (the three-layer ladder) — rather than an external vendor doc, since this page describes Grimdex-edu's own identity. Fact-checked against D41/D36 and against `CLAUDE.md`'s "What this is" section before shipping; no context7_library applies here for the same reason. This page follows the capability page structure used by the other Learn modules.

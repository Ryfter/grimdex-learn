---
title: How the Learn module changes responses
module_id: grimdex-harness
capabilities:
  - learn-module-verbosity
context7_library:
context7_queries:
official_sources:
  - https://github.com/Ryfter/Grimdex
  - https://github.com/Ryfter/grimdex-learn
last_checked: 2026-09-20
last_material_update: 2026-09-20
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

When the Learn module is installed, the answers you get while working change in two ways. Both are visible in the moment — you don't have to configure anything to see them.

1. **More verbose answers.** Where the base Grimdex harness gives short, minimal replies, the Learn module gives more explanatory ones — enough to teach as you work, not just to unblock you.
2. **Pass-through to the wiki.** When you want more than the essentials, Learn hands you off to the wiki. If no wiki page exists for a topic, it hands you to the official documentation instead. A missing wiki is normal, not an error — the module degrades gracefully.

These are the module's only two functions. Everything else about the harness works the same.

## When it is useful

- You are learning while working and want answers that explain the *why*, not just the command to paste.
- You want a pointer to deeper material when a topic deserves more than a paragraph.
- You are reviewing what the module does and want to know exactly what changed versus stock Grimdex: response depth and link-outs. Nothing else.

## Prerequisites

- The Learn module installed (see the install lesson for this module).
- A Grimdex install on disk — Learn composes onto an existing install; it does not provide one.

## Current syntax

There are no new commands for this capability. Verbosity and pass-through are behavior, not syntax: after installation, responses are simply longer and include link-outs where deeper material exists.

## What happens (local and remote)

Locally, the module's verbosity setting sits in place while you work. When a response touches a topic with wiki coverage, the response includes a link to that wiki page (which itself links onward to official documentation). When no wiki page exists, the link-out goes straight to the official docs. Either way, the response stops at essentials — what, why, and a little how — and hands off rather than exhausting the topic.

Nothing in this behavior requires a network connection beyond fetching the linked pages, and no course content is delivered. Course content is out of scope for this module.

## Practical example

You ask the harness about a Git concept while working on a project. Without Learn, you get a one-line answer. With Learn installed, the same question gets a short explanation plus a link: "This is covered in more depth in the wiki" — or, if that topic has no wiki page, a link to the official Git documentation instead. Either is expected and correct.

## Explanation guidance

### Essential

- Learn makes responses more verbose and adds pass-through to deeper material. Two functions, nothing else.
- Learn must function 100% without the wiki. If there's no wiki page, it links to official docs. A missing wiki is not a failure.

### Experienced-user note

- Depth is deliberately capped. Learn answers stop at what/why plus a little how, then link out. If you find yourself wanting the full picture, that's the pass-through doing its job — follow the link.

### Optional deeper context

- The ladder is: base Grimdex (shortest answers) → Learn (essentials, in place while you work) → wiki (deeper) → official docs (real expertise). Learn is a middle layer, not a destination.

## Cautions and common failures

- Expecting course content: this module is not a course delivery system, classroom install, or "education edition." It only changes response depth and routes to deeper material.
- Treating a missing wiki link as an error: it isn't. Handing off to official docs directly is the designed fallback.
- Expecting new commands: verbosity is behavioral, not invoked via any new syntax.

## Related capabilities

- what-is-grimdex — the already-shipped page explaining what Learn is and how it fits the harness.
- install-and-bootstrap — how the module gets installed in the first place.
- student-zone-layout — where the module's files live on disk.

## Official sources

- https://github.com/Ryfter/Grimdex — the public Grimdex engine repository.
- https://github.com/Ryfter/grimdex-learn — the public release repository for the Learn module.

## Provenance

This page was authored against this product's own locked decision records — specifically D41 (what Grimdex-edu is: the two functions, pass-through and verbosity) and D36 (the three-layer depth ladder and the rule that Learn stops at essentials and links out) — not against an external vendor doc. It should be fact-checked against those records before shipping.

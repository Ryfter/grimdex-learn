---
title: Clear and direct instructions
module_id: prompt-engineering
capabilities:
  - clear-and-direct-instructions
context7_library: /websites/platform_claude_en
context7_queries:
  - prompt engineering overview success criteria test empirically first draft prompt
  - prompting best practices be clear and direct state desired output
  - give reason behind instruction context improves compliance ellipses text-to-speech
  - scope constraints reduce over-engineering features docs defensive code abstractions
  - never use ellipses versus response read aloud text-to-speech engine
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
last_checked: 2026-08-02
last_material_update: 2026-08-02
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

Clear and direct instructions mean you **state the outcome you want** instead of
hoping the model infers it. Official prompting guidance emphasizes being explicit
about the desired output, giving the **reason** behind a rule when it matters,
and constraining scope so the assistant does not invent extra work.

Before iterating on clever prompt wording, platform docs put three prerequisites
first: a clear definition of **success criteria**, a way to **test empirically**
against them, and a **first draft** prompt. Prompt engineering is then the cycle
of changing the draft and checking whether those criteria improve — not wordcraft
for its own sake.

## When it is useful

Use this whenever you ask a coding agent to change code, write a summary, or
follow a house rule. It is especially valuable for:

- Rules that look arbitrary without a reason (style bans, format limits).
- Tasks where "help with X" is too open and invites large, unrequested refactors.
- Work you will judge with a concrete check (tests pass, only these files change,
  output is a bullet list of three items).

## Prerequisites

- You can name what "done" looks like in one or two sentences (even if imperfect).
- You have some way to check the result later — a command, a file review, or a
  short acceptance list (see verifying agent work).
- You understand that the model only reliably follows what is present in the
  current context (see context and working memory).

## Current syntax

Copyable instruction block that states outcome, reason, and scope:

```
Task: Add input validation for the email field on the signup form.

Success criteria:
- Empty or malformed email shows an inline error and does not submit
- Existing valid-email path still works
- No new dependencies

Scope constraints:
- Change only the signup form component and its existing tests
- Do not add features, docs, defensive abstractions, or refactors beyond this

Why the scope limit:
- We are fixing one validation gap before a release cut; extra surface area
  delays review

Output:
- Implement the change
- List the files you touched
- Show how to run the relevant tests
```

Bare prohibitions work less well than the same rule with a reason. Documented
pattern: "NEVER use ellipses" is weaker than explaining that the response will be
read aloud by a text-to-speech engine that will not know how to pronounce them.

## What happens (local and remote)

**Locally**, writing a clear prompt does not change your repository by itself.
You are shaping the request. If the assistant is chat-only, results appear as
text you must apply. If it is an agent with tools, a clear request still becomes
local file and command effects only after tools run (see tools and agent actions).

**Remotely**, the full instruction text — including any code snippets, error
logs, and secrets you paste — is sent to the model provider as part of the
request. Clarity does not make sensitive material safe; it only makes the task
easier to follow. Prefer redacted examples and local paths that do not embed
credentials.

Clear success criteria also define what you will check after the response
returns. Without them, neither you nor the model has a stable target, and
"sounds right" becomes the only metric.

## Practical example

Vague request:

```
Can you improve the retry logic?
```

Direct request with reason and scope:

```
Improve retry logic in src/net/client.ts only.

Success criteria:
- Retries at most 3 times on HTTP 429 and 503
- Uses exponential backoff starting at 200ms
- Existing unit tests in client.test.ts pass; add tests for the new limits

Why:
- Production logs show stampeding retries that amplify outages

Do not:
- Rewrite the HTTP stack
- Add a new retry library
- Change unrelated modules
```

The second form states the outcome, the test surface, and what not to build.
Official best-practice guidance treats scope constraints as a way to reduce
over-engineering: extra features, docs, defensive code, and abstractions that
were not asked for.

## Explanation guidance

### Essential

Say the result you want. Define how you will know it worked before you iterate
on wording. Give reasons for sharp rules. Limit scope so the assistant does not
"help" by expanding the job. Prefer a plain first draft you can test over a
perfect prompt you never evaluate.

### Experienced-user note

Keep a short personal template: goal, success criteria, in-scope paths, out-of-
scope list, and "why" for non-obvious constraints. Reuse it so every agent turn
starts complete. When quality stalls, change one instruction variable at a time
and re-check the same criteria — that is the empirical loop the overview docs
describe.

### Optional deeper context

Different products layer system prompts and tool policies under your message.
Your job is still to make the user-visible task unambiguous. Cross-tool practice
is the same even when the cited examples come from one vendor's docs: clarity,
reasons, and scope travel; marketing feature names do not need to.

## Cautions and common failures

- **Implied outcomes.** "Make it better" invites large, unreviewable diffs.
- **Rules without reasons.** Arbitrary bans are easier to ignore or misapply;
  a short why improves compliance in documented prompting guidance.
- **No success criteria.** You cannot tell whether a prompt change helped.
- **Missing scope bounds.** Assistants often over-build (extra files, frameworks,
  defensive layers) unless told not to.
- **Secrets in the clear prompt.** Credentials in the instruction text leave the
  machine with the request.

## Related capabilities

- Context and working memory — restating constraints so they stay in the working
  set.
- Tools and agent actions — clear scope matters more when tools can edit the
  tree and run commands.
- Verifying agent work — empirical checks against the success criteria you
  defined here.

## Official sources

- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview>
  — success criteria, empirical testing, and a first draft before deeper prompt
  work.
- <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>
  — be clear and direct; give reasons; constrain scope to reduce over-engineering.

## Provenance

Authored 2026-08-02 against the official Anthropic platform documentation cited
above, retrieved via Context7 (`/websites/platform_claude_en`) and aligned with
the verified source notes in the module authoring brief. This page follows the
capability page structure for the `prompt-engineering` module; the module-level
provenance policy and source registry live in `../provenance.md` and
`../source-registry.md`. Instruction clarity is cross-tool craft anchored on
these docs, not a single-product tutorial.

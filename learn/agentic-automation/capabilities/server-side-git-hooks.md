---
title: Server-side git hooks
module_id: agentic-automation
capabilities:
  - server-side-git-hooks
context7_library: /websites/git-scm
context7_queries:
  - "Why can a git push be rejected by the remote even though the local commit succeeded?"
  - "What are pre-receive and update hooks in git and when do they run?"
  - "How do server-side hooks differ from client-side hooks like pre-commit?"
official_sources:
  - https://git-scm.com/docs/githooks
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

Server-side git hooks are scripts that run **on the remote server** when a push arrives. The documented hooks include `pre-receive` and `update` (per git-scm.com/docs/githooks). Unlike client-side hooks such as `pre-commit`, which run on your machine during a local operation, server-side hooks run after the client has finished committing locally but before the server accepts the pushed refs.

The key consequence: a `pre-receive` or `update` hook can reject the push. This explains a situation that confuses many beginners — your local `git commit` succeeded, your local history looks fine, and yet `git push` fails with a rejection from the remote. The remote, not you, made that decision, via a hook script running server-side.

## When it is useful

- Understanding (and debugging) push rejections that happen even though local commits succeeded — e.g. pushes blocked by branch protection, file-size checks, or commit-message policy enforced on the server.
- Designing team guardrails that cannot be bypassed by a client simply skipping or disabling local hooks — server-side enforcement applies to everyone pushing, regardless of what their local setup does.
- When an AI coding agent is pushing commits autonomously: a server-side hook is a remote guardrail that runs even for unattended pushes, complementing client-side checks that a misconfigured agent environment might not run at all.

## Prerequisites

- Basic `git commit` and `git push` fluency, and familiarity with client-side hooks (`pre-commit`, `commit-msg`) is helpful context.
- Awareness that hooks are plain scripts the server executes; you do not need to be the server administrator to *encounter* server-side hooks, but you do need administrator access to *install or modify* them.
- Context that hooks are not version-controlled by default — they live in `.git/hooks` on the relevant machine (client or server) and are machine-local. `core.hooksPath` and the pre-commit framework are documented ways teams make hooks shareable, and this applies to how hook setup is managed generally.

## Current syntax

There is no "syntax" you type at the command line to trigger these hooks — they are script filenames placed in the server repository's hooks directory (`hooks/` inside the bare repository, i.e. `.git/hooks` on non-bare repos). Per git-scm.com/docs/githooks:

- `pre-receive` — runs once for the entire push, before any ref is updated. A non-zero exit rejects all refs in the push.
- `update` — runs once **per ref** being pushed, with the ref name, old revision, and new revision as arguments. A non-zero exit rejects that one ref.

Note that client-side hooks and this hooks directory are the same documented mechanism at different sites: `pre-commit`/`commit-msg` run client-side; `pre-receive`/`update` run server-side. All are documented at git-scm.com/docs/githooks.

## What happens (local and remote)

1. You (or an agent) run `git commit` locally. Client-side hooks (`pre-commit`, `commit-msg`) may run here; if a client hook fails, the commit is aborted locally and nothing is sent anywhere.
2. The commit succeeds locally. Your local history is updated. Nothing has touched the server yet.
3. You run `git push`. The remote server receives the push.
4. The server runs its `pre-receive` hook (once, for the whole push), then `update` (once per ref).
5. If either hook exits non-zero, the **server rejects the push**. Your local commits still exist and are fine — they just were not accepted by the remote. The remote's ref history is unchanged.
6. If the hooks pass, the server updates the refs and the push completes.

The critical mental model: **local commit success and remote acceptance are two separate events**, separated by a network hop and by whatever server-side policy runs at that hop.

## Practical example

A team wants to block pushes that contain commits with placeholder messages. On the server, an administrator installs an `update` hook that inspects each pushed commit's message and exits non-zero if it matches a banned pattern.

An unattended AI coding agent, running in headless mode, creates a commit locally with a placeholder message and pushes. Locally, no `pre-commit` hook is installed (or it was never set up on that machine), so the commit succeeds. The push then arrives at the server, the `update` hook examines the new revision, exits non-zero, and the remote rejects that ref. The agent's push fails — and importantly, the guardrail worked even though the client-side setup did not enforce it. The team fixes the agent's workflow or tightens its instructions, and the server-side hook remains the enforcement point of last resort.

## Explanation guidance

### Essential

- "Server-side" means the script runs on the machine hosting the remote repository, not on your laptop.
- `pre-receive` sees the whole push and can reject all of it; `update` sees one ref at a time and can reject just that ref.
- The rejection message you see during `git push` failure comes from the server. Your local commit did not "half-happen" — it fully happened locally; only the *propagation* to the remote was refused.
- This is the documented reason a push can fail when the local commit succeeded (git-scm.com/docs/githooks).

### Experienced-user note

- Because `update` runs per-ref with old/new revision arguments, it is the natural place for per-branch policy (e.g. allow fast-forwards only to certain branches), while `pre-receive` suits whole-push checks.
- Server-side hooks give you enforcement that client-side hooks cannot: a `pre-commit` hook is only as reliable as every clone's local `.git/hooks` directory, and hooks are not version-controlled by default. Server-side policy applies to every pusher uniformly.
- If you also use an agent lifecycle hooks system (e.g. Claude Code's documented PreToolUse/PostToolUse/Stop hooks), keep the two vocabularies distinct: git hooks fire around git operations; agent hooks fire around agent actions. They are separate, documented mechanisms in separate documentation sets.

### Optional deeper context

- Client-side hooks are machine-local and unversioned by default; `core.hooksPath` and the pre-commit framework (pre-commit.com) are documented approaches to making hook setups shareable and reproducible across a team. Server-side hooks have the analogous operational concern — they must be installed and maintained on the server.
- A team running semi-autonomous agents often layers guardrails: client-side git hooks and agent lifecycle hooks as early feedback, server-side git hooks as remote enforcement, and (for CI-triggered work) separate controls again. Each layer is documented for its own tool; the layering itself is general practice, not a vendor feature.

## Cautions and common failures

- **Confusing "commit succeeded" with "push succeeded."** They are separate events. A rejected push is not data loss — your local commits are intact; retry after addressing the server's policy.
- **Reading the rejection as a git bug.** It is the documented behavior of `pre-receive`/`update` hooks. Look for the hook's output in the push output for the actual reason.
- **Assuming local hooks ran.** Hooks are not version-controlled by default and live in `.git/hooks` per machine. A fresh clone, a new agent environment, or an unattended runner may not have the same client-side hooks you do — which is precisely the gap server-side hooks close.
- **Assuming platform-level branch protection is the same thing as git hooks.** Hosted platforms enforce policy through their own mechanisms; `pre-receive`/`update` are the documented raw git hooks. Both can reject pushes, but they are configured in different places by different people. Do not conflate them when debugging.
- **Cross-tool parity is unverified.** If a lesson or discussion compares how specific agent tools (e.g. Cursor, Codex-CLI) interact with server-side hooks or offer equivalent lifecycle-hook systems to Claude Code's, that parity has not been verified — scope such claims to the tool's actual documentation or flag them as unverified.

## Related capabilities

- Client-side git hooks (`pre-commit`, `commit-msg`) and sharing them via `core.hooksPath` / the pre-commit framework.
- Agent lifecycle hooks (e.g. Claude Code's PreToolUse/PostToolUse/Stop, documented at code.claude.com) as a distinct hook mechanism for guardrails on agent actions.
- Permission modes and human approval gates for unattended agent runs.
- GitHub environment protection rules with required reviewers (documented GitHub feature) as remote-side approval guardrails.

## Official sources

- https://git-scm.com/docs/githooks — git hooks documentation, including `pre-receive` and `update`
- https://git-scm.com/docs/githooks — hooks directory location and client-side/server-side distinction

## Provenance

- Grounded in this session's fleet/Context7 research for the agentic-automation module, anchored to git-scm.com/docs/githooks.
- Claims are scoped to git's documented hook behavior. No claims are made about Cursor or Codex-CLI hook or scheduling feature parity, per the module's explicit caution.
- Provenance class: practice-guidance-with-official-anchors.
# Update log — git-and-github

Chronological, newest first. Entries state before/after facts in complete sentences.

## 2026-09-26 — claims baseline extended

Normalized claims were added to `claims/baseline.yaml` for every page that had none.
They were extracted by a non-Claude model from the fact-checked pages and mechanically
checked (cited source, wording grounded in the page); each is marked
`verification: page-restatement` until a refresh pass confirms it against its source.

## 2026-08-01 — full capability page set authored

The module previously contained only the golden page; it now contains all fourteen
capability pages (thirteen new: overview, setup/configuration/authentication,
creating/cloning, working-tree/staging/status, branches/switching,
remotes/fetch/pull, push/upstream, pull-requests/review,
merge-commit/squash/rebase, merge-conflicts, post-merge cleanup,
undoing/recovering, glossary). Method: Grok-drafted against official sources,
conformance-checked by `Test-CapabilityPageContract`, Claude fact-checked before
commit. `claims/baseline.yaml` grew from 7 entries to 107.

## 2026-08-01 — module created

Module scaffold and manifest created; first golden capability page
(`commits-and-history.md`) authored manually against official Git documentation as the
D32 conformance shakedown.

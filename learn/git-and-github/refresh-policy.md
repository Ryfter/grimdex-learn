# Refresh policy — git-and-github

**Status: designed, not built.** The golden module is produced and refreshed manually
until the pipeline shakedown completes; automation never precedes the manual golden
module.

Designed monthly sequence (for the future pipeline): read pages → run stored Context7
queries → extract normalized claims → compare to `claims/baseline.yaml` → classify
material / non-material / ambiguous → apply high-confidence material changes, skip
non-material, flag ambiguous for human review → update page metadata and registry →
append to `update-log.md`.

Fail-safe rules: a failed query never erases known-good content; pages are never
auto-deleted; third-party sources are never substituted for official ones; ambiguous
changes are never guessed.

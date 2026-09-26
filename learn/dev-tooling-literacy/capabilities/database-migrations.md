---
title: "Database migrations: changes to stored structure"
module_id: dev-tooling-literacy
capabilities:
  - database-migrations
context7_library:
context7_queries:
official_sources:
  - https://prisma.io/docs/orm/prisma-migrate/understanding-prisma-migrate/overview
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

A **database migration** is a managed change to the structure of stored data — adding a field, renaming a column, creating or removing a table, changing how records relate to each other. It is different from editing an application file: application files are copies you can regenerate or discard, while a database holds **persistent** data that accumulates real records over time.

A migration tool (such as Prisma Migrate, which is one well-known example) records these structural changes as ordered, named steps. Each migration represents a change applied to the database, and the tool keeps track of which migrations have already been applied so they aren't run twice.

For a beginner collaborating with an AI agent, the key recognition point is: when an agent proposes or runs a migration, it is proposing to **alter the persistent structure of stored data** — not merely to change text in the project.

## When it is useful

- An agent proposes a "migration" as part of adding a feature — recognizing this tells you the change will reach beyond the code into the data store.
- You see new files appear in the project that look like ordered, named change records — recognizing them as migrations explains why an "edit" touched several files.
- You are asked to approve running something against a database — recognizing migrations helps you ask what structure will change and whether any existing data could be affected.
- The application behaves differently after a database-related step — recognizing that structure and code are two separately managed layers helps narrow down where the change happened.

## Prerequisites

- Recognition-level familiarity with **databases and connection strings** (which database is being used, and that connection settings can point at real data).
- Recognition of **config file formats** (many migration tools define structure in a schema file, often in a recognizable format).
- Awareness of the **install / build / run** distinction, since applying migrations is typically its own step, separate from starting the app.

## Current syntax

Recognition level only — there is no syntax to learn here. What a reader should be able to recognize:

- A **schema or model description file** maintained by the migration tool, describing the intended structure (tables, fields, relationships).
- **Generated migration files**, usually named or numbered in sequence, each representing one recorded change.
- An **applied-migrations record** kept by the tool (often in the database itself) noting which steps have already run.

## What happens (local and remote)

- **Locally:** the agent edits the schema description, generates a migration file, and may run a command that applies the change to a database the project connects to. If that database is a local development database, the blast radius is usually small — but it is still persistent data, not a throwaway file.
- **Remotely:** the same mechanism can target a shared or production database. Structural changes there can affect real data and other users, and undoing them may require a *reverse* migration that itself may not perfectly restore what was lost.
- The agent's wording may not distinguish these cases. "Update the database" could mean a harmless local step or a significant change to shared data — the connection string and environment (see the .env and environment-variables lessons) are the clues.

## Practical example

An annotated, recognition-level example of what this can look like in a project:

```
prisma/
  schema.prisma                 ← the schema description: intended structure
  migrations/
    20260920143000_add_status/  ← one generated migration, timestamp-named
      migration.sql             ← the recorded change for this step
    migration_lock.toml         ← which database provider the migrations target
```

If an agent says it will "add a status field and run the migration," a reader can now recognize:

- the schema file will change (the *intended* structure),
- a new timestamped migration folder will appear (the *recorded* change),
- a database somewhere will actually be altered when the migration is applied (the *real effect*).

That third bullet is the one with consequences beyond editing application files.

## Explanation guidance

### Essential

- A migration changes the **structure** that data lives in, not just the application code.
- Migrations are **recorded and ordered steps**, kept track of so they can be applied consistently.
- Applying a migration affects **persistent data** — unlike code edits, some changes are hard to reverse and some data may not come back.
- Ask which **database** is being targeted (local? shared? production?) before a migration is run.

### Experienced-user note

- The schema file describes *intent*; the migration files record *what was actually applied*. Divergence between the two is a common source of confusion — an agent that edits the schema without generating/applying a migration has changed intent but not reality.
- "Roll back" is itself a managed operation, not an undo button: depending on the change, a reverse migration may not fully restore prior data.
- Teams often review migrations more carefully than ordinary code changes precisely because of the persistence and reversibility issues.

### Optional deeper context

- Migration tools differ in approach: some generate SQL from a schema description (declarative), others record hand-written change steps (change-based). Recognizing that the *style* varies helps you read different projects without assuming one universal convention.
- Migration history interacting with branching workflows (two branches generating conflicting migrations) is a classic team friction point — worth knowing exists, not needed at this depth.

## Cautions and common failures

- **Approving "apply migration" against production or shared data** without checking the target. The connection string in the environment is the ground truth, not the agent's description.
- **Assuming migrations are reversible.** Removing a column is quick to apply and permanently discards the data in it.
- **Confusing schema edits with applied changes.** Editing the schema description alone does not change the database until the migration is generated and applied.
- **Migration fails midway** — some databases apply migrations in transactions, others don't; a partially applied state can be confusing. Treat a failed migration as a state worth investigating, not a message to dismiss.
- **Treating migration files as throwaway.** Deleting or regenerating them can desynchronize what the tool thinks has been applied.

## Related capabilities

- database-connections — recognizing which database is being connected to and what connection strings contain
- env-files-and-secrets — where connection settings and credentials typically live
- dependencies-and-package-managers — migration tools are themselves project dependencies
- install-build-run — applying migrations is a distinct step, separate from running the app
- reproducing-a-bug — establishing repeatable state matters when data structure has changed

## Official sources

- Prisma docs, "Migrate overview": https://prisma.io/docs/orm/prisma-migrate/understanding-prisma-migrate/overview

## Provenance

- Module: dev-tooling-literacy (cross-language, cross-tool workflow/tooling recognition; recognition-level depth only).
- Topic anchored to the Prisma Migrate documentation, as cited in the module's verified grounding facts from this session's research.
- context7_library and context7_queries are intentionally empty for this module: the topics span many vendor doc sets (Prisma, PostgreSQL, npm, GNU, MDN, OWASP, Docker, SPDX) that do not map to a single indexed library in this product's Context7 setup; official source URLs are relied upon instead. This is a deliberate, correct choice for this module, not a gap.
- Not programming-language fundamentals: this page teaches recognition of migrations as a workflow concept, not how to write schema definitions or migration code.
- last_checked / last_material_update: 2026-09-20; status: current; version_stamp: fall-2026-0.1.0.
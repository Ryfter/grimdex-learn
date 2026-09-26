---
title: Repository access roles and permissions
module_id: git-and-github
capabilities:
  - repository-access-roles
context7_library: /websites/github_en
context7_queries:
  - What are the repository access roles for an organization on GitHub?
  - What is the difference between the Read, Triage, Write, Maintain, and Admin roles?
  - Can an organization define custom repository roles with granular permissions?
official_sources:
  - https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization
  - https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/about-custom-repository-roles
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

For a repository owned by a GitHub organization, each person is assigned one of a
ladder of access roles, from least to most access: Read, Triage, Write, Maintain,
and Admin. The role determines what that person can do in that repository --
view and discuss, manage issues and pull requests, push code, manage repository
settings, or fully administer it. Organizations can also define custom roles that
build on one of these base roles with additional granular permissions.

## When it is useful

Any time a repository belongs to an organization and more than one person needs
access, someone has to decide who can do what. The role ladder is how you grant
just enough access: an outside consultant can view without pushing, a project
manager can triage issues without touching code, a contractor can push to feature
branches without administering settings, and only a few trusted people hold full
Admin. It is also relevant when auditing who currently has access to a repository
and why.

## Prerequisites

- A GitHub organization-owned repository (personal repositories do not use this
  role ladder).
- Organization admin (or repository Admin) access to view and change role
  assignments.
- No installation needed -- roles are managed in the GitHub web UI.

## Current syntax

There is no command-line syntax for this capability; it is configuration in the
GitHub UI under the repository's Settings, in the Collaborators and teams section,
or at the organization level via teams. The five built-in roles, least to most
access:

| Role | Fits |
| --- | --- |
| Read | People who need to view code and participate in discussions (issues, PRs) but not change anything. |
| Triage | People who manage the day-to-day flow of issues and pull requests -- labeling, assigning, closing, merging? no, applying labels/assignments and managing discussions -- without write access to the code. |
| Write | Regular contributors who push commits and branches. |
| Maintain | People who manage the repository (settings that are not sensitive or destructive) without full admin power. |
| Admin | Owners of the repository who need full control, including sensitive and destructive actions. |

## What happens (local and remote)

Nothing happens locally. Role assignment is entirely on the GitHub side: when a
member's role is set, GitHub enforces it on every interaction with the
repository -- viewing, opening issues, pushing, merging, and changing settings.
A Read-level user who attempts a push, or a Write-level user who attempts to
delete the repository, gets the action denied by GitHub regardless of what their
local git setup looks like.

## Practical example

An organization repository `webapp` is set up like this:

- The whole engineering team is granted **Write** via a GitHub team, so everyone
  can push branches and open pull requests.
- A product manager is granted **Triage**, so she can label, assign, and close
  issues and manage the PR queue without any ability to push code.
- An external security auditor is granted **Read**, so he can browse the code and
  comment on issues but cannot change anything.
- A team lead is granted **Maintain**, so she can manage branch settings and
  repository housekeeping but cannot perform destructive actions like deleting
  the repository.
- Two staff engineers hold **Admin** for full control, including settings that
  affect repository existence and access.

Later, the organization notices triage users repeatedly need one extra granular
ability. Instead of promoting them to Write, the organization creates a **custom
organization role** based on the Triage base role plus that one additional
granular permission, and assigns it to the triage users.

## Explanation guidance

### Essential

The five roles form a ladder from "look only" to "full control." Read can view
and discuss. Triage adds management of issues, pull requests, and discussions,
but no code write access. Write adds pushing code. Maintain adds managing the
repository short of sensitive or destructive actions. Admin is everything,
including destructive actions. Custom organization roles let you start from a
base role and add specific granular permissions rather than jumping a whole
rung.

### Experienced-user note

Role assignment composes with teams: granting a role to an organization team
gives that role to all its members, which is usually how access should be managed
at scale rather than per-person grants. Also note that repository roles govern
what a person can do inside one repository; organization-level membership and
organization roles are a separate layer on top of this.

### Optional deeper context

Custom roles are built from a base role (Read, Triage, Write, or Maintain) plus
selected granular permissions, so they sit conceptually between rungs of the
built-in ladder. When auditing access, the useful question per repository is not
just "who has a role" but "which role and via which team," since effective access
is the union of everything granted.

## Cautions and common failures

- Granting Admin by default "so nobody is blocked" removes the safety the ladder
  provides; sensitive and destructive actions then sit with everyone.
- Confusing Triage with Write: Triage users can manage issues and PRs but cannot
  push code, and Write users can push code but do not get Triage's issue/PR
  management powers automatically beyond their own PRs.
- Assuming personal repositories follow the same ladder -- the five-role ladder
  applies to organization repositories; personal repos have a simpler
  collaborator model.
- Forgetting that access can come from multiple teams; removing one team grant
  may not remove access if another team still grants it.
- Building a custom role by starting from Admin is not the model -- custom roles
  build on a non-Admin base role plus granular permissions.

## Related capabilities

- branch-protection-rulesets
- codeowners
- forks-create-sync-contribute
- secret-scanning-push-protection

## Official sources

- https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization -- GitHub docs, "Repository roles for an organization": the Read/Triage/Write/Maintain/Admin ladder.
- https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/about-custom-repository-roles -- GitHub docs, "About custom repository roles": custom roles built from a base role plus granular permissions.

## Provenance

This page was authored against GitHub's official documentation -- specifically
"Repository roles for an organization" and "About custom repository roles" on
docs.github.com -- retrieved via Context7. It should be spot-checked against
current docs before shipping, since GitHub reorganizes doc paths periodically.
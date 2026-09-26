---
title: Containers, sandboxes, and isolation boundaries
module_id: dev-tooling-literacy
capabilities:
  - containers-and-sandboxes
context7_library:
context7_queries:
official_sources:
  - https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/
  - https://docs.docker.com/engine/security/
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

A container is a way of running software in an isolated environment: the application gets its own filesystem, its own view of the system, and its own dependencies, separate from the host machine's defaults. The word "sandbox" is used loosely for any setup that seems to fence software in -- a Python virtual environment, a browser's sandbox, a container, or a labeled "sandbox mode" in a tool.

The key recognition point: **isolation is a spectrum, not a guarantee.** A virtual environment isolates only project dependencies. A container isolates more -- but it can still read and write files you mount into it, and reach networks you allow it to reach. A "sandbox" label on an AI agent's activity does not, by itself, tell you what that activity can actually access. What matters is what is explicitly connected to the isolated environment: mounted folders, ports, credentials, and network access.

## When it is useful

Recognition-level understanding of containers and sandboxes helps when:

- An AI coding agent proposes to "run this in a container" or "use a sandboxed environment," and you want to know what that does and does not protect.
- You are reviewing an agent's proposed actions and want to ask a grounded question: what files, networks, or credentials will this isolated environment have access to?
- You see `Dockerfile` or `docker-compose` files in a project and want to recognize what they describe without needing to operate Docker yourself.
- Someone on the team says the app "runs in a container, so it's safe to let the agent experiment" -- and you want to know which parts of that statement are justified.

## Prerequisites

- The terminal/commands lesson from this module (recognizing what a command invocation is).
- The environment variables and .env files lessons (credentials flowing into an environment).
- No hands-on Docker experience required. This page is recognition, not operation.

## Current syntax

There is no syntax to learn on this page. You only need to recognize, in an agent's output or a project's files, vocabulary that signals isolation is in play:

- **Virtual environment** -- project-scoped dependency isolation only (see the virtual environments lesson in this module).
- **Container** -- an application packaged with its runtime and dependencies, run in an isolated environment on a host machine.
- **Sandbox** -- a generic label; ask what it actually restricts rather than trusting the word.
- **Volume / mount** -- a folder from your real machine connected into the container; the container can read and write it.
- **Port mapping** -- a service inside the container exposed to your machine (see the localhost/ports lesson).

## What happens (local and remote)

When an agent works inside an isolated environment:

- **Locally:** the agent may create or start a container on your machine. The container's internal filesystem is separate, but anything the agent mounts into it -- often the project folder itself -- is real and changeable. Ports the agent publishes make services inside the container reachable from your machine.
- **Remotely:** cloud or hosted execution environments may also be called "sandboxes" or "containers." These usually reduce blast radius, but the same question applies: what was connected in? If the environment has API keys, mounted code, or network access, agent mistakes -- or a malicious dependency the agent installs -- can still reach those things.
- **Nothing about isolation is automatic safety.** An isolated environment with your project folder mounted, your `.env` file present, and open network access is fenced in name only.

## Practical example

An annotated snippet of the kind you might see when an agent describes containerized work (recognition only -- do not build this):

```
docker run ...                    ← starts a container
  -v ./my-project:/app            ← mounts your real project folder INTO the
                                     container; changes there are real
  -p 3000:3000                    ← exposes the app on your machine at
                                     localhost:3000 (see localhost/ports lesson)
  --env-file .env                 ← loads your credentials into the container
  ...                             ← plus network access unless explicitly
                                     restricted
```

What to recognize: the container is isolated, but three explicit connections have been made into it -- your project files, a network-reachable port, and your secrets. Each is a legitimate, common choice. Each is also a boundary the agent's activity can cross. "It ran in a container" is the start of a safety question, not the end of one.

## Explanation guidance

### Essential

- A container is an isolated environment for running software; a virtual environment isolates only project dependencies; "sandbox" is a loose label, not a defined guarantee.
- Isolation is defined by what is connected in: mounted files, exposed ports, injected credentials, network access.
- "Isolated" and "safe" are not synonyms. Ask what the environment can reach, not what it is called.

### Experienced-user note

- Docker's own security documentation treats container isolation as a shared-responsibility topic: containers on a default Linux setup do not provide a hard security boundary equivalent to a full virtual machine, and configuration choices (mounts, capabilities, network) determine real exposure. When an agent proposes container-based execution, the meaningful review questions are: what is mounted, what secrets are present, and what can the network reach?
- Teams that routinely grant agents broad container access often distinguish two cases: disposable environments with no mounted secrets (low stakes) versus environments connected to real credentials or production-adjacent data (review each connection).

### Optional deeper context

- Containers vs. virtual machines: both provide isolation, but with different strength and overhead characteristics; Docker's "What is a container?" documentation explains the basic concept and how containers share the host's kernel.
- If you later need to actually configure container isolation (resource limits, network policies, user permissions), that is an operations skill beyond this module's recognition scope -- start from Docker's security documentation rather than agent-generated configurations.

## Cautions and common failures

- **Trusting the label.** "Sandboxed" is marketing shorthand unless you know what it restricts. Ask: which files, which network, which credentials?
- **Mounting without thinking.** Agents commonly mount the whole project directory into containers -- convenient, but it makes everything in that directory (including `.env` files) accessible to anything running inside.
- **Secrets in the container.** Passing credentials into an isolated environment is normal practice, but it means the isolation does not protect those credentials from software running inside. Keep this consistent with the .env/secrets lesson.
- **Assuming containment of network activity.** Unless networking is explicitly restricted, code inside a container can typically reach the internet -- so a compromised dependency installed by an agent inside a "sandbox" can still phone home.
- **Confusing isolation with the virtual environment lesson.** A Python virtual environment is far weaker isolation than a container; do not let the words blur together.

## Related capabilities

- environment-variables
- env-files-and-secrets
- virtual-environments
- localhost-ports-exposed-services

## Official sources

- Docker docs, "What is a container?" -- https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/
- Docker Security documentation -- https://docs.docker.com/engine/security/

## Provenance

Grounded in the Docker documentation pages listed above, verified during this session's earlier research. Recognition-level treatment per the dev-tooling-literacy module contract: this page teaches readers to recognize isolation boundaries and ask grounded access questions about agent-proposed container or sandbox activity; it does not teach container operation or security configuration. The "sandbox" framing deliberately covers loose usage across virtual environments, containers, and hosted agent execution environments, per the grounding facts' caution that a label does not automatically make agent activity safe.
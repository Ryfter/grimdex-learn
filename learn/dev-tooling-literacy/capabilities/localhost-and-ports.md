---
title: Localhost, ports, and exposed services
module_id: dev-tooling-literacy
capabilities:
  - localhost-and-ports
context7_library:
context7_queries:
official_sources:
  - https://developer.mozilla.org/en-US/docs/Learn/Common_questions/Web_mechanics/What_is_a_URL
  - https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/
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

When an AI coding agent starts an application for you, that application becomes a *service* running on your machine at a specific *address* and *port*. Recognizing a few patterns helps you find that app and understand who can reach it:

- **localhost** (also written `127.0.0.1`) is a name meaning "this same computer." A service available only at localhost can be reached only from your machine.
- **A port** is a numbered "door" on that computer where a specific service listens. It appears after a colon in an address, as in `http://localhost:3000` — here, `3000` is the port.
- **A URL** ties it together: scheme (`http://` or `https://`), host (`localhost` or a domain), optional port, and a path. This is the address you type into a browser to see the running app.

A service can be bound in different ways:

- **Locally available**: reachable only from your own machine (the typical safe default for a dev server).
- **More broadly exposed**: reachable from other devices on your network, or potentially the wider internet, depending on how the service is bound and any port-forwarding, container publishing, or tunneling in play.

## When it is useful

- An agent says "the dev server is running" — you want to know where to point your browser to actually see it.
- An agent reports a port conflict ("port already in use") and you need a mental picture of why two services can't share the same door.
- An agent proposes running a service "exposed," "published," or "on all interfaces" — you want grounds to pause and ask who, exactly, will be able to connect.
- You are reviewing output or configuration that mentions ports, hosts, or bindings and want to recognize what is being described.

## Prerequisites

- The earlier lessons in this module on the terminal, working directories, and running processes — a dev server is a process, and it runs in a terminal you can observe.
- Familiarity with HTTP requests and responses (covered in this module) helps when you open the app in a browser.
- No networking administration knowledge is assumed. This is recognition-level content.

## Current syntax

There is no command to learn. What you are learning to recognize is address notation:

| Pattern you might see | How to read it |
|---|---|
| `http://localhost:3000` | The app on this machine, at port 3000 — local only by intent |
| `http://127.0.0.1:8080` | Same meaning as localhost, written as a numeric address |
| `http://localhost:5173/preview` | Port 5173, with a path (`/preview`) selecting a page within the app |
| "listening on 0.0.0.0" | The service is accepting connections on **all network interfaces**, i.e., potentially from other machines — worth noticing |
| Container port publishing, e.g. mapping host port 3000 to a container's port | The container's service is made reachable through a port on your machine; how broadly depends on the binding used |

Port numbers are conventions more than guarantees — common dev-server ports (3000, 5000, 5173, 8000, 8080) vary by tool and project. What matters is reading *which port* and *which host* are named.

## What happens (local and remote)

- When an agent starts a server, the server process begins *listening* on a port. Terminal output often says so explicitly ("listening on http://localhost:3000").
- Opening that address in a browser sends an HTTP request to the service; the response is the page or data you see.
- If the address is localhost-only, only your machine can connect. If the service is bound to all interfaces, or a container port is published broadly, other devices may reach it — the label "sandbox" or "container" does not by itself limit that reach.
- Remote deployments follow the same shape: an app "live on the internet" is a service at a public host and port (often hidden behind a domain), reachable by anyone the deployment exposes it to.
- A port can only serve one service at a time; a second service on the same port fails to start, which is a frequent source of "address already in use" messages.

## Practical example

An agent finishes its work and the terminal shows:

```
VITE ready in 412 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.168.1.24:5173/
```

Annotated, line by line:

- **`Local: http://localhost:5173/`** — the app is running on this machine at port 5173. You can open this in your browser to see the app. The `http://` scheme tells you it is plain (unencrypted) HTTP, normal for a local dev server.
- **`Network: http://192.168.1.24:5173/`** — the same app is *also* reachable from other devices on your local network at that address. This is not the public internet, but it is broader than "just me": anyone on the same network (office, café, shared Wi-Fi) could try that address.
- Recognizing the difference is the skill: the `Local:` line answers "where do I look?", and the `Network:` line answers "who else could look?"

Contrast: if the agent had instead proposed "expose port 5173 to the internet" (for example, to share a demo), that is a materially bigger step than the local-only default above — and deserves a deliberate question about who should have access before approving it.

## Explanation guidance

### Essential

- `localhost` means "this computer." A port is a numbered door where one specific service listens.
- You find a running app by opening the address the agent printed — typically `http://localhost:<port>` — in a browser.
- Local availability and broader exposure are different things. Read the host in the address: `localhost` = just you; a machine's network address or an internet-facing host = others can potentially connect.
- "Address already in use" means another service holds that port — a normal, explainable failure, not a mystery.

### Experienced-user note

- A service being in a container or "sandbox" does not automatically confine its reach: container port publishing explicitly decides which host ports map to which container ports, and how broadly they are bound. When an agent configures port publishing or mentions bindings like `0.0.0.0`, treat that as an exposure decision, not a technicality.
- Local dev servers commonly use plain HTTP; do not conclude from `http://localhost` that a *deployed* service lacks encryption — the two contexts differ.

### Optional deeper context

- The URL structure (scheme, host, port, path) is defined in web standards documentation such as MDN's "What is a URL?" — useful if you want to read addresses fluently.
- Docker's documentation on port publishing and mapping explains the mechanics of how containerized services become reachable from a host, and is the reference behind the exposure caution above.

## Cautions and common failures

- **Approving exposure by reflex.** An agent may propose exposing a service beyond localhost to make sharing easier. Pause and ask who should be able to reach it; a locally-available service is the safer default while developing.
- **Assuming "sandbox" means unreachable.** Isolation labels do not by themselves decide network reachability — configuration does.
- **Trusting the wrong URL.** If the browser shows nothing at the printed address, check that you typed the exact host *and* port; a wrong port is the most common reason a running app "isn't there."
- **Reading a `Network:` line as private.** It means other devices on the same network can connect — on shared Wi-Fi, that is a real audience.
- **Treating a local port as publicly meaningful.** Port numbers like 3000 or 5173 are local conventions; they tell you nothing on their own about what a deployed version of the app is exposed to.
- **Reusing a busy port blindly.** If an agent suggests killing an unknown process to free a port, make sure you know what that process is first (see the related lesson on running processes).

## Related capabilities

- running-processes-and-stopping-a-server — a dev server is a process; ports belong to processes
- http-requests-and-responses — what happens when you open the app's address in a browser
- containers-and-sandboxes — why an isolated environment does not automatically limit network exposure
- environment-variables — service addresses and ports are often configured this way

## Official sources

- MDN, "What is a URL?" — https://developer.mozilla.org/en-US/docs/Learn/Common_questions/Web_mechanics/What_is_a_URL
- Docker docs, "Port publishing and mapping" — https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/

## Provenance

- Grounded in this module's verified research: MDN's URL documentation for address structure, and Docker's documentation on container port publishing for how services become reachable beyond the local machine.
- Recognition-level scope per the module spec: an annotated terminal example, not a networking tutorial; no commands or flags invented beyond the grounding facts.
- Cross-references the module's lessons on processes, HTTP, containers, and environment variables rather than repeating them.
- last_checked: 2026-09-20; claim_class: everyday; safety_class: normal; version_stamp: fall-2026-0.1.0.
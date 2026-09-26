---
title: Application logs and severity levels
module_id: dev-tooling-literacy
capabilities:
  - logs-and-severity-levels
context7_library:
context7_queries:
official_sources:
  - https://opentelemetry.io/docs/specs/otel/logs/data-model/#severity-fields
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

Applications and dev tools constantly write out short records of what they are doing. These records are called **logs**. Each log line typically includes a timestamp, a message, and a **severity level** — a label indicating how important or alarming that particular record is.

The most widely used severity levels are:

- **DEBUG** — very detailed internal activity, useful when diagnosing a problem; normally hidden in everyday operation.
- **INFO** — routine, expected events: a server started, a request was handled, a file was saved.
- **WARNING** — something unusual or potentially problematic happened, but the application kept going.
- **ERROR** — a specific operation failed.

Severity levels are a standard concept with a defined data model in the OpenTelemetry Logs specification. The exact labels and how chatty each level is can vary between tools, but the idea — a scale from "routine" to "failed" — is shared across virtually all software an AI agent might run or work on.

## When it is useful

Recognizing severity levels is useful whenever an AI agent starts or works on an application and logs scroll by. It helps you:

- Interpret activity as an agent runs a build, starts a dev server, or exercises an app, without treating every log line as a failure.
- Distinguish "expected noise" (INFO lines about startup and requests) from "worth a look" (WARNING) and "an actual failure occurred" (ERROR).
- Decide when to stop the agent and ask questions — e.g., a stream of ERROR lines is a good moment to pause.
- Follow along when the agent quotes a log line back to you as evidence.

## Prerequisites

- Basic familiarity with the terminal as the place where an application's output appears (see the terminal/shell lesson in this module).
- No programming knowledge required; reading log lines is recognition, not implementation.

## Current syntax

There is nothing to write here — this is a recognition topic. What you are learning to recognize is the shape of a log line:

```
2026-09-20 14:02:11 INFO  server: listening on port 3000
2026-09-20 14:02:15 INFO  request: GET / 200 (12ms)
2026-09-20 14:03:02 WARN  cache: miss for key "user:42", falling back to database
2026-09-20 14:03:19 ERROR db: connection to "orders-db" failed after 3 attempts
```

Typical parts of a line, left to right: a timestamp, the severity level, an optional component or module name, and a human-readable message. Some tools use shorter labels (`INFO`, `WRN`, `ERR`) or color-coding instead of the full words.

## What happens (local and remote)

When an agent runs an application on your machine, log output usually streams into the terminal — or into a terminal panel in your editor. Locally, this is your most direct window into what the application is actually doing, as opposed to what the agent *says* it is doing.

In deployed or hosted environments, the same logs are collected and stored by the platform rather than shown live, and an agent (or teammate) may retrieve or quote them after the fact. The severity-level meanings are the same in both settings; only the delivery differs.

## Practical example

Suppose an agent starts a web app for you, and the terminal shows:

```
2026-09-20 14:02:11 INFO  Starting development server...
2026-09-20 14:02:11 INFO  Server listening on http://localhost:3000
2026-09-20 14:02:40 WARN  Deprecation: config option "assets.prefix" is deprecated
2026-09-20 14:02:55 INFO  GET / 200 15ms
2026-09-20 14:03:01 INFO  GET /about 200 18ms
2026-09-20 14:03:09 ERROR Failed to save upload: permission denied
```

Reading this at recognition level:

- The two `INFO` lines at the top are good news: the server started and is listening.
- The `WARN` line is a heads-up about a deprecated setting — not a failure; the app kept running.
- The `INFO` request lines show real traffic succeeding (status `200` — see the related HTTP lesson).
- The final `ERROR` line is the one that matters: a specific operation (saving an upload) failed. That is where you would ask the agent to focus, rather than worrying about the earlier lines.

## Explanation guidance

### Essential

- Log lines are the application reporting its own activity; an agent reading or writing logs is working from the same window you can see.
- **Not every log line is a failure.** INFO lines are routine narration; DEBUG lines are verbose internal detail. If a wall of output ends with a successful startup, most of it was expected.
- ERROR is the signal to act on; WARNING is worth noting but often tolerable.
- If you are unsure whether something is a real problem, ask the agent: "Is that ERROR line blocking anything, or is it incidental?" A capable agent should be able to answer from the log context.

### Experienced-user note

- Severity level is a label the application itself assigns; it is honest but not infallible. Occasionally an app logs something alarming at INFO, or a handled-and-recovered failure at ERROR. Level plus the message text together tell the story.
- A silent application is not necessarily a healthy one — absence of log output can mean a process stopped, not that everything is fine. Exit codes (another lesson in this module) are how tools report completion status; visible output or a returned prompt alone doesn't establish success.
- Log verbosity is usually configurable; an agent may raise or lower it when diagnosing.

### Optional deeper context

- OpenTelemetry — a widely adopted industry specification for logs, metrics, and traces — defines a formal severity model with both a numeric scale and display names (TRACE, DEBUG, INFO, WARN, ERROR, FATAL and variants). Learning that this is a standardized data model explains why the same levels appear across very different tools and languages.
- Structured logs (one JSON object per line) carry the same information — timestamp, level, message — in machine-parseable form, which is often what an agent prefers to work with.

## Cautions and common failures

- **Panic at the noise.** Beginners often treat a long INFO stream as a problem report. Judge by severity level and the final lines, not by volume.
- **Relief too early.** Conversely, the absence of red ERROR lines does not prove success — cross-check with the process state and exit codes rather than the log alone.
- **Fixating on a WARNING.** Warnings frequently persist in healthy applications. Ask whether it is actionable before letting an agent spend effort "fixing" it.
- **Log lines can contain sensitive data.** Logs may echo request parameters, tokens, or connection details. Treat pasted logs you share outside your machine (or share with an agent) the way you would treat a .env file — review before sharing.
- **Don't ask the agent to "delete the errors."** Suppressing log lines hides the symptom; the underlying operation still failed. The goal is to understand the ERROR, not remove the evidence.

## Related capabilities

- Exit codes — machine-readable completion status; logs and exit codes together establish what actually happened.
- Reproducing a bug — a repeatable scenario is what produces the log lines worth reading; cross-reference the debugging-recovery module's read-error-messages lesson for interpreting failure messages themselves.
- Localhost, ports, exposed services — the log line telling you where the app is listening.
- HTTP requests and responses — status codes appearing in request logs.
- Running processes and stopping a server — a server writing logs is a running process you may need to stop.

## Official sources

- OpenTelemetry Logs data model — Severity fields: https://opentelemetry.io/docs/specs/otel/logs/data-model/#severity-fields

## Provenance

- Sourced from the OpenTelemetry Logs data model specification (severity fields section), verified in this session's research for the dev-tooling-literacy module.
- Severity-level interpretation guidance reflects the specification's standard scale (TRACE/DEBUG/INFO/WARN/ERROR/FATAL) as a recognized cross-tool convention.
- Recognition-level content per the module contract: readers learn to interpret log activity, not to configure logging or write logging code.
- Aligned with module scope: this lesson interprets application output; it does not repeat the debugging-recovery module's error-message reading lesson, which it cross-references instead.
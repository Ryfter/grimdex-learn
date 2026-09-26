---
title: Codebase retrieval -- hybrid search vs. naive RAG
module_id: agentic-ai-development
capabilities:
  - codebase-retrieval-hybrid-search
context7_library: /websites/platform_claude_en
context7_queries:
  - How should a coding agent search a large codebase for relevant files and symbols?
  - Why does pure vector embedding search underperform for code navigation?
  - What is hybrid search over a codebase and when is it used?
official_sources:
  - https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls
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

When an AI coding agent works in a large codebase, it needs to find the right files, functions, and definitions before it can act. The way that search works matters. There are two broad approaches:

- **Naive RAG (vector/embedding search):** the code is chopped into chunks, converted to numeric "embeddings," and retrieved by semantic similarity -- things that *mean* something like the query.
- **Hybrid search:** embedding search is combined with exact-match signals that code is full of -- symbol names, file paths, and import graphs -- typically via keyword or AST-aware (syntax-aware) search layered together with embeddings.

The key point, which is well-established cross-vendor practice: **pure vector search often underperforms for code navigation specifically.** Code has precise, exact-match signals that semantic similarity handles poorly. If you ask for `getUserById`, you want that exact symbol -- not files that are vaguely "about users." A hybrid approach captures both the exact structure and the fuzzy meaning, and does better than embeddings alone.

## When it is useful

This is a **recognition-level** topic. You are not expected to build retrieval yourself. It is useful to know when:

- You are choosing between coding-agent tools or harnesses and want to ask informed questions about how they search your codebase.
- An agent seems to be "looking in the wrong files" and you're wondering whether retrieval quality is the culprit.
- A vendor demo mentions "RAG over your codebase" and you want to know why that phrase alone doesn't guarantee good code navigation.

## Prerequisites

- General familiarity with what an AI coding agent does (see the module's earlier lessons).
- No retrieval-engineering or ML background required.

## Current syntax

There is no syntax to learn. This page is about a design pattern inside agent tooling, not a command or API you write.

## What happens (local and remote)

- **Locally:** your agent harness indexes or searches the repository when the agent needs context. Well-built harnesses already combine exact-match signals (symbols, paths, imports) with semantic search. You typically don't configure or see this.
- **Remotely:** cloud-based coding agents perform the same retrieval on their copy of your repo. The same principle applies -- the quality of their retrieval shapes which files the agent actually sees and edits.

## Practical example

An agent is asked to fix a bug in a function called `calculateInvoiceTotals`.

- A pure embedding search for "fix invoice total bug" might return files about invoices generally, billing docs, and loosely related modules.
- A hybrid search also hits the exact symbol `calculateInvoiceTotals`, the file path where it lives, and the modules that import it -- landing the agent directly on the code that matters.

The agent that lands on the right files produces better changes; the agent that doesn't wastes time and context wandering.

## Explanation guidance

### Essential

- Retrieval is how an agent finds the relevant parts of your codebase; bad retrieval means the agent works from the wrong context.
- Pure vector/embedding search (naive RAG) is often weaker for code than for prose, because code has exact-match signals -- symbol names, file paths, import graphs -- that similarity search misses.
- Hybrid search (keyword/AST-aware search combined with embeddings) captures those exact signals better and is the well-established approach.
- **You almost never need to build this yourself.** Your coding-agent harness already handles retrieval. Recognize the term; don't engineer the pipeline.

### Experienced-user note

- If you're evaluating harnesses, retrieval quality is worth probing: does the agent reliably find exact symbols and follow imports, or does it behave like a fuzzy document search?
- Retrieval failures show up indirectly -- an agent edits a look-alike function, or misses a caller. Reading the agent's tool-call trace (see the trace-debugging lesson) is how you spot retrieval-related missteps.

### Optional deeper context

- "AST-aware" means the search understands code syntax (functions, classes, definitions) rather than treating code as plain text. It is one of the exact-match signals hybrid approaches use.
- The same principle applies outside code: any domain with strong exact identifiers benefits from hybrid retrieval. Code is just the most prominent case.

## Cautions and common failures

- **Don't build your own retrieval pipeline** for a coding agent on the assumption that "more RAG is better" -- your harness likely already does hybrid search, and a homemade naive-vector layer can make results worse.
- **Don't equate "RAG" with quality.** A vendor saying "we use RAG over your code" says nothing about whether exact-match signals are handled.
- Retrieval problems are easy to misdiagnose as model problems. If an agent keeps missing the right files, suspect retrieval before suspecting the model.

## Related capabilities

- **Verifying agent work** -- retrieval errors surface as wrong edits; verification catches them.
- **Reading and debugging an agent's trace** -- the trace shows which files the agent actually looked at, which is how retrieval failures become visible.
- **Tool and schema design** -- retrieval is often exposed to the agent as a tool; the same description-quality principles apply.

## Official sources

- Anthropic platform docs on handling tool calls (how agents receive and act on retrieved/tool content): https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls

## Provenance

The core claim on this page -- that pure vector/embedding search often underperforms for code navigation, and that hybrid search (keyword/AST-aware plus embeddings) captures code's exact-match signals better -- is **well-established cross-vendor practice**, not a single vendor's documented feature. It is presented at recognition level: the takeaway for readers is that their coding-agent harness already handles retrieval, not that they should build it. The Anthropic platform-docs URL above is cited as a real anchor for how agents consume tool/retrieval content, not as a source for the hybrid-search claim itself.
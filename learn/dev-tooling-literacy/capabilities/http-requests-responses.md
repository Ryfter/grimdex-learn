---
title: HTTP requests and responses
module_id: dev-tooling-literacy
capabilities:
  - http-requests-responses
context7_library:
context7_queries:
official_sources:
  - https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview
  - https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
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

When an application talks to another service over the web -- fetching data, submitting a form, calling a payment provider -- the conversation follows a standard request-and-response pattern called HTTP. Recognizing the pieces of that conversation helps you follow what an AI coding agent is doing when it mentions "calls," "endpoints," or status codes, without needing to write any networking code yourself.

The key vocabulary at recognition level:

- **Methods** -- short verbs at the start of each request that state the intent. Common ones: `GET` (retrieve something), `POST` (send new data), `PUT`/`PATCH` (update existing data), `DELETE` (remove something). A `GET` should be a safe read; a `POST`, `PATCH`, or `DELETE` changes something on the other side.
- **Headers** -- small labeled lines carrying metadata about the exchange: what format the content is in, whether credentials are attached, caching instructions. They are not the main payload; they are the envelope details.
- **Bodies** -- the main content being carried, typically text in a structured format such as JSON. A `GET` request usually has no body; a `POST` usually does.
- **Status codes** -- three-digit numbers in every response summarizing the outcome: `200`-range generally means success, `300`-range redirection, `400`-range "the request itself was bad," `500`-range "the server hit a problem." The familiar `404` ("not found") lives in the `400` range.

## When it is useful

This literacy pays off in situations you are likely to encounter while collaborating with an agent:

- An agent says it will "call the API" or "test the endpoint" and you want to know what actually travels back and forth.
- Something fails with an error mentioning a status code (for example `401`, `404`, `500`) and you want to interpret whether the problem is credentials, a wrong address, or the other service misbehaving.
- An agent proposes integrating a third-party service and you want to recognize what a request/response pair would look like before agreeing.
- You are reviewing logs or tool output that shows method, path, and status (a common log line shape) and want to read it at a glance.

## Prerequisites

- General recognition of the terminal and of an agent performing steps on your behalf (see the module's earlier capabilities).
- Awareness that localhost and ports identify where a locally running app can be reached -- useful for recognizing where these requests go.

## Current syntax

There is no syntax to memorize here -- the goal is recognizing a request/response pair when you see one. An HTTP exchange, in its plain-text shape, looks roughly like this:

**Request:**

```
GET /orders/42 HTTP/1.1
Host: shop.example.com
Accept: application/json
```

**Response:**

```
HTTP/1.1 200 OK
Content-Type: application/json

{"order_id": 42, "total": "39.90", "status": "shipped"}
```

Reading it: the first line of the request is the method (`GET`) plus the path (`/orders/42`); the lines below are headers; the response's first line carries the status code (`200`) and a short reason phrase (`OK`), followed by headers and, here, a JSON body. You will rarely see this raw text -- tools and logs usually show a friendlier version -- but the underlying shape is the same.

## What happens (local and remote)

Locally: when an agent starts a dev server, your browser visiting `localhost:3000` (or similar) is an HTTP request to that local app, and the page you see is its response. When an agent tests an integration, it typically sends requests to a remote service over the internet and inspects the responses' status codes and bodies.

Remotely: the request travels to a server operated by whoever runs the service; that server processes it and sends back a response. The service may apply its own authentication and permission checks (see the related API credentials capability), rate limits, and logging -- meaning a response can fail for reasons entirely on the far side, not in your project's code.

## Practical example

Suppose an agent is wiring your app to a shipping service. In its plan or summary you might see something like:

```
POST /v1/shipments
Authorization: Bearer <token>
Content-Type: application/json

{"recipient": {...}, "items": [...]}
→ 201 Created
```

What you can recognize, without implementing anything:

- `POST` means "create something new" on the service -- a changing operation, not a safe read.
- `Authorization: Bearer <token>` is a header carrying a credential -- a sign the agent is wiring in the API key you configured, and a reminder that this file/log should not be shared carelessly if the real token appears.
- `Content-Type: application/json` says the body is JSON.
- `201 Created` is a success status in the `200` range, with the added nuance that it specifically means "a new resource was made."

If instead the summary showed `401 Unauthorized`, you could recognize a credentials problem; `404 Not Found` suggests the address or path is wrong; `500` suggests trouble inside the service. None of these interpretations require writing code -- only recognizing the vocabulary.

## Explanation guidance

### Essential

- HTTP is a request/response conversation: a method stating intent, headers carrying envelope details, a body carrying content, and a status code summarizing the outcome.
- Status code ranges are the quickest diagnostic: `2xx` success, `4xx` the request was bad (wrong address, bad input, missing credentials), `5xx` the server failed.
- A status code plus a body is the minimum an agent needs to interpret what happened; when reporting a problem, including both is more useful than "it didn't work."

### Experienced-user note

- Method choice carries meaning: agents (and reviewers) expect `GET` to be read-only. If an agent proposes a `GET` that changes data, or a `POST` where a `GET` would do, that is worth questioning.
- Some status codes have specific, common meanings -- `401` (authentication problem), `403` (authenticated but not permitted), `404` (not found), `429` (too many requests / rate limited). Recognizing these four covers a large share of real failures.
- Headers you will see often: `Authorization` (credentials), `Content-Type` (body format), and caching-related headers. An agent adjusting these is adjusting envelope details, not the payload.

### Optional deeper context

- HTTP has versioned forms (such as HTTP/1.1 and HTTP/2) that differ in transport efficiency, but the method/header/body/status vocabulary is stable across them -- no need to distinguish them for recognition purposes.
- A response body can itself contain structured information about the failure (many APIs return a JSON error message explaining what went wrong), so "read the body" is often the next step after reading the status code.
- Redirects (`3xx`) mean "the answer is elsewhere" -- the client is expected to follow up with another request, which is why a redirect can look like both success and movement.

## Cautions and common failures

- **A `200` status does not always mean the operation fully succeeded** -- some services report application-level errors inside a `200` response body. Reading the body, not just the code, is the reliable habit.
- **Requests with side effects are easy to fire accidentally.** Retrying a `POST` can create duplicates; an agent replaying requests is doing something different from re-reading a page with a `GET`.
- **Credentials in headers end up in logs.** If an agent shows a request with an `Authorization` header, treat that output like a secret -- recognize the shape (the related capability on API credentials covers this in depth).
- **Status codes come from the server you reached** -- a `404` may mean a typo in the path your agent wrote, or that the service itself changed. Don't assume the cause from the code alone.
- **Don't drift into implementing HTTP calls yourself** based on this lesson. The purpose is recognizing and interpreting the conversation; writing the code remains the agent's (or a developer's) job.

## Related capabilities

- api-credentials-authentication-permissions -- who is allowed to make which requests
- api-endpoints-rest -- what an API, an endpoint, and REST are
- localhost-ports-exposed-services -- where a locally started app can be reached
- application-logs-severity-levels -- where request/response activity often shows up

## Official sources

- MDN, "Overview of HTTP": https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview
- MDN, "HTTP response status codes": https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

## Provenance

Grounding for this page comes from this session's earlier verified research (openrouter-pareto, cross-checked), anchored on the MDN HTTP documentation cited above. Recognition-level treatment per the module spec: an annotated request/response example for interpretation, not an implementation exercise. No vendor claims beyond the cited sources. This module deliberately leaves Context7 empty, relying on the official_sources anchors instead.
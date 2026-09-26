---
title: APIs, endpoints, and REST
module_id: dev-tooling-literacy
capabilities:
  - apis-endpoints-rest
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

An **API** (Application Programming Interface) is a defined interface through which one piece of software offers services to another. In everyday web development, the most visible kind is a web API: a service a program talks to over the network by sending requests and reading responses.

An **endpoint** is a specific interaction point on that interface -- a particular address (URL) your application can send a request to, in order to perform one kind of action. A single API service typically exposes many endpoints: one for creating an item, one for listing items, one for fetching a single item, and so on.

**REST** (Representational State Transfer) is an architectural *style* for designing such APIs -- a set of conventions about how to organize resources and interactions, such as using standard HTTP methods (GET, POST, PUT, DELETE) against resource-shaped URLs. It is influential and very common, but it is a design approach, not a legal requirement and not a synonym for "API." There are APIs that are RESTful, APIs that only partly follow REST conventions, and APIs built on entirely different styles.

## When it is useful

This recognition matters whenever an AI coding agent is wiring your application to a service:

- It proposes adding a call to "the API" of some payment, mapping, or email provider -- you need to recognize what that means: your app will send network requests to defined endpoints.
- It prints or logs an error containing a URL and a status code -- recognizing "an endpoint was contacted and answered with an error" is the first step in reading the situation.
- It describes a third-party service as "a REST API" or simply "an API" -- knowing REST is a style, not a guarantee, helps you avoid assuming that any two APIs work the same way.
- It proposes replacing a direct database connection with calls to an internal API endpoint -- a meaningful architectural change you can recognize as such.

## Prerequisites

- Basic recognition of HTTP requests and responses (methods, status codes) -- see the related capability in this module.
- Recognition of URLs and addresses, including localhost and ports.
- No programming-language knowledge and no networking implementation skill is required; this is recognition-level material.

## Current syntax

There is nothing to "install" here. What you are learning to recognize is vocabulary an agent uses, and the shape of what it produces:

- A base address (for example, `https://api.example.com`) plus a path (for example, `/users/42`) together identify an endpoint.
- The HTTP method of a request (GET, POST, PUT, DELETE) signals the kind of interaction intended with that endpoint.
- Documentation for a web API is typically organized as a list of endpoints, each with its expected method, inputs, and responses.

If a proposed call, log line, or configuration mentions a URL, a method, and possibly a status code, you are likely looking at API interaction.

## What happens (local and remote)

- **Remote:** your application (or the agent's code) sends a request to a service's endpoint over the network. The service checks the request, does its work, and returns a response with a status code and usually a body (often JSON-shaped data).
- **Local:** during development, an agent may also start your *own* application's API on localhost at some port -- endpoints you can call locally while testing. This is a locally-available service, not necessarily exposed to the wider world.
- Authentication may be required: many endpoints reject requests that don't include valid credentials. See the related capability on API credentials and permissions.

## Practical example

An annotated snippet showing the *shape* of an API interaction, as you might see it in an agent's plan, a log line, or API documentation:

```
GET https://api.example.com/v1/orders/1234

Request:  no body; may include headers (e.g. an authentication token)
Response: status 200 (OK), body contains data describing order 1234
```

Recognition points:

- `GET` is the HTTP method -- a request to *read* something, not change it.
- `https://api.example.com/v1/orders/1234` is the endpoint -- the service's address plus a path identifying a specific resource (one order).
- `200` is a success status code; something like `404` (not found) or `401` (authentication problem) would indicate the request did not succeed as intended.

The same interaction in prose: "the app sends a GET request to the orders endpoint, and the service responds with the order's data." If a log, plan, or error message contains this shape -- a method, an address, and a status -- you are recognizing an API interaction, and you can follow what the agent is doing without implementing anything yourself.

## Explanation guidance

### Essential

- An API is how one program asks another program's service for something, without knowing its internals.
- An endpoint is one specific address for one specific kind of interaction with that service.
- REST is a common design *style* for such APIs; hearing "it's an API" does not tell you it is RESTful, and hearing "REST" does not guarantee any particular behavior.

### Experienced-user note

- The same service often exposes many endpoints under one base address, and versioning may appear in the path (as in `/v1/`). When an agent proposes switching endpoints or API versions, that is a real compatibility-relevant change, not a cosmetic edit.
- "RESTful" claims in documentation or agent explanations describe design intent; the practical check is always what the specific endpoint expects -- which method, which inputs, which authentication.

### Optional deeper context

- REST is one architectural style among several; other API designs exist and are common. Recognizing that a family of styles exists is enough -- deep comparison of architectural constraints is beyond this module.
- MDN's HTTP overview and status-code documentation (see Official sources) are stable references if you want to see the request/response model in full.

## Cautions and common failures

- **Assuming every API is a REST API.** The term "API" covers many designs; don't let an agent's casual "it's just an API call" skip the step of checking the specific endpoint's documented method and inputs.
- **Confusing an endpoint with the whole service.** One endpoint succeeding doesn't mean every operation on the service will succeed.
- **Treating a status code as proof of business success.** A `200` response means the request was handled at the HTTP level; the body may still report an application-level failure.
- **Sending credentials to the wrong place.** If an agent configures authentication, check that the endpoint address matches the real service -- see the API credentials capability in this module.
- **Confusing local endpoints with exposed services.** An endpoint running on localhost during development is not automatically reachable from the internet -- and one the agent binds more broadly may be; see the localhost/ports capability.

## Related capabilities

- http-requests-responses (methods, headers, status codes)
- api-credentials-authentication-permissions
- localhost-ports-exposed-services
- database-connections-connection-strings
- environment-variables
- env-files-and-secrets

## Official sources

- MDN, "Overview of HTTP": https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview
- MDN, "HTTP response status codes": https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

## Provenance

- Anchored in MDN's HTTP overview and status-code documentation as listed in this module's grounding facts.
- Recognition-level treatment only: the goal is to recognize API/endpoint/REST vocabulary and the shape of an interaction, not to implement networking or evaluate architectural conformance.
- Deliberately stays on tooling/workflow recognition; no programming-language fundamentals are introduced.
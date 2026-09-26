---
title: Dependencies and package managers
module_id: dev-tooling-literacy
capabilities:
  - dependencies-and-package-managers
context7_library:
context7_queries:
official_sources:
  - https://docs.npmjs.com/about-npm
  - https://packaging.python.org/en/latest/tutorials/installing-packages/
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

A **dependency** is third-party software your project uses but did not write itself -- a library that handles dates, talks to a database, or styles a web page. A **package manager** is a tool that finds, downloads, and organizes these dependencies so the project can use them. npm (for JavaScript/Node.js projects) and pip (for Python projects) are two widely used examples.

When a coding agent says it will "install a package" or "add a dependency," it is fetching real, external software from public package registries and wiring it into your project. This is a normal, routine part of development -- but it is worth recognizing as what it is: adding outside code to your project, not flipping a switch that "enables a feature" of a language.

## When it is useful

Recognizing this pattern helps you:

- Understand what an agent is actually doing when it lists "installing dependencies" as a step.
- Notice that a project may not run at all until its dependencies are installed -- a common first-run experience.
- Ask sensible questions, such as which package is being added and why, rather than treating every install as automatic noise.

## Prerequisites

- Module-level tooling recognition from the earlier lessons in this course (terminal, files, project folders).
- No programming-language knowledge required -- this page is recognition-level only.

## Current syntax

You don't need to run anything. The goal is to recognize the shape of install commands an agent may show you:

- **npm (JavaScript/Node.js):** an agent may run something like `npm install <package-name>` to add a package to the project.
- **pip (Python):** an agent may run something like `pip install <package-name>` to install a package into the environment.

The exact command varies by language and tool. What matters is the pattern: a package manager tool, an action such as "install," and the name of a package being retrieved from a public registry.

## What happens (local and remote)

**Locally:** the package manager downloads the package and places it in a location the project uses for dependencies (npm keeps dependencies in a `node_modules` folder inside the project; Python installs packages into the active Python environment). Your project's files change -- often including a manifest file that records what is declared as a dependency.

**Remotely:** the package is pulled from a public registry -- a large, shared online collection of published packages. Publishing is open, so quality and trustworthiness of individual packages varies; established, widely used packages are the norm for common needs, but the registry itself does not vouch for any package.

## Practical example

Annotated -- a snippet you might see in an agent's plan or terminal output:

```
npm install date-fns
```

- `npm` -- the package manager tool being invoked (JavaScript/Node.js ecosystem).
- `install` -- the action: fetch and set up the package.
- `date-fns` -- the name of a real, published third-party package for date handling.

Reading it as a sentence: "Please retrieve the third-party package `date-fns` from the public npm registry and make it available to this project." The same reading applies to `pip install requests` or similar -- tool name, action, package name. Nothing here requires you to write code; it requires you to recognize what kind of operation is happening.

## Explanation guidance

### Essential

- A dependency is someone else's code your project uses. A package manager is the tooling that retrieves and organizes it.
- Installing a package is adding external software to the project -- a routine step, but a real one, with real changes to your project's files.
- Most real projects depend on many packages; installing dependencies is often the first step before a project can run.

### Experienced-user note

- Dependency installs usually update more than one thing: the installed package and the project's record of what it depends on. If an agent touches several files during an install, that is typically expected behavior, not a mistake.
- Different ecosystems have different package managers and registries (npm for JavaScript, pip/PyPI for Python, and others for other languages) -- the concept carries over even though the tools differ.

### Optional deeper context

- Beyond plain installs, package managers handle upgrading, removing, and resolving version conflicts between packages. If you want to go further, the distinction between a project's declared dependency list and a lockfile that records exact installed versions is covered in a related lesson (Dependency manifests vs. lockfiles).
- Registries are community-run infrastructure; large ecosystems publish, review, and deprecate packages over time, which is why recognizing package names becomes easier with exposure.

## Cautions and common failures

- **"Enabling a feature" is the wrong mental model.** Packages are external software with their own authors, versions, and licenses -- not built-in capabilities being switched on.
- **First-run failures are common and usually mundane.** A project that fails to start because dependencies aren't installed yet is normal, not a sign the agent did something wrong.
- **Package names can be mistyped or ambiguous.** An agent installing the wrong package (a similar-looking name, a typo) is a real failure mode; a quick sanity check of the package name against its registry page is reasonable due diligence.
- **Installs are not free of consequence.** Adding a dependency adds someone else's code, with its own update cadence and license terms -- worth remembering when an agent adds several packages at once.

## Related capabilities

- Dependency manifests vs. lockfiles
- Semantic versioning
- Virtual environments
- License files
- Install, build, run are different steps

## Official sources

- npm docs, "About npm" -- https://docs.npmjs.com/about-npm
- Python Packaging User Guide, "Installing packages" -- https://packaging.python.org/en/latest/tutorials/installing-packages/

## Provenance

- Grounding for this page comes from vendor-authored documentation: the npm project's own docs describing what npm is and does, and the Python Packaging Authority's user guide on how Python package installation works. Both are authoritative primary sources for their respective ecosystems and are cross-checked against this session's earlier verified research (openrouter-pareto). Content is recognition-level by design, per the module spec; no vendor claims beyond the grounding facts are asserted.
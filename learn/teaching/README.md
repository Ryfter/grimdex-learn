# Teaching Decks and Workflows

## What's here

Four workflow folders. Each contains four files:

- `slides.md` — a slide outline
- `deck.html` — ready-to-present slides
- `infographic.svg` — a visual summary of the workflow
- `exercise.md` — a guided practice activity

The slides and exercise restate and link to the lessons they cite. For more depth,
follow those links to the full lesson pages and official documentation.

## Opening a deck

Double-click `deck.html`. It opens in your browser.

Navigate with arrow keys or Page Down. Each slide has a "Presenter notes" label
under it; click it to open the short note. A nested "Deeper notes" label holds the
deeper note. Presenter notes show the graphic, short note, deep note, and lesson links.
A lesson link opens that lesson's Markdown file directly — open it in a text editor
or a Markdown viewer, not a web browser.

Print to PDF from the browser's print dialog. The PDF keeps the slides; presenter
notes are hidden when printing.

## Three ways to use these slides

### A. As HTML (recommended)

Built by this command from a grimdex-edu checkout:

    pwsh ./scripts/build-teaching-decks.ps1

Writes `deck.html` in each workflow folder. No extra tools needed.

### B. Showcase (workflow 1 only)

A hand-designed HTML view of workflow 1 for visual comparison with the generated
deck. Not auto-generated; built separately so you can see both approaches side by side.

### C. With Marp

Convert `slides.md` to PowerPoint or PDF with the command-line Marp tool.
This requires Node.js 18 or later:

    npx @marp-team/marp-cli@latest slides.md --pptx
    npx @marp-team/marp-cli@latest slides.md --pdf

Marp's default PowerPoint export turns slides into images, but keeps presenter
notes intact.

## The notes format

Each slide's presenter notes follow this pattern:

- **Graphic:** the visual shown on the slide (infographic reference or description)
- **Short note:** one or two sentences, the key point
- **Deep note:** why this step matters, a common mistake, or the next concept
- **Lessons:** the module and lesson keys cited on the slide

## Reusing in a course

Copy the workflow folder or link it into your own course materials. When you add
course-specific content, keep it in your own materials, not here.

The decks are frozen; any changes belong in a new build from the source `slides.md`.

## How slides and lessons connect

Every slide cites the lessons it draws from. The slides restate only facts from
those lessons, at essentials depth. For more:

- The lesson pages explain the why and how in more detail.
- The lessons link to official vendor documentation, where the full expertise lives.

This three-rung ladder (essentials, depth, expertise) is by design. The slides
keep you moving forward; the lessons fill in the gaps.

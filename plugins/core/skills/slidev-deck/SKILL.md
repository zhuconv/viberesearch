---
name: slidev-deck
description: Author or refactor a Slidev deck (a slides.md file, especially under jiajun's slides-hub repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls.
---

# Slidev deck — house style + verification recipe

Use this skill whenever the user is creating, refactoring, or debugging a Slidev deck — i.e. a `slides.md` under `slides-hub/projects/<name>/`, or any standalone Slidev `.md`. The deck conventions below match the user's `graphagent-4023` and `graph-agent-0507` decks; copy that grammar before inventing new layouts.

---

## 1. Style grammar (one claim per slide)

A deck slide answers **one question** with **one piece of evidence** — never two. The 4023 template:

```md
# <Slide title — the claim>

<div class="grid grid-cols-2 gap-4 mt-3 text-sm">
<div class="p-3 bg-blue-50 rounded border border-blue-200">

### <Half A — setup / what>

- bullet
- bullet

</div>
<div class="p-3 bg-green-50 rounded border border-green-200">

### <Half B — payoff / why>

- bullet
- bullet

</div>
</div>

<div class="mt-3 p-2 bg-yellow-50 rounded border border-yellow-300 text-xs">
<strong>Punchline / honest reading.</strong> One sentence the reader takes home.
</div>
```

**Color palette (semantic, not decorative):**
- `bg-blue-50 / border-blue-200` — primary "what" / status quo / setup
- `bg-green-50 / border-green-200` — "now" / proposed / yes-side
- `bg-purple-50 / border-purple-200` — alternative or third option
- `bg-yellow-50 / border-yellow-300` — bottom callout for the punchline (always `text-xs`)

**Density rules:**
- Use `text-sm` everywhere by default. `text-xs` is reserved for the yellow callout and table footnotes.
- Prefer 1-line bullets. Two-line bullets are tolerable; three-line means the slide is wrong.
- Tables are fine for hard numbers; markdown tables get the global `.slidev-layout table td { padding: 0.25em 0.5em }` tightening if a `<style>` block is present.
- Don't write paragraphs. If you have a paragraph, you have two slides masquerading as one.
- Footers / sources / dates → `text-xs opacity-60` or `opacity-70`.

---

## 2. Page-size budget (so it fits)

Slidev exports at **735.12 × 414 pt** (16:9). At default `text-sm`, a slide reliably fits:

| Region | Budget |
|---|---|
| Each `grid-cols-2` half | ~12 lines incl. sub-header |
| Bullets per half | 4 single-line, or 3 two-line |
| Tables | up to 6 rows + header |
| Yellow callout | 1–2 lines max |

If you bust the budget you have **three escape hatches in order of preference**:

1. **Trim content first.** Drop adjectives, join short bullets, kill an entire sub-section. This is almost always the right answer.
2. **Drop inline-`code` styling on entity names** in italic example lines. The shaded code background adds line-height; plain italic doesn't. Single most common cause of overflow on the bullet that has *"for each `account`, …"* — write *"for each account, …"* instead.
3. **Apply `class: compact` to that one slide.** Last resort — only when the slide is genuinely dense (e.g. a 2×2 grid of content boxes). Do **not** apply globally; sparse slides under compact CSS look anemic.

The compact CSS to put in the deck `<style>` block (only if needed):

```html
<style>
.slidev-layout.compact h1 { font-size: 1.5em !important; line-height: 1.15 !important; margin-bottom: 0.3em !important; }
.slidev-layout.compact h3 { font-size: 1em !important; margin: 0.15em 0 !important; }
.slidev-layout.compact p, .slidev-layout.compact li { line-height: 1.3 !important; font-size: 0.85em !important; }
.slidev-layout.compact ul { margin: 0.15em 0 !important; padding-left: 1.1em !important; }
.slidev-layout.compact li { margin: 0.05em 0 !important; }
.slidev-layout.compact table { font-size: 0.8em !important; }
.slidev-layout.compact .p-2 { padding: 0.5rem 0.6rem !important; }
.slidev-layout.compact .mt-3 { margin-top: 0.4rem !important; }
</style>
```

Apply per slide via frontmatter:

```md
---
class: compact
---

# Dense slide
```

---

## 3. Build / export / verify loop

Slides-hub layout (relevant to anything in `/mnt/vita-nas/jiajun/slides-hub/projects/<name>/`):

```bash
# Build for GitHub Pages (writes to dist/<name>/)
cd slides-hub/projects/<name>
npx slidev build slides.md \
    --base /slides-hub/<name>/ \
    --out  /mnt/vita-nas/jiajun/slides-hub/dist/<name>

# Export PDF for visual verification
npx slidev export slides.md --output slides.pdf
```

`sync-slides.mjs` is **broken on entries without `src`** (TypeError on `resolve(undefined)`); skip it for in-tree decks like `graphagent-4023` / `graph-agent-0507` and edit `slides.md` directly.

**Verification — render every page and READ each PNG:**

```bash
rm -f /tmp/sl-*.png                                   # critical, see gotcha #2
pdftoppm -r 110 slides.pdf /tmp/sl -png
ls /tmp/sl-*.png
```

Then `Read` each `/tmp/sl-N.png` (or `/tmp/sl-NN.png`, see gotcha #2) and check:
- No content cut off at the bottom (yellow callout fully visible)
- No headings wrapping unexpectedly
- Tables not overflowing the half-box
- All arrows in any embedded SVG land in a box, not in empty space

Type-checking and unit tests don't catch slide overflow — visual inspection is mandatory before saying "done".

---

## 4. Recurring pitfalls (each cost real time before)

### 4.1 — Don't write `---` twice

Slidev frontmatter syntax `---\nclass: foo\n---` already includes the slide separator. Putting another `---` before it inserts an empty slide:

```md
[end of previous slide content]

---            ← BAD: this is an extra separator

---            ← this `---class:foo---` is the actual separator
class: compact
---

# Next slide
```

Symptom: page count is N+1 when you expected N, slide N is blank, all subsequent slide numbers shift. Fix: delete the standalone `---`.

### 4.2 — `pdftoppm` switches naming when crossing 9 → 10 pages

`pdftoppm -r 110 slides.pdf /tmp/sl -png` produces:
- `/tmp/sl-1.png` … `/tmp/sl-9.png` for ≤ 9 pages
- `/tmp/sl-01.png` … `/tmp/sl-NN.png` for ≥ 10 pages (zero-padded)

If you don't `rm -f /tmp/sl-*.png` first, both naming schemes coexist and `Read /tmp/sl-6.png` returns the **previous** render's slide 6, silently. Always `rm` before re-rendering.

### 4.3 — Slide separator that gets accidentally deleted

When refactoring a slide and the search-and-replace removes the surrounding `---`, you fuse two slides. Symptom: page count drops by 1, two titles appear stacked on one page. Fix: re-insert `---` between them. (Watch for this when removing a `class: compact` frontmatter block.)

### 4.4 — Inline `code` formatting forces line wrap

In `*for each `account`, sum amount in last 7d*` the `code` spans add ~2 px line-height each. A bullet that fits at 1 line in plain text wraps to 2 with code styling. Drop code formatting on entity names in italic examples. Reserve `code` for actual identifiers / API names.

### 4.5 — Section title double-line eats page height

`### Relational lane types (multi-table, time-respecting)` wraps to 2 lines on a half-box at `text-sm`. Shorten to `### Relational *(time-respecting)*` or just `### Relational`. Long sub-headers are a hidden ~30 px tax.

---

## 5. Architecture / illustration SVGs

The user prefers high-level "stages of the system" diagrams, not full-fidelity dataflow. Conventions (see `slides-hub/projects/graph-agent-0507/public/architecture.svg`):

- **Canvas:** `1280 × 560` viewBox (or smaller); embed via `<img src="/foo.svg" class="w-full mt-3" />`
- **Color encoding** (must match deck palette):
  - LLM nodes → `fill="#e1d5e7" stroke="#9673a6"` (purple)
  - Compute nodes → `fill="#dae8fc" stroke="#6c8ebf"` (blue)
  - Store nodes → `fill="#d5e8d4" stroke="#82b366"` (green; cylinder shape OK)
  - I/O nodes → `fill="#fff2cc" stroke="#d6b656"` (yellow)
- **Layout:** prefer left→right column-of-stages with light dashed separators. 3 columns × 3-4 boxes is the upper bound — past that, split into two SVGs.
- **Arrows must terminate inside a box.** An arrow that ends in empty space ("between columns" / "near a box") is the #1 source of "what is that arrow pointing at?" confusion. Use orthogonal L-shaped paths to enter the target box's edge directly. Label any arrow whose semantics aren't visually obvious (`stop`, `round k+1`, `lanes`).
- **Loop arrows:** color the loop-back differently (`#9673a6` purple) and curve it on the side, not over the boxes.

Don't add fanout fanart, decorative gradients, or shadow effects. The diagram is read in 5 seconds.

---

## 6. Naming general / dataset-specific things

When the deck describes a system that was bootstrapped on one dataset, the code names often carry that dataset's vocabulary as a prefix (e.g. `account_history`, `account_static_aggregate` from ibm-aml). For the **slide**, give the **general name first** and put the code name in parentheses if it adds value, never the other way around. The deck audience does not care that the first benchmark was banking; they care about the operator class.

If unsure what the general name is, look at the code's relation_path / semantics — most "X_history" / "X_static_aggregate" / "X_mixed_history" tuples are 2-hop self-loops via a connector and differ only on (time-windowed?) and (same-relation vs cross-relation on the two hops). Name them by structure, not by domain.

---

## 7. Commit hygiene

Slides-hub commit messages: `<deck-name>: <short imperative>`. The deck-name prefix matches the directory under `projects/`. The body explains the editorial decision (what got tighter, what got cut), not just "update slides".

Commit `slides.md` and any new assets in `public/`. **Don't commit `slides.pdf`** unless the deck explicitly checks it in (graph-agent-0507 does; not all decks do — check `git status` first).

`dist/` is `.gitignore`d; GitHub Pages deploys from a workflow on push to main, so a successful local `slidev build` is for cache-warming and sanity, not for deploy.

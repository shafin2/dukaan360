# Design System

**Source of truth changed:** this document previously proposed a speculative navy/blue palette based on general fintech-SaaS research (no brand asset existed yet). The team has since produced a real Figma file ("Dukan-Branding") with an actual visual identity — a **Karobar Design System Guide** built and audited against that file. This document now transcribes that guide as the authoritative spec. The navy/blue direction is superseded; nothing below is speculative.

If you're implementing UI, treat this file as the spec to hand to engineering — it resolves not just *what* the colors/type styles are, but *where* each one is used, since that mapping was the gap in the raw Figma file.

## 1. Color system

### Primary — olive/lime green

| Step | Hex | Use |
|---|---|---|
| 0 | `#F4FAEB` | Selected-row/section tint |
| 50 | `#E8F4D3` | Hover backgrounds |
| 100 | `#D2E9AD` | Light fills, chart area fills |
| 200 | `#B4DA7C` | Secondary icons, chart series |
| 300 | `#97C853` | Chart fills, decorative accents |
| 400 (base) | `#84BD3A` | Light-weight moments only — highlights, hover states, chart fills |
| 500 | `#5D8927` | Active nav item, links |
| **600** | **`#476922`** | **Primary buttons, structural chrome, sidebar — main working color** |
| 700 | `#3B5420` | Button hover/pressed |
| 800 | `#19270C` | Text on light-primary tints only |

**Rule:** use 600/700 for anything load-bearing (buttons, active states, chrome). Reserve the lighter 400 base for decorative/highlight moments — straight lime green on every button reads more "consumer eco-app" than "handles your money," which matters for a product asking shop owners to trust it with their khata.

### Secondary — blue-violet

| Step | Hex | Use |
|---|---|---|
| 25 | `#EBEDFA` | Secondary card backgrounds, info tints |
| 100 | `#BBC4F1` | Hover states |
| 400 | `#657DF7` | Links/emphasis in navy-adjacent contexts, chart series 2 |
| **500** | **`#4E62C7`** | Section headers on Reports, secondary emphasis text |

Only 4 stops exist today; extend to a full 0–800 ramp in Figma if a solid secondary button is ever needed.

### Accent — olive-yellow

| Step | Hex | Use |
|---|---|---|
| 25 | `#FFFCE5` | Udhaar/outstanding-balance badge background |
| 100 | `#E8DE92` | Hover on accent chips |
| **500** | **`#C0AF2F`** | Outstanding-balance emphasis, "featured" badges — used once per screen |

**Watch this:** Accent (`#C0AF2F`, hue ~54°) and Warning (`#FAB115`, hue ~40°) sit close in the yellow-gold family. Keep them apart by *context*, not hue alone — Accent only on financial numbers/badges tied to a Bill or Customer; Warning only on stock-status badges. If they ever appear side-by-side on one screen, that's the signal to shift Accent's saturation/lightness.

### Greyscale — cool, 11-step

`#FFFFFF` (0) → `#F9F9FA` (25) → `#F4F5F5` (50) → `#E8E8E9` (100) → `#D0D1D3` (200) → `#C3C4C7` (300) → `#A2A3A7` (400) → `#73757C` (500) → `#5A5C66` (600) → `#2D303A` (700) → `#161924` (800)

### Semantic

| Role | Hex | Notes |
|---|---|---|
| Success | `#21E794` | Mint/spring green, hue ~155° — deliberately distinct from Primary's ~87° hue so "positive delta" and "brand chrome" never get confused |
| Warning | `#FAB115` | |
| Error | `#E52F2F` / `#DB3333` | |

### Chart palette

Also the official multi-series chart colors: Chart 1 orange `#D16932` · Chart 2 purple `#864DC0` · Chart 3 blue-violet `#4E62C7` (= Secondary) · Chart 4 olive-yellow `#C0AF2F` (= Accent). Charts default to Primary + Secondary as the two-series pair; add Chart 1 or 2 only when a report genuinely needs a third series.

### Where color goes across the product

- **Dashboard/Reports KPI cards:** Neutral-0 card, Neutral-200 border, numbers in Neutral-800, deltas in Success/Error only — **never Primary for a number going up.**
- **Low stock / status badges:** Warning tint for Low Stock, Error tint for Out of Stock, Success tint for In Stock — pill-shaped, never full-row background tinting.
- **Udhaar/Bill outstanding amounts:** Accent-500, once per Bill/Customer row.
- **Forms:** Neutral-300 border default, Primary-500 border + ring on focus, Error-tint background + Error text for validation errors.
- **Financial totals (Reports, Bills):** Neutral-800, semibold, tabular figures — never colored unless it's a delta (Success/Error) or the one-per-screen Accent emphasis.

## 2. Typography

**Single family: Inter Tight** (Regular/Medium/Semibold/Bold) — chosen over a two-family pairing for lower maintenance, with strong numeral/tabular support built in. This supersedes the earlier Inter + Noto Nastaliq Urdu pairing proposed before the brand identity existed; if/when a dedicated Urdu-script UI mode is built, pair Inter Tight with Noto Nastaliq Urdu (display) / Noto Sans Arabic (dense table text) as before — that guidance still holds, it just sits alongside Inter Tight now rather than Inter.

### Usage map

| UI moment | Style | Size | Notes |
|---|---|---|---|
| App page title (Dashboard, Reports) | Heading H2 / Semibold | 40px | H1 (48px) reserved for marketing/onboarding only |
| In-app section header | Heading H5 / Semibold | 28px | |
| Card / module header | Heading H7 / Semibold | 20px | |
| Modal / dialog title | Heading H7 / Semibold | 20px | |
| Standard body/UI text | Body Medium / Regular | 16px | Default for descriptions, paragraphs |
| Secondary/supporting text | Body Small / Regular | 14px | |
| Table header label | Caption Small / Medium | 14px | Uppercase + 0.04em letter-spacing override |
| Table cell text | Body Small / Regular | 14px | |
| Table cell — numeric column | Body Small / Semibold | 14px | Tabular figures enabled |
| Financial emphasis (Bill totals, KPI numbers) | **Numeric/Financial/Semibold** | 18px | New style — see below |
| Button text | Body Small / Semibold | 14px | Body Medium/Semibold (16px) for large/primary CTAs only |
| Form field label | Caption Small / Medium | 14px | |
| Form input text | Body Small / Regular | 14px | |
| Form helper/error text | Caption XSmall / Regular | 12px | |
| Timestamps/metadata | Caption XSmall / Regular | 12px | |

### Two functional gaps to fix in Figma (not style choices — genuinely missing)

1. **Tabular figures aren't enabled anywhere yet.** Non-negotiable for a financial/POS product — misaligned decimals across table rows read as unpolished immediately. Enable `font-variant-numeric: tabular-nums` on Body Small/Semibold (numeric table cells) and on the new Numeric/Financial style.
2. **No dedicated financial-number style exists.** Add exactly one new style: duplicate Body Large/Semibold (18px/600) with tabular figures on, named `Numeric/Financial/Semibold` so it's directly selectable.

### Letter-spacing cleanup flagged

Tracking currently doesn't follow a consistent rule across weight variants of the same size (e.g. H1/Semibold carries `+0.5` while H1/Medium carries `-1` at identical 48px). Normalize so tracking depends only on size, not weight, next time anyone is in the type styles.

```css
@import url('https://fonts.googleapis.com/css2?family=Inter+Tight:wght@400;500;600;700&display=swap');
```

```js
// tailwind.config
fontFamily: {
  sans: ['Inter Tight', 'system-ui', 'sans-serif'],
}
```

## 3. Overall visual direction

### Elevation — border over shadow

Cards and tables use a **1px Neutral-200 border**, not a shadow, as default elevation. Shadow is reserved for things temporarily floating above the page: dropdowns, modals, toasts, slide-overs. This reads calmer and more premium than the "every card has a soft shadow" default seen across most competitor dashboards, and it makes the *actual* floating elements feel meaningfully different instead of just decorated.

- Standard card: `border: 1px solid #D0D1D3; border-radius: 10px; background: #FFFFFF;` — no shadow.
- Floating layers only: `box-shadow: 0 4px 16px rgba(22,25,36,0.10);`

### Corner radius

| Token | Value | Use |
|---|---|---|
| radius-sm | 6px | Inputs, small buttons, table action icons |
| radius-md | 10px | Cards, primary/secondary buttons, modal inner elements |
| radius-lg | 16px | Modal/dialog outer container, slide-over panels |
| radius-pill | 999px | Status badges/chips only |

### Buttons

- **Primary:** solid Primary-600 fill, white text, radius-md, height 40px (**44px on POS checkout screens** for larger tap targets on shop tablets/phones).
- **Secondary:** white fill, Neutral-300 border, Neutral-800 text.
- **Tertiary/text:** no fill, no border, Primary-700 text — low-emphasis actions like "Cancel."
- **Destructive:** Error text, Error-tint background on hover — solid Error fill only inside a true delete-confirmation modal.
- Button text always sentence case ("Record payment," not "Record Payment").

### Inputs

Outlined, white background, Neutral-300 border, 40px height, radius-sm. Focus: Primary-500 border + a 2px solid ring (no blur/glow). Label above the field, helper/error text below.

### Tables — the signature motif

- No zebra striping — a single 1px Neutral-100 divider between rows.
- Sticky header, Neutral-50 background, Table Header style.
- **The "ledger rule":** a 2px Neutral-200 double-weight rule under the header row, heavier than the 1px row dividers below it — a quiet nod to a physical *bahi khata's* ruled lines. This is the one deliberate signature carried across every table in the product; keep it consistent everywhere a table appears.
- Status via pill badges in the relevant semantic tint, never full-row background color.
- Numeric columns always right-aligned with tabular figures.

### Iconography

Lucide or Tabler outline icons, 1.5px stroke weight, outline by default. Filled/duotone reserved exclusively for the active/selected state in the left nav.

### Spacing

8px base grid: `4 · 8 · 12 · 16 · 24 · 32 · 48 · 64`. Card padding: 16px (Compact) or 24px (Comfortable). Section gaps: 32px.

### Density modes

- **Comfortable (default):** 16px row padding — Dashboard, Reports, back-office work.
- **Compact:** 8px row padding — Inventory and Sales tables, where seeing more rows matters more than breathing room.

Maps directly to the two real users: the Owner reviewing numbers at a desk vs. the Worker moving fast at a counter — worth keeping this framing when building any new table-heavy screen.

### Dashboard aesthetics

KPI cards in a 2–4 column grid, each with the ledger-rule top border, a Caption-style label, a large Financial Emphasis number below, deltas in Success/Error only. Flat solid fills throughout — no gradients, consistent with the border-over-shadow philosophy.

## 4. Known cleanup items in the Figma file (for whoever owns Figma next)

1. Reassign Primary's working color from 400 to 600/700 for buttons and chrome.
2. Rename/duplicate Chart/Color 3 → Secondary; Chart/Color 4 → Accent (labels only, hex values don't change).
3. Fix the Colors page's section headers, currently rendering in SF Pro Display instead of Inter Tight (leftover placeholder text).
4. Add the typography usage-map table above as annotation directly in the Typography page.
5. Turn on tabular figures for numeric contexts; add the one new Numeric/Financial style.
6. Normalize letter-spacing across weight variants at the same size.
7. Apply border-based elevation, the ledger-rule table motif, and the two density modes to actual screens — none of this requires new colors or type sizes, it's reassignment, one addition, and documentation.

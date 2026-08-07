# Design System

Built for: a mobile-first B2B dashboard used by non-technical shop owners and workers on budget Android phones, often outdoors/in bright sunlight, needing a trustworthy "financial ledger" feel with strong data-density support (tables, reports) and unambiguous status color-coding for stock and payment states. Targets shadcn/ui + Tailwind conventions so it's a direct implementation reference, not just inspiration.

This refines the palette direction the earlier Rails prototype already validated (blue primary, slate secondary, green/amber/red/sky semantic colors — see `dukaan360-rails/THEME_COLORS.md`) into a full light+dark token system with real hex/HSL values and rationale, rather than inventing a new direction from scratch.

## Color palette

Light mode is the default and primary target (outdoor, bright-sun phone use, and a "clean ledger" feel favor light over dark as the default — dark mode is a supported preference, not the baseline).

### Core tokens

| Token | Light | Dark | Notes |
|---|---|---|---|
| `--background` | `#F8FAFC` | `#0B1120` | Page background |
| `--foreground` | `#0F172A` | `#F1F5F9` | Primary text |
| `--card` | `#FFFFFF` | `#131B2E` | Card/surface background |
| `--card-foreground` | `#0F172A` | `#F1F5F9` | Text on cards |
| `--primary` | `#0F172A` | `#3B82F6` | Navy in light mode (trust, authority); brighter blue in dark mode for visibility |
| `--primary-foreground` | `#FFFFFF` | `#0B1120` | Text/icons on primary |
| `--accent` | `#0369A1` | `#38BDF8` | Interactive/CTA blue — buttons, links, active states |
| `--accent-foreground` | `#FFFFFF` | `#0B1120` | |
| `--secondary` | `#334155` | `#94A3B8` | Secondary text, less prominent UI |
| `--muted` | `#E8ECF1` | `#1E293B` | Subtle backgrounds (table stripes, disabled fields) |
| `--muted-foreground` | `#64748B` | `#94A3B8` | Secondary/caption text |
| `--border` | `#E2E8F0` | `#26324A` | Dividers, input borders |
| `--ring` | `#0369A1` | `#38BDF8` | Focus ring |

### Semantic status colors

These carry real operational meaning (stock levels, payment status) — always pair with an icon or label, never color alone, per accessibility guidance.

| Meaning | Token | Light | Dark | Used for |
|---|---|---|---|---|
| Success | `--success` | `#16A34A` | `#4ADE80` | Paid bills, stock adequate, completed transfers |
| Warning | `--warning` | `#D97706` | `#FBBF24` | Low stock, partial payment, pending approval |
| Danger | `--destructive` | `#DC2626` | `#F87171` | Out of stock, overdue credit, cancelled/deleted |
| Info | `--info` | `#0284C7` | `#38BDF8` | Neutral notices, in-transit transfers |

Each gets a `-light`/tint variant for badge backgrounds (e.g. `--success-light: #DCFCE7` light / `#052E16` dark) so status badges read as a filled pill, not just colored text — this is the pattern the current app already uses (`alert-success`, `alert-warning` classes) and should carry forward.

### Why this direction

- Navy/blue-based, not purple or teal — research into fintech/B2B palettes consistently pairs navy primary + blue accent for "professional, trustworthy, banking-adjacent" positioning, which is the right register for a ledger/credit-tracking product people trust with their money.
- Light-mode-first, high-contrast — outdoor/bright-sun phone use punishes low-contrast or midtone-heavy palettes; the light background (`#F8FAFC`) and near-black text (`#0F172A`) exceed WCAG AA comfortably.
- Green/amber/red semantic set is the same one already shipped in the v1 prototype (`success`/`warning`/`danger`) — keep it, since it's already correct and workers may already have muscle memory for it.

## Typography

| Role | Font | Why |
|---|---|---|
| UI / Latin script (headings + body) | **Inter** | Excellent legibility at small sizes on low-DPI Android screens, huge weight range, the de facto standard for data-dense SaaS UI, pairs cleanly with shadcn/ui's default conventions |
| Numeric/tabular data | Inter with `font-variant-numeric: tabular-nums` | Keeps price/quantity columns aligned in tables — critical for a billing/ledger UI; avoid a separate mono font, it's unnecessary overhead here |
| Urdu script UI (optional language mode) | **Noto Nastaliq Urdu** for display/headings, **Noto Sans Arabic** for dense body/table text | Noto Nastaliq Urdu is Google's purpose-built Nastaliq font and reads as "real" Urdu to native readers, but Nastaliq's vertical stacking makes it too tall/slow for dense tables — fall back to Noto Sans Arabic (a cleaner Naskh-style face) for anything data-dense, same pattern used by major South Asian apps that support both scripts |

**Type scale:** `12 / 14 / 16 / 18 / 20 / 24 / 32` (px), base body at **16px minimum** (avoids iOS/Android auto-zoom-on-focus and stays legible outdoors). Line-height 1.5 for body, 1.25 for headings. Weight hierarchy: 700 for headings, 500 for labels/emphasis, 400 for body — don't rely on color alone to establish hierarchy.

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700&family=Noto+Nastaliq+Urdu:wght@400;600&display=swap');
```

```js
// tailwind.config
fontFamily: {
  sans: ['Inter', 'system-ui', 'sans-serif'],
  urdu: ['Noto Sans Arabic', 'Noto Nastaliq Urdu', 'sans-serif'],
}
```

## Spacing, radius, shadow (shadcn/ui + Tailwind conventions)

- **Spacing scale:** 4px base unit (Tailwind default) — `1=4px 2=8px 3=12px 4=16px 6=24px 8=32px`. Section spacing at 24–32px, component internal padding at 12–16px, touch-target spacing minimum 8px between adjacent tappable elements.
- **Radius:** `--radius: 0.625rem` (10px) as the shadcn/ui base — cards and dialogs at full `--radius`, buttons/inputs/badges at `calc(var(--radius) - 4px)`, avoid fully-rounded (`9999px`) except for status pills and avatars. Keep radius consistent across the app; this alone is one of the fastest ways v1's UI can read as more "designed."
- **Shadow:** keep elevation minimal and consistent — `sm` for cards on a list (`0 1px 2px rgb(0 0 0 / 0.05)`), `md` for popovers/dropdowns, `lg` for modals/sheets only. Avoid heavy drop shadows; they read as dated on a data-dense financial UI. Dark mode should lean on `border` + slightly lighter `card` background rather than shadows, which barely read on dark surfaces.
- **Touch targets:** minimum 44×44px, 8px+ gap between adjacent targets — this is non-negotiable given the primary device class (budget Android, thumb-operated counters).

## Component conventions carried from v1 (keep, restyle)

- Status badges (`alert-success/warning/danger/info`) — keep the semantic classes, restyle to the filled-pill pattern above.
- Buttons: `btn-primary` (accent blue), `btn-secondary` (outline/muted), `btn-success`/`btn-warning`/`btn-danger` for confirm/destructive actions — destructive actions always get a confirmation dialog before firing, per existing app behavior.
- Tables are the primary UI surface (bills, sales, inventory, customers) — prioritize `tabular-nums`, sortable columns, and a persistent low-stock/overdue visual flag over decorative styling.

## Dark mode

Defined via the same token table above, applied through CSS variables (`:root` for light, `.dark` class or `prefers-color-scheme` for dark) — never invert colors wholesale; dark mode uses desaturated/lighter tonal variants (e.g. `--primary` shifts from navy to a brighter blue in dark mode specifically because navy-on-near-black loses contrast). Test contrast independently per mode, not assumed from light-mode values.

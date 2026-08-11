# Competitor Analysis

This combines two research passes: an initial sweep (khata/ledger apps, global tools, WhatsApp-commerce tooling) and a deeper, later pass focused specifically on Pakistan-native POS incumbents, run against real product tiers and pricing. Read this alongside [10-feature-gap-matrix.md](./10-feature-gap-matrix.md), which turns the incumbent research below into a concrete P0–P3 backlog against the current data model.

## The market splits into four segments, not one flat competitor list

### Segment A — Lightweight khata/udhaar ledger apps
**Players:** Udhaar Book, DigiKhata, Mobikhata, Zayyrah, Khatabook (India-origin, used in PK too), OkCredit.

These solve exactly one problem: replace the paper *bahi khata* for tracking who owes what, with one-tap WhatsApp/SMS reminders. No inventory, no billing, often no login friction. Mobikhata's positioning is explicit: free unlimited ledgers, offline access, WhatsApp PDF debt reminders, no subscription.

**Why this matters:** this segment proves WhatsApp reminders and dead-simple credit tracking are **already an expected baseline** in the Pakistani market — not a differentiator, a prerequisite. It's the zero-training-threshold entry point a shopkeeper adopts *before* they're ready for a real POS. Dukaan360's planned WhatsApp reminder feature (see [06-whatsapp-integration.md](./06-whatsapp-integration.md)) is catching up to table stakes here, not innovating past it — treat it with corresponding urgency, not as a nice-to-have.

### Segment B — Full POS + inventory platforms (the real competitive set)

**B1 — International product, localized for Pakistan**
- **Vyapar** — India-origin (GST-first product), running a dedicated Pakistan operation (vyaparpk.com) with PKR pricing, a local WhatsApp support line, and Roman-Urdu testimonials. Tiers: Mobile-only, Desktop-only, or Mobile+Desktop, each in Gold/Platinum, roughly **PKR 10,500–78,000/year** depending on tier and term. Positions itself across retail, wholesale, service, manufacturing, and distribution — the same breadth Dukaan360 targets. Marketed as needing zero accounting/technical knowledge. Core pitch in their own testimonial language: *"pehle manual registers use karti thi, ab sab kuch ek hi app me manage ho jata hai"* — the value prop is consolidation, not any single feature.
- **Marg ERP** — India-only today, but the deepest wholesale/distribution ERP found. Useful as a "what mature looks like" benchmark even though not a direct PK competitor: party-wise rate/discount/scheme engine, route/salesman-wise dispatch, cash/credit/split invoicing, bank reconciliation on the supplier side.

**B2 — Pakistan-native/local players**
- **iPOS** (ipos.com.pk) — operating since 1995, one of the most established. Sells hard on **FBR-IMS integration** (QR code, JSON invoice, fiscal number), offline billing, multi-store/cloud dashboards, batch/expiry + CNIC tracking (pharmacy-grade), full hardware kits (barcode scanners, label/weighing-scale printers). Closest thing to an enterprise incumbent in this space.
- **myPOS** (Lahore-based) — markets itself as a "complete online ERP," not just POS: multi-company/multi-location, purchase orders tied to supplier payments, inventory movement tracked through purchase→return→damage→sale, and **per-user role levels (Owner, Sale, Purchase)** — the same idea as Dukaan360's Owner/Worker split, just coarser.
- **Sadahisab POS** — actively marketing itself as "better than myPOS," multi-unit inventory, positioning directly against myPOS as the incumbent to unseat.
- **LookPOS** — claims "#1 overall," multi-location, full offline mode, ~$95/year entry price, 500+ PK businesses claimed.
- **CornPOS / Granet Pro** — public pricing (CornPOS ~PKR 8,000/month **per branch**; Granet Pro from PKR 2,999/month), both push offline-first architecture and **PRA (Punjab Revenue Authority) tax compliance** — lean restaurant/retail hybrid.
- **Moneypex** — explicit "Built for Pakistan" messaging: PKR-native, FBR/PRA/SRB tax sync, offline desktop billing, multi-branch centralized dashboard.
- **ManageKaro** — newer, explicitly frames itself against Vyapar and iPOS as "all-in-one" vs. "POS-only tools solve one problem" — the exact consolidation argument Dukaan360 would also want to make.

**Also referenced for a global-standard-setter view (low PK relevance today):** Zoho Inventory (explicit multi-warehouse, role-based permissions — a level of granularity worth benchmarking against even without PK localization), Square/Loyverse (fast counter-sale UX, no PKR pricing or udhaar model).

### Segment C — Restaurant-specific POS (adjacent, not core competitors)
DinePlan, Oscar POS, CISePOS, Blink — table management, KDS, online ordering/delivery. Not a direct threat to a retail/wholesale/distribution product, but some vendors (Granet Pro) straddle both restaurant and retail, which is worth knowing when reading their marketing.

### Segment D — International generalist SaaS (low Pakistan-fit today)
Square, QuickBooks POS, Loyverse, HDPOS, ERPLY — show up in "best POS Pakistan" listicles but have no PKR-native pricing, no udhaar/credit-first design, no FBR/local tax handling, and largely assume card/digital payment rails not yet dominant in cash-heavy Pakistani retail.

## Cross-cutting patterns across nearly every competitor

1. **Offline-first is a headline feature, not a footnote.** Moneypex, LookPOS, Granet Pro, CornPOS, iPOS all lead with "billing continues without internet." This is the single strongest recurring signal in both research passes — see [09-roadmap.md](./09-roadmap.md), where it stays a standing priority, not a one-time task.
2. **WhatsApp reminders/sharing are close to universal** — present even in free khata-only apps. Confirms the point above: Dukaan360's planned WhatsApp features are catching up to baseline, not leapfrogging it.
3. **Role-based access exists everywhere, but shallow.** myPOS's Owner/Sale/Purchase is the most explicit example found; none of the researched competitors describe anything as granular as Dukaan360's Worker role hiding profit specifically (see differentiators below).
4. **Tax/regulatory compliance (FBR/PRA/SRB) is becoming a 2026 selling point among local incumbents** — iPOS, Moneypex, CornPOS, Granet Pro all foreground it, even though it's explicitly out of scope for Dukaan360 right now. This is a forward-looking gap to track, not act on immediately — see [10-feature-gap-matrix.md](./10-feature-gap-matrix.md) for the timing read (currently P2, likely P0/P1 within 12–18 months as informal-economy pressure increases).
5. **Batch/expiry tracking is called out specifically for pharmacy and perishables** — directly relevant to Dukaan360's current sweets/mithai client, and the product's existing warehouse expiry-date field means it may already be ahead here for that vertical.
6. **Pricing is per-branch/location in most local tools** (CornPOS ~PKR 8,000/mo/branch; Vyapar scales by device/seat instead) — worth keeping in mind for how multi-shop plans get priced later, even though multi-shop isn't this rewrite's v1 focus.

## Table stakes (must not lag)

Customer credit/khata ledger with a running balance, basic sales/purchase invoicing and reporting, payment reminders over SMS/WhatsApp, cloud backup tied to a phone number, low-stock alerts, multi-payment-mode recording (cash/bank/mobile wallet), a simple low-literacy-friendly UI. Dukaan360 v1 already covers most of this — the gap is reminders, backup framing, and (per the deeper incumbent research) barcode scanning and supplier/purchasing, which are near-universal among the Pakistan-native POS tier specifically (Segment B2) even though absent from the khata-app tier (Segment A).

## Where the real opportunity is

1. **True offline-first billing.** The most-cited dealbreaker across both research passes — more than any feature checklist.
2. **Native JazzCash/Easypaisa integration.** Table stakes locally, absent from every non-PK competitor.
3. **Automated WhatsApp/SMS credit-reminder engine.** Vendors claim 3–4x faster credit recovery with this; described as the emotional core feature in Segment A, not a nice-to-have — and, per the incumbent research, a gap versus the *free* khata apps specifically, which is a more urgent framing than "behind paid POS competitors."
4. **Role-based access + a tamper-evident, field-level audit trail as an explicit anti-theft feature.** Dukaan360 already has this, and the deeper research confirms it: audit logging with old→new value diffs is unusually rigorous compared to every incumbent's back-office module, which typically tracks actions less visibly.
5. **Urdu/Roman Urdu as a first-class UI language**, not bolted on.
6. **AI-assisted low-friction entry** (OCR, natural-language queries) — nascent even among leaders.
7. **Expiry/waste tracking with loss reporting**, extended with expiry alerts and shrinkage analytics — a strong hook for the current sweets/mithai client and for pharmacy/grocery generally.
8. **Transparent, non-paywall pricing** — OkCredit/Khatabook draw real resentment for paywalling previously-free features.

## Two standout differentiators worth protecting and marketing (confirmed against 6 named competitors)

Nothing else surfaced across iPOS, myPOS, Marg ERP, Vyapar, Zoho Inventory, or Square/Loyverse that does either of these:

1. **A single object (the `Bill`) that natively carries both the itemized order and the udhaar/credit state.** Competitors either do billing well (POS tier) or credit tracking well (khata tier) — rarely both natively fused in one record. This is a genuine structural advantage baked into the domain model since v1; the rewrite should preserve and highlight it, not just carry it forward incidentally.
2. **Profit-visibility gating by role** — a Shop Worker sees today's sales, never profit. myPOS and Vyapar both have *some* role concept, but neither is documented as specifically protecting margin/profit data the way Dukaan360's Owner/Worker split does. This is a trust-building feature for an owner deciding whether to let staff use the system at all, and worth stating explicitly in positioning rather than leaving implicit.

## What NOT to build (confirmed across both research passes)

- **Full accounting/GL/CA-grade bookkeeping** — even Vyapar is criticized for being too basic here versus dedicated accounting software; it's a different product category and no competitor tries to be great at both.
- **Restaurant-specific features** (KDS, table management, waiter pads) — not the target vertical; several competitors (Marg, iPOS, Granet Pro) spread themselves thin trying to serve retail + restaurant + pharmacy + salon at once. Staying focused on retail/wholesale/distribution is a defensible choice, not a limitation.
- **E-commerce/online store builder** — low relevance until there's evidence customers want online ordering; don't build speculatively.
- **Multi-currency** — already correctly deferred; no researched competitor makes this a headline feature for the Pakistani market either.

## Recurring shop-owner pain points found in reviews/complaints

Distrust of digitizing records at all (frame around privacy/control, not "digital transformation"); load-shedding breaking app usability; India-first apps ignoring Pakistan (no Urdu, no JazzCash/Easypaisa); freemium bait-and-switch (OkCredit/Khatabook); sync failures and broken WhatsApp invoice attachments (Vyapar); full ERPs (ERPNext) being too complex for one shop — users explicitly ask for "a light version, lower cost"; fear of losing all records if the phone is lost.

## What this means for the rewrite, ranked by impact

1. Offline-first billing/quick-sale/khata entry that survives outages and syncs losslessly — the single most-cited dealbreaker across both research passes.
2. Native JazzCash/Easypaisa payment collection and reconciliation.
3. Automated WhatsApp credit-due reminder engine — reframed as catching up to a free-tier baseline, not innovating past paid competitors, which raises its urgency.
4. Barcode scanning + label printing and a supplier/purchasing module (vendor records, purchase orders, payables) — confirmed universal gaps against the Pakistan-native POS tier specifically; see [10-feature-gap-matrix.md](./10-feature-gap-matrix.md) for the full prioritized breakdown.
5. Sharpen the existing audit-trail/role system into an explicit anti-theft and trust-building selling point — already a genuine differentiator, currently under-marketed.
6. Urdu/Roman Urdu as a first-class UI and WhatsApp-bot language.
7. AI-assisted entry (OCR invoices, natural-language queries) — see [07-ai-features.md](./07-ai-features.md).
8. Expiry/waste tracking extended with alerts and loss reporting — pulled forward given the current sweets/mithai client, where perishability and weighing-scale-based sale are direct operational needs (see [10-feature-gap-matrix.md](./10-feature-gap-matrix.md)).
9. Flat, transparent pricing with no feature paywall creep.

Multi-shop consolidated dashboards and supplier/reorder marketplace integration remain real opportunities but stay out of scope for this rewrite's v1 per [01-vision-and-problem.md](./01-vision-and-problem.md) — though note the feature-gap research explicitly flags wholesale/distribution as a named expansion target, which is worth keeping in view even while the v1 concept stays single-shop.

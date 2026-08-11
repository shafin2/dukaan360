# Roadmap

Phased so each phase ships something usable on its own, and later phases build on infrastructure the earlier ones already stood up (Postgres schema, RLS, JWT auth, BullMQ) rather than requiring rework.

## Phase 1 — Foundation

- Design the Postgres schema translating v1's Mongoose models 1:1 in domain terms (Business, Shop, Product, ShopInventory, Bill, Sale, Customer, Payment, Return, Expense, StockTransfer, AuditLog) — same vocabulary, now with real foreign keys and check constraints (e.g. `totalPaid <= totalAmount`) instead of application-code discipline.
- **Give Quick Sale a Bill-like grouping shape** — one parent transaction record owning multiple line items, not one record per item as in v1 (client-reported gap, [11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #9). Decide this before writing the MongoDB→Postgres migration script, since existing per-item Quick Sale records need an explicit grouping strategy during migration, not just in new code.
- Stand up the Fastify (or NestJS-on-Fastify) API with Prisma, JWT auth (access + refresh tokens, tenant/shop/role claims), and Row-Level Security wired in from day one — not retrofitted later. Build and test the **full reset-password loop** (request → token → expiry/reuse rejection → set new password) as a first-class flow here, and decide explicitly whether email is mandatory at account creation or a WhatsApp/phone-based reset path fits this user base better ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #7).
- **Adopt one shared server-side convention for list endpoints**: sort + filter + paginate + aggregate-total as explicit, consistent query behavior across every table screen (Sales, Bills, Expenses, Inventory, Customers) — several client-reported bugs (wrong totals across pages, no sortable columns) trace back to this being ad hoc per-screen in v1 ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #4, #11).
- **Make audit logging structural, not a manually-remembered call** — a Prisma middleware or repository-layer wrapper that diffs old/new values on every mutation, so coverage (currently inconsistent — rigorous for stock additions, missing for product edits) becomes automatic rather than per-feature discipline ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #8).
- **Enforce snapshot-vs-live-value discipline explicitly**: sale/bill line-item prices and costs are written once at transaction time and never re-derived from the current product row; spot-sale items require a captured purchase cost at entry (no silent zero-default). Add an integration test that changes a product's price after a sale exists and asserts the historical sale is unaffected ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #5, #6).
- **Design Worker date-range restriction and profit-visibility gating as one coherent server-side permission system**, not two separate UI-hiding hacks ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #2).
- Repoint the existing Next.js frontend at the new API (REST + generated OpenAPI client), replacing direct Mongoose calls.
- Docker Compose deployment to a single EC2 instance (Caddy, web, api, worker, Postgres, Redis) with nightly Postgres backups to S3.
- Data migration script from MongoDB Atlas to Postgres, run against a copy first, verified against v1's data before any production cutover.
- Write the cross-tenant-isolation integration test before anything else ships (see [05-architecture.md](./05-architecture.md)) — this is the one thing that must never regress.

## Phase 1.5 — Product P0s from the feature-gap matrix

These come from a deeper competitive audit against 6 named vendors (see [10-feature-gap-matrix.md](./10-feature-gap-matrix.md)) and are mostly additive to the domain model established in Phase 1, not dependent on WhatsApp/AI infrastructure — they can be pulled forward or built in parallel with Phase 2/3 if urgency demands it:

- **Barcode scanning + label printing** — confirmed universal across every researched competitor tier; the current app has a printer purchased but no scanning yet.
- **Party/customer-wise custom pricing** — different rates per customer/wholesale tier on the same product; core to the wholesale/distribution expansion target flagged in [01-vision-and-problem.md](./01-vision-and-problem.md), not just a nice-to-have.
- **Supplier/vendor records + purchase orders + payables tracking** — Dukaan360 has receivables (customer side) but no payables (supplier side); the ledger model is half-built without this, and it's a baseline expectation every researched competitor has.
- **Weighing-scale integration** — pulled forward specifically because the current real client is a sweets/mithai shop selling loose, weighed goods; this is a direct operational need, not a speculative feature.
- **Thermal receipt printing** — already in progress (printer purchased), close it out.
- **Live item-count on bill/inventory forms** and a **daily purchasing-cost KPI** — small, cheap wins directly requested by the client ([11-client-feedback-requirements.md](./11-client-feedback-requirements.md) #3, #10), worth bundling in here alongside the reporting/UX work rather than treating as separate projects.

## Phase 2 — WhatsApp inbound

- WhatsApp Cloud API setup (Meta Business Manager verification), webhook endpoint with signature verification.
- Tenant-mapping table (phone_number_id/wa_id → business_id).
- Deterministic keyword router for the top 5–10 owner questions (today's sales, pending bills, low stock, who owes money, this week vs last week).
- Basic per-sender rate limiting and audit logging of WhatsApp queries.

## Phase 3 — WhatsApp outbound

- Meta Embedded Signup connection flow for shop owners to link their own number (Coexistence-enabled).
- Encrypted token storage per tenant.
- Utility-template payment-due reminder job in `worker`, triggered on a schedule against overdue bills.
- Approved-template wording library maintained internally to avoid Marketing-category reclassification.
- **Treat this phase with real urgency, not "nice to have" pacing** — deeper competitive research confirms this feature is a gap versus the *free* khata apps (Mobikhata, Udhaar Book), not just paid POS competitors. It's table stakes in this market already, and Dukaan360 is currently behind the zero-cost entry point of the category, which is a worse competitive position than being behind a premium competitor.

## Phase 4 — AI, P0

- Function-calling layer over the same internal API the WhatsApp bot already uses (`getOutstandingByCustomer`, `getLowStockProducts`, `getSalesSummary`, etc.) — extends the Phase 2 router to handle ambiguous free text, and doubles as the in-app chat feature.
- Template-based daily/weekly digest (numbers computed deterministically; LLM narrative layer added once the numbers pipeline is trusted).
- Rule-based anomaly/fraud flags over `AuditLog` (mass deletions, above-threshold discounting, refund patterns, after-hours cancellations) surfaced to the owner.

## Phase 5 — AI P1 + competitive-gap features

- OCR/vision supplier-invoice entry (confirm-before-save, never auto-commit).
- Low-stock/reorder heuristic (rolling days-of-cover), extending the existing slow-moving-stock feature symmetrically to fast movers.
- JazzCash/Easypaisa native payment integration (identified as a clear local wedge in [03-competitor-analysis.md](./03-competitor-analysis.md)).
- Offline-resilience hardening for core flows (billing, quick sale, khata entry) — the single most-cited dealbreaker in the competitive research; treat as an ongoing investment area rather than a one-time task, since it's what most differentiates the product locally.

## Deliberately deferred, not forgotten

- Multi-shop consolidated owner dashboards (data model supports it; product concept stays single-shop for this rewrite's v1 per [01-vision-and-problem.md](./01-vision-and-problem.md)).
- Voice-based sale entry (Urdu STT not reliable enough yet — see [07-ai-features.md](./07-ai-features.md)).
- Supplier/reorder marketplace integration (Dastgyr/Tajir-style) — real opportunity, but out of scope until the core rewrite is stable.
- Real ML forecasting/anomaly models — revisit once a shop has 12+ months of clean data.
- Scheme/promotion support ("buy A get B free"), route/salesman-wise dispatch tracking, and adjustment-type granularity on stock transfers — relevant once the business moves further into FMCG-style distribution, not yet.
- Cashier/shift-level accountability (till open/close, per-register reconciliation) and granular per-staff permissions beyond Owner/Worker — matter once a shop runs 2+ cashiers on rotating shifts or needs roles like Accountant/Delivery staff; not yet.
- **FBR/PRA/SRB tax compliance** — deliberately out of scope today, but flagged as the headline 2026 pitch among Pakistan-native incumbents (iPOS, Moneypex, CornPOS, Granet Pro all lead with it). Currently P2; re-evaluate within 12–18 months rather than letting it drift indefinitely — see [10-feature-gap-matrix.md](./10-feature-gap-matrix.md).

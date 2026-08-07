# Roadmap

Phased so each phase ships something usable on its own, and later phases build on infrastructure the earlier ones already stood up (Postgres schema, RLS, JWT auth, BullMQ) rather than requiring rework.

## Phase 1 — Foundation

- Design the Postgres schema translating v1's Mongoose models 1:1 in domain terms (Business, Shop, Product, ShopInventory, Bill, Sale, Customer, Payment, Return, Expense, StockTransfer, AuditLog) — same vocabulary, now with real foreign keys and check constraints (e.g. `totalPaid <= totalAmount`) instead of application-code discipline.
- Stand up the Fastify (or NestJS-on-Fastify) API with Prisma, JWT auth (access + refresh tokens, tenant/shop/role claims), and Row-Level Security wired in from day one — not retrofitted later.
- Write the cross-tenant-isolation integration test before anything else ships (see [05-architecture.md](./05-architecture.md)) — this is the one thing that must never regress.
- Repoint the existing Next.js frontend at the new API (REST + generated OpenAPI client), replacing direct Mongoose calls.
- Docker Compose deployment to a single EC2 instance (Caddy, web, api, worker, Postgres, Redis) with nightly Postgres backups to S3.
- Data migration script from MongoDB Atlas to Postgres, run against a copy first, verified against v1's data before any production cutover.

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

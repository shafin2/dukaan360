# Architecture

## Multi-tenancy model

Tenant boundary is `Business`, unchanged from v1. Implementation changes from "trust application code to filter every query" to **shared schema + `tenant_id` column on every table, enforced by Postgres Row-Level Security (RLS)**:

- Every tenant-owned table carries a `business_id` column.
- Each request sets `app.current_tenant_id` via `SET LOCAL` inside the request's transaction (a Prisma middleware wraps this), scoped to the authenticated user's business from their JWT claims.
- RLS policies on every table reject rows outside the current tenant context **at the database level** — so even a missing `WHERE business_id = ...` in a query, a bug class that directly caused several of v1's fixed bugs, can no longer leak cross-tenant data.
- Chosen over schema-per-tenant or database-per-tenant: those create real ops pain past a few dozen tenants (N migrations to run and keep in sync, catalog/connection bloat) and are overkill for the 50–200 shop range this needs to reach. Shared-schema + RLS scales cleanly to that range on one Postgres instance.
- **This is load-bearing, not decorative** — a missed `SET LOCAL` on one connection-pool code path could silently leak data across tenants. Ship a hard integration test asserting cross-tenant reads fail before onboarding a second real business.

Shop-level scoping (Business Owner sees all shops in their business, Shop Worker sees only their assigned shop) is a second, narrower filter on top of tenant RLS — same pattern, applied at the shop_id level within a tenant's already-isolated data.

## Service topology

```
                         ┌─────────────────────────┐
Internet ── HTTPS ──────▶│  Caddy (reverse proxy)   │
                         │  auto TLS via Let's       │
                         │  Encrypt, routes by host  │
                         └───────────┬──────────────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 ▼                                       ▼
        app.dukaan360.com                        api.dukaan360.com
        ┌────────────────┐                        ┌──────────────────┐
        │  Next.js (web)  │──── internal net ─────▶│  API (Fastify)    │
        └────────────────┘                        └─────────┬─────────┘
                                                              │
                                    ┌─────────────────────────┼─────────────────────────┐
                                    ▼                         ▼                         ▼
                            ┌──────────────┐         ┌───────────────┐         ┌───────────────┐
                            │  PostgreSQL   │         │     Redis      │         │  worker proc.  │
                            │ (RLS-enforced)│◀───────▶│ (cache+queue) │◀───────▶│ (BullMQ consumer)│
                            └──────────────┘         └───────────────┘         └───────┬────────┘
                                                                                        │
                                                                          jobs: WhatsApp send/receive,
                                                                          reports, digests, AI calls,
                                                                          low-stock checks, backups
                                                                                        │
                                                                                        ▼
                                                                          WhatsApp Cloud API (Meta-hosted —
                                                                          not self-hosted on this box, see
                                                                          06-whatsapp-integration.md)
                                                                                        │
                                                                                        ▼
                                                                              AWS S3 (images/files, off-box)
```

All Node services (`web`, `api`, `worker`) run from the same monorepo as separate Docker Compose services; `worker` is the same codebase as `api` with a different entrypoint that consumes BullMQ queues instead of serving HTTP.

## Deployment on a single AWS EC2 instance

- **Instance sizing to start:** `t4g.large` (Graviton/ARM, 2 vCPU/8GB) or `t3.large` (x86, same specs) if multi-arch Docker builds aren't set up yet. `t3.medium` (4GB) is too tight once Next.js + API + Postgres + Redis + a worker process run simultaneously. Reassess to an `xlarge` once tenant count pushes past ~150–200 or Postgres's working set grows.
- **Services (Docker Compose):**
  - `caddy` — reverse proxy + automatic TLS. Chosen over nginx+certbot specifically so a small team doesn't own cert-renewal cron jobs — Caddy's automatic HTTPS removes that entirely.
  - `web` — Next.js, talks to `api` over the internal Docker network.
  - `api` — Fastify (or NestJS-on-Fastify, per [04-tech-stack.md](./04-tech-stack.md)) backend.
  - `worker` — BullMQ consumer, same image as `api`.
  - `postgres` — single instance, persistent volume.
  - `redis` — cache + BullMQ broker.
  - No `evolution-api` service — the WhatsApp integration decision in [06-whatsapp-integration.md](./06-whatsapp-integration.md) uses Meta's Cloud API directly, which removes a moderately resource-hungry process from this box entirely and simplifies this topology versus the original plan.
- **Backups:** nightly `pg_dump`/`pg_dumpall` piped to S3 via a small cron container, with a 30-day retention lifecycle rule. Full WAL archiving/point-in-time recovery (pgBackRest, wal-g) is overkill at 50–200 tenants — revisit once data volume or compliance requirements justify it.
- **Zero/low-downtime deploys:** run two tagged versions of `web`/`api` behind Caddy, flip the upstream after health checks pass (simple blue-green via Caddy's dynamic config reload), or accept `docker compose up -d --no-deps --build` with brief downtime for services where that's acceptable given low overnight traffic in Pakistani retail hours. Schedule schema migrations off-hours; a few seconds of API downtime during a migration is acceptable at this scale — full blue-green for Postgres itself is not needed yet.

## Data flow for the two new surfaces

- **WhatsApp inbound:** Meta webhook → `api` (signature-verified) → tenant lookup → deterministic router or AI function-calling (read-only, tenant-scoped) → reply sent via Cloud API. No queue needed for the reply itself (it's fast), but logging/audit writes go through the normal Postgres path.
- **WhatsApp outbound (reminders):** scheduled job in `worker` (BullMQ, cron-style) queries overdue bills per tenant → enqueues one send job per reminder → `worker` sends via Cloud API using the tenant's stored Embedded Signup token → result logged.
- **AI calls (digests, OCR, anomaly summaries):** always run through `worker`, never inline in a request — keeps API response times unaffected by third-party LLM latency, and gives natural retry/backoff via BullMQ.

## What this replaces from v1

- MongoDB Atlas → self-hosted Postgres with RLS (structural tenant isolation instead of application-code discipline).
- Vercel serverless functions → Docker Compose services on one EC2 box (a home for background jobs and scheduled work that serverless can't host).
- NextAuth session-only auth → JWT auth usable by multiple services (Next.js, API, WhatsApp bot logic inside `worker`).
- Cloudinary → S3 (cheaper at scale, offloads I/O from the EC2 box).
- No queue → BullMQ + Redis, the backbone for reminders, digests, AI calls, and reports.

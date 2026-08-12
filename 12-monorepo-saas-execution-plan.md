# Karobar — Monorepo & SaaS Execution Plan

**Status:** Draft v1 · **Created:** 2026-08-12 · **Owner:** ai@aurmak.com

This document is the execution layer on top of the existing research in [`docs/01-11`](./README.md) and [`../PRD.md`](../PRD.md). Nothing below re-litigates that research — multi-tenancy design, the Postgres/Prisma/BullMQ/RLS stack, the WhatsApp Cloud API decision, AI feature phasing, the Karobar design system colors/type, and the client-feedback/competitive-gap backlog all carry forward unchanged. This document adds what changed with the domain purchase and the decision to build this as a real multi-tenant SaaS: **the monorepo shape, the karobar.tech domain split, the self-serve signup/trial/billing layer, the platform admin panel, and the concrete frontend execution stack (shadcn/ui, GSAP, mobile-first rules) for a premium feel.** Read this alongside the PRD, not instead of it.

---

## 1. What's actually changing vs. the existing PRD

| Area | Existing PRD/docs position | This plan |
|---|---|---|
| Brand | Docs already secretly agree — the design system is called the **"Karobar Design System"** (sourced from a Figma file named "Dukan-Branding"), even though the repo/product is still called Dukaan360 externally. | Make it official everywhere: product name **Karobar**, domain **karobar.tech**. This isn't a new decision, it's catching the repo up to a decision the design work already made. |
| Backend framework | [docs/04-tech-stack.md](./04-tech-stack.md) recommends bare Fastify, but explicitly leaves NestJS-on-Fastify-adapter as "a completely reasonable choice... if the team prefers its opinionated structure" — not a rejection. | We're taking that documented fallback: **NestJS on the Fastify adapter**, flat domain-scoped modules (not deeply nested). This keeps Fastify's throughput and every other stack decision in docs/04 intact, and gets Nest's DI/testing/module structure, which is worth it once WhatsApp, AI, billing, and admin are all separate concerns living in one backend. |
| Registration model | [docs/README.md](./README.md) states "No self-registration" as a **non-negotiable** carried from v1 — accounts are provisioned, not signed up. | This still holds **within a business**: a Shop Worker never self-registers, only an Owner invites them. What's new is a layer *above* that: a Business **Owner** can self-serve signup for a **new tenant** with a free trial — that's the SaaS growth motion. These are compatible, not contradictory — see §5. |
| Product surface | One app (Next.js), one deploy. | Two surfaces in **this** repo: **the app** (app.karobar.tech) and a **platform admin panel** (admin.karobar.tech) — see §2. The marketing site (karobar.tech) is a deliberately separate, entirely different repo/project — not part of this monorepo, not built here. |
| Frontend execution | Design system (colors/type/elevation) specified in [docs/08](./08-design-system.md), but no component-library or animation stack named. | Concrete stack: **shadcn/ui** (Radix-based, themed to the Karobar tokens) + **Tailwind CSS v4** + **GSAP** for premium motion, mobile-first as the default build target since most usage is on a phone. See §7. |

Everything else — Postgres schema direction, RLS multi-tenancy, BullMQ/Redis, WhatsApp Cloud API (not self-hosted Baileys), AI advisory-only guardrails, the six structural client-feedback fixes, the P0 competitive-gap features (barcode, party pricing, suppliers/purchasing, weighing scale) — is unchanged. This plan does not repeat that content; see the PRD and docs/01–11 for it.

---

## 2. Domains & surfaces

| Domain | App | Hosting | Notes |
|---|---|---|---|
| **karobar.tech** | Marketing site — landing, pricing, product tour, blog/SEO content, "Start free trial" CTA | Own choice, made in its own repo | **Explicitly out of scope for this repo.** Separate project, separate codebase, built and hosted independently — not touched by anything in this monorepo. Only shared surface between the two: the marketing site's CTA links out to `app.karobar.tech/signup`. |
| **app.karobar.tech** | The ERP itself — auth, dashboard, POS/billing, inventory, customers, reports, in-app AI chat | EC2 (Docker Compose), per [docs/05](./05-architecture.md) | This is `web` in the existing architecture diagram, unchanged in hosting, renamed in domain. |
| **api.karobar.tech** | NestJS REST API | EC2 | Same as `api` in docs/05, backing `app.` and eventually the WhatsApp webhook and admin panel. |
| **admin.karobar.tech** | Platform admin panel (Karobar staff only — not a tenant-facing feature) | EC2, same box, separate Next.js app | See §6 for why this is a separate app rather than a route inside `app.`. |

**Deployment reality, superseding the EC2/Caddy specifics in [docs/05](./05-architecture.md):** Karobar deploys to `mvp-server`, a shared EC2 box (13.204.83.93) that already runs another client project ("link-analyzer") — not a dedicated instance. Two deliberate deviations from docs/05, both because the box already had an established, working convention it was cheaper and safer to match than to replace:

- **nginx, not Caddy**, as the reverse proxy — the box already runs nginx with certbot-managed TLS for the other project; introducing Caddy would mean two proxies fighting over ports 80/443. New server blocks for `app./api./admin.karobar.tech` live in `/etc/nginx/sites-available/`, same pattern as the existing site.
- **One shared Postgres + Redis instance for the whole box, not one per project.** Karobar does not run its own database/cache containers. It joins the existing `link-analyzer_default` Docker network and connects to the already-running `postgres`/`redis` containers — a dedicated `karobar` Postgres role/database for isolation, and Redis logical DB index 1 (vs. link-analyzer's 0) to keep keyspaces separate on the shared instance. Matches how local dev already works (one shared Postgres/Redis across multiple projects on the same machine, per the resourcing decision made when this was set up).

CI/CD mirrors the existing pattern on that box exactly: `docker-compose.prod.yml` + `deploy.sh` + a GitHub Actions workflow (`appleboy/ssh-action`, `EC2_HOST`/`EC2_SSH_KEY` repo secrets) that deploys on every push to `main`. A 4GB swapfile was added to the box (it wasn't there before) since RAM is genuinely tight running two projects' worth of containers on a 3.7GB instance.

Caddy continues to route by host, now for `app.`/`api.`/`admin.karobar.tech`, per the existing topology in docs/05 — the root `karobar.tech` host isn't Caddy's concern at all since that site doesn't live on this box or in this repo.

---

## 3. Monorepo layout

```
karobar/
├── apps/
│   ├── web/          # Next.js — app.karobar.tech (the ERP)
│   ├── admin/         # Next.js — admin.karobar.tech (platform admin)
│   ├── api/           # NestJS (Fastify adapter) — api.karobar.tech
│   └── worker/        # NestJS — BullMQ consumers (WhatsApp, AI, digests, reminders, backups)
├── packages/
│   ├── ui/             # shadcn/ui components pre-themed to Karobar tokens, shared by web/admin
│   ├── database/       # Prisma schema, generated client, RLS session-scoping helpers
│   ├── domain/         # Shared business-logic services (billing calc, snapshot rules, permission checks) consumed by both api and worker
│   ├── contracts/       # Shared DTOs / Zod schemas / OpenAPI-generated types, consumed by web, admin, and api
│   ├── whatsapp/        # WhatsApp Cloud API client wrapper (webhook verify, send, template management)
│   ├── ai/              # LLM function-calling tool definitions, shared between the WhatsApp bot and in-app chat
│   ├── config/          # Shared eslint/tsconfig/tailwind base config
│   └── utils/           # Currency (PKR) formatting, date/timezone helpers — timezone bugs were a recurring v1 issue, worth centralizing once
├── docs/                 # This folder — planning docs, unchanged
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

**No `apps/marketing` here.** karobar.tech is intentionally a separate, entirely different repo — a different team/timeline/deploy target than this ERP monorepo. Nothing in this plan builds it; it's mentioned only where its existence affects this repo (e.g. the signup deep-link in §5).

**Why `api` and `worker` are two Nest apps, not one codebase with two entrypoints:** docs/05 originally described `worker` as "the same codebase as `api` with a different entrypoint," written before the NestJS decision. In Nest terms, the cleaner version of that idea is two separate Nest applications that both import `packages/domain` and `packages/database` — `api` exposes HTTP controllers, `worker` boots the same services as BullMQ processors with no HTTP surface at all. Same shared logic, no duplication, but each app has a correctly-shaped Nest module graph instead of forcing one app to conditionally behave as either a server or a queue consumer.

**Why `admin` is a separate app, not a route group inside `web` gated by a role check:** a platform-admin panel that can view/edit every tenant's data (impersonation, subscription overrides, cross-tenant metrics) is the single highest-blast-radius surface in the whole product. Keeping it a physically separate Next.js app, on its own subdomain, with its own auth session (platform-staff accounts are not `Business`-scoped users at all — a different table, not a role flag on the tenant user table) means a bug in tenant-facing auth/RBAC code can never accidentally expose admin routes, and vice versa. This costs one more app to maintain; given this is a SaaS handling other people's money and customer credit data, that cost is worth it.

**Tooling:** pnpm workspaces + Turborepo, as already recommended in [docs/04](./04-tech-stack.md) — unchanged, now just applied across four apps (`web`, `admin`, `api`, `worker`) instead of one.

---

## 4. Tech stack (deltas only — full stack in docs/04, unchanged otherwise)

| Layer | Decision |
|---|---|
| Backend framework | **NestJS on the Fastify adapter** (not Express, not bare Fastify) — module-per-domain: `auth`, `tenants`, `billing-subscriptions` (new), `shops`, `products`, `inventory`, `sales`, `bills`, `payments`, `customers`, `suppliers` (P0 gap), `returns`, `expenses`, `audit`, `whatsapp`, `ai`, `admin`. |
| ORM / DB / multi-tenancy / jobs / auth / realtime / storage | Unchanged — Prisma v7, Postgres + RLS, BullMQ + Redis, self-rolled JWT + Passport, SSE, S3. See docs/04. |
| Component library | **shadcn/ui** — not a runtime dependency; its CLI copies component source directly into `packages/ui`, themed to the exact Karobar tokens (colors, radius, elevation) from [docs/08](./08-design-system.md). Works cleanly with Tailwind v4's CSS-based config. Every app imports from `packages/ui`, never re-implements a button/input/table. |
| Motion | **GSAP** (+ `@gsap/react`'s `useGSAP` hook for safe cleanup in React, ScrollTrigger for marketing scroll effects, Flip for table row reorder/insert animations). GSAP has been **100% free, including every former paid plugin, since the Webflow acquisition (April 2024)** — no licensing cost or tier to plan around. See §7 for where motion is and isn't used. |
| Forms/tables/charts | React Hook Form + Zod for forms; **TanStack Table** + **TanStack Query** for the sort/filter/paginate/aggregate-total list convention Phase 1 already requires (docs/09); a chart library matching the four-color chart palette in docs/08 (Recharts is the simplest fit for that palette; Tremor is a reasonable alternative if pre-built KPI-card compositions save time). |
| Fonts | Inter Tight via `next/font`, per docs/08 — self-hosted through Next's font optimizer rather than the Google Fonts `<link>` shown in docs/08, since `next/font` removes the render-blocking request and is strictly better for a premium/fast feel. |
| Mobile app-like surface | No native app in this plan. Ship `app.karobar.tech` as an installable **PWA** (manifest + service worker for basic offline shell) — this gets most of "feels like an app on a shop owner's phone" without a second native codebase, and directly supports the offline-resilience priority already flagged as the single most-cited competitive dealbreaker in [docs/03](./03-competitor-analysis.md). Revisit React Native only if PWA install/engagement data says it's not enough — not a v1 commitment. |
| Testing | **Jest** for `api`/`worker` (Nest's native, best-supported runner — fighting Nest's test tooling to force Vitest isn't worth it), **Vitest** for `web`/`admin`/`packages/*` (per docs/04). **Playwright** for critical-flow E2E across both Next.js apps in this repo. |

---

## 5. The SaaS layer: self-serve signup, free trial, subscriptions

This is the one genuinely new product surface versus the existing PRD, so it gets worked through in full rather than a table row.

**Reconciling with "no self-registration":** the existing non-negotiable is about *within* a business — a Worker never creates their own account, an Owner adds them. That stays exactly as-is. What's new sits one level up: **a prospective Business Owner can create a brand-new tenant themselves**, on `app.karobar.tech/signup`, without a Karobar staff member provisioning it by hand. Once that Owner's business exists, everything below it (adding Workers, permissions, profit-visibility gating) is unchanged from the existing design. Two different trust boundaries, two different rules — both correct at their own level.

**Signup flow:**
1. Owner enters business name, shop type (grocery/sweets-mithai/pharmacy/electronics/etc. — feeds onboarding defaults), name, phone number.
2. **Phone verification via WhatsApp OTP** — not email. This reuses the WhatsApp Cloud API integration the product needs anyway (docs/06), matches how this user base actually communicates, and sidesteps the exact reset-password/email-reliability failure mode that was client-reported bug #7 in v1. Email becomes optional (useful for receipts/invoices later), never the primary identity/reset channel.
3. On verified OTP: create `Business` + first `Shop`, `subscription_status = trialing`, `trial_ends_at = now() + 14 days` (trial length is a pricing decision, not an engineering one — flagged in §8).
4. Short onboarding checklist (add first products, invite first Worker, connect WhatsApp number) rather than dropping the Owner into an empty dashboard — first-run experience matters more for self-serve conversion than for a provisioned account, since there's no one walking them through it in person.

**Trial → paid:** `subscription_status` moves through `trialing → active | past_due | canceled`. Plans are PKR-denominated tiers (naming/pricing itself is a business decision — see §8), likely gated on shop count and/or feature set (e.g. WhatsApp reminders, AI chat, multi-shop as paid-tier features) rather than per-transaction limits, since usage-based pricing is a worse fit for a shop owner who wants predictable monthly cost.

**Billing collection — the one real open problem:** there's no clean Stripe-equivalent for PKR recurring billing in Pakistan (Stripe doesn't onboard Pakistani merchants directly). Two-phase plan:
- **Phase A (ship first):** manual/invoice-based billing. System generates a monthly invoice, Owner pays via JazzCash/Easypaisa/bank transfer to Karobar's business account, a Platform Admin marks it paid in the admin panel (§6). Unglamorous but correct, and buys time to validate pricing/retention before investing in payment automation.
- **Phase B (once volume justifies it):** evaluate PKR-capable recurring-billing processors (Safepay, PayFast, or a JazzCash/Easypaisa business API integration) to automate charge → dunning → suspend-on-failure. Don't build this before there's a real base of paying tenants to justify it.

**Trial-abuse guard:** WhatsApp OTP at signup (step 2 above) is also the anti-abuse control — one trial per verified phone number, which is a meaningfully higher bar than an email-only signup form and costs nothing extra to build since the OTP flow already has to exist for password reset.

---

## 6. Platform admin panel (admin.karobar.tech)

New product surface, not present in the original single-tenant-provisioned PRD. Scope for v1:

- **Tenant list & detail** — every `Business`, its plan/trial/subscription status, shop count, last-active date.
- **Manual billing** — mark an invoice paid (Phase A billing model above), view payment history per tenant.
- **Impersonate-as-Owner** — for support, always fully audit-logged (who impersonated whom, when, what changed) using the same audit infrastructure already required for Phase 1 ([docs/09](./09-roadmap.md)) — this is not a new audit system, it's the existing one applied to a new actor type.
- **Usage/cost dashboards** — WhatsApp message volume and AI (LLM) spend per tenant, since both are genuine variable costs at scale and need visibility before pricing tiers are finalized.
- **Feature flags per tenant** — useful for staged rollout of new modules (e.g. barcode scanning, weighing-scale integration) without a full release train.

This is the natural successor to the "System Admin" role named in the original PRD (§2/docs/README.md) — same concept, renamed **Platform Admin** to avoid confusion now that "Admin" could otherwise be read as a tenant-level role, and moved to its own app per the isolation rationale in §3.

---

## 7. Frontend execution: premium, mobile-first

**Mobile-first as the literal build order, not a media-query afterthought:** every screen gets built at a 375px viewport first — including back-office screens like Reports, since the Owner checking numbers from their phone at the end of the day is a primary use case, not an edge case — then adapted up to tablet (768px, realistic for a shop counter) and desktop. This is a process rule, not just a CSS strategy: designing desktop-first and squeezing down produces the cramped, overflow-hidden mobile experience this product needs to avoid.

**Tap targets:** [docs/08](./08-design-system.md) already specifies 44px buttons on POS checkout screens specifically. Extend that 44px minimum to every primary action on every screen when viewed at mobile width, not just checkout — a Worker or Owner using this one-handed on a budget Android phone shouldn't have to zoom or mis-tap.

**Where GSAP is (and isn't) used in this repo** (the marketing site is a separate repo — its motion direction, likely just as expressive with ScrollTrigger/hero parallax, is that project's own call, not covered here):
- **App (app.karobar.tech):** restrained, purposeful only — page-transition fade/slide, KPI number count-up on dashboard load, table row insert/remove using Flip (matters for the Quick Sale / bill line-item flows that are used constantly), toast/modal enter/exit. No decorative motion competing with a Worker trying to close a sale fast at a counter.
- **Non-negotiable:** respect `prefers-reduced-motion` everywhere, and never animate a financial total in a way that could show a transiently wrong number mid-transition — correctness over polish on money figures, always.
- **Admin panel:** minimal motion — this is an operational tool for Karobar staff, not a surface that needs to feel premium to a customer.

**Component build order (packages/ui foundation before feature screens):** Button, Input/Select/Combobox (product search), Table (with the ledger-rule double-border header motif from docs/08 built in once, reused everywhere), Card (border elevation, no shadow — per docs/08), Badge/Pill (status), Modal/Dialog/Slide-over, Toast, Tabs, DateRangePicker, Sidebar/bottom-nav (mobile gets a bottom tab bar for primary actions — Sales/Inventory/Customers/More — rather than a hamburger-only pattern, since bottom nav is faster to reach one-handed), KPI stat card, empty states, skeleton loaders. Build this set once, fully themed, before any feature screen — every screen after this point is assembly, not new component design.

---

## 8. Open decisions — flagged, not blocking

These need a real answer from you before or during Phase 0/1, but shouldn't hold up starting the work below them:

1. **Trial length and plan tiers/pricing in PKR.** Needed before the `subscription_plan` enum can be finalized and before the (separately-repo'd) marketing site can build a pricing page. 14-day trial assumed above as a placeholder only.
2. **Billing collection Phase A mechanics** — which business bank account/JazzCash/Easypaisa merchant number invoices should reference, and who on the team actually marks invoices paid day-to-day.
3. ~~Marketing site hosting~~ — **moot for this repo.** karobar.tech is a separate project entirely; its hosting choice doesn't affect this monorepo's infra at all.
4. ~~Repo housekeeping before Phase 0 starts~~ — **resolved during Phase 0.** `docs/.git` is not an accidental nesting — it's a real, independent GitHub repo (`shafin2/dukaan360.git`, remote `origin`) that a colleague pushes docs updates to directly (commit history includes "Ammar feedback incoporated in docs"). Deleting or absorbing its history would have been wrong. Fix applied: `docs/` is left completely untouched and independently git-managed exactly as before; the new monorepo's root `.gitignore` excludes `docs/` explicitly so the outer repo never silently mis-tracks it as an empty submodule, and doesn't attempt to own its history either. Anyone editing docs still commits/pushes from inside `docs/` against its own remote, same as before this rewrite started.
5. **Repo/folder rename** — GitHub repo (and optionally this local folder) renamed from `Dukaan360`/`Dukaan360-Revamp` to something `karobar`-branded, for consistency with the domain. Cosmetic, low priority, but cheap to do in Phase 0 while the repo is still new.

---

## 9. Revised master phase sequence

This supersedes the *sequencing* of [docs/09-roadmap.md](./09-roadmap.md) by inserting the monorepo/brand/SaaS work at the right points — it does not change the *content* of any phase there. Every bullet in docs/09 Phases 1–5 still applies; they're referenced, not repeated. **This sequence is scoped to this repo only** — the marketing site (karobar.tech) has its own separate timeline in its own repo and isn't a phase here; the only thing this repo owes it is a stable `app.karobar.tech/signup` URL to link to.

| Phase | Scope | Notes |
|---|---|---|
| **0 — Monorepo & brand foundation** *(new)* | Scaffold pnpm+Turborepo monorepo (§3); resolve the `docs/.git` nesting issue (§8.4); DNS for `app./api./admin.karobar.tech`; `packages/ui` bootstrap (Tailwind v4 + shadcn init + Karobar design tokens + base component set from §7); CI skeleton (lint/typecheck/test/build on PR, Turborepo remote caching). | Nothing product-facing ships yet — this is the floor everything else stands on. |
| **1 — Foundation** | Exactly [docs/09 Phase 1](./09-roadmap.md) — Postgres schema, Nest+Prisma+JWT+RLS, cross-tenant-isolation test first, the six client-feedback structural fixes as acceptance criteria, v1 data migration. **Plus, layered in here:** the self-serve signup + free trial flow (§5) and WhatsApp-OTP verification/reset, since auth is being built from scratch in this phase anyway — building OTP-based signup and OTP-based reset together, once, is cheaper than building password-reset now and retrofitting OTP-based signup later. | This is the phase where "provisioned account" becomes "self-serve signup," so it's the right place to make that change, not an afterthought. |
| **1.5 — Admin panel MVP** *(new, pulled forward)* | `admin.karobar.tech`: tenant list, trial/subscription status, manual invoice-paid marking, audited impersonation, basic usage dashboard (§6). | Pulled forward ahead of most product features because a self-serve SaaS with no way to see who signed up or mark anyone as paid can't actually operate — this is infrastructure for running the business, not a nice-to-have. |
| **2 — Product P0s** | Exactly [docs/09 Phase 1.5](./09-roadmap.md) — barcode scanning + label printing, party/customer-wise pricing, supplier/vendor records + purchase orders + payables, weighing-scale integration, thermal receipt printing, live item-count, daily purchasing-cost KPI. | Unchanged from existing roadmap. |
| **3 — WhatsApp inbound** | Exactly [docs/09 Phase 2](./09-roadmap.md). | Unchanged. |
| **4 — WhatsApp outbound** | Exactly [docs/09 Phase 3](./09-roadmap.md) — payment reminders. | Unchanged; the Embedded Signup/token infrastructure here is separate from the signup-OTP use of WhatsApp in Phase 1 (one is the shop's own number reaching customers, the other is Karobar's number reaching the Owner) — don't conflate them. |
| **5 — AI, P0** | Exactly [docs/09 Phase 4](./09-roadmap.md). | Unchanged. |
| **6 — AI P1 + competitive-gap features** | Exactly [docs/09 Phase 5](./09-roadmap.md) — OCR, low-stock heuristic, JazzCash/Easypaisa, offline-resilience hardening. | Unchanged. |
| **7 — Billing automation maturity** *(new)* | Move from manual invoice-marking (Phase A, §5) to an automated PKR-capable recurring-billing processor (Phase B, §5); dunning notices via WhatsApp/email for `past_due` accounts. | Deliberately last — don't build payment automation before there's a real base of paying tenants to justify the integration cost. |

---

## 10. Testing strategy (given the "test everything" instruction)

- **The one test that ships before anything else:** the cross-tenant RLS isolation test already mandated in [docs/05](./05-architecture.md) — still the single highest-priority test in this entire plan, now with an added SaaS-specific case: a Platform Admin's impersonation session must never leak into a normal request path once the impersonation session ends.
- **Unit:** Jest for `api`/`worker`, Vitest for the three Next.js apps and `packages/*`.
- **Integration:** snapshot-vs-live-price regression (client bug #5 — change a product's price after a sale exists, assert history is unaffected), Quick Sale grouped-record shape (client bug #9), server-side list convention (sort/filter/paginate/aggregate-total, client bugs #4/#11), trial-to-paid state transitions.
- **E2E (Playwright):** signup → WhatsApp OTP verify → trial active → first sale, login, create sale/bill, quick sale, credit sale + discount (client bug #1), close bill/payment, low-stock alert, WhatsApp reminder trigger (mocked Cloud API), OTP-based password reset, admin impersonation with audit-log verification.
- **CI:** GitHub Actions — lint, typecheck, unit, integration, build, Playwright smoke on every PR; Turborepo remote caching so this stays fast as the monorepo grows across its four apps.

---

## Appendix

This plan should be read alongside, in this order: [`../PRD.md`](../PRD.md) → this document → [docs/01–11](./README.md) for any specific rationale this document references but doesn't re-derive.

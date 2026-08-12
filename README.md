# Dukaan360 Rewamp — Documentation

This folder is the planning + research base for the full technical rewrite of Dukaan360, a POS / inventory / credit-ledger ("khata") platform for local Pakistani shop owners. It does not contain code — it contains the fundamentals we agreed we needed before touching a keyboard: what's wrong with v1, what competitors do, what stack we're rebuilding on, and how WhatsApp + AI fit in.

Three research tracks feed this folder: an initial AI-driven sweep (vision, tech stack, WhatsApp, AI features, an initial design-system draft), a deeper partner-run track (Pakistani POS incumbent research, a P0–P3 feature-gap matrix, and the real Figma-sourced design system that now supersedes the initial draft), and direct client QA feedback on the live v1 app (11 concrete, ground-truth bugs and gaps). Where these overlap, the docs below are already merged — you shouldn't need to reconcile anything yourself. **This folder is meant to be sufficient on its own to start building** — read 01 → 11 in order and you have the full context.

## Reading order

1. **[01-vision-and-problem.md](./01-vision-and-problem.md)** — why we're rebuilding, who the user is, what "better" means
2. **[02-current-state-audit.md](./02-current-state-audit.md)** — what v1 (this repo) actually has today, its concrete weaknesses, and ground-truth client-reported gaps
3. **[03-competitor-analysis.md](./03-competitor-analysis.md)** — khata apps, Pakistani POS incumbents (iPOS, myPOS, Vyapar PK, and more), and global tools — market segmentation, feature table, gaps, differentiators
4. **[04-tech-stack.md](./04-tech-stack.md)** — the chosen stack and why, layer by layer
5. **[05-architecture.md](./05-architecture.md)** — multi-tenancy model, deployment topology on a single EC2 box, data flow
6. **[06-whatsapp-integration.md](./06-whatsapp-integration.md)** — inbound bot (owner → Dukaan360 number) and outbound (owner's number → customers)
7. **[07-ai-features.md](./07-ai-features.md)** — prioritized AI feature set, P0/P1/P2, cost and Urdu/Roman-Urdu notes
8. **[08-design-system.md](./08-design-system.md)** — the real Figma-sourced Karobar design system: colors, typography, spacing/radius/shadow tokens
9. **[09-roadmap.md](./09-roadmap.md)** — phased build plan, with client-reported acceptance criteria folded into Phase 1
10. **[10-feature-gap-matrix.md](./10-feature-gap-matrix.md)** — capability-by-capability P0–P3 backlog against 6 named competitors
11. **[11-client-feedback-requirements.md](./11-client-feedback-requirements.md)** — 11 concrete bugs/gaps reported directly by the client running v1, each with a specific rewrite implication
12. **[12-monorepo-saas-execution-plan.md](./12-monorepo-saas-execution-plan.md)** — execution layer on top of 01–11: the karobar.tech monorepo shape, self-serve signup/trial/billing, the platform admin panel, and the shadcn/GSAP/mobile-first frontend stack. Read this last — it assumes everything above it.

## Non-negotiables carried over from v1

- **Single shop per tenant remains the working model.** The data model should stay multi-shop-capable (v1 already supports multiple shops per business), but we are not chasing multi-shop complexity in v1 of the rewrite — we're fixing the foundation under the same concept that's already working for one shop.
- **Roles stay:** Platform Admin (renamed from System Admin, now its own app — see [12-monorepo-saas-execution-plan.md](./12-monorepo-saas-execution-plan.md)) → Business Owner → Shop Worker.
- **No self-registration *within a business*** — a Worker never signs up on their own, only an Owner adds them. This is unchanged. What's new: an Owner *can* now self-serve signup to create a brand-new tenant with a free trial — a SaaS growth layer sitting above this rule, not a contradiction of it. See [12-monorepo-saas-execution-plan.md](./12-monorepo-saas-execution-plan.md) §5.

# Dukaan360 Rewamp — Documentation

This folder is the planning + research base for the full technical rewrite of Dukaan360, a POS / inventory / credit-ledger ("khata") platform for local Pakistani shop owners. It does not contain code — it contains the fundamentals we agreed we needed before touching a keyboard: what's wrong with v1, what competitors do, what stack we're rebuilding on, and how WhatsApp + AI fit in.

## Reading order

1. **[01-vision-and-problem.md](./01-vision-and-problem.md)** — why we're rebuilding, who the user is, what "better" means
2. **[02-current-state-audit.md](./02-current-state-audit.md)** — what v1 (this repo) actually has today, and its concrete weaknesses
3. **[03-competitor-analysis.md](./03-competitor-analysis.md)** — Khatabook, Vyapar, and the rest — feature table, gaps, opportunities
4. **[04-tech-stack.md](./04-tech-stack.md)** — the chosen stack and why, layer by layer
5. **[05-architecture.md](./05-architecture.md)** — multi-tenancy model, deployment topology on a single EC2 box, data flow
6. **[06-whatsapp-integration.md](./06-whatsapp-integration.md)** — inbound bot (owner → Dukaan360 number) and outbound (owner's number → customers)
7. **[07-ai-features.md](./07-ai-features.md)** — prioritized AI feature set, P0/P1/P2, cost and Urdu/Roman-Urdu notes
8. **[08-design-system.md](./08-design-system.md)** — color palette, typography, spacing/radius/shadow tokens
9. **[09-roadmap.md](./09-roadmap.md)** — phased build plan

## Non-negotiables carried over from v1

- **Single shop per tenant remains the working model.** The data model should stay multi-shop-capable (v1 already supports multiple shops per business), but we are not chasing multi-shop complexity in v1 of the rewrite — we're fixing the foundation under the same concept that's already working for one shop.
- **Roles stay:** System Admin (platform operator) → Business Owner → Shop Worker.
- **No self-registration** — accounts are provisioned, not signed up. This is a trust/security decision worth keeping.

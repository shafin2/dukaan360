# WhatsApp Integration

## The two features

1. **Inbound bot** — a shop owner messages a dedicated Dukaan360 WhatsApp number. That number maps to their tenant, and they can ask natural-language questions ("today's sales", "pending bills", "low stock") and get answers pulled from their live data.
2. **Outbound notifications** — a shop owner connects *their own* WhatsApp number to the platform, and Dukaan360 sends messages from that number to their customers — payment-due reminders, etc.

The original idea was to self-host **Evolution API** (an open-source wrapper around **Baileys**, which reverse-engineers the WhatsApp Web multi-device protocol — not an official Meta integration) on our EC2 box for both directions, to avoid Meta's official per-message pricing. Research changed that plan.

## Decision: use the official WhatsApp Cloud API for both directions, not Evolution API

This is a reversal of the original plan, made deliberately after research, not a default. The reasoning:

- **Ban risk is real, not theoretical, and it's asymmetric with the cost we're trying to save.** One analysis of 600+ SMBs using unofficial WhatsApp automation found **68% reported at least one ban within 12 months**, with detection typically hitting within 2–8 weeks for aggressive use and "weeks to months" for wrapper tools like Evolution API. WhatsApp's detection stack includes protocol/handshake fingerprinting (Baileys' handshake differs from the real app), behavioral signals, user-report velocity, and infrastructure correlation — and a shared Dukaan360 box running many "unrelated" numbers identically is exactly the fingerprint that infrastructure-correlation detection is built to catch. Mitigations (random delays, warm-up schedules, number rotation) reduce but don't reliably eliminate this, per vendors who sell those mitigations themselves.
- **The inbound bot is the worst-case profile for this**: one shared number, replying near-instantly to many unrelated senders, is structurally identical to a spam-bot signature.
- **The outbound case is worse to get wrong**: that's a real shop owner's own personal/business WhatsApp number. A ban there is a livelihood-level failure Dukaan360 would be directly responsible for causing.
- **Meta's "Coexistence" feature (GA since May 2025) removes the old objection.** A business can connect the official Cloud API to a number *while still using the normal WhatsApp Business App on that same number* — messages mirror both ways, chat history and app access are preserved. Shop owners no longer have to choose between "use the real app" and "connect to the platform."
- **Cost is manageable, not prohibitive.** Meta moved to per-delivered-message billing (July 2025). Utility/Authentication messages (which is what a payment reminder is, if it stays purely transactional) run roughly **$0.004–$0.05 per message** in Pakistan, with automatic volume discounts, and template approval for Utility-category messages typically takes **1–5 minutes**. Replies to a conversation the customer started (the inbound bot's core case) fall inside the 24-hour Service-message window, which is free today (this changes **1 October 2026**, when Service messages inside the window also become billable — budget for this before then). Low-markup BSPs (e.g. 360dialog, ~€49/mo with near-zero per-message surcharge) can front the official API if we don't want to deal with Meta Business Manager verification directly.
- **Self-hosting doesn't actually buy us the "one EC2 box" simplicity we wanted anyway.** A Baileys-based session costs ~200–500MB RAM each (Node build), and Node's single-threaded nature means scaling past ~20–40 concurrent sessions on a shared 8–16GB box (which also has to run Next.js, NestJS, Postgres, and Redis) requires sharding across multiple hosts. At 50–200 tenants, this quietly stops being "one server" anyway — so the cost savings from avoiding Meta's per-message pricing gets eaten by needing more infrastructure, plus ongoing ban-recovery overhead (recovery takes weeks, ~30–40% first-appeal success rate).

**Where Evolution API/Baileys can still be useful:** an internal or free-tier pilot, with explicit disclosed risk, never as the default path for a paying customer's real business number. If it's used at all, treat it as a clearly-labeled "beta/unofficial" connection option, not the primary flow.

## Inbound bot architecture

1. Meta sends a webhook to our NestJS backend on every inbound message.
2. **Verify the `X-Hub-Signature-256` HMAC** against our app secret before processing anything — reject unsigned/invalid requests outright.
3. Map the receiving `phone_number_id` and sender `wa_id` to a `tenant_id` via a Postgres lookup table. **Never trust any tenant identifier embedded in the message text itself** — that's a spoofing vector.
4. Intent parsing: a **deterministic keyword/regex router for the common, well-defined queries** ("pending bills", "today's sales", "low stock") — these are financial-data queries where a hallucinated answer is unacceptable, so don't put an LLM in the critical path for the common case. Fall back to LLM function-calling only for ambiguous free text, and even then restrict the model to a **fixed allow-list of read-only, tenant-scoped internal API functions** — never let it construct raw SQL or accept a tenant id from user input. (See [07-ai-features.md](./07-ai-features.md) for the function-calling design.)
5. Call the internal NestJS API (already tenant-scoped from step 3), format the reply (PKR formatting, short WhatsApp-friendly text, Roman Urdu by default), and send via the Cloud API within the 24-hour window.
6. Rate-limit per sender to blunt abuse, and audit-log every WhatsApp query per tenant the same way in-app actions are audit-logged.

## Outbound architecture

1. Shop owner connects their number via **Meta Embedded Signup** (an OAuth-style flow through Business Manager) — this produces a durable access token we store encrypted per tenant. No daily re-linking or QR re-scanning.
2. Coexistence keeps their personal WhatsApp Business App fully usable on the same number throughout.
3. If a token is ever revoked, the UX is a re-auth prompt, not a broken integration.
4. Reminder sends use pre-approved **Utility-category templates** — this is the constraint that matters most operationally: a payment-due reminder must stay purely transactional (amount, due date, shop name). The moment it includes a discount or promotional line, Meta reclassifies it as Marketing, which is pricier and has slower/stricter approval. Keep a small internal library of approved template wording rather than improvising message text per-send.

## What this replaces from the original plan

Evolution API is no longer the transport layer for either direction in production. "Self-hosted on our own EC2 instance" now describes the app stack (Next.js, NestJS, Postgres, Redis, background workers) — not the WhatsApp connection itself, which Meta hosts. This actually simplifies the EC2 architecture in [05-architecture.md](./05-architecture.md): no persistent Baileys session processes, no session-file volume to protect, no sharding-across-hosts problem to solve later.

## Risks & mitigations to carry forward

| Risk | Mitigation |
|---|---|
| Unofficial-API ban risk | Use the Cloud API for both directions in production; never default a paying customer's real number onto Baileys |
| Template misclassification | Keep reminders strictly Utility-category; maintain an internal approved-wording library |
| Tenant data leakage via the LLM layer | Read-only, tenant-scoped function allow-list only; treat inbound message text as untrusted |
| Webhook spoofing | Always verify Meta's HMAC signature; reject unauthenticated calls |
| 24h-window pricing change (1 Oct 2026) | Budget for Service messages inside the window becoming billable |
| Rising per-tenant messaging cost at scale | Consider a low-markup BSP (e.g. 360dialog) instead of dealing with Meta directly, and/or a monthly message allowance bundled into pricing |

# Vision & Problem

## Who this is for

A local Pakistani shop owner — grocery, general store, pharmacy, electronics, clothing, wholesale/retail hybrid. Today they run the business on paper registers and memory: a notebook for who owes them money (*khata*), rough mental math on stock, and no real visibility into whether the business is actually making money. Their staff (workers) may be even less comfortable with technology than they are. Phones are budget Android devices, internet is inconsistent, and English is a second language — Urdu and Roman Urdu are how people actually think and talk about their business.

Dukaan360 digitizes that: products, stock, billing (cash/credit/partial), customers, payments, expenses, and reports — for one shop today, with the data model already able to grow to multiple shops per business later.

## Why we're rebuilding, not patching

v1 works — it's in production, used by a real shop, and the feature set (billing, inventory, stock transfers, credit, waste/expiry write-offs, audit logs, worker roles) is already fairly complete for a single shop. But market feedback consistently says "this can be much better," and the reasons are structural, not cosmetic:

- **No real backend.** Next.js API routes directly hitting MongoDB is fine for a single shop's traffic, but it means no proper job queue, no scheduled tasks (reminders, digests, backups), no clean place to put WhatsApp/AI integration logic, and every feature is coupled to the request/response cycle of a serverless function.
- **MongoDB for inherently relational, financial data.** Bills, payments, inventory ledgers, and customer balances are relational by nature (foreign keys, transactions, referential integrity). Mongoose + manual transaction handling is fighting the database instead of using it. This shows up as bugs the commit history already reflects (net collection calculation fixes, partial-bill refund fixes, timezone fixes) — categories of bugs a relational schema + proper constraints would prevent at the schema level, not the application level.
- **No automation.** Everything is manual, in-app, and reactive. A shop owner has to open the app to know if a customer's payment is overdue or if stock is running low. There is no channel that reaches them where they already are — WhatsApp.
- **No AI.** Competitors are starting to differentiate on this even in the South Asian small-business SaaS space (see [03-competitor-analysis.md](./03-competitor-analysis.md)). "Just digitizing the register" is table stakes now, not a differentiator.

## What "better" means for this rewrite

In priority order:

1. **A backend that can actually run background work** — reminders, digests, WhatsApp send/receive, scheduled reports, AI calls — without living inside a request handler.
2. **A database that enforces correctness** for money — Postgres with real transactions, constraints, and a schema that makes "bill total ≠ sum of line items" or "payment exceeds balance" structurally harder to get wrong.
3. **WhatsApp as a first-class surface**, not an app feature bolted on:
   - Shop owner texts the Dukaan360 number → gets answers from their own data ("today's sales", "pending bills", "low stock").
   - Shop owner connects their own number → platform sends customers payment reminders and other notices on the owner's behalf.
4. **AI that solves a real problem for a non-technical, Urdu-speaking shop owner** — not AI for its own sake. Natural-language querying, OCR-based product/invoice entry, and low-stock/insight digests are the priorities (see [07-ai-features.md](./07-ai-features.md)); anything that doesn't clearly help a shopkeeper in under 10 seconds of value is out of scope for v1.
5. **Self-hosted on our own AWS EC2 instance** instead of Vercel + MongoDB Atlas — full control, predictable cost, and a home for the WhatsApp bridge (Evolution API) and background workers that a serverless platform can't host.

## What stays the same

- **Single shop per tenant is still the working concept.** We are not building for multi-shop complexity in this rewrite's v1 — we're rebuilding the same concept (one business, one shop, workers, owner) on a foundation that *can* grow into multi-shop later, because v1's data model already proved that shape is right.
- **The three roles** — System Admin, Business Owner, Shop Worker — and the permission boundaries between them.
- **No self-registration.** Businesses are provisioned by the platform operator. This is a deliberate trust/quality control decision for a market where fraud and low-quality signups are a real risk, and it stays.

## Success criteria for the rewrite

- A shop owner can text the Dukaan360 WhatsApp number and get "today's sales" or "who owes me money" back in under 5 seconds, in Urdu or English.
- A customer with an overdue bill gets a WhatsApp reminder automatically, sent from the shop owner's own number, without the owner doing anything.
- Financial data integrity bugs (the kind fixed repeatedly in v1's history) become structurally much harder because Postgres constraints and transactions do the work MongoDB + application code was doing by hand.
- The whole stack — app, API, database, queue, WhatsApp bridge — runs on one AWS EC2 instance we control, at a cost that scales with real usage instead of serverless invocation pricing.

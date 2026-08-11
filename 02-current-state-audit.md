# Current State Audit (v1)

This is what exists today in this repo (`DUKAAN360`), as of 2026-08-08. It's the baseline the rewrite replaces — not to throw away the product thinking (it's good and validated by real usage), but to replace the technical foundation underneath it.

## Stack today

Next.js 15 (App Router, API routes as the only backend) · React 19 · MongoDB Atlas + Mongoose 8 · NextAuth v5 (JWT, credentials provider) · Tailwind v4 · Cloudinary (images) · Zod (validation) · SWR (client cache) · deployed on Vercel.

## Domain model (what the product actually does)

**Tenancy:** `Business` is the tenant boundary. A Business has many `Shop`s (in practice, one shop per business today). Products belong to the Business (shared catalog); inventory is tracked per shop via `ShopInventory` (shop ↔ product ↔ quantity, with min/max/reorder levels and a computed status: out_of_stock / low_stock / adequate / overstocked). There's also a business-level "warehouse" quantity on `Product` that gets distributed into shop inventory.

**Roles:** System Admin (separate `/admin` surface, approves/suspends businesses) → Business Owner (full access within their business, not tied to a shop) → Shop Worker (tied to exactly one shop, day-to-day operations only). No self-registration — all accounts are provisioned.

**Core entities:**
- `Product` — catalog item, category enum, buy/sell price, unit enum (piece/kg/liter/dozen/...), expiry date, stock thresholds, soft-deletable.
- `ShopInventory` — per-shop stock level for a product, unique on (shop, product).
- `StockTransfer` — inter-shop stock movement with a request → approve → in-transit → complete/reject workflow and a required reason.
- `Bill` — multi-line-item invoice; `billType` (cash/credit/partial), `status` (paid/pending/partial/cancelled), discount (none/amount/percent), items can be sourced from inventory or be an ad-hoc "spot" item not in the catalog.
- `Sale` — line-item-level record (can exist standalone via "quick sale" or attached to a bill), stores a **cost-price snapshot at time of sale** so profit reporting survives later price changes; tracks returned quantity/amount.
- `Customer` — per-shop contact with running `totalCredit` / `totalPaid`.
- `Payment` — payment against a customer/bill; supports cash, bank transfer, mobile payment (relevant for Pakistan — Easypaisa/JazzCash-style), cheque; supports **split payments** (part cash, part online) and categorizes payments (udhar/credit collection, at bill creation, at quick sale).
- `Return` — product return tied to a sale/bill, restocks inventory.
- `Expense` — shop-level expense tracking.
- `AuditLog` — actor + action (create/update/delete/approve/reject/cancel/import/distribute/transfer/stock_adjust) + entity type, with actor name/role **snapshotted** so history reads correctly even after a user is renamed/removed. Recently extended to cover edits and "spot sale" effects on amount-in-hand.

**Recent feature additions (from commit history)** — waste/write-off button for expired stock, refund-only option on returns, notes on bills, slow-moving-stock report, sale delete with audit trail, "net collection" (cash actually in hand accounting for quick sales and returns), worker-visible full product catalog when creating bills/quick sales, CSV import/export across products/sales/bills/customers/inventory, timezone fixes for date-based reports.

## What this tells us

The product thinking is solid and already validated by a real shop's daily use — bills, credit, split payments, stock transfers, waste write-offs, and audit trails are not naive features, they reflect real operational needs (e.g. `paymentChannel: split` and `mobile_payment` exist because Pakistani customers genuinely pay in a mix of cash and Easypaisa/JazzCash). **The rewrite should preserve this domain model almost as-is** — it just needs a database and backend that can enforce its invariants instead of relying on application code to get every calculation right by hand.

Competitive research against 6 named vendors (iPOS, myPOS, Vyapar, Marg ERP, Zoho Inventory, Square/Loyverse — see [03-competitor-analysis.md](./03-competitor-analysis.md)) independently confirms two things in this model are genuine differentiators, not just adequate: the `Bill` object natively fusing the itemized order with udhaar/credit state (no competitor does both cleanly in one object), and the Owner/Worker role split specifically gating profit visibility (Workers see today's sales, never profit — more deliberate than any researched competitor's role system). Both are worth preserving exactly as-is and marketing explicitly, not just carrying forward incidentally. The audit trail's actor-snapshotting and per-field tracking is similarly rated unusually rigorous compared to competitors' back-office modules.

## Concrete weaknesses to fix

1. **Financial correctness is being hand-rolled in application code, not enforced by the database.** The commit history shows repeated fixes to money-adjacent logic — "fix the net collection calculation," "fix partial bill refund issue," "fix bill and sale product show issue," "fix all issue created by the date edit option." These are exactly the class of bug a relational schema with real transactions, foreign-key constraints, and check constraints (e.g. `totalPaid <= totalAmount`) catches at write time instead of in production. Mongoose transactions exist but are opt-in and easy to miss on a new code path; Postgres transactions with proper constraints are structural.
2. **No background job system.** Every operation is synchronous within a Vercel function. There is no way to run a scheduled "send payment reminders at 6pm" job, a nightly low-stock digest, a slow-running report export, or a WhatsApp message queue with retries — all of which the rewrite needs.
3. **No real-time/event layer.** Two devices on the same shop (owner's phone + worker's counter tablet) don't see each other's changes without a manual refresh (SWR revalidation only, no push).
4. **Auth is app-only.** NextAuth sessions only make sense inside the Next.js app. A WhatsApp bot backend and any future mobile app need a proper token-based auth story that isn't tied to Next.js's session cookie model.
5. **Timezone handling has been a recurring bug source** (`fix timezone issue` is the most recent commit) — a symptom of doing date-boundary logic (e.g. "today's sales") in application code against a database with no native date/time type discipline.
6. **No automation or outward-reaching channel.** Everything requires the owner to open the app. There's no WhatsApp, no notifications, no AI — the app only works when someone is actively looking at it.
7. **Serverless + MongoDB Atlas cost/control tradeoff.** Fine at one shop's scale; doesn't give us a place to run Evolution API (needs a persistent, stateful process, not a serverless function) or background workers.

## Ground-truth bugs and gaps reported by the client

A functional-requirements/QA doc from the client actually running v1 confirms 11 specific, concrete issues — the most direct signal in this whole docs folder, since it's reported pain rather than inferred priority. Full detail and per-item rewrite implications in [11-client-feedback-requirements.md](./11-client-feedback-requirements.md); the headline items:

- **Quick Sale has a real data-model gap** — a multi-item quick sale is stored as N separate transaction records instead of one grouped record with line items, unlike `Bill`, which already does this correctly. This needs a schema decision in Phase 1, before any data migration runs.
- **Reset password is broken end to end**, traced to an email field that's disabled/unset on some accounts — a concrete P0 for the new JWT auth system, and a real question of whether email or a WhatsApp/phone-based reset path fits this user base better.
- **Historical price/profit snapshots aren't being honored consistently** (a later price change appears to retroactively affect past sales in at least one code path) and **spot-sale profit silently defaults to zero** because purchase cost isn't captured at entry — both are instances of the same underlying discipline gap: values that must be fixed at transaction time are instead being read live or defaulted.
- **Audit logging coverage is inconsistent** — rigorous for some flows (stock additions), missing for others (direct product edits), confirming the differentiator above is not yet true everywhere it should be.
- **List/total endpoints (Expenses, Sales, Bills) lack a consistent server-side sort/filter/paginate/aggregate-total convention** — several reported bugs (wrong running totals across pages, no sortable columns) trace back to this one missing pattern.
- **Worker date-range restriction needs to be enforced server-side**, not hidden in the frontend — the same category of control as the existing profit-visibility gating, and should be designed as one coherent permission system with it.

## What to carry forward unchanged

- The three-role model and the "no self-registration" policy.
- The Business → Shop → Worker tenancy shape (even though v1 in practice = one shop per business today).
- The bill/sale/payment/return domain vocabulary — it's already correct and shop owners understand it.
- Soft deletes for products/customers, and audit logging as a first-class concern.

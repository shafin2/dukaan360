# AI Features

Grounded rule for this whole document: **AI is advisory and narrative, not autonomous, in v1.** Nothing here auto-reorders stock, auto-refunds, or takes an action a human hasn't confirmed — this market needs trust built first, and mistakes with money are unforgivable at this stage. Dukaan360's data model (`Bill.billType/status/dueDate`, `AuditLog.action/entityType/metadata`, `ShopInventory`'s computed stock status) is already shaped well for AI tool-calling — most of what follows needs a thin function-calling layer over existing API logic, not new infrastructure.

## P0 — build first

### 1. Natural-language "ask your business data" (WhatsApp + in-app chat)
**Problem:** owners and workers don't want to navigate report menus, especially non-technical staff.
**Approach:** LLM **function-calling**, never raw SQL access. Define ~10–15 read-only tools (`getOutstandingByCustomer`, `getLowStockProducts`, `getSalesSummary(range)`, `compareSalesPeriods`, `getTopProducts`, `getPendingBills`) wrapping existing API logic. The model only picks a tool + params; the server injects `businessId`/`shopId` before ever touching the database — the model never controls tenant scope. The model then narrates the JSON result in Roman Urdu, Urdu, or English.
**Cost:** at realistic shop scale (10–50 queries/day), each query is ~500–1500 tokens in, ~100–300 out. A cheap-tier model (Claude Haiku ~$1/$5 per M tokens, or Gemini Flash ~$0.10/$0.40 per M) puts this at a fraction of a cent per query — cents per shop per month. Not worth self-hosting a model for.
**Language:** system prompt should default to Roman Urdu (matches how people actually text: "aaj ki sale kitni hui", "kis ne udhaar dena hai"), with English/Urdu-script fallback. Test against real shopkeeper phrasing before launch, not synthetic queries.
**Ties to:** [06-whatsapp-integration.md](./06-whatsapp-integration.md) uses a deterministic keyword router for the common cases first, falling back to this function-calling layer only for ambiguous free text.

### 2. AI-generated daily/weekly digest
**Problem:** owners don't open dashboards; a pushed summary is far more likely to be read and acted on.
**Approach:** **template + narrative hybrid, not pure LLM.** Compute real numbers server-side with deterministic queries (sales vs. last period, top movers, low-stock items, biggest overdue customer). Start **template-only** for the numeric facts (zero hallucination risk, near-zero cost); add a thin LLM narrative polish layer later once the numbers pipeline is trusted. Sent as the WhatsApp digest described in the vision doc.

### 3. Anomaly/fraud detection over audit logs — rule-based, not ML
**Problem:** worker deletes sales, suspicious discount patterns, refund abuse.
**Approach:** this is a case where **rules beat ML outright** at small-shop data volumes — rules are explainable, auditable, deployable immediately, and don't need the history an ML model would require (which a single shop will never generate). `AuditLog` already has `action`, `entityType`, `userId`, `metadata` — build straightforward rules: a worker deleting >N sales/day, discount% above a threshold on bills not created by the owner, repeated refunds shortly after sale by the same user, waste/stock-adjust write-offs clustering around one worker, after-hours cancellations. Flag into a review feed or WhatsApp alert. An LLM's only role here is *summarizing* a week of flags into a plain sentence for the owner ("Ali ne is hafte 3 bar bari discount di") — a P1 nicety on top of the rule engine, not a replacement for it. This directly reinforces the audit-trail-as-anti-theft-feature positioning from [03-competitor-analysis.md](./03-competitor-analysis.md).

## P1 — build after P0 is proven

### 4. OCR/vision for supplier invoice → stock entry
**Problem:** retyping supplier invoices into inventory is tedious and error-prone.
**Approach:** a **vision LLM** (Gemini Flash or GPT-4o-mini vision), not a classic OCR engine — it can read the photo *and* structure it into JSON (product name, qty, unit cost) in one call, handling messy handwritten Urdu/Roman-Urdu notes far better than Tesseract, which struggles badly with Urdu script and handwriting.
**Cost:** roughly $0.04/image on Gemini Flash — a shop scanning 30 invoices/month costs about $1.20/month.
**Rule:** always route through a confirm-before-save screen. Never auto-commit OCR output straight to inventory — price errors from a misread are costly.

### 5. Demand forecasting / low-stock reorder prediction
**Problem:** owners run out of fast movers or over-order slow movers.
**Approach:** **do not reach for a real forecasting model.** Shop-level SKU data is thin (often <90 days, sparse, seasonal noise from Eid/Ramadan spikes) — a lightweight heuristic outperforms an undertrained model here. Use rolling N-day average daily sale rate per SKU vs. current stock → days-of-cover → flag when days-of-cover < lead time. Pure arithmetic, free to compute, and a natural extension of the "slow moving stock" feature already shipped in v1 — apply the same logic symmetrically to fast movers. LLM's role is narrating the flagged list for the digest, not doing the math. Revisit a real seasonal model only once a shop has 12+ months of clean data.

### 6. Smart payment reminder tone/timing
**Problem:** generic reminders get ignored or feel abrasive to regular customers.
**Approach:** a simple rule set — days-overdue tiers → escalating tone (gentle Roman Urdu nudge at day 1, firmer at day 7+, optionally referencing relationship length). No ML needed. True "predicted best send time" personalization needs reply/open-rate history most shops won't generate for months — treat as P2.

## P2 / explicitly not v1

### 7. Voice-based quick sale entry
Feasible eventually, not worth building now. Urdu speech-to-text quality is inconsistent — Whisper shows 53–67%+ word-error-rates on Urdu in recent benchmarks. Commercial engines (Speechmatics, ElevenLabs Scribe) do much better but aren't tuned for noisy shop-floor audio with code-switched Roman Urdu numbers/product names ("do packet Lifebuoy, ek Tapal") — exactly what a sale utterance looks like. A single misheard quantity directly corrupts a bill; the error cost is asymmetric and high for financial data. Worth monitoring: Vyapar has already shipped an offline, on-device (Vosk-based) Hinglish voice assistant for this exact use case, so it's a real competitive signal — just not a v1 build. Revisit once natural-language chat (P0 #1) is live and trusted.

## What NOT to build yet

- **Self-hosted/local LLMs** — real ops burden on a constrained EC2 box for no benefit at this query volume; hosted small models are already cheap enough that self-hosting doesn't pay back.
- **Real ML forecasting/anomaly models** — insufficient per-shop data; heuristics and rules win on cost, explainability, and time-to-ship.
- **Full voice billing** — STT error rate too risky for financial data until a Urdu-specific engine is validated on real shop audio.
- **Fine-tuning any model on Dukaan360 data** — premature; prompt engineering + function-calling over a general model is sufficient.
- **Autonomous actions** (auto-reorder, auto-refund) — AI stays advisory-only in v1, full stop.

## Recommended provider approach

API-hosted, cheap-tier models — **Claude Haiku** or **Gemini Flash** for function-calling/text, **Gemini Flash** for vision/OCR (cheapest found per-image, ~$0.04 vs. GPT-4o's ~$0.98). Avoid self-hosting given EC2 constraints. Since cost is already trivial at shop scale, the deciding factor between Haiku and Flash should be tool-calling reliability and Roman Urdu fluency on real shopkeeper phrasing — worth a small bake-off before committing, not a pricing decision.

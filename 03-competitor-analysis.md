# Competitor Analysis

Research covers Indian khata/billing leaders (Khatabook, Vyapar, OkCredit, myBillBook), Pakistan-specific apps (Udhaar Book, DigiKhata, Mobikhata, Khata Master, POSify, Karobar Solution, AsaanDukaan, Oscar POS), global POS/accounting tools (Loyverse, Square, ERPNext/Frappe, Zoho Books/Inventory, QuickBooks, Wave), Pakistani B2B/procurement plays (Dastgyr, Tajir, Bazaar), and WhatsApp-commerce tooling (WhatsApp Business App, AiSensy/WATI/Interakt).

## Feature matrix

| Tool | Category | Credit/Khata | Multi-Shop | WhatsApp | AI | Offline | Urdu/Roman Urdu | Pricing |
|---|---|---|---|---|---|---|---|---|
| Khatabook (IN) | Ledger | Yes, core | Yes | Reminders | No | Yes | No (13 langs, not Urdu) | Free + paid add-ons |
| Vyapar (IN) | Billing+Inventory | Basic | Limited | Reminders (buggy) | Voice entry, OCR bill scan | Partial | No | ₹699–14,299/yr |
| OkCredit (IN) | Ledger | Yes, core | No | Reminders | No | Partial | No (11 langs) | Free, ads + new paywalls |
| myBillBook (IN) | GST Billing | Basic | Yes | Reminders+links | AI bank reconciliation | Partial | No | From ₹349/mo |
| **Udhaar Book (PK)** | Ledger+staff | Yes, core | Yes | SMS | No | Yes | Urdu, Sindhi | Free |
| **DigiKhata (PK)** | Ledger+payroll | Yes, core | No | Free, unlimited | No | Yes | Urdu, Persian, Pashto | 100% free |
| **Mobikhata (PK)** | Ledger | Yes, core | No | — | No | Yes | Urdu | Free, ad-free |
| **Khata Master (PK)** | Cloud POS+accounting | Yes | Yes | — | No | Partial | Yes | PKR 2,000/mo |
| **POSify (PK)** | POS | Yes | Yes | — | No | Yes | Yes | From PKR 2,000/mo, JazzCash/Easypaisa |
| **Karobar Solution (PK)** | POS+khata | Yes | Yes | — | No | 100% offline | Yes | Undisclosed |
| **AsaanDukaan (PK)** | POS | Basic | — | Invoices | No | — | Yes | Undisclosed |
| **Oscar POS (PK)** | POS, FBR-integrated | — | Yes | Invoices | No | Cloud+on-prem | — | Undisclosed |
| Loyverse | POS+inventory | No | Paid add-on | No | No | Partial | No | Free core, paid add-ons |
| Square | POS | No | Yes | No | No | Yes | No | Not usable in PKR |
| ERPNext/Frappe | Full ERP | No | Yes | No | No | Yes | No | Free/self-hosted, needs a developer |
| Dastgyr/Tajir/Bazaar (PK B2B) | Procurement/BNPL | Bazaar: yes | N/A | — | No | — | Tajir: Urdu | Free app, margin on goods |
| Zoho Books/Inventory | Accounting | No | Yes (Enterprise) | No | Zia AI | No | No | Free–$275/mo |
| QuickBooks | Accounting | No | Yes | No | Limited | No | No PK localization | From $38/mo |
| Wave | Accounting | No | No | No | No | No | No | Free / $19/mo |
| WhatsApp Business App | Catalog/orders | No | No | Native | No | N/A | N/A | Free |
| AiSensy/WATI/Interakt | WA automation | No | N/A | Native+bots | Basic AI agents | N/A | N/A | $49–187/mo — overbuilt for one shop |

## Table stakes — must not lag on these

- Customer credit/khata ledger with a running balance
- Basic sales/purchase invoicing and reporting
- Payment reminders over SMS/WhatsApp
- Cloud backup tied to a phone number (survives device loss)
- Low-stock alerts on inventory
- Multi-payment-mode recording (cash / bank / mobile wallet)
- Simple, low-literacy-friendly UI — every serious PK player leads with this

Dukaan360 v1 already covers most of this (credit/khata via Bill+Payment+Customer, low-stock via ShopInventory status, split cash/online payments). The gap is reminders and cloud backup framing, not the core ledger.

## Where the real opportunity is (few or no competitors do this well)

1. **True offline-first billing.** Load-shedding and patchy PTCL internet are repeatedly cited as the actual dealbreaker in this market — more than any feature checklist. Khatabook/Vyapar/OkCredit are only partially offline; a handful of PK-specific apps (Karobar Solution, Mint POS) market full offline as their headline. This matters more for a single physical shop than almost anything else on this list.
2. **Native JazzCash/Easypaisa integration.** Table stakes locally, absent from every India-first or global tool. Dukaan360 already models `mobile_payment` and split payments — wiring an actual JazzCash/Easypaisa API in is a clear, cheap wedge.
3. **Automated WhatsApp/SMS credit-reminder engine tied to due dates.** Vendors in this space claim 3–4x faster credit recovery with automated reminders — this is described as the emotional core feature of khata apps, not a nice-to-have. This is exactly the "outbound" WhatsApp use case already planned (see [06-whatsapp-integration.md](./06-whatsapp-integration.md)).
4. **Role-based access + a tamper-evident audit trail as an explicit anti-theft feature.** Dukaan360 already has this (`AuditLog` with snapshotted actor identity, recently extended to edits and spot-sale effects) — no competitor solves worker-theft/shrinkage well, and it directly answers the top qualitative owner complaint (trusting staff with the register).
5. **Urdu / Roman Urdu as a first-class UI language**, not bolted on. PK-specific apps do this; every India-first or global competitor (Khatabook, Vyapar, OkCredit, Zoho, QuickBooks) does not.
6. **AI-assisted low-friction entry** — OCR invoice scanning, voice entry — is nascent even among the leaders (only Vyapar and myBillBook attempt it) and entirely absent from PK-specific apps. See [07-ai-features.md](./07-ai-features.md) for the concrete build plan.
7. **Expiry/waste tracking with loss reporting.** Dukaan360 already has a waste/write-off button for expired stock — extending it with expiry alerts and shrinkage analytics is a strong, cheap hook for pharmacies (where DRAP compliance makes batch/expiry logging a legal expectation) and grocery.
8. **Transparent, non-paywall pricing.** OkCredit and Khatabook both draw real user resentment for paywalling previously-free features and creeping ads/KYC friction. A flat, predictable price is a trust play in a price-sensitive, subscription-wary market.

## Recurring shop-owner pain points found in reviews/complaints

- Distrust of digitizing records at all (tax-averse, cash-first culture) — framing needs to emphasize privacy/control, not "digital transformation."
- Load-shedding breaks app usability — repeatedly named as a dealbreaker.
- India-first apps ignore Pakistan entirely: no Urdu, no JazzCash/Easypaisa, no local support.
- Freemium bait-and-switch (OkCredit/Khatabook) — previously free features later paywalled.
- Sync failures and data mismatches (Vyapar), broken WhatsApp invoice attachments.
- Full ERPs (ERPNext) are too complex for a single shop — needs a dedicated developer, users explicitly ask for "a light version, lower cost."
- Fear of losing all records if the phone is lost — cloud recovery tied to a phone number is a repeated trust-builder in competitor marketing.

## What this means for the rewrite, ranked by impact

1. Offline-first billing/quick-sale/khata entry that survives outages and syncs losslessly after — the single most-cited dealbreaker locally; worth real architectural attention (see [05-architecture.md](./05-architecture.md)).
2. Native JazzCash/Easypaisa payment collection and reconciliation.
3. Automated WhatsApp credit-due reminder engine (the outbound WhatsApp feature) — highest-leverage single feature for retention.
4. Sharpen the existing audit-trail/role system into an explicit anti-theft selling point.
5. Urdu/Roman Urdu as a first-class UI and WhatsApp-bot language, not an afterthought.
6. AI-assisted entry (OCR invoices, natural-language queries) — see [07-ai-features.md](./07-ai-features.md).
7. Expiry/waste tracking extended with alerts and loss reporting.
8. Flat, transparent pricing with no feature paywall creep.

Multi-shop consolidated dashboards and supplier/reorder integration (à la Dastgyr/Tajir) are real opportunities too, but out of scope for this rewrite's v1 per [01-vision-and-problem.md](./01-vision-and-problem.md) — the concept stays single-shop-per-tenant for now.

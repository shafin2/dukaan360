# Feature Gap Matrix

Feature-by-feature audit of Dukaan360's current capabilities against 6 named competitors across three tiers: **Pakistani incumbents** (iPOS, myPOS), **Indian-origin/adjacent** (Vyapar, localized for PK; Marg ERP, India-only but the deepest wholesale/distribution ERP found — a "what mature looks like" benchmark), and **international generalist** (Zoho Inventory, Square/Loyverse). See [03-competitor-analysis.md](./03-competitor-analysis.md) for the fuller market-segment context these vendors sit in.

**Priority key:** P0 = build next, P1–P3 = later, in decreasing urgency. "Working" priorities below reflect this research pass — reconcile against the roadmap in [09-roadmap.md](./09-roadmap.md) before treating as final commitments.

## A. Multi-location & inventory movement

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Multi-shop/branch management | ✅ Native (Shop module) | iPOS, myPOS, Marg — all strong, proven at scale | None significant — already core to the design, not bolted on | High | Keep as-is |
| Warehouse→Shop distribution | ✅ Distribute Stock, 1:1 | Marg (route/area-wise dispatch), iPOS | Route/salesman-level dispatch tracking | Med — matters more once there's delivery staff/routes | P2 |
| Shop→Shop transfer | ✅ Native, requires a reason | iPOS (reason/adjustment codes) | Adjustment *types* (damage vs. shrinkage vs. correction) beyond free-text reason | Med | P2 |
| Multi-warehouse (plural warehouses, not just one central) | ❌ Single warehouse today | Zoho Inventory (explicit multi-warehouse), Marg | Real gap only if 2+ actual warehouses exist (not shops) | Low today, rises with scale | P3 — revisit if the business model needs 2+ warehouses |
| Barcode-based stock movement | ❌ Planned (printer purchased, no scanning yet) | iPOS (full hardware ecosystem), Vyapar, Zoho, Marg — universal | Real gap — barcode is table stakes across every tier | High | **P0** |

## B. Sales, billing & returns

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Quick/counter sale flow | ✅ Native, toggles cleanly between Quick/Inventory sale in one form | Loyverse, Square (extremely fast checkout) | Minor UX polish only | High | P3 |
| Party/customer-wise custom pricing | ❌ Not evidenced | Marg (Party Wise Rate/Discount/Scheme), Vyapar (Party Wise Item Rate) | **Real gap for a wholesale-distribution business** — retail vs. wholesale buyers need different rates on the same product; this is core to the named expansion target, not a nice-to-have | High | **P0/P1** |
| Scheme/promotion support ("buy A get B free") | ❌ Not evidenced | Marg (explicit scheme engine) | Relevant once moving beyond a single sweets shop into FMCG-style distribution | Med-High for the distribution vertical | P2 |
| Returns with type (restock/no-refund/etc.) | ✅ Native, 3 types, owner-confirmed real-world logic | iPOS (sale/return/damage as separate states) | Minor — could add a "Damage" type distinct from the current 3 | Med | P3 |
| Split/partial invoice payment | ✅ Native (Bill Full/Partial) | Marg (Cash/Credit/Split invoice) | None significant | High | Keep as-is |

## C. Credit / udhaar & customer management

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Udhaar/credit-native billing | ✅ `Bill` object, native | Vyapar (reminders only, not credit-native); khata apps (credit-native but no inventory) | **None significant — this may be a real differentiator.** No researched competitor combines credit tracking + inventory + billing in one object as cleanly. Protect and highlight this. | Very High | Keep as-is, market it |
| WhatsApp payment reminders | ❌ Planned | Khata apps (Mobikhata, Udhaar Book) — near-universal; Vyapar mentions it peripherally | **Real, urgent gap — behind the *free* khata apps here, not just paid POS players** | Very High | **P0** |
| Customer balance/ledger view | ✅ Native (Customers module) | myPOS, iPOS (customer ledgers) | None significant | High | Keep as-is |

## D. Purchasing & suppliers

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Supplier/vendor records | ❌ Not built | All 6 competitors have this | Real gap — baseline expectation | High | **P0** |
| Purchase orders | ❌ Not built | myPOS (Advanced Supplier Payment), iPOS, Marg (ERP-to-ERP ordering), Zoho | Real gap, universal | High | **P0** |
| Supplier payables tracking | ❌ Not built | iPOS, myPOS, Marg (some go as far as bank reconciliation) | Real gap — Dukaan360 has receivables (customer side) but no payables (supplier side); the ledger model is half-built | High | **P0/P1** |
| Import purchase bills from supplier files (Excel/CSV/PDF) | ❌ Not built | Marg | Lower priority — nice-to-have once purchasing exists at all | Med | P2, after the purchasing module exists |

## E. Roles, accountability & security

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Owner/Worker role split | ✅ Native, profit hidden from Worker | myPOS (Owner/Sale/Purchase); Vyapar (predefined, non-customizable — users complain) | **None significant — more deliberate than any of the 6.** Financial visibility is specifically gated, which none of the researched competitors document doing. Highlight in positioning. | High | Keep as-is |
| Customizable/granular permissions per staff member | ❌ Only 2 fixed roles | Zoho Inventory (role-based permissions, done well); Vyapar users explicitly request this and it's criticized for not having it | Real gap once roles beyond Owner/Worker are needed (e.g. Accountant, Delivery staff) | Med — matters as team size grows | P2 |
| Cashier/shift-level accountability (till open/close, per-register reconciliation) | ❌ Not evidenced | myPOS (separate register per cashier) | Real gap, matters once a shop has 2+ cashiers on rotating shifts | Med-High for retail counters | P1/P2 |
| Audit log with old→new value diffs | ✅ Native, already rigorous, field-level | Back-office modules generally track this less visibly | **None — this is unusually rigorous already.** Keep and market it as a positioning asset. | Med (owners value it; workers rarely notice) | Keep as-is |

## F. Tax / compliance / regulatory

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| FBR/PRA/SRB/KPRA integration | ❌ Deliberately deferred | iPOS (broadest — all 4 authorities), Moneypex, Marg (GST/e-invoice/e-way bill equivalent) | Real, growing gap — increasingly the headline 2026 pitch among PK incumbents, even though deliberately deprioritized for now | Rising from Med→High over time | P2 now, **likely P0/P1 within 12–18 months** as informal-economy pressure increases |

## G. Hardware & physical operations

| Capability | Dukaan360 today | Best competitor reference | Gap | PK relevance | Priority |
|---|---|---|---|---|---|
| Thermal receipt printing | 🔶 In progress (printer purchased) | Universal across all 6 | Closing already | High | P0 (already underway) |
| Barcode scanning + label printing | ❌ Not built | iPOS (full catalog), Vyapar, Zoho, Marg — universal | Real gap | High | **P0** |
| Weighing-scale integration (loose/weighted goods) | ❌ Not built | iPOS (serial + label weighing scales), Loyverse (weighted barcodes) | **Directly relevant to the current sweets/mithai vertical** — loose mithai is typically sold by weight | High for the current client | **P1 — worth pulling forward given it fits the existing client directly** |

## Working priority summary

**P0 (build next):** barcode-based stock movement + scanning + label printing, party/customer-wise custom pricing, supplier/vendor records, purchase orders, WhatsApp payment reminders.

**P0/P1 (right after):** supplier payables tracking, weighing-scale integration for the sweets vertical.

**P1/P2:** cashier/shift-level accountability, scheme/promotion support, route/salesman-wise dispatch tracking, adjustment-type granularity on transfers.

**P2, rising to P0/P1 within 12–18 months:** FBR/PRA/SRB tax compliance — not urgent today, but every Pakistan-native incumbent is foregrounding this as their 2026 pitch; don't let it drift past the point where it becomes a competitive blocker.

**P3 / revisit later:** multi-warehouse (plural), damage as a distinct return type, granular per-staff permissions beyond Owner/Worker, purchase-bill import from files.

## What this does NOT change

The two standout differentiators identified in [03-competitor-analysis.md](./03-competitor-analysis.md) — the `Bill` object fusing billing and udhaar state, and profit-visibility gating by role — have no competing gap in this matrix. They're marked "keep as-is" everywhere they appear above; the priority is marketing them more explicitly, not building anything new.

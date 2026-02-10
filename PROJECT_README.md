# Dukaan360 — Complete Project Documentation

> **Multi-Tenant POS & Inventory Management System for Local Businesses**

Dukaan360 is a comprehensive web-based Point of Sale (POS) and inventory management platform designed specifically for local Pakistani market businesses. It enables business owners to manage multiple shops, workers, products, inventory, sales (cash & credit), customers, billing, and payments — all from a single unified dashboard. The system supports multi-tenancy, meaning one deployed application serves multiple independent businesses with complete data isolation.

---

## Table of Contents

1. [Project Idea & Vision](#1-project-idea--vision)
2. [Tech Stack](#2-tech-stack)
3. [User Roles & Access Levels](#3-user-roles--access-levels)
4. [Multi-Tenancy Architecture](#4-multi-tenancy-architecture)
5. [System Admin (Super Admin) — What They Can Do](#5-system-admin-super-admin--what-they-can-do)
6. [Business Owner — What They Can Do](#6-business-owner--what-they-can-do)
7. [Shop Worker — What They Can Do](#7-shop-worker--what-they-can-do)
8. [Complete Business Workflow](#8-complete-business-workflow)
9. [Two-Tier Inventory System](#9-two-tier-inventory-system)
10. [Sales & Billing Workflow](#10-sales--billing-workflow)
11. [Credit System & Payments](#11-credit-system--payments)
12. [Stock Transfer Workflow](#12-stock-transfer-workflow)
13. [Reports & Analytics](#13-reports--analytics)
14. [Permission System](#14-permission-system)
15. [Database Schema & Relationships](#15-database-schema--relationships)
16. [Authentication System](#16-authentication-system)
17. [Frontend Architecture](#17-frontend-architecture)
18. [Key Business Rules & Constraints](#18-key-business-rules--constraints)
19. [PWA Support](#19-pwa-support)
20. [Setup & Installation](#20-setup--installation)

---

## 1. Project Idea & Vision

### The Problem
Local Pakistani market shop owners (grocery stores, pharmacies, electronics shops, clothing stores, etc.) typically manage their businesses manually — using paper registers for sales, manually tracking inventory, and keeping credit records in notebooks. When a business grows to multiple shops, this becomes unmanageable. There's no visibility into which shop is performing well, what's in stock where, who owes money, or how the overall business is doing.

### The Solution
Dukaan360 provides a **complete digital management system** where:
- A **System Admin** (the platform operator) creates businesses on the platform
- A **Business Owner** manages their entire business — multiple shops, workers, products, inventory, and sees consolidated reports
- **Shop Workers** handle day-to-day operations — selling products, creating bills, managing customers, and accepting payments
- Everything is **scoped to the business** — each business only sees its own data, ensuring complete isolation

### Key Design Principles
- **Simplicity first** — designed for non-technical shop owners and workers
- **Mobile-responsive** — works on phones, tablets, and desktops
- **No self-registration** — all accounts are created by admins or business owners for security

---

## 2. Tech Stack

| Technology | Purpose |
|---|---|
| **Ruby on Rails 8.0.2** | Backend framework |
| **PostgreSQL** | Database |
| **Devise** | Authentication (dual: AdminUsers + Users) |
| **ActiveAdmin** | System admin panel |
| **TailwindCSS v3** | UI styling with custom theme colors |
| **Hotwire (Turbo + Stimulus)** | SPA-like interactivity without heavy JS |
| **Alpine.js** | Lightweight JS for interactive components |
| **Importmap** | JavaScript module loading (no bundler) |
| **Propshaft** | Asset pipeline (Rails 8 default) |
| **Will Paginate + Kaminari** | Pagination |
| **Puma** | Web server |
| **Feather Icons + FontAwesome 6** | Icons |

---

## 3. User Roles & Access Levels

The system has **three distinct user roles**, each with different access levels:

### 🔴 System Admin (Super Admin)
- Accesses the platform at `/admin`
- Has a **completely separate authentication** system (`AdminUser` model via ActiveAdmin)
- Can see and manage **all businesses, shops, and users** across the entire platform
- This is the **platform operator**, not a business user

### 🟠 Business Owner (`role: 0`)
- A regular user with the `business_owner` role
- Belongs to exactly **one business**
- Does **NOT** belong to any specific shop — they oversee all shops
- Has **full access** to everything within their business
- Can create/manage shops, workers, products, inventory, and view all reports
- Cannot access data from other businesses

### 🟢 Shop Worker (`role: 1`, default)
- A regular user with the `shop_worker` role
- Belongs to exactly **one business** AND exactly **one shop**
- Can only see and interact with data from **their assigned shop**
- Handles day-to-day operations: selling, billing, customer management
- Cannot access other shops, cannot manage products or inventory at business level

---

## 4. Multi-Tenancy Architecture

Dukaan360 follows a **single-database, shared-schema multi-tenancy** model where **Business is the tenant boundary**.

### How Isolation Works

```
Platform (Dukaan360)
├── Business A (Grocery Store Chain)
│   ├── Shop 1 (Main Branch)
│   │   ├── Worker 1
│   │   ├── Worker 2
│   │   ├── Customers of this shop
│   │   ├── Bills created here
│   │   └── Shop-level inventory
│   ├── Shop 2 (City Branch)
│   │   ├── Worker 3
│   │   ├── Customers of this shop
│   │   ├── Bills created here
│   │   └── Shop-level inventory
│   ├── Products (shared across all shops)
│   ├── Business-level inventory (unassigned stock)
│   └── Business Owner (oversees everything)
│
├── Business B (Pharmacy)
│   ├── Shop 1
│   │   └── ...
│   ├── Products
│   └── Business Owner
│
└── System Admin (can see all businesses)
```

### Data Scoping Rules
- Every query in controllers is scoped: `current_user.business.products`, `current_user.business.shops`, etc.
- Products belong to a business (not a shop) — they are shared resources distributed to shops
- Customers belong to a shop (not a business) — they are shop-level contacts
- Bills and Sales belong to a shop — created by workers at that shop
- ShopInventory links products to specific shops with individual stock levels
- StockTransfers can only happen between shops within the same business

---

## 5. System Admin (Super Admin) — What They Can Do

The System Admin operates through a dedicated **ActiveAdmin panel** at `/admin`. They are the **platform operator** — the person or team running the Dukaan360 service.

### System Admin Capabilities

#### Business Management
- **Create new businesses** with details:
  - Business name (must be unique across the platform)
  - Description
  - Business type (Retail, Wholesale, Restaurant, Pharmacy, Electronics, Clothing, Grocery, Other)
  - Contact email and phone
  - Address
  - Logo URL
  - Primary and secondary brand colors (hex values)
  - Website URL
  - Custom settings (JSON)
  - Active/inactive toggle
- **View all businesses** with shop count and user count
- **Edit/delete any business**
- **Deactivate businesses** without deleting data

#### Shop Management
- **Create shops** and assign them to a business
- **View all shops** across all businesses with worker count
- **Edit/delete any shop**

#### User Management
- **Create users** (business owners or shop workers)
  - Assign them to a business
  - Assign workers to a specific shop
  - Set their role (business_owner or shop_worker)
  - Set password
- **View all users** across all businesses
- **Filter users** by name, email, business, shop, role

#### Dashboard
- View **platform-wide statistics**: total businesses, shops, users
- See **recent businesses** and **recent users** tables

#### Admin User Management
- Create/manage other system admin accounts

---

## 6. Business Owner — What They Can Do

The Business Owner is the primary operator of a business on the platform. They log in through the main application (not `/admin`) and see a **comprehensive dashboard** with everything related to their business.

### Business Owner Capabilities

#### Dashboard & Overview
- **Total sales** across all shops (today, this month, last month)
- **Monthly growth percentage** compared to previous month
- **Total bills** and **total customers** across all shops
- **Total receivables** (outstanding credit amounts)
- **Shop-wise performance breakdown** — sales per shop
- **Recent sales and bills** across all shops
- **Top 5 products** by revenue
- **Inventory alerts** — low stock, out of stock, unassigned products

#### Product Management
- **Create products** for the business:
  - Name (2-100 characters)
  - Category (Grains, Oil, Dairy, Beverages, Meat, Spices, Snacks, Cleaning, Personal Care, General, etc.)
  - Buying price and selling price (selling must be > buying)
  - SKU, description, image URL
  - Unit type (piece, kg, gram, liter, ml, dozen, pack, box, bag, bottle, can, jar, tube, roll, set, pair, bundle, carton, sack, other)
  - Expiry date (required for perishable categories like grains, oil, dairy, meat)
  - Stock levels: min, max, reorder point
  - Initial business inventory quantity
- **View all products** with search, filter by category, and sorting
- **Edit/delete products**
- **Add stock** to business-level inventory
- **Assign/distribute stock** from business inventory to shops

#### Inventory Management
- **View complete inventory status** across all shops
- **Summary stats**: total business inventory, total shop inventory, inventory value, low stock count, unassigned products
- **Filter inventory** by shop, status (low stock, out of stock, overstocked, adequate)
- **Distribute products** to multiple shops at once (adjust quantities across shops)
- **Transfer stock** directly between shops
- **Restock** individual shop inventory items
- **View low stock items** across all shops
- **Stock movement report** — history of all transfers with date filtering and CSV export
- **Valuation report** — per-shop breakdown of inventory value (cost vs. selling price)
- **Movement history** — audit trail of all stock transfers

#### User/Worker Management
- **Create shop workers** — name, email (password defaults to `password123`)
- **Assign workers to shops** — a worker can only be assigned to one shop
- **View all workers** with their assigned shops
- **Edit/delete workers**
- **Reset worker passwords** (resets to `password123`)

#### Stock Transfer Management
- **View all stock transfers** across all shops
- **Approve pending transfers** requested by workers
- **Reject transfers** with a reason
- **Complete approved transfers** — this actually moves the inventory
- **Cancel transfers**
- **Bulk approve** multiple transfers at once
- **View pending approvals** dashboard

#### Reports & Analytics
- **Sales Dashboard**:
  - Total revenue, today's sales, this month's sales, last month's sales
  - Monthly growth percentage
  - Shop-wise performance comparison
  - Top 10 products by revenue
  - Monthly trend data
  - Date period filtering (today, this week, this month, this quarter, this year, custom range)
- **Sales by Shop Report**: drill down into individual shop sales with date filtering
- **Receivables Report**: outstanding credit bills, overdue items (30+ days)
- **Inventory Report**: comprehensive product-level view with shop allocations, stock values

---

## 7. Shop Worker — What They Can Do

Shop Workers handle the daily operations at their assigned shop. They see a **personalized dashboard** focused on their shop's data.

### Shop Worker Capabilities

#### Dashboard
- **Personal sales metrics**: today's sales, this month's sales, total sales
- **Customer count** at their shop
- **Pending bills** count
- **Shop inventory status** (in stock, low stock, out of stock items)
- **Recent activities** (latest sales and bills)
- **Top 5 products** they've sold

#### Quick Sales
- **Create quick sales** from their shop's inventory:
  - Select product (from their shop's available stock)
  - Enter quantity and unit price
  - System validates stock availability
  - Sale is recorded and shop inventory is decremented
- **View their sales** with today/total/monthly stats
- **View sale details**

#### Bill Management
- **Create Cash Bills**:
  - No customer required
  - Add multiple line items (product + quantity + price)
  - System auto-generates a unique bill number
  - Inventory is decremented for each item
  - Sale records are created automatically
  - Status is automatically set to "cash"
- **Create Credit Bills**:
  - Must select/create a customer
  - Add multiple line items
  - Set a due date
  - Inventory is decremented immediately
  - Status starts as "pending"
  - Sale records are NOT created until bill is fully paid
- **View their bills** with pending count and total receivables
- **Edit/delete bills**

#### Customer Management
- **Create customers** at their shop:
  - Name, phone, address
  - Customer is linked to the worker's shop
- **View their customers** with outstanding balances
- **Edit customers**
- **Delete customers** (blocked if customer has existing bills)
- **View customer details** with their bills and payment history

#### Payment Collection
- **Record payments** against credit bills:
  - Select customer and bill
  - Enter payment amount (cannot exceed outstanding amount)
  - Select payment method and date
  - System automatically:
    - Updates bill status (pending → partial → paid)
    - Updates customer's total_paid and total_credit
    - When bill becomes fully paid, creates Sale records for credit items

#### Stock Transfer Requests
- **Request stock transfers** from their shop to another shop:
  - Select product, destination shop, quantity, and reason
  - System validates stock availability
  - Transfer goes to "pending" status for business owner approval
- **View transfers** involving their shop
- **Cancel their own transfer requests**

---

## 8. Complete Business Workflow

Here's the **end-to-end journey** from platform setup to daily operations:

### Phase 1: Platform Setup (System Admin)
```
1. System Admin logs into /admin
2. Creates a Business → "Ali's Grocery Chain"
   - Sets business type: Grocery
   - Sets brand colors: green primary, dark secondary
   - Activates the business
3. Creates the Business Owner account → "Ali Khan" (role: business_owner)
   - Assigns to "Ali's Grocery Chain"
4. Ali receives his credentials and logs in
```

### Phase 2: Business Setup (Business Owner)
```
1. Ali (Business Owner) logs in → sees empty dashboard
2. Creates Shop 1 → "Main Branch, Gulberg"
3. Creates Shop 2 → "City Branch, Model Town"
4. Creates Worker accounts:
   - "Ahmed" → assigned to Main Branch
   - "Hassan" → assigned to City Branch
5. Creates Products:
   - "Basmati Rice 5kg" → buying: Rs.800, selling: Rs.950, unit: bag
   - "Cooking Oil 1L" → buying: Rs.400, selling: Rs.480, unit: bottle
   - "Sugar 1kg" → buying: Rs.120, selling: Rs.145, unit: kg
   - Sets business_inventory_quantity: 100 bags rice, 50 bottles oil, 200 kg sugar
6. Distributes inventory to shops:
   - Main Branch: 60 rice, 30 oil, 120 sugar
   - City Branch: 40 rice, 20 oil, 80 sugar
   - (Remaining stays in business inventory as reserve)
```

### Phase 3: Daily Operations (Shop Workers)
```
Ahmed (Main Branch Worker) logs in:

CASH SALE:
1. Customer walks in, buys 2 bags of rice → Ahmed creates a cash bill
2. Adds line item: Basmati Rice 5kg × 2 = Rs.1,900
3. Saves bill → inventory decremented (60 → 58), sale recorded, bill marked "cash"

CREDIT SALE:
1. Regular customer "Imran" comes in, wants to buy on credit
2. Ahmed creates customer "Imran" (phone, address)
3. Creates credit bill for Imran:
   - Rice × 5 = Rs.4,750
   - Oil × 2 = Rs.960
   - Total: Rs.5,710, due date: 30 days
4. Inventory decremented immediately (rice: 58 → 53, oil: 30 → 28)
5. Bill status: "pending", Imran's total_credit: Rs.5,710

PAYMENT COLLECTION:
1. Imran comes in after 15 days, pays Rs.3,000
2. Ahmed records payment → bill status changes to "partial"
3. Imran's total_paid: Rs.3,000, outstanding: Rs.2,710
4. Later, Imran pays remaining Rs.2,710
5. Bill status changes to "paid" → Sale records are now created
6. Imran's outstanding: Rs.0
```

### Phase 4: Inventory Management (Business Owner)
```
Ali (Business Owner) checks dashboard:
1. Sees "Low Stock Alert" — Main Branch rice is at 53 (min level: 10)
2. Goes to Inventory → Distribute
3. Assigns 20 more bags from business inventory to Main Branch
4. Business inventory: 100 → 0 (already distributed), but Ali added more stock earlier

STOCK TRANSFER:
1. Hassan (City Branch) has excess oil (20 bottles) but Main Branch is running low
2. Hassan requests transfer: 10 bottles oil → Main Branch
3. Ali sees pending approval → approves it
4. Ali completes the transfer → City Branch: 20 → 10, Main Branch: 28 → 38
```

### Phase 5: Reporting (Business Owner)
```
End of month, Ali checks Reports:
1. Total sales across both shops: Rs.245,000
2. Monthly growth: +15% vs last month
3. Main Branch outperforming City Branch (Rs.150,000 vs Rs.95,000)
4. Top products: Rice leading, followed by Oil
5. Total receivables: Rs.12,000 still outstanding from 4 customers
6. 2 bills overdue (> 30 days) — need to follow up
7. Inventory value: Rs.180,000 across both shops
8. Low stock alert: Sugar running low at City Branch
```

---

## 9. Two-Tier Inventory System

This is a **core design feature** of Dukaan360 that enables multi-shop inventory management.

### Level 1: Business Inventory (`business_inventory_quantity` on Product)
- This is the **unassigned/reserve stock** owned by the business
- Not tied to any specific shop
- Think of it as the "warehouse" or "godown" stock
- Only the Business Owner can add stock here
- Stock must be **assigned/distributed** to shops before it can be sold

### Level 2: Shop Inventory (`ShopInventory` model)
- This is the **per-shop allocated stock**
- Each shop has its own inventory record for each product
- Has its own min/max stock levels and reorder points
- This is what workers sell from
- When a sale happens, this quantity is decremented

### How Stock Flows
```
[Business adds stock]
        ↓
[Business Inventory] ←── (Business Owner adds stock)
        ↓
[Assign/Distribute to shops]
        ↓
┌───────────────────────────┐
│  Shop 1 Inventory (qty)   │ ←→ [Stock Transfer] ←→ │ Shop 2 Inventory (qty) │
└───────────────────────────┘                          └────────────────────────┘
        ↓                                                        ↓
[Worker sells]                                          [Worker sells]
        ↓                                                        ↓
[Quantity decremented]                                  [Quantity decremented]
```

### Inventory Statuses
Each `ShopInventory` item has a calculated status:
- **Out of Stock**: quantity = 0
- **Low Stock**: quantity ≤ min_stock_level
- **Overstocked**: quantity > max_stock_level
- **Adequate**: everything else

### Stock Level Constraints
- `min_stock_level` ≥ 0
- `max_stock_level` > `min_stock_level`
- `reorder_point` ≥ `min_stock_level`
- Alerts are triggered when stock hits reorder_point or min_stock_level

---

## 10. Sales & Billing Workflow

There are **two paths** to record a sale in Dukaan360:

### Path 1: Quick Sale (Simple)
- Worker selects product → enters quantity and price → done
- Creates a `Sale` record directly
- Decrements shop inventory
- No bill generated, no customer needed
- Best for: walk-in cash customers buying one item

### Path 2: Bill-Based Sale (Full)
- Worker creates a `Bill` with multiple line items (`BillItem`)
- Each line item specifies: product, quantity, unit_price
- Bill has a type: **cash** or **credit**
- Bill number is auto-generated: `{ShopCode}{YYMMDDHHMMSS}{RandomSuffix}`

#### Cash Bill Flow
```
Worker creates bill (type: cash)
    ↓
Adds line items (products, quantities, prices)
    ↓
Saves bill
    ↓
System automatically:
  ├── Decrements shop inventory for each item
  ├── Creates Sale records for each line item
  ├── Sets bill status to "cash"
  └── Done — no payment tracking needed
```

#### Credit Bill Flow
```
Worker creates bill (type: credit) for a Customer
    ↓
Adds line items (products, quantities, prices)
    ↓
Sets due date
    ↓
Saves bill
    ↓
System automatically:
  ├── Decrements shop inventory for each item (immediately)
  ├── Sets bill status to "pending"
  ├── Updates customer's total_credit
  └── Does NOT create Sale records yet
    ↓
Customer makes payments over time
    ↓
Each payment:
  ├── Records payment amount and method
  ├── Updates bill status (pending → partial → paid)
  └── Updates customer's total_paid
    ↓
When bill is fully paid:
  ├── Status changes to "paid"
  ├── Sale records are created for each line item
  └── Revenue is now counted in reports
```

### Bill Statuses
| Status | Meaning |
|---|---|
| `cash` | Cash bill — fully paid at creation |
| `pending` | Credit bill — no payments made yet |
| `partial` | Credit bill — some payments made |
| `paid` | Credit bill — fully paid |
| `cancelled` | Bill was cancelled |

### Important Business Rule
> **Credit sales are NOT counted as revenue until the bill is fully paid.** This means the Sales reports and dashboard metrics only reflect *collected* revenue, not *billed* revenue. Receivables are tracked separately.

---

## 11. Credit System & Payments

### Customer Model
- Customers are created by workers and scoped to a specific shop
- Each customer tracks:
  - `total_credit` — total amount billed on credit
  - `total_paid` — total amount paid so far
  - `outstanding_balance` = total_credit - total_paid

### Payment Recording
- Payments are recorded against a specific bill
- Payment amount cannot exceed the bill's outstanding amount
- Supports multiple payment methods (cash, bank transfer, etc.)
- Each payment triggers a cascade:
  1. Payment saved
  2. Bill's `update_status!` called
  3. Bill recalculates: total_paid vs total_amount
  4. Bill status updated (pending/partial/paid)
  5. Customer totals recalculated
  6. If bill becomes "paid" → Sale records created

### Receivables Tracking
- Business Owner can view all outstanding credit across all shops
- Overdue bills (> 30 days past due) are highlighted
- Per-customer breakdown available

---

## 12. Stock Transfer Workflow

Stock transfers move inventory **between shops** within the same business.

### Transfer Lifecycle
```
[Worker/Owner Initiates Transfer]
  ↓ (status: pending)
[Business Owner Reviews]
  ├── Approve → (status: approved)
  │     ↓
  │   [Business Owner Completes]
  │     ↓ (status: completed)
  │   [Inventory moved: source - qty, destination + qty]
  │
  ├── Reject → (status: rejected)
  │   [Rejection reason recorded]
  │
  └── Cancel → (status: cancelled)
      [Cancellation reason recorded]
```

### Transfer Statuses
| Status | Meaning |
|---|---|
| `pending` (0) | Awaiting approval |
| `approved` (1) | Approved, ready to complete |
| `in_transit` (2) | In transit (for future use) |
| `completed` (3) | Inventory has been moved |
| `cancelled` (4) | Transfer was cancelled |
| `rejected` (5) | Transfer was rejected by owner |

### Validation Rules
- Source and destination shops must be **different**
- Both shops must belong to the **same business**
- Source shop must have **sufficient stock**
- Reason must be 10-500 characters
- Only pending transfers can be approved/rejected
- Only approved transfers can be completed

### Bulk Operations
- Business owners can approve multiple pending transfers at once from the pending approvals dashboard

---

## 13. Reports & Analytics

Reports are **only available to Business Owners** and provide comprehensive business intelligence.

### Main Reports Dashboard (`/reports`)
- **Total sales** (overall + time-segmented)
- **Today's sales** vs **this month's** vs **last month's**
- **Monthly growth %** (this month vs. last month)
- **Total bills** and **total customers**
- **Total receivables** (outstanding credit)
- **Shop-wise performance** — comparison table
- **Top 10 products** by revenue
- **Monthly trend** — chart data for sales over time
- **Date filtering** — today, this week, this month, this quarter, this year, custom date range

### Sales by Shop Report (`/reports/sales_by_shop`)
- Drill into individual shop performance
- Filter by specific shop and date range
- Paginated sales list

### Receivables Report (`/reports/receivables`)
- All pending and partial credit bills
- Overdue calculation (bills > 30 days past due)
- Customer-level outstanding amounts

### Inventory Report (`/reports/inventory_report`)
- Product-level view with shop allocations
- Business inventory vs shop inventory breakdown
- Total inventory value
- Low stock items highlighted

### Inventory-Specific Reports (via Inventory Controller)
- **Stock Report** — date-filtered transfer history with CSV export
- **Valuation Report** — per-shop cost vs selling value analysis
- **Movement History** — complete audit trail of stock movements

---

## 14. Permission System

### Current Implementation: Simple Role-Based
The system currently uses a **simple two-role authorization** model via the `Authorizable` concern:

#### Business Owner Permissions
- `can?` **always returns true** for any action within their business
- Full access to all resources: products, inventory, users, reports, transfers

#### Shop Worker Permissions
Limited to:
| Permission | Description |
|---|---|
| `view_products` | Can see products in their shop |
| `create_sales` | Can create sales at their shop |
| `view_sales` | Can see their own sales |
| `create_customers` | Can create customers at their shop |
| `view_customers` | Can see their shop's customers |
| `create_bills` | Can create bills at their shop |
| `view_bills` | Can see their own bills |

### Future Implementation: Granular Permission System (Built but Dormant)
The database has a full **granular permission system** ready to be activated:

#### `permissions` Table
- Each permission has: `name`, `resource`, `action`, `category`, `system_permission`
- Example: `name: "view_products"`, `resource: "products"`, `action: "view"`, `category: "inventory"`

#### `user_permissions` Table (Pivot)
- Links users to permissions
- Can be **shop-scoped** — a user might have permission X at Shop A but not Shop B
- Has a `granted` boolean — permissions can be explicitly denied
- Supports notes for audit trail

> **Note:** This granular system is fully modeled but the `Authorizable` concern currently bypasses it with the simpler role-based checks. It's ready to be wired up when needed.

---

## 15. Database Schema & Relationships

### Entity Relationship Overview

```
                    ┌──────────────┐
                    │  AdminUser   │ (Platform Admin - separate auth)
                    └──────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                          BUSINESS (Tenant)                           │
│                                                                      │
│  ┌──────────┐     ┌──────────┐     ┌───────────┐                    │
│  │ Business │────<│   Shop   │────<│   User    │                    │
│  │  Owner   │     │          │     │ (Worker)  │                    │
│  │  (User)  │     └────┬─────┘     └─────┬─────┘                   │
│  └──────────┘          │                  │                          │
│                        │                  │                          │
│  ┌──────────┐    ┌─────┴──────┐    ┌─────┴─────┐   ┌──────────┐   │
│  │ Product  │───<│ShopInvent. │    │ Customer  │──<│   Bill   │   │
│  │          │    │ (per-shop  │    │           │   │          │   │
│  │          │    │   stock)   │    └───────────┘   └────┬─────┘   │
│  └────┬─────┘    └────────────┘                         │          │
│       │                                           ┌─────┴─────┐    │
│       │         ┌──────────────┐                  │ BillItem  │    │
│       ├────────<│    Sale      │                  └───────────┘    │
│       │         └──────────────┘                                    │
│       │                                           ┌───────────┐    │
│       └────────<│StockTransfer │                  │  Payment  │    │
│                 └──────────────┘                  └───────────┘    │
│                                                                      │
│  ┌────────────┐    ┌────────────────┐                               │
│  │ Permission │───<│ UserPermission │ (dormant granular perms)      │
│  └────────────┘    └────────────────┘                               │
└──────────────────────────────────────────────────────────────────────┘
```

### Complete Model Relationships

#### Business
```
has_many :shops
has_many :users
has_many :products
has_many :shop_inventories
has_many :stock_transfers
has_many :customers, through: :shops
has_many :bills, through: :shops
has_many :sales, through: :shops
```

#### Shop
```
belongs_to :business
has_many :users
has_many :shop_inventories
has_many :products, through: :shop_inventories
has_many :sales
has_many :customers
has_many :bills
has_many :outgoing_transfers (StockTransfer, foreign_key: :from_shop_id)
has_many :incoming_transfers (StockTransfer, foreign_key: :to_shop_id)
```

#### User
```
belongs_to :business
belongs_to :shop (optional — only for shop_workers)
has_many :products (as creator)
has_many :sales
has_many :customers
has_many :bills
has_many :payments
has_many :user_permissions
has_many :permissions, through: :user_permissions
```

#### Product
```
belongs_to :business
belongs_to :user (creator, optional)
has_many :shop_inventories
has_many :shops, through: :shop_inventories
has_many :sales
has_many :bill_items
has_many :stock_transfers
```

#### Bill
```
belongs_to :customer (optional — not needed for cash bills)
belongs_to :user
belongs_to :shop (optional)
has_many :bill_items (accepts_nested_attributes)
has_many :payments
has_many :products, through: :bill_items
has_many :sales
```

---

## 16. Authentication System

### Dual Authentication Architecture
Dukaan360 uses **two completely separate Devise authentication systems**:

#### 1. Admin Authentication (`AdminUser`)
- **Route:** `/admin`
- **Purpose:** System admin panel access
- **Features:** Database auth, password recovery, remember me
- **Managed by:** ActiveAdmin
- **Completely isolated** from business user authentication

#### 2. Business User Authentication (`User`)
- **Route:** `/users/sign_in`
- **Purpose:** Business owners and shop workers
- **Features:** Database auth, password recovery, remember me
- **Registration is DISABLED** — no self-signup
- **Accounts are created by:** System Admin (via ActiveAdmin) or Business Owner (via worker management)
- **Default password:** `password123` (for workers created by business owners)
- **After login redirect:** Dashboard (business owner or shop worker, context-dependent)

### Session Flow
```
User visits site → Landing page (HomeController#index)
    ↓
Clicks "Login" → Devise sign-in form
    ↓
Authenticates → Redirect based on role:
  ├── AdminUser → /admin dashboard
  └── User → /dashboard (business owner or worker view)
```

---

## 17. Frontend Architecture

### Layouts
The application uses **three main layouts**:

1. **`application`** — General pages (home, landing) with top navigation bar
2. **`dashboard`** — Main application layout with:
   - Collapsible sidebar (products, inventory, sales, bills, customers, payments, reports, team management)
   - Top header bar with user info and logout
   - Content area
   - Responsive — sidebar collapses on mobile
3. **`devise`** — Authentication pages (clean login/register forms)

### Dynamic Branding
Each business has custom `primary_color` and `secondary_color` that are injected as CSS custom properties:
```css
:root {
  --primary-color: #3B82F6;      /* From business.primary_color */
  --secondary-color: #1F2937;    /* From business.secondary_color */
}
```
This means every business sees the application in their own brand colors.

### JavaScript Framework
- **Turbo** (Hotwire) — SPA-like navigation without full page reloads
- **Stimulus** — Lightweight JS controllers for interactive behaviors
- **Alpine.js** — Used for dropdowns, modals, toggles
- **No heavy frontend framework** (no React, Vue, etc.) — keeps it fast and simple

### Key UI Components
- Searchable product select dropdowns
- Payment modals
- Stock status badges (color-coded)
- Expiry status indicators
- Responsive data tables with pagination
- Flash message notifications
- Sidebar navigation with active state indicators

### Internationalization (i18n)
- Default: English
- Supported: Urdu (RTL layout), Arabic
- Custom fonts: Inter (English), Amiri + Cairo (Arabic/Urdu)
- Locale switcher in navigation

---

## 18. Key Business Rules & Constraints

### Product Rules
- Selling price must be **greater than** buying price
- Product name: 2-100 characters
- Expiry date must be in the future
- Expiry date is **required** for perishable categories (grains, oil, dairy, meat, beverages, snacks)
- Products are unique by name within a business
- Unit must be one of: piece, kg, gram, liter, ml, dozen, pack, box, bag, bottle, can, jar, tube, roll, set, pair, bundle, carton, sack, other

### Inventory Rules
- Stock quantities must be ≥ 0
- max_stock_level must be > min_stock_level
- reorder_point must be ≥ min_stock_level
- A product can only have one ShopInventory record per shop
- Shop and product must belong to the same business
- Cannot assign more stock to a shop than available in business inventory
- Cannot sell more than available shop inventory

### Billing Rules
- Bill number must be unique per shop+user combination
- Total amount must be > 0
- Cash bills don't require a customer
- Credit bills require a customer and should have a due date
- Inventory is decremented at bill creation time (for both cash and credit)
- Payment amount cannot exceed outstanding bill amount

### Transfer Rules
- Source and destination shops must be different
- Both shops must be in the same business
- Source must have sufficient stock
- Only pending transfers can be approved/rejected
- Only approved transfers can be completed
- Stock is only moved when transfer is "completed" (not at approval)

### User Rules
- Business owners must NOT have a shop assigned
- Shop workers MUST have a shop assigned
- Email must be unique across all users
- Users cannot self-register — accounts are always created by admins or business owners
- A user belongs to exactly one business

---

## 19. PWA Support

Dukaan360 has **PWA (Progressive Web App) scaffolding** in place:

- **Manifest file** (`manifest.json`) — defines app name "Dukaan360", standalone display mode
- **Service Worker** (`serviceworker.js`) — exists but currently only has push notification stubs (commented out)
- **Status:** PWA support is **scaffolded but not actively enabled** — the manifest link in the layout is commented out

When enabled, users will be able to install Dukaan360 as a native-like app on their phones, with offline capabilities and push notifications.

---

## 20. Setup & Installation

### Prerequisites
- Ruby (version compatible with Rails 8.0.2)
- PostgreSQL
- Node.js (for TailwindCSS compilation)
- Bundler

### Installation Steps
```bash
# Clone the repository
git clone <repository-url>
cd dukaan360

# Install Ruby dependencies
bundle install

# Install JavaScript dependencies
yarn install  # or npm install

# Setup database
rails db:create
rails db:migrate
rails db:seed  # Creates default admin: admin@example.com / password123

# Compile TailwindCSS
rails tailwindcss:build

# Start the server
bin/dev  # Starts Rails + Tailwind watcher
```

### Default Credentials
| Role | Email | Password |
|---|---|---|
| System Admin | admin@example.com | password123 |

### First Steps After Setup
1. Log into `/admin` with the system admin credentials
2. Create a Business
3. Create a Business Owner user and assign to the business
4. Log out of admin, log in as the Business Owner
5. Create Shops, Workers, and Products
6. Distribute inventory to shops
7. Workers can now log in and start selling

---

## Summary

Dukaan360 is a **complete multi-tenant POS system** with:
- ✅ **3-tier user hierarchy** — System Admin → Business Owner → Shop Worker
- ✅ **Complete data isolation** — each business is a separate tenant
- ✅ **Two-tier inventory** — business pool + per-shop allocation
- ✅ **Dual billing** — cash (instant) and credit (tracked with payments)
- ✅ **Stock transfers** — between shops with approval workflow
- ✅ **Comprehensive reporting** — sales, receivables, inventory, trends
- ✅ **Custom branding** — per-business colors and identity
- ✅ **Role-based access** — business owners see everything, workers see their shop
- ✅ **Multi-language** — English, Urdu (RTL), Arabic
- ✅ **Mobile responsive** — works on all devices
- ✅ **PWA ready** — scaffolding for offline/installable app

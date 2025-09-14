# Dukaan360

Dukaan360 is a simple inventory and sales management system built for local Pakistani markets.  
It is designed to be **mobile responsive and user-friendly** so even people with little technical knowledge can use it (similar to WhatsApp or other daily apps).

---

## Project Overview
- A system admin manages businesses using **Active Admin** at `/admin`.
- Each business has one **business owner** (account created by system admin).
- Business owner logs into the main website to manage:
  - Products / Inventory
  - Shops
  - Shop workers
  - Sales, profits, and losses
- Business owner adds **products** → they go into **business-level inventory**.
- Business owner assigns stock to **shops**.
- Shop workers log in to:
  - View only their shop’s assigned products.
  - Sell products (cash or credit).
  - For credit sales, workers must create a **customer** (already implemented).
- Business owner can see:
  - Stock assigned to each shop.
  - Remaining inventory (unassigned stock).
  - Sales, profits, and losses.
- Role-based privileges will be added later.

---

## App Flow
1. **System Admin**
   - Creates businesses and business owners.
   - Creates shops for each business.
2. **Business Owner**
   - Adds products → inventory.
   - Assigns inventory to shops.
   - Creates workers for shops.
   - Monitors sales, profits, losses, and stock.
3. **Shop Worker**
   - Logs in with worker account.
   - Sees only products assigned to their shop.
   - Makes sales (cash or credit).
   - Cannot access business-level inventory.

---

## Tech Stack
- **Backend**: Ruby on Rails 8
- **Frontend**: Tailwind CSS (custom theme)
- **Database**: PostgreSQL
- **Admin Panel**: Active Admin
- **Architecture**: MVC with Concerns & Helpers

---

## Coding Practices
- Follow Rails 8 best practices.
- Use **single responsibility functions** (keep methods small and focused).
- Follow **DRY** principle (Don’t Repeat Yourself).
- Use **Concerns** and **Helpers** for reusable logic.
- Keep **controllers thin** (business logic should not live in controllers).
- Use **partials** in views, avoid long view files.
- Keep design **simple and mobile-friendly** (no over-engineering).

---

## Goals
- Provide a **POS-like system** for local markets.
- Make it **easy to use** for non-technical shop owners and workers.
- Help businesses manage stock, shops, workers, and sales in one place.

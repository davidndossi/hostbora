# Customer Rent summary template

This template mirrors the layout recoverable from **`Customer Rent.numbers`** (Apple Numbers). The `.numbers` file is a ZIP of protobuf-based **`.iwa`** shards; cell text is not stored as plain CSV inside the bundle.

## What was recovered from the source file

| Evidence | What it suggests |
|----------|-------------------|
| `Index/Document.iwa` (strings) | Sheet/tab title **“Rents details”**; locale/currency hints **FCFA**, **XAF**; paper **iso-a4**; calendar **gregorian**; **Africa/Dar_es_Salaam** appears in `CalculationEngine-905420.iwa`. |
| `Index/Tables/DataList-905303.iwa` (strings) | Detailed rent rows: **name**, **room no**, **rent/month**, **rent period**, **start**, **expry** (expiry), **date**, **amt paid**, **remarks**; fragments consistent with **amount not paid** / **to pay** style notes. |
| `Index/Tables/DataList-905343.iwa` (strings) | Section labels **GROUND FLOOR**, **FIRST FLOOR**, **SECOND FLOOR**, **THIRD FLOOR**; column-like tokens **NAME**, **AMOUNT**, **PAID**, **STATUS**, **CONTRACT**, **DURATION**, **CO-HOST**; partial **FROM** (likely part of a date range or a “from / to” contract field). |
| `HeaderStorageBucket-*.iwa` | No plain ASCII header text was extractable with `strings`; **exact column order** in Numbers may differ slightly from the order below. |

**Limitation:** Row values, formulas, and precise column order were **not** decoded from the binary IWA format; the tables below are a **faithful structural mirror** of the strings that appeared in the bundle, plus sensible defaults where the file was opaque.

---

## Table A — “Rents details” (monthly / payment tracking)

Use one row per tenant (or per tenant × period row, matching how you used the original sheet).

### Column headers (copy as header row)

| Name | Room No. | Rent / month | Rent period | Start | Expiry | Date | Amt paid | Amount owing / not paid | Remarks |
|------|-----------|----------------|-------------|-------|--------|------|----------|---------------------------|---------|
| | | | | | | | | | |

### Row template (empty)

```text
Name          | 
Room No.      | 
Rent / month  | 
Rent period   |   (e.g. month name or “Jan–Mar 2025”)
Start         |   (lease or period start)
Expiry        |   (lease or period end)
Date          |   (payment date or statement date)
Amt paid      | 
Amount owing  |   (optional; aligns with “amt not” / “to pay” fragments in source)
Remarks       | 
```

### How to fill — Table A

1. **Rent / month** — contracted monthly rent (FCFA/XAF in the original workbook).
2. **Rent period** — the month(s) or billing window this row covers.
3. **Start / Expiry** — lease boundaries or the valid range for that rent line.
4. **Date** — when payment was received or recorded.
5. **Amt paid** — amount received this period.
6. **Amount owing / not paid** — carry-forward or shortfall; leave blank if you track balance elsewhere.
7. **Remarks** — advances, partial payments, WhatsApp/SMS notes, etc.

---

## Table B — Tenant summary by floor

The source contained **floor band titles** and **ALL-CAPS** field names typical of a summary block (not necessarily a single Numbers “table” in one piece).

### Section structure

Repeat the block for each floor:

1. **GROUND FLOOR**
2. **FIRST FLOOR**
3. **SECOND FLOOR**
4. **THIRD FLOOR**

### Column headers (per floor block)

| Name | Amount | Paid | Status | Contract | Duration | Co-host |
|------|--------|------|--------|----------|----------|---------|
| | | | | | | |

Optional extra columns if your original had explicit from/to dates (the string **FROM** appeared without a matching **TO** in the extract):

| … | Contract from | Contract to | … |
|---|----------------|---------------|---|

### Row template (empty)

```text
Name       | 
Amount     |   (total due or contract total — match your original meaning)
Paid       |   (Y/N, amount, or status text)
Status     |   (e.g. Active, Arrears, Notice)
Contract   |   (reference or link text)
Duration   |   (e.g. “12 months”, date range)
Co-host    |   (name or blank)
```

### How to fill — Table B

1. Group tenants under the correct **floor** heading.
2. **Amount / Paid / Status** — keep definitions consistent (e.g. Amount = monthly vs total contract).
3. **Contract / Duration** — store either human-readable text or ISO dates in **Contract from / to** if you add those columns.
4. **Co-host** — secondary host or partner on the listing; leave blank if not used.

---

## Optional: CSV files in this folder

| File | Purpose |
|------|---------|
| `customer_rent_details_template.csv` | Header row for **Table A**. |
| `customer_rent_tenant_summary_template.csv` | Header row for **Table B** (no floor column; add a **Floor** column in Numbers/Excel if you prefer one flat file). |

---

## Re-import tip

To match Numbers again: create two sheets (**Rents details** and **Tenant summary**), paste headers, apply **FCFA** or **XAF** currency to money columns, and set the document timezone to **Dar es Salaam** if you rely on local dates.

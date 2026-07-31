# Sales & Order Management Analytics — SQL + Power BI

End-to-end analytics project on a real-world e-commerce transaction dataset, 
built to answer 5 core business questions using PostgreSQL for data cleaning/
analysis and Power BI for dashboarding.

## Dataset
UCI "Online Retail II" — real UK-based online gift retailer transactions, 
Dec 2009–Dec 2011. Combined two source sheets into 1,067,371 raw rows.

## Data Quality Issues Found & Handled
- ~20% of rows missing Customer ID (excluded from customer-level analysis, 
  noted as a caveat)
- Negative-quantity rows not flagged as cancellations turned out to be manual 
  stock adjustments (damages, loss) — separated into their own category
- A distinct invoice-prefix pattern represented bad-debt write-offs, with 
  price values as extreme as -£53,594
- Non-product codes (postage, discounts, bank fees, test data, gift vouchers) 
  were mixed into the product column — split out via a `transaction_type` 
  classification column
- One product split across two rows due to inconsistent casing in its code
- 13 test-data rows dropped; ~34K possible-duplicate rows flagged (not 
  deleted, since no unique row ID exists to confirm intent)

All cleaning logic lives in SQL (not pandas) — raw data loaded as-is, typed 
and categorized via a `staging_retail` table.

## Business Questions Answered
1. **Revenue trends** — monthly trend, Dec 2009–Dec 2011
2. **Top products & categories** — with and without extreme-bulk-order outliers
3. **Top countries/regions** by revenue
4. **Customer behavior** — repeat vs one-time buyer value
5. **Cost of cancellations & write-offs**

## Key Findings
- Clear seasonal peak every **November** in both 2010 and 2011 — the 
  strongest month each year by a wide margin
- One "top product" by raw revenue was almost entirely a single bulk order — 
  flagged and excluded in a second ranked view, since it wasn't a repeatable 
  sales pattern
- Revenue is heavily concentrated in the **United Kingdom (~84%)**, with 
  Ireland a distant second
- **Repeat customers** (72% of attributed customers) drive **~97% of 
  attributed revenue** — average repeat-customer value is ~11x a one-time 
  buyer's
- **Cancellations** total ~7.7% of gross sales; stock write-offs account for 
  over 570K lost units

## Tools
PostgreSQL (staging + business-question queries), Power BI Desktop (DAX 
measures, relationships, dashboard pages)

## Dashboard
See `/screenshots` for exported dashboard pages. PBIX file available on 
request (large file).

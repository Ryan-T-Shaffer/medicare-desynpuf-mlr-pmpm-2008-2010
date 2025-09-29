# DDL: Derived Tables for Visual Distributions

This folder contains SQL to create the consolidated table used by visuals.

- **Script:** `create_remaining_tables.sql` (creates `calc_dist_all` and `kpi_year_final_ab`)
- **Run order:** 1 of 3 (DDL -> Prep -> KPI) for `calc_dist_all`; run **after KPI** for `kpi_year_final_ab`
- **DB:** MySQL 8.0+

## Purpose
Compute three per-year distributions and unify them for dashboard consumption:
1. Member-months distribution (Part B, Part D, Greatest-of-two) — buckets `'0'`, `'1-11'`, `'12'`  
2. Claims-count distribution (`carrier_claims`, `outpatient_claims`, `prescript_drug_events`) — per-year percentages  
3. Cost-amount distribution  (`carrier_claims`, `outpatient_claims`, `prescript_drug_events`) — per-year percentages

## Dependencies & assumptions
Tables (and key columns) required by the script:
- `beneficiary_summary`: `year`, `BENE_SMI_CVRAGE_TOT_MONS`, `PLAN_CVRG_MOS_NUM`
- `carrier_claims`: `year`, `CLM_ID`, `LINE_ALOWD_CHRG_AMT_1..13`
- `outpatient_claims`: `year`, `CLM_ID`, `CLM_PMT_AMT`, `NCH_BENE_PTB_DDCTBL_AMT`, `NCH_BENE_PTB_COINSRNC_AMT`, `NCH_PRMRY_PYR_CLM_PD_AMT`
- `prescript_drug_events`: `year`, `TOT_RX_CST_AMT`

Semantics:
- Member-months: coverage buckets `'0'`, `'1-11'`, `'12'` within `[0,12]`
- Claims counts: DISTINCT `CLM_ID` for carrier/outpatient; PDE rows counted directly
- Cost amounts: null-safe sums of allowed/payment fields

Output legends:
- For member-months: `legend` = `'0' | '1-11' | '12'`
- For claims/cost: `legend` = `'carrier_claims' | 'outpatient_claims' | 'prescript_drug_events'`

## Performance expectations
- Suggested BTREE indexes on `(year)` and `(CLM_ID, year)` in claims tables.
- Partition claims tables by month/year where feasible.
- With indexing/partitioning, aggregation should complete in **minutes to tens of minutes** on typical developer hardware.
- Validate plans with `EXPLAIN` / `EXPLAIN ANALYZE`.

## Style conventions (used in the SQL)
- SQL keywords in UPPERCASE, identifiers in snake_case
- Clear aliases; 2-space indentation; one clause per line

## Security
- No credentials or local file paths appear in the script.

## Additional convenience table (from KPI)
This script also includes a convenience table **`kpi_year_final_ab`** that filters the KPI output to **race_group = 'AB'**.

**Dependency:** `kpi_year_final` must already exist (created by `sql/kpi/kpi_query.sql`).  
**Run order:** either run this script **after** the KPI step, or re-run just the bottom snippet after KPI.

Creation snippet (already included at the end of this file):
```sql
DROP TABLE IF EXISTS kpi_year_final_ab;
CREATE TABLE kpi_year_final_ab AS
SELECT *
FROM kpi_year_final
WHERE race_group = 'AB';
```

_Last updated: 2025-09-28_

---
**Copyright (c) 2025 Ryan Shaffer. All rights reserved.**

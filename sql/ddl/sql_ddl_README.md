# DDL: Derived Tables for Visual Distributions

This folder contains SQL to create the consolidated table used by visuals.

- **Script:** `create_remaining_tables.sql` (creates `calc_dist_all`)
- **Run order:** 1 of 3 (DDL -> Prep -> KPI)
- **DB:** MySQL 8.0+

## Purpose
Compute three per-year distributions and unify them for dashboard consumption:
1. Member-months distribution (Part B, Part D, Greatest-of-two) — buckets `'0'`, `'1-11'`, `'12'`  
2. Claims-count distribution (PROF/OP/RX) — per-year percentages  
3. Cost-amount distribution (PROF/OP/RX) — per-year percentages

## How to run
From the repository root in MySQL Shell or the MySQL CLI:
```sql
SOURCE sql/ddl/create_remaining_tables.sql;
```
This creates (or replaces) `calc_dist_all` with columns:
```
specific_calculation, year, legend, pct
```

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
- For claims/cost: `legend` = `'PROF' | 'OP' | 'RX'` (carrier/outpatient/PDE)

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

---
**Copyright (c) 2025 Ryan Shaffer. All rights reserved.**

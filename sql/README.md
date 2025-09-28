# Medicare KPI Query (MySQL 8.0)

This repository includes a single SQL script that computes **Cost PMPM**, **Count PMPM**, and **MLR** by **year**, **service line** (Total, OP, PROF, RX), and **race group**, including the **AB (all beneficiaries)** rollup using **sum(numerators) / sum(denominators)**. The output is a single table intended for dashboards and analysis.

## Files
- `sql/kpi_query.sql` — main query that creates `kpi_year_final` with KPI columns.
- `LICENSE` — license covering reuse of this SQL in the repository.

## Requirements
- **MySQL 8.0+** (uses CTEs).
- Tables referenced in the SQL header (`beneficiary_summary`, `prescript_drug_events`, `carrier_claims`, `outpatient_claims`, `z_part_b_premium_cost`, `z_part_d_premium_cost`). See the header in `sql/kpi_query.sql` for required columns and assumptions.

## How to run
In MySQL Shell or the MySQL CLI from the repo root:
```sql
SOURCE sql/kpi_query.sql;
```
This will create or overwrite `kpi_year_final`.

## Output schema (`kpi_year_final`)
- `year`
- `svc` — `Total`, `OP`, `PROF`, or `RX`
- `svc_group` — `Total` or `Service Line`
- `race_group` — per‑race values plus `AB` (all beneficiaries)
- `cost_pmpm`
- `cnt_pmpm`
- `mlr_pct`

## Correctness rules (important)
- **Total is not OP + PROF + RX.** KPIs are computed as **Σ numerators / Σ denominators** with service‑specific denominators:
  - `Total` uses `mm_all` (per‑member `GREATEST(mm_b, mm_d)`) and `prem_all`.
  - `RX` uses Part D months/premiums (`mm_d`, `prem_d`).
  - `OP` and `PROF` use Part B months/premiums (`mm_b`, `prem_b`).
- **AB (all beneficiaries)** is computed with the same **Σ/Σ rule** across all race groups (not an average of ratios).

## Performance expectations (brief)
- Designed for **large, partitioned claims tables**; practical on a laptop if tables are month‑partitioned and key columns are indexed.
- Recommended BTREE indexes:
  - Claims tables: `(DESYNPUF_ID, year)` (and any date/partition keys used in joins).
  - `beneficiary_summary`: `(DESYNPUF_ID, year)`, `BENE_RACE_CD`.
  - Premium tables: `(year)`.
- With proper indexing/partitioning, aggregation should execute in **4-6 hours** on a standard laptop with 16GB of RAM; without them, runtimes may be substantially longer like **Like 6 days**.
- Use `EXPLAIN` / `EXPLAIN ANALYZE` to verify partition pruning and index use.

## Data/privacy
- The SQL assumes de‑identified data and contains **no credentials or local file paths**.
- If you publish loaders, keep secrets out of scripts and the repo history.

## Copyright
All content in this repository is copyright (c) 2025 Ryan Shaffer. All rights reserved.

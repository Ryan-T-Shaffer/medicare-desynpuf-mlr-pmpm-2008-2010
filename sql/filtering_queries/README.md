# Filtering — Overview (Outpatient + Beneficiary Summary)

This folder documents how the project filters data **at the database boundary** and in a **repeatable SQL pipeline**. There are two parts:

1) **Outpatient constraint** — keep only beneficiary‑level rows by enforcing `SEGMENT = 1` on `outpatient_claims` (aggregated rows are rejected).  
2) **Beneficiary Summary filtering (demo)** — a stepwise CTE pipeline that shows how I would filter/clean a cohort and safely materialize the result (non‑destructive).

> These examples are intentionally simple and well‑commented to demonstrate professional filtering/cleanup practices for reviewers. The source data is not modified directly; constraints and a demo table are used instead.

---

## Quick navigation

**SQL in this folder**
- `outpatient_segement_filter.sql` — adds the `CHECK (SEGMENT = 1)` constraint on `outpatient_claims`.
- `beneficairy_summary_filtering.sql` — demonstration pipeline that materializes a filtered cohort to `beneficiary_summary_filtered_demo` and runs basic validation queries.

**Ingestion samples (clickable)**
[![Open functions.py](https://img.shields.io/badge/Open-functions.py-blue)](../../data_ingestion_method/samples/example_carrier_claims_parallel_load_functions.py)
[![Open call.py](https://img.shields.io/badge/Open-call.py-blue)](../../data_ingestion_method/samples/example_carrier_claims_parallel_load_call.py)

Plain links:
- [Sample loader (functions)](../../data_ingestion_method/samples/example_carrier_claims_parallel_load_functions.py)  
- [Sample loader (caller)](../../data_ingestion_method/samples/example_carrier_claims_parallel_load_call.py)

---

## How the pieces fit

- **Ingestion** (MySQL Shell `util.import_table`) loads raw CSV rows without dataset‑specific filters.  
- The **Outpatient constraint** rejects any non‑beneficiary rows at insert time by requiring `SEGMENT = 1`. Rejected rows surface as warnings in the ingest summary.  
- The **Beneficiary Summary demo** shows a clean, readable SQL workflow (CTEs → one final materialization) with basic instrumentation and data‑quality checks.

---

## Outpatient — beneficiary‑level only (`SEGMENT = 1`)

**File:** `outpatient_segement_filter.sql`  

What it does:
- Adds a table‑level `CHECK` constraint to `outpatient_claims` requiring `SEGMENT = 1` (your designated beneficiary‑level flag).  
- (Optional) Provides a one‑liner to purge any non‑conforming rows if you’re adding the constraint to a pre‑existing table.  
- Includes a quick verification query to confirm there are no violating rows.

Outcome:
- Aggregated/rolled‑up records (any `SEGMENT ≠ 1`) never land in the table and are therefore excluded from all downstream reporting.

---

## Beneficiary Summary — demonstration filtering pipeline

**File:** `beneficairy_summary_filtering.sql`  

What it demonstrates:
- **CTE pipeline** you can read top‑to‑bottom:  
  1. `alive` — remove rows with a recorded death date.  
  2. `valid_birth` — enforce a sensible birth‑date window.  
  3. `race_present` — keep rows with a populated `BENE_RACE_CD`.  
  4. `pa_only` — scope to Pennsylvania using SSA `SP_STATE_CODE = 39`.  
  5. `final_cohort` — the filtered result used for materialization.
- **Instrumentation**: a small `counts` query to show how each gate reduces the dataset.  
- **Non‑destructive materialization**: writes to `beneficiary_summary_filtered_demo` (safe to rerun).  
- **Post‑load checks**: null ID count, duplicate check on `(DESYNPUF_ID, year)`, and final row count.  
- **Optional view and indexes** to mirror the same logic for exploration and speed up joins.

Outcome:
- A clean, repeatable cohort table you can index and join in reports, plus a documented pattern hiring managers can quickly evaluate.

---

## Suggested run order

1. Run **`outpatient_segement_filter.sql`** once per environment to enforce the constraint.  
2. Run **`beneficairy_summary_filtering.sql`** whenever you want to (re)build the demo cohort table.  

> If your environment uses different `SEGMENT` semantics, adjust the constant in the constraint and comments to match your data contract.

---

© 2025 Ryan Shaffer. All rights reserved. These files are **samples**; the complete, production codebase (and final license) will be published separately.

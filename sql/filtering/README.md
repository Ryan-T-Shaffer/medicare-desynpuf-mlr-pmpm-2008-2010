# Filtering — Outpatient (SEGMENT = 0)

**Goal**: keep only **beneficiary‑level** outpatient rows by enforcing `SEGMENT = 0`.  
Rows where `SEGMENT ≠ 0` (e.g., aggregated/rolled‑up across multiple patients) are rejected at the **database boundary** via a `CHECK` constraint and therefore excluded from reporting.

> This folder contains the table‑level filter used by the report. Ingestion remains generic (no dataset‑specific filtering in code) and relies on this constraint.

---

## Jump to the ingestion samples (clickable)

[![Open functions.py](https://img.shields.io/badge/Open-functions.py-blue)](../../ingest/samples/example_carrier_claims_parallel_load_functions.py)
[![Open call.py](https://img.shields.io/badge/Open-call.py-blue)](../../ingest/samples/example_carrier_claims_parallel_load_call.py)

**Plain links:**  
- [Sample loader (functions)](../../ingest/samples/example_carrier_claims_parallel_load_functions.py)  
- [Sample loader (caller)](../../ingest/samples/example_carrier_claims_parallel_load_call.py)

> Tip: after committing, you can link to a specific function/lines by appending anchors, e.g.  
> `../../ingest/samples/example_carrier_claims_parallel_load_functions.py#L120-L190`

---

## How the pieces fit

- **Ingestion** (MySQL Shell `util.import_table`) inserts raw rows.  
- **Constraint** in `outpatient_segement_filter.sql` ensures only `SEGMENT = 0` rows land.  
- Any rejected rows surface as warnings in the ingest summary.

---

© 2025 Ryan Shaffer. All rights reserved. This is a **sample**; the complete, production codebase and its final license will be published in a separate repository.

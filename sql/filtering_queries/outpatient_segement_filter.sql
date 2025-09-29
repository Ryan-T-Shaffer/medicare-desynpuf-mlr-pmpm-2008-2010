/*
  Filtering — Outpatient (SEGMENT = 1)
  ------------------------------------
  Purpose:
    Enforce beneficiary-level granularity by allowing only SEGMENT = 0 rows in
    `outpatient_claims`. Rows where SEGMENT ≠ 1 (e.g., aggregated across multiple
    patients) are rejected at the database boundary and excluded from reporting.

  Navigation:
    For clickable “Open functions.py / call.py” links in GitHub, see this folder’s README:
      ./README.md

  Notes:
    • MySQL 8.0 enforces CHECK constraints; run once per environment. If the
      constraint already exists, you may ignore the duplicate error.
*/

-- 1) Enforce beneficiary-level rows only.
ALTER TABLE outpatient_claims
  ADD CONSTRAINT chk_outpatient_segment_zero
  CHECK (`SEGMENT` = 1);

-- 2) (Optional) If adding the constraint to a table that already contains data,
--    purge non-conforming rows first to avoid failures when enabling the constraint.
-- DELETE FROM outpatient_claims WHERE `SEGMENT` <> 1;

-- 3) Quick verification.
SELECT COUNT(*) AS violating_rows
FROM outpatient_claims
WHERE `SEGMENT` <> 1;

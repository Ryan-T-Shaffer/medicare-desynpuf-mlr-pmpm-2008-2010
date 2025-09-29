/*
  Filtering — Outpatient (SEGMENT = 0)
  ------------------------------------
  Purpose:
    Enforce beneficiary-level granularity by allowing only SEGMENT = 0 rows in
    `outpatient_claims`. Rows where SEGMENT ≠ 0 (e.g., aggregated across multiple
    patients) are rejected at the database boundary and excluded from reporting.

  Navigation:
    For clickable “Open functions.py / call.py” links in GitHub, see this folder’s README:
      ./README.md

  Notes:
    • If the source header spells the field `SEGEMENT`, normalize the column name
      to `SEGMENT` in your schema (example shown below, commented).
    • MySQL 8.0 enforces CHECK constraints; run once per environment. If the
      constraint already exists, you may ignore the duplicate error.
*/

-- 1) (Optional) Normalize the column name if needed.
-- ALTER TABLE outpatient_claims
--   CHANGE COLUMN `SEGEMENT` `SEGMENT` TINYINT UNSIGNED NOT NULL;

-- 2) Enforce beneficiary-level rows only.
ALTER TABLE outpatient_claims
  ADD CONSTRAINT chk_outpatient_segment_zero
  CHECK (`SEGMENT` = 0);

-- 3) (Optional) If adding the constraint to a table that already contains data,
--    purge non-conforming rows first to avoid failures when enabling the constraint.
-- DELETE FROM outpatient_claims WHERE `SEGMENT` <> 0;

-- 4) Quick verification.
SELECT COUNT(*) AS violating_rows
FROM outpatient_claims
WHERE `SEGMENT` <> 0;

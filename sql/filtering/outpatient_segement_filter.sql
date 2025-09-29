/* 
  Filtering — Outpatient (beneficiary-level only)
  ------------------------------------------------
  Purpose:
    Enforce beneficiary-level granularity by allowing only SEGMENT = 1 rows in
    `outpatient_claims`. Rows where SEGMENT ≠ 1 (e.g., 2 = rolled-up/aggregated,
    2 = other non-beneficiary aggregations) are rejected during ingest.

  Why here (SQL) and not in Python?
    This rule is a *data contract* for the table and should be enforced at the
    database boundary. The ingestion jobs (MySQL Shell `util.import_table`) will
    attempt to insert all rows; the CHECK constraint below ensures non-conforming
    records never land and will appear as warnings in the ingest summary.

  Ingestion context:
    - In tandem with the sample Python callers that run inside `mysqlsh --py`.
      They do not filter on SEGMENT; they rely on this constraint to keep only
      beneficiary-level rows. See the outpatient loader examples in your repo.

  Notes:.
    - Run this once per environment. If you already have the constraint, skip.

*/

/* 1) Make sure the column is typed appropriately (idempotent check not shown).
      Example: ALTER TABLE outpatient_claims MODIFY COLUMN SEGMENT TINYINT UNSIGNED NOT NULL; */

/* 2) Add a CHECK constraint to allow only beneficiary-level rows. */
ALTER TABLE outpatient_claims
  ADD CONSTRAINT chk_outpatient_segment_zero
  CHECK (`SEGMENT` = 1);

/* 3) (Optional) If the table already contains data and you are *adding* the
      constraint after the fact, you may want to purge non-conforming rows
      before enabling the constraint to avoid failures on existing data.

-- DELETE FROM outpatient_claims WHERE `SEGMENT` <> 0;
*/

/* 4) (Optional) Verify enforcement */
SELECT COUNT(*) AS violating_rows
FROM outpatient_claims
WHERE `SEGMENT` <> 1;

/* 
  beneficiary_summary_filtering.sql  — DEMONSTRATION / HYPOTHETICAL EXAMPLE
  -------------------------------------------------------------------------
  Purpose (read me):
    This file is a **hypothetical example** that demonstrates how I would filter
    and clean a beneficiary-level dataset in MySQL 8.x. It is included in the
    report to show employers my end-to-end filtering style (readability, data
    quality gates, instrumentation, and safe materialization), not to assert that
    these are the only “correct” cohort rules for your use case.

  Non-destructive guarantee:
    • Source table is **not** modified.
    • The pipeline materializes to a demo table: `beneficiary_summary_filtered_demo`.

  What this demonstrates:
    • Stepwise CTE pipeline (clear, testable gates).
    • Data-quality checks (alive, valid birth, race present; optional coverage).
    • Regional scoping using SSA `SP_STATE_CODE = 39` (Pennsylvania).
    • Instrumentation (before/after row counts).
    • Post-load validation (duplicates, nulls).
    • Optional view + indexes you’d typically add downstream.

  Notes:
    • `SP_STATE_CODE` in DE-SynPUF uses **SSA codes**; PA = 39.
    • Uncomment the “coverage” step if your analysis requires it.
    • Rename the destination table if you want this to be production, not demo.
*/

/* --------------------------------------------------
   0) Quick peek (optional during exploration)
-------------------------------------------------- */
-- SELECT COUNT(*) AS raw_count FROM beneficiary_summary;
-- SELECT * FROM beneficiary_summary LIMIT 5;

/* ==================================================
   1) CTE pipeline (readable, testable, single pass)
   ================================================== */
WITH
raw AS (
  SELECT * FROM beneficiary_summary
),
alive AS (
  -- Keep beneficiaries without a recorded death date
  SELECT * FROM raw
  WHERE BENE_DEATH_DT IS NULL
),
valid_birth AS (
  -- Sanity window; tune as needed for your study
  SELECT * FROM alive
  WHERE BENE_BIRTH_DT BETWEEN '1900-01-01' AND '2010-12-31'
),
/* OPTIONAL: uncomment if you want a coverage guardrail.
has_coverage AS (
  SELECT * FROM valid_birth
  WHERE
        COALESCE(BENE_SMI_CVRAGE_TOT_MONS, SMI_COV_MOS, 0) > 0   -- Part B months
     OR COALESCE(PARTD_CVRAGE_TOT_MONS, PTD_COV_MOS, 0) > 0      -- Part D months
),
*/
race_present AS (
  SELECT * FROM valid_birth /* or FROM has_coverage */
  WHERE BENE_RACE_CD IS NOT NULL
),
pa_only AS (
  -- Pennsylvania by SSA state code (PA = 39)
  SELECT * FROM race_present
  WHERE SP_STATE_CODE = 39
),
final_cohort AS (
  SELECT * FROM pa_only
)

/* --------------------------------------------------
   2) (Optional) Instrumentation — stepwise counts
   --------------------------------------------------
   Keeps the “show your work” vibe: how each gate impacts rows.
   Comment out in production if you don’t need it.
-------------------------------------------------- */
,
counts AS (
  SELECT 'raw' AS step, (SELECT COUNT(*) FROM raw) AS n UNION ALL
  SELECT 'alive', (SELECT COUNT(*) FROM alive) UNION ALL
  SELECT 'valid_birth', (SELECT COUNT(*) FROM valid_birth) UNION ALL
  /* SELECT 'has_coverage', (SELECT COUNT(*) FROM has_coverage) UNION ALL */  -- if enabled
  SELECT 'race_present', (SELECT COUNT(*) FROM race_present) UNION ALL
  SELECT 'pa_only', (SELECT COUNT(*) FROM pa_only) UNION ALL
  SELECT 'final_cohort', (SELECT COUNT(*) FROM final_cohort)
)
SELECT * FROM counts;
-- (You can remove the SELECT * FROM counts if you prefer a quieter run.)

/* ==================================================
   3) Materialize (non-destructive demo target)
   ================================================== */
CREATE TABLE IF NOT EXISTS beneficiary_summary_filtered_demo LIKE beneficiary_summary;
TRUNCATE TABLE beneficiary_summary_filtered_demo;

INSERT INTO beneficiary_summary_filtered_demo
SELECT * FROM final_cohort;

/* --------------------------------------------------
   4) Post-load validation — quick data quality checks
-------------------------------------------------- */
-- Expect zero
SELECT COUNT(*) AS dq_null_ids
FROM beneficiary_summary_filtered_demo
WHERE DESYNPUF_ID IS NULL;

-- Look for accidental duplicates by ID + year
SELECT DESYNPUF_ID, `year`, COUNT(*) AS dup_rows
FROM beneficiary_summary_filtered_demo
GROUP BY DESYNPUF_ID, `year`
HAVING COUNT(*) > 1;

-- Final cohort size
SELECT COUNT(*) AS final_rowcount FROM beneficiary_summary_filtered_demo;

-- Optional indexes that help most downstream joins/filters
-- ALTER TABLE beneficiary_summary_filtered_demo
--   ADD INDEX idx_bsf_year (`year`),
--   ADD INDEX idx_bsf_id_year (DESYNPUF_ID, `year`);

/* --------------------------------------------------
   5) Optional: logical view for ad-hoc reuse
-------------------------------------------------- */
-- DROP VIEW IF EXISTS v_beneficiary_summary_filtered_demo;
-- CREATE VIEW v_beneficiary_summary_filtered_demo AS
-- WITH
--   raw AS (SELECT * FROM beneficiary_summary),
--   alive AS (SELECT * FROM raw WHERE BENE_DEATH_DT IS NULL),
--   valid_birth AS (SELECT * FROM alive WHERE BENE_BIRTH_DT BETWEEN '1900-01-01' AND '2010-12-31'),
--   /* has_coverage AS ( ... ) */
--   race_present AS (SELECT * FROM valid_birth WHERE BENE_RACE_CD IS NOT NULL),
--   pa_only AS (SELECT * FROM race_present WHERE SP_STATE_CODE = 39),
--   final_cohort AS (SELECT * FROM pa_only)
-- SELECT * FROM final_cohort;

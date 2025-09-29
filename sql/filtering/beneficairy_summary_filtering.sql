/* 
  beneficiary_summary_filtering.sql
  ---------------------------------
  Goal:
    Produce a clean, beneficiary-level cohort from `beneficiary_summary` using a
    readable, stepwise (5-step) CTE pipeline and then materialize the result.

  Why this structure:
    - CTEs keep each filter focused and self-documenting.
    - We only write to disk once (final INSERT), which is efficient.
    - The final table can be indexed / joined by the rest of your report.

  After running:
    - You will have a refreshed table: beneficiary_summary_filtered
    - Optional: uncomment the VIEW at the bottom to have a reusable logical defn.

  MySQL 8.x required.
*/

-- ---------------------------------------------------------------------------
-- (Optional) Peek at the raw table shape before starting
-- SELECT COUNT(*) FROM beneficiary_summary;
-- SELECT * FROM beneficiary_summary LIMIT 5;
-- ---------------------------------------------------------------------------

/* =====================
   Stepwise CTE pipeline
   ===================== */
WITH
-- 1) Alive-only and real cohort.
alive_real AS (
  SELECT *
  FROM beneficiary_summary
  WHERE BENE_DEATH_DT IS NULL AND BENE_BIRTH_DT IS NOT NULL;
),
-- 2) Basic data quality on birth date.
valid_birth AS (
  SELECT *
  FROM alive_real
  WHERE BENE_BIRTH_DT BETWEEN '1900-01-01' AND '2010-12-31'
),
-- 3) Valid race to participant in the study
valid_race AS (
  SELECT *
  FROM valid_birth
  WHERE BENE_RACE_CD IS NOT NULL
),
-- 4) Filter to makesure all participants are in Pennsylvania, PA's SP_STATE_CODE is 39
final_cohort AS (
  SELECT *
  FROM valid_race
  WHERE SP_STATE_CODE = 39
),
-- 5) Filter on makin
-- Final SELECT for ad-hoc checks (commented out in production runs)
-- SELECT * FROM final_cohort LIMIT 5
-- No more filtering required some counties in this study only have around 50 participants
-- So down filtering is not an option
-- ;
-- =====================

/* ===============================
   Materialize the final cohort
   =============================== */
-- Create or refresh the destination table with the same structure as the source.
CREATE TABLE IF NOT EXISTS beneficiary_summary_filtered LIKE beneficiary_summary;
TRUNCATE TABLE beneficiary_summary_filtered;

-- Insert the filtered cohort in one pass.
INSERT INTO beneficiary_summary_filtered
SELECT *
FROM final_cohort;

-- Optional: sanity checks
-- SELECT COUNT(*) AS filtered_count FROM beneficiary_summary_filtered;
-- SELECT * FROM beneficiary_summary_filtered LIMIT 5;

-- (Optional) Helpful indexes for downstream joins/filters
-- ALTER TABLE beneficiary_summary_filtered
--   ADD INDEX idx_bsf_year (year),
--   ADD INDEX idx_bsf_id_year (DESYNPUF_ID, year);

-- (Optional) A view that mirrors the same logic (handy for exploration)
-- DROP VIEW IF EXISTS v_beneficiary_summary_filtered;
-- CREATE VIEW v_beneficiary_summary_filtered AS
-- WITH
--   alive AS (SELECT * FROM beneficiary_summary WHERE BENE_DEATH_DT IS NULL),
--   in_years AS (SELECT * FROM alive WHERE `year` IN (2008, 2009, 2010)),
--   valid_birth AS (SELECT * FROM in_years WHERE BENE_BIRTH_DT BETWEEN '1900-01-01' AND '2010-12-31'),
--   has_coverage AS (
--     SELECT * FROM valid_birth
--     WHERE COALESCE(BENE_SMI_CVRAGE_TOT_MONS, SMI_COV_MOS, 0) > 0
--        OR COALESCE(PARTD_CVRAGE_TOT_MONS, PTD_COV_MOS, 0) > 0
--   ),
--   final_cohort AS (SELECT * FROM has_coverage WHERE BENE_RACE_CD IS NOT NULL)
-- SELECT * FROM final_cohort;

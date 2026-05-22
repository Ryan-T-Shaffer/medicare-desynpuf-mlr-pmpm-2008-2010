/*
================================================================================
File: data_cleaning_before_kpi_calc.sql

Purpose:
    Creates cleaned versions of the raw CMS Medicare DE-SynPUF tables before they
    are used in downstream KPI calculations and reporting queries.

Overview:
    This script filters the current/raw project tables into cleaner analysis-ready
    tables by applying basic data-quality rules, date-range restrictions, and
    duplicate-removal logic. The cleaned tables preserve the original table
    structure while removing records that would weaken claim-to-beneficiary
    mapping, service-date accuracy, race-level grouping, or KPI denominator logic.

Cleaned Output Tables Created:
    - beneficiary_summary_clean
    - carrier_claims_clean
    - outpatient_claims_clean
    - prescript_drug_events_clean

Source Tables Used:
    - beneficiary_summary
    - carrier_claims
    - outpatient_claims
    - prescript_drug_events

Main Cleaning Rules:
    1. beneficiary_summary_clean
       - Keeps only records with a non-null beneficiary ID and year.
       - Keeps only records with valid birth dates between 1900-01-01 and
         2010-12-31.
       - Keeps only records with a non-null race code so race-level KPI
         breakdowns can be calculated.
       - Keeps only records with valid Medicare Part B and Part D coverage-month
         values between 0 and 12.

    2. carrier_claims_clean
       - Keeps only claims with a non-null claim ID and beneficiary ID.
       - Keeps only claims with claim-from dates between 2008-01-01 and
         2010-12-31.
       - Removes duplicate claim rows using ROW_NUMBER() over claim date and
         claim ID.

    3. outpatient_claims_clean
       - Keeps only claims with a non-null claim ID and beneficiary ID.
       - Keeps only segment-level records where SEGMENT = 1 to avoid retaining
         rolled-up duplicate rows.
       - Keeps only claims with claim-from dates between 2008-01-01 and
         2010-12-31.
       - Removes duplicate claim rows using ROW_NUMBER() over claim date and
         claim ID.

    4. prescript_drug_events_clean
       - Keeps only prescription drug events with a non-null PDE ID and
         beneficiary ID.
       - Keeps only prescription service dates between 2008-01-01 and
         2010-12-31.
       - Removes duplicate prescription drug event rows using ROW_NUMBER() over
         service date and PDE ID.

Notes:
    - DROP TABLE IF EXISTS is used so this script can be rerun safely during
      development or pipeline refreshes.
    - CREATE TABLE ... ENGINE = InnoDB AS is used to materialize each cleaned
      table for downstream SQL queries.
    - The cleaned tables are intended to be queried instead of the raw source
      tables when calculating Medicare KPIs such as MLR, PMPM medical cost, and
      PMPM claim count.

Requirements:
    - MySQL 8.0 or later.
    - Raw source tables must already exist before this script is executed.
================================================================================
*/

-- beneficiary_summary filtering
DROP TABLE IF EXISTS beneficiary_summary_clean;
CREATE TABLE beneficiary_summary_clean
ENGINE = InnoDB
AS
WITH
raw AS (
  SELECT * FROM beneficiary_summary
),
real_patient_id AS (
  SELECT * FROM raw
  WHERE DESYNPUF_ID IS NOT NULL AND `year` IS NOT NULL -- these values cannot be NULL otherwise the KPI calculations become useless
),
valid_birth AS (
  SELECT * FROM real_patient_id
  WHERE BENE_BIRTH_DT BETWEEN '1900-01-01' AND '2010-12-31' -- this also filters out null birth_date values which what is needed
),
race_present AS (
  SELECT * FROM valid_birth
  WHERE BENE_RACE_CD IS NOT NULL -- we need to be able to aggregate by race for the query
),
amount_of_months_of_coverage_is_real AS (
  SELECT * FROM race_present -- makesure the patient actually has real values for the months of Medicare coverage they signed up for, if this does not exist then I can't use the patient in the KPI calc
  WHERE BENE_SMI_CVRAGE_TOT_MONS BETWEEN 0 AND 12 AND PLAN_CVRG_MOS_NUM BETWEEN 0 AND 12 
),
final_cohort AS (
  SELECT * FROM amount_of_months_of_coverage_is_real
)
SELECT * FROM final_cohort;


-- carrier_claims table filtering
DROP TABLE IF EXISTS carrier_claims_clean;
CREATE TABLE carrier_claims_clean
ENGINE = InnoDB
AS
WITH
raw AS (
  SELECT *
  FROM carrier_claims
),
real_cc_claim_id AS (
  SELECT *
  FROM raw
  WHERE CLM_ID IS NOT NULL
    AND DESYNPUF_ID IS NOT NULL
  -- Keeps only claims that have both a claim ID and a beneficiary ID,
  -- so each claim can still be mapped to an individual beneficiary.
),
valid_claim_date AS (
  SELECT *
  FROM real_cc_claim_id
  WHERE CLM_FROM_DT BETWEEN '2008-01-01' AND '2010-12-31'
),
ranked_claims AS (
  SELECT
    valid_claim_date.*,
    ROW_NUMBER() OVER (
      PARTITION BY CLM_FROM_DT, CLM_ID
      ORDER BY CLM_FROM_DT, CLM_ID
    ) AS duplicate_rank
  FROM valid_claim_date
),
deduped_claims AS (
  SELECT *
  FROM ranked_claims
  WHERE duplicate_rank = 1
)
SELECT * FROM deduped_claims;


-- outpatient_claims_filtering
DROP TABLE IF EXISTS outpatient_claims_clean;
CREATE TABLE outpatient_claims_clean
ENGINE = InnoDB
AS
WITH
raw AS (
  SELECT *
  FROM outpatient_claims
),
real_op_claim_id AS (
  SELECT *
  FROM raw
  WHERE CLM_ID IS NOT NULL
    AND DESYNPUF_ID IS NOT NULL
    AND SEGMENT = 1
  -- Keeps only claims that have both a claim ID and a beneficiary ID,
  -- so each claim can still be mapped to an individual beneficiary.
  -- SEGMENT must equal 1 if not then rolled up rolls will be in the dataset
),
valid_claim_date AS (
  SELECT *
  FROM real_op_claim_id
  WHERE CLM_FROM_DT BETWEEN '2008-01-01' AND '2010-12-31'
),
ranked_claims AS (
  SELECT
    valid_claim_date.*,
    ROW_NUMBER() OVER (
      PARTITION BY CLM_FROM_DT, CLM_ID
      ORDER BY CLM_FROM_DT, CLM_ID
    ) AS duplicate_rank
  FROM valid_claim_date
),
deduped_claims AS (
  SELECT *
  FROM ranked_claims
  WHERE duplicate_rank = 1
)
SELECT * FROM deduped_claims;


-- prescription drugs filtering
DROP TABLE IF EXISTS prescript_drug_events_clean;
CREATE TABLE prescript_drug_events_clean
ENGINE = InnoDB
AS
WITH
raw AS (
  SELECT *
  FROM prescript_drug_events
),
real_pde_claim_id AS (
  SELECT *
  FROM raw
  WHERE PDE_ID IS NOT NULL
    AND DESYNPUF_ID IS NOT NULL
  -- Keeps only claims that have both a claim ID and a beneficiary ID,
  -- so each claim can still be mapped to an individual beneficiary.
),
valid_claim_date AS (
  SELECT *
  FROM real_pde_claim_id
  WHERE SRVC_DT BETWEEN '2008-01-01' AND '2010-12-31'
),
ranked_claims AS (
  SELECT
    valid_claim_date.*,
    ROW_NUMBER() OVER (
      PARTITION BY SRVC_DT, PDE_ID
      ORDER BY SRVC_DT, PDE_ID
    ) AS duplicate_rank
  FROM valid_claim_date
),
deduped_claims AS (
  SELECT *
  FROM ranked_claims
  WHERE duplicate_rank = 1
)
SELECT * FROM deduped_claims;



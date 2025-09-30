/*
File: sql/ddl/create_remaining_tables.sql
Purpose: Build a single consolidated output table (calc_dist_all) used by visuals.
         The script computes three distributions and unions them:
           1) Member-months distribution (Part B, Part D, Greatest-of-two)
           2) Claims-count distribution (PROF/OP/RX)
           3) Cost-amount distribution  (PROF/OP/RX)
         All logic is in CTEs; no intermediate tables are created.

Output table:
  calc_dist_all(specific_calculation, year, legend, pct)

Notes:
  - This script standardizes legend names for claim/cost splits as PROF (carrier), OP (outpatient), RX (PDE).
  - Percentages are per-year, rounded to 2 decimals.
  - Uses MySQL 8.0+ (CTEs, window functions).
  - No credentials or local file paths are included.
  - If you prefer the original labels ('carrier_claims','outpatient_claims','prescript_drug_events'),
    adjust the CASE mappings in cte_claims and cte_cost.

This graph is used to make the 5 sliced graphs in the middle of the table that show distributions of different
component measures (numerator and denominator values) of the 3 KPIs MLR, PMPM Cost, and PMPM Count.
*/

DROP TABLE IF EXISTS calc_dist_all;

CREATE TABLE calc_dist_all AS
WITH
/* -----------------------------
   1) Member-months distributions
   ----------------------------- */
cte_mm_b AS (
  SELECT
      bs.`year`,
      CASE
        WHEN bs.BENE_SMI_CVRAGE_TOT_MONS = 0  THEN '0'
        WHEN bs.BENE_SMI_CVRAGE_TOT_MONS = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY bs.`year`), 2) AS pct
  FROM beneficiary_summary AS bs
  WHERE bs.BENE_SMI_CVRAGE_TOT_MONS BETWEEN 0 AND 12
  GROUP BY bs.`year`, months_covered
),
cte_mm_d AS (
  SELECT
      bs.`year`,
      CASE
        WHEN bs.PLAN_CVRG_MOS_NUM = 0  THEN '0'
        WHEN bs.PLAN_CVRG_MOS_NUM = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY bs.`year`), 2) AS pct
  FROM beneficiary_summary AS bs
  WHERE bs.PLAN_CVRG_MOS_NUM BETWEEN 0 AND 12
  GROUP BY bs.`year`, months_covered
),
cte_mm_greatest AS (
  SELECT
      y.`year`,
      CASE
        WHEN y.months_max = 0  THEN '0'
        WHEN y.months_max = 12 THEN '12'
        ELSE '1-11'
      END AS months_covered,
      COUNT(*) AS cnt,
      ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY y.`year`), 2) AS pct
  FROM (
      SELECT bs.`year`,
             GREATEST(bs.BENE_SMI_CVRAGE_TOT_MONS, bs.PLAN_CVRG_MOS_NUM) AS months_max
      FROM beneficiary_summary AS bs
  ) AS y
  GROUP BY y.`year`, months_covered
),

/* -----------------------------
   2) Claims-count distribution
   ----------------------------- */
cte_claims_counts AS (
  SELECT `year`, 'PROF' AS svc, COUNT(DISTINCT CLM_ID) AS claims_count
  FROM carrier_claims
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'OP'   AS svc, COUNT(DISTINCT CLM_ID) AS claims_count
  FROM outpatient_claims
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'RX'   AS svc, COUNT(*) AS claims_count  -- PDE_ID unique
  FROM prescript_drug_events
  GROUP BY `year`
),
cte_claims AS (
  SELECT
      c.`year`,
      c.svc AS legend,  -- standardized labels: PROF/OP/RX
      ROUND(100 * c.claims_count / SUM(c.claims_count) OVER (PARTITION BY c.`year`), 2) AS pct
  FROM cte_claims_counts AS c
),

/* -----------------------------
   3) Cost-amount distribution
   ----------------------------- */
cte_cost_amounts AS (
  SELECT
      `year`,
      'PROF' AS svc,
      SUM(  COALESCE(LINE_ALOWD_CHRG_AMT_1 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_2 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_3 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_4 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_5 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_6 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_7 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_8 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_9 ,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_10,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_11,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_12,0)
          + COALESCE(LINE_ALOWD_CHRG_AMT_13,0)
      ) AS cost_amount
  FROM carrier_claims
  GROUP BY `year`
  UNION ALL
  SELECT
      `year`,
      'OP' AS svc,
      SUM(  COALESCE(CLM_PMT_AMT               ,0)
          + COALESCE(NCH_BENE_PTB_DDCTBL_AMT   ,0)
          + COALESCE(NCH_BENE_PTB_COINSRNC_AMT ,0)
          + COALESCE(NCH_PRMRY_PYR_CLM_PD_AMT  ,0)
      ) AS cost_amount
  FROM outpatient_claims
  GROUP BY `year`
  UNION ALL
  SELECT
      `year`,
      'RX' AS svc,
      SUM(COALESCE(TOT_RX_CST_AMT,0)) AS cost_amount
  FROM prescript_drug_events
  GROUP BY `year`
),
cte_cost AS (
  SELECT
      a.`year`,
      a.svc AS legend,  -- standardized labels: PROF/OP/RX
      ROUND(100 * a.cost_amount / SUM(a.cost_amount) OVER (PARTITION BY a.`year`), 2) AS pct
  FROM cte_cost_amounts AS a
)

/* -----------------------------
   4) Final union of three distributions
   ----------------------------- */
SELECT
  'part_b' AS specific_calculation,
  b.`year`,
  b.months_covered AS legend,
  b.pct
FROM cte_mm_b AS b

UNION ALL
SELECT
  'part_d' AS specific_calculation,
  d.`year`,
  d.months_covered AS legend,
  d.pct
FROM cte_mm_d AS d

UNION ALL
SELECT
  'greatest_amt_months' AS specific_calculation,
  g.`year`,
  g.months_covered AS legend,
  g.pct
FROM cte_mm_greatest AS g

UNION ALL
SELECT
  'claims_dist' AS specific_calculation,
  cc.`year`,
  cc.legend,
  cc.pct
FROM cte_claims AS cc

UNION ALL
SELECT
  'cost_dist' AS specific_calculation,
  co.`year`,
  co.legend,
  co.pct
FROM cte_cost AS co
;


/* ----------------------------------------------------------
   Additional convenience table (requires kpi_year_final):
   Creates an AB-only slice from the KPI results.
   Basically filters on the combined total All Beneficiaries
   instead of individually by race. Important for making the
   All beneficiairy KPI graphs and the KPI YoY percent 
   change graphs. Run this after kpi_query.sql has 
   created kpi_year_final.
-----------------------------------------------------------*/
DROP TABLE IF EXISTS kpi_year_final_ab;

CREATE TABLE kpi_year_final_ab AS
SELECT *
FROM kpi_year_final
WHERE race_group = 'AB';



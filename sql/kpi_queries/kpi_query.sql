/*
Copyright (c) 2025 Ryan Shaffer. All rights reserved.
Viewing only. No permission to copy, modify, distribute, or use without written consent.
Contact: 20rs2002@gmail.com
*/
/*
File: sql/kpi_query.sql
Purpose: Compute KPI rollups (PMPM Cost, PMPM Count, MLR) by year (2008-2010), service line (Total, OP, PROF, RX),
         and race_group (AB plus named race groups). Returns a single table suitable for dashboards.

Tested: MySQL 8.0+ (CTEs required)
How to run: SOURCE sql/kpi_query.sql;

Dependencies & assumptions
--------------------------
Tables expected (with required columns):
  - beneficiary_summary
      DESYNPUF_ID (PK or unique per member/year)
      year (INT)
      BENE_RACE_CD (INT code)
      BENE_SMI_CVRAGE_TOT_MONS (member months for Part B; INT)
      PLAN_CVRG_MOS_NUM (member months for Part D; INT)
  - prescript_drug_events
      DESYNPUF_ID, year, TOT_RX_CST_AMT (numeric total cost), PDE_ID (row id)
      Notes: RX claim date fields must allow YEAR(...) extraction used upstream.
  - carrier_claims
      DESYNPUF_ID, year, CLM_ID
      LINE_ALOWD_CHRG_AMT_1 ... LINE_ALOWD_CHRG_AMT_13 (numeric allowed costs)
  - outpatient_claims
      DESYNPUF_ID, year, CLM_ID,
      CLM_PMT_AMT, NCH_BENE_PTB_DDCTBL_AMT, NCH_BENE_PTB_COINSRNC_AMT, NCH_PRMRY_PYR_CLM_PD_AMT
  - z_part_b_premium_cost
      year, monthly_rate (numeric Part B premium)
  - z_part_d_premium_cost
      year, monthly_rate (numeric Part D premium)

Indexing/partition guidance (for performance):
  - On claims tables, create BTREE indexes on (DESYNPUF_ID, year) and partition by month if available.
  - On beneficiary_summary, index (DESYNPUF_ID, year) and BENE_RACE_CD.
  - Premium tables indexed by (year).
  - These enable efficient joins and aggregation and allow partition pruning when filtering by year/service.

Service line denominator rules (very important for correctness):
  - 'Total' does NOT equal OP + PROF + RX. For KPIs, compute as SUM(numerator) / SUM(denominator).
  - Denominators and premiums by service line:
      OP and PROF use Part B months/premiums (mm_b, prem_b).
      RX uses Part D months/premiums (mm_d, prem_d).
      Total uses mm_all = GREATEST(mm_b, mm_d) per member and prem_all = prem_b + prem_d.
  - Race-group 'AB' represents all beneficiaries and is computed with the same SUM/SUM rule across every race.

Race mapping (from BENE_RACE_CD):
  1 Caucasian, 2 Black, 3 Other, 4 Asian, 5 Hispanic, 6 Native American, ELSE Unknown.

Outputs:
  - kpi_year_final columns:
      year, svc (Total/OP/PROF/RX), svc_group (Total or Service Line), race_group,
      cost_pmpm, cnt_pmpm, mlr_pct

Notes:
  - Monetary values are assumed USD.
  - Avoid secrets and local file paths in this script.
  - This script creates/overwrites kpi_year_final. Back up if needed.

Last updated: 2025-09-28
*/

CREATE TABLE kpi_year_final
ENGINE = InnoDB
AS
WITH
/* 1) Per-table, per-member, per-year subtotals, total medical cost per year for each beneficairy by svc*/
pde AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(COALESCE(TOT_RX_CST_AMT,0)) AS cost_pde,
         COUNT(PDE_ID)                   AS cnt_pde
  FROM prescript_drug_events
  GROUP BY DESYNPUF_ID, `year`
),
carrier AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(
           COALESCE(LINE_ALOWD_CHRG_AMT_1 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_2 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_3 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_4 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_5 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_6 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_7 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_8 ,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_9 ,0) + COALESCE(LINE_ALOWD_CHRG_AMT_10,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_11,0) + COALESCE(LINE_ALOWD_CHRG_AMT_12,0) +
           COALESCE(LINE_ALOWD_CHRG_AMT_13,0)
         ) AS cost_carrier,
         COUNT(DISTINCT CLM_ID) AS cnt_carrier
  FROM carrier_claims
  GROUP BY DESYNPUF_ID, `year`
),
outp AS (
  SELECT DESYNPUF_ID, `year`,
         SUM(
           COALESCE(CLM_PMT_AMT              ,0) +
           COALESCE(NCH_BENE_PTB_DDCTBL_AMT  ,0) +
           COALESCE(NCH_BENE_PTB_COINSRNC_AMT,0) +
           COALESCE(NCH_PRMRY_PYR_CLM_PD_AMT ,0)
         ) AS cost_outp,
         COUNT(DISTINCT CLM_ID) AS cnt_outp
  FROM outpatient_claims
  GROUP BY DESYNPUF_ID, `year`
),

/* 2) Member-year rollup (keep race and both denominators & premiums) */
member_year AS (
  SELECT
    bs.DESYNPUF_ID,
    bs.`year`,
    bs.BENE_RACE_CD, /*Race Code identifier*/
    COALESCE(bs.BENE_SMI_CVRAGE_TOT_MONS,0) AS mm_pt_b, /*number of months of Medicare part B a beneficairy purchased for a year*/
    COALESCE(bs.PLAN_CVRG_MOS_NUM      ,0) AS mm_pt_d, /*number of months of Medicare part D a beneficairy purchased for a year*/
    pb.monthly_rate * COALESCE(bs.BENE_SMI_CVRAGE_TOT_MONS,0) AS prem_b, /*amount of total part B premiums a beneficairy paid over a year monthly in terms of months subscribed x monthly rate*/
    pd.monthly_rate * COALESCE(bs.PLAN_CVRG_MOS_NUM      ,0) AS prem_d, /*amount of total Part D premiums a beneficairy paid over a year monthly in terms of months subscribed x monthly rate*/
    COALESCE(pde.cost_pde     ,0) AS cost_pde,
    COALESCE(carrier.cost_carrier,0) AS cost_carrier,
    COALESCE(outp.cost_outp   ,0) AS cost_outp,
    COALESCE(pde.cnt_pde      ,0) AS cnt_pde,
    COALESCE(carrier.cnt_carrier ,0) AS cnt_carrier,
    COALESCE(outp.cnt_outp    ,0) AS cnt_outp,
         
    /* totals for 'Total' svc */
    COALESCE(pde.cost_pde     ,0) +
    COALESCE(carrier.cost_carrier,0) +
    COALESCE(outp.cost_outp   ,0) AS total_allowed_cost,
    COALESCE(pde.cnt_pde      ,0) +
    COALESCE(carrier.cnt_carrier ,0) +
    COALESCE(outp.cnt_outp    ,0) AS total_claim_count
  FROM beneficiary_summary bs
  LEFT JOIN pde     USING (DESYNPUF_ID, `year`)
  LEFT JOIN carrier USING (DESYNPUF_ID, `year`)
  LEFT JOIN outp    USING (DESYNPUF_ID, `year`)
  LEFT JOIN z_part_b_premium_cost pb USING (`year`)
  LEFT JOIN z_part_d_premium_cost pd USING (`year`)
),

/* 3) Denominators/premiums by race + an AB rollup (Î£ over all races) */
denoms AS (
  /* AB: sum across all races */
  SELECT
    `year`,
    'AB' AS race_group,
    SUM(mm_pt_b)                            AS mm_b,
    SUM(mm_pt_d)                            AS mm_d,
    SUM(GREATEST(mm_pt_b, mm_pt_d))         AS mm_all, /*Used to determine Member Months denominator when combining all parts of Medicare for the Total svc. You wonuldn't add the 2 values together here, just use the greatest number of months a beneficairy subscribed to between parts B & D for that year. */
    SUM(prem_b)                             AS prem_b,
    SUM(prem_d)                             AS prem_d,
    SUM(prem_b + prem_d)                    AS prem_all
  FROM member_year
  GROUP BY `year`
  UNION ALL
  /* Each race group */
  SELECT
    `year`,
    CASE BENE_RACE_CD
      WHEN 1 THEN 'Caucasian'
      WHEN 2 THEN 'Black'
      WHEN 3 THEN 'Other'
      WHEN 4 THEN 'Asian'
      WHEN 5 THEN 'Hispanic'
      WHEN 6 THEN 'Native American'
      ELSE 'Unknown'
    END AS race_group,
    SUM(mm_pt_b)                            AS mm_b,
    SUM(mm_pt_d)                            AS mm_d,
    SUM(GREATEST(mm_pt_b, mm_pt_d))         AS mm_all,
    SUM(prem_b)                             AS prem_b,
    SUM(prem_d)                             AS prem_d,
    SUM(prem_b + prem_d)                    AS prem_all
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
),

/* 4) Service-line numerators (allowed & count) by race + AB rollup */
svc AS (
  /* AB (all beneficiaries) */
  SELECT `year`, 'AB' AS race_group, 'ALL' AS svc,
         SUM(total_allowed_cost) AS allowed, SUM(total_claim_count) AS cnt
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'PROF', SUM(cost_carrier), SUM(cnt_carrier)
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'RX',   SUM(cost_pde),     SUM(cnt_pde)
  FROM member_year
  GROUP BY `year`
  UNION ALL
  SELECT `year`, 'AB', 'OP',   SUM(cost_outp),    SUM(cnt_outp)
  FROM member_year
  GROUP BY `year`

  UNION ALL

  /* Each race group */
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'ALL' AS svc,
         SUM(total_allowed_cost), SUM(total_claim_count)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'PROF' AS svc,
         SUM(cost_carrier), SUM(cnt_carrier)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'RX' AS svc,
         SUM(cost_pde), SUM(cnt_pde)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
  UNION ALL
  SELECT `year`,
         CASE BENE_RACE_CD
           WHEN 1 THEN 'Caucasian'
           WHEN 2 THEN 'Black'
           WHEN 3 THEN 'Other'
           WHEN 4 THEN 'Asian'
           WHEN 5 THEN 'Hispanic'
           WHEN 6 THEN 'Native American'
           ELSE 'Unknown'
         END AS race_group,
         'OP' AS svc,
         SUM(cost_outp), SUM(cnt_outp)
  FROM member_year
  GROUP BY `year`, BENE_RACE_CD
)

/* 5) Final rollup: pick denominators by svc and compute KPIs */
SELECT
  s.`year`,
  CASE WHEN s.svc = 'ALL' THEN 'Total' ELSE s.svc END AS svc,
  CASE WHEN s.svc = 'ALL' THEN 'Total' ELSE 'Service Line' END AS svc_group,
  s.race_group,

  /* PMPM Cost = Î£ Allowed / Î£ Member Months (svc-specific denominator) */
  ROUND(
    s.allowed /
    CASE
      WHEN s.svc = 'ALL' THEN d.mm_all      /* Total uses max(B,D) per member */
      WHEN s.svc = 'RX'  THEN d.mm_d        /* RX on Part D months           */
      ELSE                   d.mm_b         /* OP/PROF on Part B months      */
    END, 2
  ) AS cost_pmpm,

  /* PMPM Count = Î£ Claim Count / Î£ Member Months */
  ROUND(
    s.cnt /
    CASE
      WHEN s.svc = 'ALL' THEN d.mm_all
      WHEN s.svc = 'RX'  THEN d.mm_d
      ELSE                   d.mm_b
    END, 2
  ) AS cnt_pmpm,

  /* MLR (%) = Î£ Allowed / Î£ Premium Revenue * 100 */
  ROUND(
    (s.allowed /
     CASE
       WHEN s.svc = 'ALL' THEN d.prem_all
       WHEN s.svc = 'RX'  THEN d.prem_d
       ELSE                  d.prem_b
     END) * 100, 2
  ) AS mlr_pct

FROM svc s
JOIN denoms d
  ON d.`year` = s.`year`
 AND d.race_group = s.race_group
ORDER BY s.`year`, svc, s.race_group;

ALTER TABLE kpi_year_final
  ADD PRIMARY KEY (`year`, svc, race_group);



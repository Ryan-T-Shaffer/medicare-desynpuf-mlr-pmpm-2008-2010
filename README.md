# Project Background
The CMS DE-SynPUF Medicare dataset was used to create an interactive dashboard that lets U.S. health plans benchmark year-over-year (YoY) trends in Cost PMPM, Count PMPM, and Medical Loss Ratio (MLR) across Medicare service lines (svc) and 5 race groups. The analysis is framed from the perspective of an in-house healthcare-analytics analyst to align insights with business questions.

A sentence of space was left in the project background for whatever POV this project wants to be framed in later. You are also missing a so what as to why you are analyzing these metrics and what this all means.

*How insights are evaluated in the report on the following key areas*:
- **MLR Trends by SVC:** The amount of money Medicare's spending yearly on healthcare compared to the amount Medicare's is charging beneficiaries in premiums to pay for it. SVCs analyzed: Outpatient (OP), Carrier (PROF), Prescription Drug Events (RX), and the combined Total. 
- **MLR Trends by Race Group & SVC:** MLR by race group (All Beneficiaries, Caucasian, Black, Hispanic, Other) analyzed within each svc to find deeper segment-level differences.
- **Cost PMPM Trends:** Medicare's average spending on care for each beneficiary every month, segmented by svc and race group.
- **Count PMPM Trends:** The number of claims on average each beneficiary uses per month in order to get care, segmented by svc and race group.

The SQL queries used to inspect and clean the data for this analysis can be found here [link].

Targeted SQL queries regarding various business questions can be found here [link].

An interactive PowerBI dashboard used to report and explore sales trends can be found here [link].

# Data Structure & Initial Checks

The database structure as seen below for the CMS DE-SynPUF Medicare dataset consists of 4 tables: beneficiary_summary, outpatient_claims, carrier_claims, and prescript_drug_events, with a total row count of [228.6 Million records](./assets/DE_SynPUF_table_records_distribution.png) being used acrossed all 4 tables. A description of each table is as follows:
- **beneficiary_summary:** Each row represents an individual beneficiary in the study. This table can connect to any of the healthcare claims tables below with a JOIN on the columns year and DESYNPUF_ID. This table covers: basic patient information, months of enrollment by Medicare plan pt., the patient's chronic conditions, and different yearly payments and reimbursement.
- **outpatient_claims:** Each row is a unique claim from a beneficiary in one of these areas: ER visits, same-day/ambulatory surgeries, hospital clinic visits, diagnostic testing, and rehab therapies. The rows in this table and the tables below are identified by a combo of a claim ID and a claim date. The table is under pt. B of Medicare. This table covers: physician and provider information, procedure codes, diagnosis codes, coinsurance and deductible payment amounts, and HCPCS cost codes.
- **carrier_claims:** Each row is a unique claim from a  beneficiary in one of these areas: doctor office visits & imaging, minor procedures, pathology tests, and physician-administered drugs. This table is also under pt. B of Medicare. This table covers: claim info, ICD claim & line diagnosis codes, physician info, provider tax numbers, HCPCS cost codes, different types of payment amounts.
- **prescript_drug_events:** Each row is a unique claim about a prescription drug order from a specific  beneficiary that was handled by the pharmacies. This table solely covers pt. D of Medicare. This table covers: the type of drug dispensed, the quantity, the day supply, the patient payment amount, and the gross drug cost.


ERD for CMS 2008-2010 DE-SynPUF
[<img src="./assets/desynpuf_medicare_db.png" alt="Entity Relationship Diagram" width="800">](./assets/erd.png)

***Disclaimer:*** The outpatient_claims and carrier_claims tables had columns removed from the ERD diagram in order to fit in a singular screenshot because each table had 80+ columns. All removed columns were non-essential to the ERD.

# Executive Summary

### Overview of Findings

Add 1 more sentence related to the data analyst POV of the project, maybe tie in the so-what related to the data analyst POV that you still need to write. 

In the Total svc group Cost PMPM (+9.5%), Count PMPM (+6.3%), and MLR (+2.1%) rose modestly from 2008→2009; then from 2009→2010 they dropped sharply (−37.8%, −35.8%, −45.5%). These sharp declines a crossed all KPIs happenend due to 1 of 3 influences: positive influences (prevention, unit-price reductions, fewer complications, shift to home care), negative influences (higher patient cost sharing, tighter prior authorization, narrower networks, delayed claims), or a combination of both. The report further decomposes these KPIs by individual svc, race groups, and their component measures to identify what kinds of influences are driving these changes and evaluate how Medicare is performing. 

[![Executive summary](./assets/executive_summary.png)](./assets/executive_summary.png)

# Insights Deep Dive
### MLR by SVC:

- Total MLR (MLR where svc = Total) peaked at 301.0% in 2009—up +2.1% YoY from 2008—then fell -45.5% YoY in 2010 to 164.2%.

- The svc RX was the only svc with declines in MLR every year (-23.3% YoY 08->09 and -43.2% YoY 09->10). RX’s MLR fell from 552.2% (2008) to 240.7% in (2010). 

- The decline in RX's MLR is partly attributable to more beneficiaries with 12 months of Pt. D coverage: full-year enrollment rose from 53.2% (2008) to 74.7% (2010) in this sample.
  
- Just like the svc Total, OP’s and PROF’s MLR values peaked in 2009 at 95.9% and 173.6%, then fell in 2010 to 47.2% and 97.2%. In 2010, MLR declined across all service lines (YoY): Total −45.5%, OP −50.8%, PROF −44.0%, RX −43.2%.
  
- Allowed Cost is Medicare’s total annual spend on beneficiaries’ care and the numerator of MLR. Across OP, PROF, and RX, the relative distribution of Allowed Cost was stable, with a mean absolute YoY % change of 4.2%.


***Disclaimer:*** High Medical Loss Ratio (MLR) values in the 200–300% range in this report are not errors; they reflect that, unlike private insurers, Medicare is not funded solely by premiums. MLRs below 85% aren’t errors—Part B premiums can fully cover some service lines (e.g. OP), but this service-line view excludes the combined OP + PROF cost.
[![Insights Deep Dive](./assets/data_reads1.png)](./assets/data_reads1.png)


### MLR by Race Group and SVC:

- Total MLR by race group: All Beneficiaries (AB), Black, Caucasian, and Hispanic are tightly clustered, peaking in 2009 at 301.0–305.2%. The Other group peaks lower at 272.7% (vs. AB 301%) in 2009. In 2010 all groups declined by a similar margin (YoY −44.1% to −45.6%).

- OP MLR by race group: AB, Black, Caucasian, and Hispanic are tightly clustered, peaking in 2009 at 90.8–97.8%; Other peaks lower at 81.5% (vs. AB 95.9%). In 2010, all groups declined by a similar amount (YoY −49.0% to −50.9%). 

- PROF MLR by race group: The five groups are fairly evenly spaced, with inter-group ranges of ~15–32 points year over year. MLR peaked in 2009 at 144.5–176.9% (Other 144.5% vs. AB 173.6%). In 2010 all groups declined similarly (YoY −42.9% to −44.6%).
  
- RX MLR by race group: The Hispanic group’s MLR is consistently higher than the other four, with the widest gap in 2009 (526% vs. Black 451%, +75 pts). RX MLRs peak in 2008 (545.6–600.2%). Again, in 2010 all groups declined similarly (YoY −40.8% to −43.4%).


[![Insights Deep Dive](./assets/data_reads2.png)](./assets/data_reads2.png)


### Cost PMPM by Race Group and SVC:

- Cost PMPM uses Allowed Cost as its numerator—the same claims-dollar numerator as MLR—divided by member-months. Because the numerator trends are shared, Cost PMPM largely mirrors the MLR pattern: PROF, OP, and Total peak in 2009 at 167.4, 92.4, and 359.8 PMPM, then drop sharply in 2010, while RX peaks earlier at 154.2 in 2008 and declines thereafter. In 2010, Cost PMPM fell YoY across all service lines: Total −37.8%, OP −43.6%, PROF −35.8%, RX −40.2%.

- Despite the sharp decline in Total Cost PMPM by 2010, the denominator (member-months) was not the driver. Full-year enrollment was stable to rising: 87.3% of beneficiaries had 12 months of Part B or Part D coverage in 2008, increasing to 92.1% in 2010.
  
- Segmenting by race shows the same pattern. Total Cost PMPM for AB, Black, Caucasian, and Hispanic is tightly clustered, peaking in 2009 at 358.9–371.5 PMPM. The Other group peaks lower at 326.1 (vs. AB 359.8) in 2009. In 2010, all groups decline by a similar amount (YoY −36.5% to −38%).


[![Insights Deep Dive](./assets/data_reads3.png)](./assets/data_reads3.png)


### Count PMPM by Race Group and SVC:

- Count PMPM uses the same denominator as Cost PMPM—member-months—but a different numerator (claim counts, not dollars). Even so, it mirrors the MLR/Cost PMPM pattern: PROF, OP, and Total peak in 2009 at 1.5, 0.3, and 3.4 claims PMPM, then drop sharply in 2010, while RX peaks earlier at 2.5 in 2008 and declines thereafter. In 2010, Count PMPM falls YoY across all service lines: Total −35.8%, OP −44.0%, PROF −36.1%, RX −39.7%.

- Claim Count is the annual total number of claims and serves as the numerator of Count PMPM. Across OP, PROF, and RX, its service-line share was stable, with a mean absolute YoY %Δ  of 3.5%.

- PROF Count PMPM (Count where svc = PROFl) peaked at 1.5 claims PMPM in 2009—up +5% YoY from 2008—then fell -36.1% YoY in 2010 to 0.9.

- The decline in PROF Count PMPM is not explained by coverage duration: full-year Part B enrollment rose from 84.0% (2008) to 89.1% (2010) in this sample. This points to lower utilization per member, not a shrinking denominator.

- Total Count PMPM by race group mirrors the other KPIs: AB, Black, Caucasian, and Other are tightly clustered, peaking in 2009 at 3.3–3.4 claims PMPM, while Hispanic peaks higher at 3.8 (vs. AB 3.4). In 2010, all groups decline by a similar amount (YoY −34.8% to −35.9%).
  
[![Insights Deep Dive](./assets/data_reads4.png)](./assets/data_reads4.png)



# Recommendations:

Based on the insights and findings above, we would recommend the [stakeholder team] to consider the following: 

### Medicare's overall performance (talk about the overall values being bad and what this means,  not the trends all pointing in the same direction?
  
### The Underlying trends of the downward trajectories of the KPIs?
  
### Further Segmenting and digging deeper is not showing anything unexpected, recommended to take a step back before continuing?
  
### Can we conclude specifc positive or negative impacts that explain the results of the data? 
  
### What is the next step that should be taken? 


# Assumptions and Caveats:

Throughout the analysis, multiple assumptions were made to manage challenges with the data. These assumptions and caveats are noted below:

* Assumption 1 (ex: missing country records were for customers based in the US, and were re-coded to be US citizens)
  
* Assumption 1 (ex: data for December 2021 was missing - this was imputed using a combination of historical trends and December 2020 data)
  
* Assumption 1 (ex: because 3% of the refund date column contained non-sensical dates, these were excluded from the analysis)

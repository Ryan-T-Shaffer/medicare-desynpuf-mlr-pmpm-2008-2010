# Project Background
The CMS DE-SynPUF Medicare dataset was used to create an interactive dashboard that lets U.S. health plans benchmark year-over-year (YoY) trends in Cost PMPM, Count PMPM, and Medical Loss Ratio (MLR) across Medicare service lines and five race groups. The analysis is framed from the perspective of an in-house healthcare-analytics analyst to align insights with business questions.

A sentence of space was left in the project background for whatever POV this project wants to be framed in later. 

*How insights are evaluated in the report on the following key areas*:

- **MLR Trends by Service Line:** The amount of money Medicare's spending yearly on healthcare compared to the amount Medicare's is charging patients in premiums to pay for it. Service lines analyzed: Outpatient (OP), Carrier (PROF), Prescription Drug Events (RX), and the combined total. 
- **MLR Trends by Race Group & Service Line:** MLR by race group (all_races, Caucasian, Black, Hispanic, Other) analyzed within each service line to find deeper segment-level differences.
- **Cost PMPM Trends:** Medicare's average spending on care for each patient every month, segmented by service line and race group.
- **Count PMPM Trends:** The number of claims on average each patient uses per month in order to get care, segmented by service line and race group.

The SQL queries used to inspect and clean the data for this analysis can be found here [link].

Targeted SQL queries regarding various business questions can be found here [link].

An interactive PowerBI dashboard used to report and explore sales trends can be found here [link].

# Data Structure & Initial Checks

The database structure as seen below for the CMS DE-SynPUF Medicare dataset consists of 4 tables: beneficiary_summary, outpatient_claims, carrier_claims, and prescript_drug_events, with a total row count of [228.6 Million records](./assets/DE_SynPUF_table_records_distribution.png) being used acrossed all 4 tables.  A description of each table is as follows:

- **beneficiary_summary:** The reference table of all the patients for the entire dataset. All JOINS occour when this table is used to connect a patient to their healthcare claims in 1 of the other 3 tables. Each row in this datatset when seperated by year represents an indiviudal patient who is a part of the study. JOINS to the other tables are done by using the composite PRIMARY KEY (PK) (year,DESYNPUF_ID). This table broadly consist of the following information in this order: basic but differentiable patient information, months of purchased coverage for different parts of Medicare for that year, chronic conditions the patient has, and different yearly payment and remibursement amounts.
- **outpatient_claims:** This table of healthcare claims consist mainly of these specific categories: chiefly emergency department visits, same-day/ambulatory surgeries and procedures, hospital-based clinic/observation visits, diagnostic imaging and testing, and rehabilitative therapies. This table is under part B of Medicare. Each row is a unique healthcare claim from a singular patient that is related to one of the categories listed above, and is identified in the database by the PK (CLM_FROM_DT, CLM_ID) which is just the claim date and claim id. The outpatient_claims table columns consist of info about the claim, physican and provider information, procedure codes used, diagnosis codes used, coinsurance and deductible payment amounts, and HCPCS cost codes used. 
- **carrier_claims:** This table of healthcare claims consist mainly of these specific categories: doctor office/clinic visits and check-ups, minor procedures and injections, lab/pathology tests, physician-office imaging, and physician-administered drugs. This table is also under part B of Medicare. Each row is a unique healthcare claim from a singular patient that is related to one of the categories listed above, and is identified in the database by the PK (CLM_FROM_DT, CLM_ID) which is just the claim date and claim id. The carrier_claims table columns consist of info about the claim, ICD claim diagnosis codes, physican info and provider tax number, HCPCS cost codes, payemnt amounts, deductible amounts, other payment amounts, and ICD line diagnosis codes. 
- **prescript_drug_events:** This table consist of all of the healthcare claims related to prescription drug orders handled by pharmacies. This table is solely responsible for caclulations on part D of Medicare. Each row is a unique healthcare claim that is a prescription drug order identified in the database by the PK (SRVC_DT, PDE_ID) which is just the claim date and claim id. Besides the already discussed columns the table listt info on the type of drug dispensed, the quantity, the day supply, the patient pay amount, and the gross drug cost. 

ERD for CMS 2008-2010 DE-SynPUF
[<img src="./assets/desynpuf_medicare_db.png" alt="Entity Relationship Diagram" width="800">](./assets/erd.png)

***Disclaimer:*** The outpatient_claims and carrier_claims tables were shortened in the ERD diagram in order to fit in a singular screenshot because each table had 80+ columns. Anywhere a column ends with "_..." means there were columns removed in order to save space because the names changed incrementally like "_1", "_2" , "_3". All columns removed from the ERD were non-essential.

# Executive Summary

### Overview of Findings

From 2008→2009, Cost PMPM (+9.5%), Count PMPM (+6.3%), and MLR (+2.1%) rose modestly; from 2009→2010 they dropped sharply (−37.8%, −35.8%, −45.5%). The 2010 declines indicate lower utilization, spend per member, and a lower claims-to-revenue ratio—consistent with either positive reasons (prevention, unit-price reductions, fewer complications, shift to home care), negative reasons (higher patient cost sharing, tighter prior auth, narrower networks, delayed claims), or a combination of both. The report decomposes these KPIs by service line, race group, and their component measures to identify what is driving this change and evaluate how Medicare is performing. 

[![Executive summary](./assets/executive_summary.png)](./assets/executive_summary.png)

# Insights Deep Dive
### Category 1:

- Analyzing MLR values by service line (OP, PROF, RX) and in total, highlighting how claims costs are changing relative to premium revenue aka how much money is Medicare spending on healthcare compared to the amount money Medicare is charging in premiums to pay for it.  are using. Additionally, using %Δ YoY to compare values MLR overtime. Lastly, the componet measure of MLR, claims cost, was evluated using percent distirbutions. 

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

***Disclaimer:*** High Medical Loss Ratio (MLR) values in the 200–300% range in this report are not errors; they reflect that, unlike private insurers, Medicare is not funded solely by premiums. Medicare’s claim costs are covered by multiple sources—primarily payroll taxes and general federal revenues, along with beneficiary premiums—so an MLR calculated with premiums as the denominator can legitimately exceed well over 100%. (Note: Medicare Advantage plans not available in this dataset follow a commercial-style MLR with an 85% minimum; the 200–300% figures apply only to this premium-only calculation for Medicare.)

[Visualization specific to category 1]


### Category 2:

YoY MLR comparison across race groups within each service line to surface segment-level takeaways using %Δ YoY to compare values. 

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

[Visualization specific to category 2]


### Category 3:

YoY change in Cost PMPM by service line, showing how total claim costs **per member-month** are changing as well the underlying percent distributions of this metric.

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

[Visualization specific to category 3]


### Category 4:

YoY change in Count PMPM by service line, showing how service/claim counts per member-month are changing as well as underlying percent distributions of this metric.

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

[Visualization specific to category 4]



# Recommendations:

Based on the insights and findings above, we would recommend the [stakeholder team] to consider the following: 

* Specific observation that is related to a recommended action. **Recommendation or general guidance based on this observation.**
  
* Specific observation that is related to a recommended action. **Recommendation or general guidance based on this observation.**
  
* Specific observation that is related to a recommended action. **Recommendation or general guidance based on this observation.**
  
* Specific observation that is related to a recommended action. **Recommendation or general guidance based on this observation.**
  
* Specific observation that is related to a recommended action. **Recommendation or general guidance based on this observation.**
  


# Assumptions and Caveats:

Throughout the analysis, multiple assumptions were made to manage challenges with the data. These assumptions and caveats are noted below:

* Assumption 1 (ex: missing country records were for customers based in the US, and were re-coded to be US citizens)
  
* Assumption 1 (ex: data for December 2021 was missing - this was imputed using a combination of historical trends and December 2020 data)
  
* Assumption 1 (ex: because 3% of the refund date column contained non-sensical dates, these were excluded from the analysis)

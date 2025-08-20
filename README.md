# Medicare-DESYNPUF-DA-Report-1
This is a Data Analyst Report about the CMS DESYNPUF Medicare dataset for the KPIs per member per month (PMPM) Medical Cost, PMPM Claim Count, and Medical Loss Ratio (MLR).

# Project Background
Using the CMS DE-SynPUF Medicare dataset, I built an interactive dashboard that lets U.S. health plans benchmark year-over-year (YoY) Cost PMPM, Count PMPM, and MLR trends across different Medicare service lines and five distinct race groups. I approached the project as an in-house analyst at a healthcare-analytics firm to shape the insights delivered from business questions.

*How insights are evaluated in the report on the following key areas*:

- **MLR Trends by Service Line:** YoY MLR by service line and in total, highlighting where claim costs are rising fastest relative to premium revenue using %Δ YoY to compare values. Underlying percent distirbutions of claims cost also evaluated. 
- **MLR Trends by Race Group & Service Line:** YoY MLR comparison across race groups within each service line to surface segment-level takeaways using %Δ YoY to compare values. 
- **Cost PMPM Trends:** YoY change in Cost PMPM by service line, showing how total claim costs **per member-month** are changing as well the underlying percent distributions of this metric.
- **Count PMPM Trends:** YoY change in Count PMPM by service line, showing how service/claim counts per member-month are changing as well as underlying percent distributions of this metric.

The SQL queries used to inspect and clean the data for this analysis can be found here [link].

Targed SQL queries regarding various business questions can be found here [link].

An interactive PowerBI dashboard used to report and explore sales trends can be found here [link].

# Data Structure & Initial Checks

The database structure as seen below for CMS 2008-2010 DE-SynPUF consists of 4 tables: beneficiary_summary, outpatient_claims, carrier_claims, and prescript_drug_events, with a total row count of 228.6 Millon records being used acrossed all 4 tables. A description of each table is as follows:

- **beneficiary_summary:** The reference table of all the patients for the entire dataset. All JOINS occour when this table is used to connect a patient to their healthcare claims in 1 of the other 3 tables. Each row in this datatset when seperated by year represents an indiviudal patient who is a part of the study. JOINS to the other tables are done by using the composite PRIMARY KEY (PK) (year,DESYNPUF_ID). This table broadly consist of the following information in this order: basic but differentiable patient information, months of purchased coverage for different parts of Medicare for that year, deadly health conditions the patient currently has, and different yearly payment and remibursement amounts. There are a total of 2.2-2.3M patients in this study YoY.
- **outpatient_claims:** This table of healthcare claims consist mainly of these specific categories: chiefly emergency department visits, same-day/ambulatory surgeries and procedures, hospital-based clinic/observation visits, diagnostic imaging and testing, and rehabilitative therapies. This table is under part B of Medicare. Each row is a unique healthcare claim from a singular patient that is related to one of the categories listed above, and is identified in the database by the PK (CLM_FROM_DT, CLM_ID) which is just the claim date and claim id. The outpatient_claims table columns consist of info about the claim, physican and provider information, procedure codes used, diagnosis codes used, coinsurance and deductible payment amounts, and HCPCS cost codes used. 
- **carrier_claims:** This table of healthcare claims consist mainly of these specific categories: doctor office/clinic visits and check-ups, minor procedures and injections, lab/pathology tests, physician-office imaging, and physician-administered drugs. This table is also under part B of Medicare. Each row is a unique healthcare claim from a singular patient that is related to one of the categories listed above, and is identified in the database by the PK (CLM_FROM_DT, CLM_ID) which is just the claim date and claim id. The carrier_claims table columns consist of info about the claim, ICD claim diagnosis codes, physican info and provider tax number, HCPCS cost codes, payemnt amounts, deductible amounts, other payment amounts, and ICD line diagnosis codes. 
- **prescript_drug_events:** This table consist of all of the healthcare claims related to prescription drug orders handled by pharmacies. This table is solely responsible for caclulations on part D of Medicare. Each row is a unique healthcare claim that is a prescription drug order identified in the database by the PK (SRVC_DT, PDE_ID) which is just the claim date and claim id. Besides the already discussed columns the table listt info on the type of drug dispensed, the quantity, the day supply, the patient pay amount, and the gross drug cost. 

ERD for CMS 2008-2010 DE-SynPUF
[<img src="./assets/desynpuf_medicare_db.png" alt="Entity Relationship Diagram" width="800">](./assets/erd.png)

***Disclaimer:*** The outpatient_claims and carrier_claims tables were shortened in the ERD diagram in order to fit in a singular screenshot because each table had 80+ columns. Anywhere a column ends with "_..." means there were columns removed in order to save space because the names changed incrementally like "_1", "_2" , "_3". All columns removed from the ERD were non-essential.

# Executive Summary

### Overview of Findings

Explain the overarching findings, trends, and themes in 2-3 sentences here. This section should address the question: "If a stakeholder were to take away 3 main insights from your project, what are the most important things they should know?" You can put yourself in the shoes of a specific stakeholder - for example, a marketing manager or finance director - to think creatively about this section.

[Visualization, including a graph of overall trends or snapshot of a dashboard]

# Insights Deep Dive
### Category 1:

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

***Disclaimer:*** High Medical Loss Ratio (MLR) values in the 200–300% range in this report are not errors; they reflect that, unlike private insurers, Medicare is not funded solely by premiums. Medicare’s claim costs are covered by multiple sources—primarily payroll taxes and general federal revenues, along with beneficiary premiums—so an MLR calculated with premiums as the denominator can legitimately exceed well over 100%. (Note: Medicare Advantage plans not available in this dataset follow a commercial-style MLR with an 85% minimum; the 200–300% figures apply only to this premium-only calculation for Medicare.)

[Visualization specific to category 1]


### Category 2:

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

[Visualization specific to category 2]


### Category 3:

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

[Visualization specific to category 3]


### Category 4:

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

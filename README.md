# Medicare-DESYNPUF-DA-Report-1
This is a Data Analyst Report about the CMS DESYNPUF Medicare dataset for the KPIs per member per month (PMPM) Medical Cost, PMPM Claim Count, and Medical Loss Ratio (MLR).

# Project Background
Using the CMS DE-SynPUF Medicare dataset, I built an interactive dashboard that lets U.S. health plans benchmark year-over-year (YoY) Cost PMPM, Count PMPM, and MLR trends across different Medicare service lines and five distinct race groups. I approached the project as an in-house analyst at a healthcare-analytics firm to shape the insights delivered from business questions.

***Insights and recommendations are provided on the following key areas***:

- **MLR Trends by Service Line:** YoY MLR by service line and in total, highlighting where claim costs are rising fastest relative to premium revenue using %Δ YoY to compare values. Underlying percent distirbutions of claims cost also evaluated. 
- **MLR Trends by Race Group & Service Line:** YoY MLR comparison across race groups within each service line to surface segment-level takeaways using %Δ YoY to compare values. 
- **Cost PMPM Trends:** YoY change in Cost PMPM by service line, showing how total claim costs **per member-month** are changing as well the underlying percent distributions of this metric.
- **Count PMPM Trends:** YoY change in Count PMPM by service line, showing how service/claim counts per member-month are changing as well as underlying percent distributions of this metric.


Do this eventually: 
The SQL queries used to inspect and clean the data for this analysis can be found here [link].

Targed SQL queries regarding various business questions can be found here [link].

An interactive Tableau dashboard used to report and explore sales trends can be found here [link].



# Data Structure & Initial Checks

The companies main database structure as seen below consists of four tables: table1, table2, table3, table4, with a total row count of X records. A description of each table is as follows:
- **Table 2:**
- **Table 3:**
- **Table 4:**
- **Table 5:**

[<img src="./assets/desynpuf_medicare_db.png" alt="Entity Relationship Diagram" width="800">](./assets/erd.png)





# Executive Summary

### Overview of Findings

Explain the overarching findings, trends, and themes in 2-3 sentences here. This section should address the question: "If a stakeholder were to take away 3 main insights from your project, what are the most important things they should know?" You can put yourself in the shoes of a specific stakeholder - for example, a marketing manager or finance director - to think creatively about this section.

[Visualization, including a graph of overall trends or snapshot of a dashboard]


***Disclaimer:*** High Medical Loss Ratio (MLR) values in the 200–300% range in this report are not errors; they reflect that, unlike private insurers, Medicare is not funded solely by premiums. Medicare’s claim costs are covered by multiple sources—primarily payroll taxes and general federal revenues, along with beneficiary premiums—so an MLR calculated with premiums as the denominator can legitimately exceed well over 100%. (Note: Medicare Advantage plans not available in this dataset follow a commercial-style MLR with an 85% minimum; the 400–500% figures apply only to this premium-only calculation for Medicare.)

# Insights Deep Dive
### Category 1:

* **Main insight 1.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 2.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 3.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.
  
* **Main insight 4.** More detail about the supporting analysis about this insight, including time frames, quantitative values, and observations about trends.

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

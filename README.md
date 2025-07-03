# Critical Care ICU Infection Data Analysis

## Project Overview

This project delves into the Critical Care Database from Zigong Fourth People’s Hospital, a valuable open-access dataset designed to address the scarcity of ICU data from China. It contains high-granularity electronic health records for adult ICU patients admitted with infections (including sepsis and septic shock) between January 2019 and December 2020.

The analysis aims to extract meaningful insights from this rich dataset, covering patient demographics, ICU stay dynamics, infection trends, treatment patterns, and patient outcomes. All data is de-identified following HIPAA guidelines, with temporal information shifted to protect patient privacy.

## Project Objectives

The core objectives of this data analysis project are to:

* **Understand ICU Infection Trends:** Analyze the prevalence and patterns of infections within the ICU.
* **Patient Demographics & Admissions:** Explore basic patient characteristics and admission trends.
* **ICU Stay & Mortality:** Analyze the duration of ICU stays (ICULOS) and mortality rates.
* **Identify Common Anomalies:** Pinpoint frequent infections, lab abnormalities, and prescribed treatments.
* **Assess Medication Patterns:** Examine drug administration patterns and their potential correlation with patient outcomes.
* **Diagnostic Insights:** Investigate the underlying reasons for specific health events or conditions.
* **Predictive Analysis:** Identify risk factors and support intervention planning based on historical data.

## Data Source

The dataset used is the publicly available Critical Care Database from Zigong Fourth People’s Hospital. It comprises seven interlinked tables:

* `baseline`: Patient demographics and admission/discharge information.
* `drugs`: Medication administration records.
* `icd`: International Classification of Diseases (ICD) codes for diagnoses.
* `lab`: Laboratory test results.
* `nursingchart`: Nursing chart data, including vital signs and observations.
* `outcome`: Patient outcomes (e.g., mortality, general health post-discharge).
* `transfer`: Patient transfer records between departments.

## Tools and SQL Techniques Used

* **Database:** PostgreSQL
* **Query Execution:** pgAdmin
* **SQL Techniques:**
    * `JOIN` operations across seven relational tables to integrate diverse datasets.
    * `AGGREGATIONS` (`COUNT`, `AVG`, `SUM`) for summary statistics.
    * `WINDOW FUNCTIONS` (`ROW_NUMBER`, `RANK`, `AVG OVER`, `LAG`, `PERCENTILE_CONT`) for calculating trends, rankings, and time-based comparisons.
    * `CTEs` (Common Table Expressions) and `subqueries` for modular, layered analysis and improved readability.
    * `CASE` statements for conditional logic and classification (e.g., infection severity).
    * `Stored Procedures`/`Functions` for encapsulating reusable query logic.
    * Date and time functions (`EXTRACT`, `TO_CHAR`, `AGE`, `DATE_PART`) for time-based analysis.
    * Statistical functions (`CORR`, `STDDEV_STAMP`) for correlation and outlier detection.

## Analysis Highlights & Key Queries

The SQL script `critical_care_icu-analysis.sql` contains a series of queries organized into "Descriptive," "Exploratory," "Diagnostic," and "Predictive" analysis sections. Here are some of the key areas explored:

### 1. Demographics & Admissions

* Counting patients discharged in specific years (e.g., 2020).
* Analyzing drug counts per patient aged 65+.
* Understanding monthly discharge distributions.

### 2. ICU Transfers & Stay

* Calculating average ICU stay duration for transferred patients, broken down by outcome (alive/deceased).
* Identifying the hour of the day with the least ICU discharges.
* Listing recent patient transfers and discharges.

### 3. Trends & Common Patterns

* Identifying the most commonly administered drug for each department using window functions.
* Finding the average age in each department.
* Analyzing average length of stay for specific infection types (e.g., Soft Tissue infections).
* Comparing average time spent across departments for alive vs. deceased patients.

### 4. Vital Signs & Lab Values

* Correlating blood sugar levels with ICU discharge time using `CORR` function and epoch time conversion.
* Calculating average, minimum, and maximum systolic blood pressure for patients in each department.
* Identifying patients with abnormal vital signs (e.g., temperature above 38°C, heart rate fluctuations).
* Pinpointing patients whose blood sugar is in the 99th percentile.
* Detecting outliers in heart rate using standard deviations.

### 5. Medical Conditions & Drug Usage

* Tracking patients whose breathing tubes have been removed (`extubation`).
* Identifying the most administered drug overall and among specific patient cohorts (e.g., patients who were never intubated).
* Analyzing drug administration times (e.g., drugs administered between 4 AM and 5 AM).
* Investigating patients with specific medical conditions (e.g., hypoproteinemia and intubation rates).

### 6. Sepsis & Outcomes

* Identifying patients with specific pain scores (e.g., CPOT score of 0).
* Calculating the percentage of alive patients with a "poor" general health status post-discharge.

### 7. Predictive & Intervention Planning

* Using CTEs to calculate the percentage of hypoproteinemia patients requiring intubation, providing insights into risk factors.
* Implementing a stored procedure (`totalpatients_dept`) to calculate total patients per department, useful for administrative queries.

## Conclusion

This SQL-based analysis provides a comprehensive overview of patient demographics, treatment patterns, vital signs, and outcomes within the Critical Care ICU Infection Dataset. From exploring the dataset's structure to performing intricate diagnostic and predictive analyses, the project yielded valuable insights into ICU operations and patient care.

Key takeaways include:
* Understanding time-based patterns in ICU discharges and patient flow.
* Identifying frequently prescribed medications and their distribution across departments.
* Detecting critical vital sign anomalies and tracking disease progression.
* Uncovering correlations between lab values, clinical observations, and patient outcomes.
* Providing foundational insights for potential risk factor identification and intervention planning in an ICU setting.

This project demonstrates the power of SQL for in-depth clinical data analysis, transforming raw healthcare data into actionable knowledge that can inform hospital management, treatment protocols, and future research.



## Author

**Nidhi Singhal**
(https://www.linkedin.com/in/nidhi-singhal-b91aa0b9/)

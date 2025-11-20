# Hospital Operational Fragility Analysis

![SQL](https://img.shields.io/badge/Language-SQL%20(BigQuery)-orange)
![Analysis](https://img.shields.io/badge/Analysis-Operational%20Risk-red)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

## Project Overview
Most hospital analyses focus on disaster scenarios. This project takes a different approach: identifying **routine operational fragility**. [cite_start]It addresses the fundamental challenge of pinpointing which departments compromise patient quality during normal operational stresses, such as staff absence, capacity strain, and morale fluctuation[cite: 2].

[cite_start]By analyzing weekly service data, this project establishes quantifiable, data-driven links between internal staff metrics (morale, attendance) and external patient outcomes (satisfaction, risk exposure)[cite: 3].

---

## Table of Contents
- [Project Overview](#-project-overview)
- [Strategic Questions](#-strategic-questions)
- [Data Dictionary](#-data-dictionary)
- [Analysis Workflow](#-analysis-workflow)
- [Key Insights](#-key-insights)
- [Strategic Recommendations](#-strategic-recommendations)
- [Technologies Used](#-technologies-used)

---

## Strategic Questions
[cite_start]The analysis focuses on three high-impact questions to identify root causes of quality failure[cite: 5]:

1.  [cite_start]**The Hidden Cost of Refusal:** Where is capacity strain actively damaging patient satisfaction for admitted patients? [cite: 7]
2.  [cite_start]**Staff Morale & Vulnerability:** Are vulnerable patients (very young/old) being admitted to high-risk environments where staff stress is high? [cite: 10]
3.  [cite_start]**Morale-Driven Quality Collapse:** Which service is most vulnerable to a crash in patient satisfaction when staff morale drops below a critical threshold? [cite: 13]

---

## Data Dictionary
The analysis utilizes a relational database with the following key tables:

* **`services_weekly`**: Aggregated weekly metrics including `patients_refused`, `patients_request`, `patient_satisfaction`, and `staff_morale`.
* **`patients`**: Individual patient records with `arrival_date`, `departure_date`, and `age`.
* **`staff_schedule`**: Staff attendance records (`present` status) used to calculate absence rates.

---

## Analysis Workflow

### 1. Capacity & Satisfaction Analysis
* **Refusal Quartiles:** Used SQL Window Functions (`NTILE`) to segment weeks into "High" vs. "Low" refusal periods.
* [cite_start]**Satisfaction Delta:** Calculated the difference in patient satisfaction scores between these high-stress and low-stress periods to measure resilience[cite: 8].

### 2. Bottleneck Identification
* [cite_start]**ALOS Calculation:** Calculated **Average Length of Stay (ALOS)** for each service to identify operational bottlenecks driving capacity strain[cite: 8].

### 3. Risk Scoring (Complex Joins)
* **Vulnerability Metric:** Created a weighted risk score by joining weekly staff absence rates with the count of vulnerable patients (Age < 10 or > 75).
* [cite_start]**Logic:** `Risk Score = Vulnerable Patient Count / Weekly Absence Rate`[cite: 11].

### 4. Morale Impact Analysis
* [cite_start]**Conditional Aggregation:** Used `SUM(CASE WHEN...)` to compare patient satisfaction during "High Morale" (>=70) vs. "Low Morale" (<70) weeks to find the "Quality Collapse Delta"[cite: 14].

---

## Key Insights

### [cite_start]1. The Cost of Strain [cite: 8]
* **Satisfaction Drop:** **General Medicine** and **Surgery** suffered a satisfaction drop of **-5.46 points** during high-refusal weeks.
* **Resilience:** In contrast, Emergency and ICU departments showed resilience, maintaining satisfaction levels even during high capacity strain.
* **Bottleneck:** **Surgery** was identified as the primary bottleneck with an Average Length of Stay (ALOS) of **7.87 days**.

### [cite_start]2. Operational Fragility [cite: 11]
* **Emergency Risk:** The highest vulnerability risk score (**97.47**) was recorded in the **Emergency** department.
* **Protocol Failure:** This occurred during a week with only **5.13% staff absence**, proving that the triage protocol is dangerously fragile even to routine strain.

### [cite_start]3. Morale Sensitivity [cite: 14]
* **Direct Correlation:** The **ICU** showed the highest positive delta (**+3.42 points**), proving that patient quality in the ICU is directly tied to staff morale.
* **Compensatory Behavior:** Surgery and General Medicine showed a *negative* delta (satisfaction actually increased when morale was low), suggesting dedicated staff are over-compensating for systemic failures.

---

## Strategic Recommendations

[cite_start]Based on the data, the following actions are recommended to fix root causes[cite: 16, 19]:

1.  **ICU Morale Intervention:**
    * **Action:** Implement a **Morale-Linked Workload Cap**.
    * **Why:** ICU quality is statistically most sensitive to staff morale fluctuations.

2.  **Surgery Process Improvement:**
    * **Action:** Mandate a targeted reduction in **Average Length of Stay (ALOS)**.
    * **Why:** Surgery's 7.87-day ALOS is the primary bottleneck causing facility-wide capacity strain.

3.  **Emergency Triage Update:**
    * **Action:** Develop an **Adaptive Triage Protocol**.
    * **Why:** Implement automated alerts to flag vulnerable patient admissions (Age <10/>75) whenever staff absence exceeds a specific limit, as current protocols fail even under minor stress.

---

## Technologies Used
* **SQL (BigQuery):** CTEs, Window Functions, Joins, Conditional Aggregation.
* **Data Modeling:** KPIs formulation (Vulnerability Risk Score, Quality Collapse Delta).

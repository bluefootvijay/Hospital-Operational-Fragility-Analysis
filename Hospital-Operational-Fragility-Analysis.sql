



--The Hidden Cost of Refusal: Resource Allocation vs. Patient Experience
--Question 1 : Where is capacity strain actively damaging patient satisfaction and leading to quality erosion?

--Refusal Rate

select round(avg(patients_refused/patients_request)*100,2) as refusal_rate
from `project-resume-474806.HospitalBeds.services_weekly`;



--Refusal rate group by service

select service,round(avg(patients_refused/patients_request)*100,2) as refusal_rate
from `project-resume-474806.HospitalBeds.services_weekly`
group by service ;



--Calculating the Satisfaction Delta 

WITH Weekly_Refusal_Tiers AS (
    -- Weekly Refusal Rate and rank weeks by stress level
    SELECT
        service,
        patient_satisfaction,
        (patients_refused / patients_request) AS refusal_rate,
        
        -- Rank 1 = Highest Refusal Rate (Most Stressed)
        -- Rank 4 = Lowest Refusal Rate (Least Stressed)
        NTILE(4) OVER (
            PARTITION BY service
            ORDER BY (patients_refused / patients_request) DESC
        ) AS refusal_quartile
    FROM 
        `project-resume-474806.HospitalBeds.services_weekly`
    -- to avoid division errors and non-data points
    WHERE 
        patients_request > 0
)
SELECT
    service,
    
    
    ROUND(AVG(
        CASE WHEN refusal_quartile = 4 THEN patient_satisfaction END
    ), 2) AS Avg_Satisfaction_Low_Refusal,

   
    ROUND(AVG(
        CASE WHEN refusal_quartile = 1 THEN patient_satisfaction END
    ), 2) AS Avg_Satisfaction_High_Refusal,

    --Calculate the final Delta
    ROUND((
        AVG(CASE WHEN refusal_quartile = 4 THEN patient_satisfaction END) - 
        AVG(CASE WHEN refusal_quartile = 1 THEN patient_satisfaction END)
    ), 2) AS Satisfaction_Delta
FROM 
    Weekly_Refusal_Tiers
GROUP BY 
    service
ORDER BY 
    Satisfaction_Delta DESC;


-------------------------------------------------------------------------------

--Average Length of Stay (ALOS - difference between departure and arrival dates)

SELECT
    t1.service,
    ROUND(AVG(
        DATE_DIFF(
            SAFE_CAST(t1.departure_date AS DATE), 
            SAFE_CAST(t1.arrival_date AS DATE), 
            DAY
        )
    ), 2) AS ALOS_in_Days
FROM
    `project-resume-474806.HospitalBeds.patients` AS t1
GROUP BY 1
ORDER BY ALOS_in_Days DESC;

----------------------------------------------------------------------------------------------------------------------------------

--Staff Morale and Patient Age Risk: The Vulnerability Metric
--Question 2 : Are vulnerable patients (very young or very old) being admitted during periods when our staff is demonstrably stressed (low morale/high absence)?

SELECT
    week,
    service,
    
    COUNT(*) AS total_scheduled_days,
    SUM(CASE WHEN present = 0 THEN 1 ELSE 0 END) AS total_absent_days,
    ROUND(
        SUM(CASE WHEN present = 0 THEN 1 ELSE 0 END)*100 / COUNT(*),
        2
    ) AS weekly_absence_rate
FROM
    `project-resume-474806.HospitalBeds.staff_schedule` 
GROUP BY
    week,
    service
ORDER BY
    week,
    service;


--Weekly Vulnerable Patient Count (Patients Table)

SELECT
    EXTRACT(WEEK FROM SAFE_CAST(arrival_date AS DATE)) AS week,
    service,
    
    SUM(
        CASE
            WHEN age < 10 OR age > 75 THEN 1
            ELSE 0
        END
    ) AS vulnerable_patient_count
FROM
    `project-resume-474806.HospitalBeds.patients` 
GROUP BY
    1, 2 
ORDER BY
    week,
    service;


--Joining Absence Rate and Vulnerability 
WITH
Absence_Rate_CTE AS (
    SELECT
        week,
        service,
        ROUND(SUM(CASE WHEN present = 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS weekly_absence_rate
    FROM
        `project-resume-474806.HospitalBeds.staff_schedule`
    GROUP BY 1, 2
),

Vulnerable_Patients_CTE AS (
    SELECT
        EXTRACT(WEEK FROM SAFE_CAST(arrival_date AS DATE)) AS week,
        service,
        SUM(
            CASE WHEN age < 10 OR age > 75 THEN 1 ELSE 0 END
        ) AS vulnerable_patient_count
    FROM
        `project-resume-474806.HospitalBeds.patients`
    GROUP BY 1, 2
)

-- Joining the two metrics and calculating the final KPI
SELECT
    A.week,
    A.service,
    A.weekly_absence_rate,
    V.vulnerable_patient_count,
    
    CASE
        WHEN A.weekly_absence_rate = 0 THEN NULL 
        ELSE ROUND(V.vulnerable_patient_count / A.weekly_absence_rate, 2)
    END AS vulnerability_risk_score

FROM
    Absence_Rate_CTE AS A
INNER JOIN
    Vulnerable_Patients_CTE AS V
ON
    A.week = V.week AND A.service = V.service

WHERE
    A.weekly_absence_rate < 1.0

ORDER BY
    vulnerability_risk_score DESC,
    A.weekly_absence_rate DESC;


    -----------------------------------------------------------------------------------------------------------------------------

--Morale-Driven Quality Collapse: The Staff-Patient Disconnect
--Question 3 : Which service is most vulnerable to a patient satisfaction crash when staff morale drops below a critical threshold (e.g., below 70), indicating a direct link between staff well-being and patient quality?


WITH
Morale_Segmented_Performance AS (
    SELECT
        service,
        
        SUM(CASE WHEN staff_morale >= 70 THEN patient_satisfaction ELSE 0 END) AS total_sat_high_morale,
        SUM(CASE WHEN staff_morale >= 70 THEN 1 ELSE 0 END) AS count_weeks_high_morale,

      
        SUM(CASE WHEN staff_morale < 70 THEN patient_satisfaction ELSE 0 END) AS total_sat_low_morale,
        SUM(CASE WHEN staff_morale < 70 THEN 1 ELSE 0 END) AS count_weeks_low_morale
    FROM
        `project-resume-474806.HospitalBeds.services_weekly`
    GROUP BY 1
)

-- Calculate the average satisfaction
SELECT
    service,
    
    ROUND(
        total_sat_high_morale / NULLIF(count_weeks_high_morale, 0), 2
    ) AS avg_sat_high_morale,
    
    ROUND(
        total_sat_low_morale / NULLIF(count_weeks_low_morale, 0), 2
    ) AS avg_sat_low_morale,

    ROUND(
        (total_sat_high_morale / NULLIF(count_weeks_high_morale, 0)) - 
        (total_sat_low_morale / NULLIF(count_weeks_low_morale, 0)), 2
    ) AS quality_collapse_delta
FROM
    Morale_Segmented_Performance
WHERE
    count_weeks_high_morale > 0 AND count_weeks_low_morale > 0
ORDER BY
    quality_collapse_delta DESC;




























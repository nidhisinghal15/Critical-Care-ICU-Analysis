
-- Demographics & Admissions

--1. Descriptive Analysis (What happened?)
--Goal: Explore basic details of the dataset, count records, and check the structure of tables

--Preview key tables to understand structure

 select * from public.baseline
 select * from public.drugs
 select * from public.icd
 select * from public.lab
 select * from public.nursingchart
 select * from public.outcome
 select * from public.transfer

-- Count of columns in the nursingchart table.

select count(*)as column_count
from information_schema.columns         
where table_name = 'nursingchart'

-- Number of patients discharged in 2020 

 select count(patient_id)as patient_discharged_2020
 from public.baseline
 where EXTRACT(year from icu_discharge_time)=2020 

 or 

 SELECT COUNT(patient_id) AS patient_discharged_2020
FROM public.baseline
WHERE icu_discharge_time BETWEEN '2020-01-01' AND '2020-12-31 23:59:59';


-- Drug count per patient aged 65+

SELECT b.patient_id,COUNT(DISTINCT d.drugname) AS drug_count
FROM baseline b
JOIN drugs d ON b.patient_id = d.patient_id
WHERE b.age >= 65
GROUP BY b.patient_id
ORDER BY drug_count DESC;

-- ICU TRANSFERS & STAY

-- Monthly discharge distribution

SELECT EXTRACT(MONTH FROM icu_discharge_time) AS month_no,
       TO_CHAR(icu_discharge_time, 'FMMonth') AS month, 
       COUNT(patient_id) AS num_patients_discharged
FROM baseline
WHERE icu_discharge_time IS NOT NULL
GROUP BY month_no, month
ORDER BY month_no;

--Average ICU stay duration (for patients who had transfers), by outcome
with duration as (
select patient_id, max(stoptime) - min(starttime) as duration
from transfer 
group by 1
)
select follow_vital as dead_alive, count(o.patient_id), avg(duration)  as avg_duration
from duration d, outcome o
where d.patient_id = o.patient_id
and follow_vital is not null
group by 1


--Time-based analysis

-- Display the month name and the number of patients discharged from the ICU in that month.

SELECT EXTRACT(MONTH FROM icu_discharge_time) AS month_no,
       TO_CHAR(icu_discharge_time, 'FMMonth') AS month, 
       COUNT(patient_id) AS num_patients_discharged
FROM baseline
WHERE icu_discharge_time IS NOT NULL
GROUP BY month_no, month
ORDER BY month_no;


--Show the hour (as a time slot like 9 AM - 10 AM) when the least discharges happen.*/

SELECT COUNT(PATIENT_ID) AS DISCHARGE_COUNT,  
concat(DATE_PART('HOUR',(ICU_discharge_time)),' Oclock to ',(DATE_PART('HOUR',(ICU_discharge_time))+1),' Oclock' )
AS Time_Range
FROM baseline
GROUP BY DATE_PART('HOUR',(ICU_discharge_time))
ORDER BY  DISCHARGE_COUNT ASC
limit 1


select concat(case when extract(hour from icu_discharge_time) % 12 = 0 then 12 else extract(hour from icu_discharge_time) % 12 end, ' ',
        case when extract(hour from icu_discharge_time) < 12 then 'AM' else 'PM' end,
        ' - ', 
        (extract(hour from icu_discharge_time) + 1) % 12, ' ',
        case when (extract(hour from icu_discharge_time) + 1) < 12 or (extract(hour from icu_discharge_time) + 1) = 24 then 'AM' else 'PM' end
    ) as discharge_slot,
    count(*) as discharge_count
from baseline
group by 1
order by 2
limit 1

-- List the 5 most recent transfers.

select distinct (patient_id),transferdept, starttime, stoptime
 from public.transfer
 order by starttime DESC
 limit 5
 
select distinct (patient_id),transferdept, starttime, stoptime
 from public.transfer
 order by stoptime DESC
 limit 5

--List the last 100 patients that were discharged.

select patient_id, icu_discharge_time from public.baseline
  order by icu_discharge_time DESC limit 100


--2. Exploratory Analysis (What patterns can be observed?)

--Trends & common patterns

--Show the most commonly administered drug for each department and the number of times it was administered with window function).

WITH ranked_drugs AS (
    SELECT 
        d.drugname, 
        b.admitdept,
        COUNT(*) AS admit_count,
        RANK() OVER (PARTITION BY b.admitdept ORDER BY COUNT(*) DESC) AS rank
    FROM drugs d
    JOIN baseline b 
        ON b.patient_id = d.patient_id
    GROUP BY b.admitdept, d.drugname
)
SELECT drugname, admitdept, admit_count
FROM ranked_drugs
WHERE rank = 1;

-- Find the average age in each department by gender.

SELECT ROUND(AVG(age)::NUMERIC, 2)as avg_age, admitdept
FROM public.baseline
GROUP BY admitdept;

--  ICU Transfers & Stay

--List the average length of stay for patients diagnosed with soft tissue infections.

SELECT b.InfectionSite,
AVG(Age(b.icu_discharge_time, StartTime)) AS average_stays
FROM transfer t
JOIN baseline b ON b.inp_no = t.inp_no
WHERE InfectionSite = 'Soft Tissue' and startreason= 'Admission'
GROUP BY b.InfectionSite;


select avg(extract(epoch from (stoptime - starttime)) / (24*3600)) as avg_stay
from transfer t, baseline b
where t.inp_no = b.inp_no
and infectionsite like '%Soft Tissue%'


--Show the average time spent across different departments among alive patients and among deceased patients.

	SELECT 
        t.transferdept,
        o.follow_vital, 
        AVG(EXTRACT(EPOCH FROM (t.stoptime - t.starttime)) / 3600) AS avg_hours_spent
    FROM transfer t
    JOIN outcome o ON t.patient_id = o.patient_id
	WHERE o.follow_vital IS NOT NULL
	GROUP BY transferdept, follow_vital
	ORDER BY transferdept, follow_vital;

-- Find the correlation between blood sugar levels and discharge time from ICU.

select corr(n.blood_sugar::numeric, extract(epoch from b.icu_discharge_time)) as bs_discharge_corr
from nursingchart n, baseline b
where n.inp_no = b.inp_no
and admitdept = 'ICU'
and blood_sugar is not null
and icu_discharge_time is not null

/*Epoch time (also called Unix time or POSIX time) is the number of seconds that have elapsed since 
January 1, 1970 (UTC), excluding leap seconds.
Timestamps are difficult to use in mathematical operations.
2025-03-31 12:45:00 is hard to compare directly in calculations.
Epoch time converts timestamps into a simple numeric format (seconds since 1970-01-01).
Makes correlation, regression, and time-based analysis easier.*/


--Use a CTE to get all patients with temperature readings above 38°C.

with tempreture_above_38
as
(select distinct(b.patient_id),n.temperature
from nursingchart n join baseline b
on n.inp_no=b.inp_no
where n.temperature>38)
select *
from tempreture_above_38

--Tracking disease progression



-- How was the general health of patients who had a breathing rate > 20

select distinct n.inp_no,n.breathing ,o.sf36_generalhealth --Suitable for reviewing individual patient data.
from baseline b join public.outcome o
on b.patient_id = o.patient_id
join public.nursingchart n
on b.inp_no= n.inp_no
where breathing >20

--Aggregates the data, making it more useful for analysis (e.g., seeing how many patients fall into each health category).

select sf36_generalhealth, count(distinct o.patient_id)--
from nursingchart n, outcome o, baseline b
where n.inp_no = b.inp_no
and b.patient_id = o.patient_id
and breathing > 20
and sf36_generalhealth is not null
group by 1
order by 2 desc

--4.Predictive Analysis (What might happen next?)

--Risk factors for conditions--

--Use CTEs to calculate the percentage of patients with hypoproteinemia who had to be intubated.

with patient_with_intubated
as
(select distinct(i.patient_id),i.icd_desc,n.endotracheal_intubation_depth
     from icd i 
	 join nursingchart n
	 on i.inp_no = n.inp_no
	 where icd_desc = 'hypoproteinemia')
select (count(case when endotracheal_intubation_depth is not null then 1 end )*100)/count(*)
	 as intubated_percentage
from patient_with_intubated

 --Intervention planning

-- Write a stored procedure to calculate the total number of patients per department and return the results as a table.


CREATE OR REPLACE function totalpatients_dept(p_admitdept TEXT)
RETURNS TABLE (
	TotalPatients BIGINT,
	abmit_dept TEXT
)
LANGUAGE plpgsql
AS $body$
BEGIN 
	RETURN QUERY 
		SELECT COUNT(patient_id)as TotalPatients,admitdept
		FROM baseline 
	where admitdept = p_admitdept
	GROUP by admitdept


$body$ 	END;


SELECT * FROM totalpatients_dept ('ICU') 
SELECT * FROM totalpatients_dept ('Medical Specialties') 	
SELECT * FROM totalpatients_dept ('Surgery') 
drop function totalpatients_dept 


--Show the position of the letter y in disease names if it exists.

select distinct icd_desc, position('y' in icd_desc) as y_position
from icd
where icd_desc like '%y%'

--or--
select distinct icd_desc,  position('y' in icd_desc) as y_position
from icd
where position('y' in icd_desc) > 0


--Show the last 6 letters of disease names.

 select right(icd_desc,6)as last_six_letters 
 from public.icd;


-- Vital Signs & Lab Values


--Find the average heart rate of patients under 40

SELECT round(AVG(nc.heart_rate)::numeric,2) as avg_heart_rate
FROM nursingchart nc
JOIN baseline b on nc.inp_no = b.inp_no
WHERE b.age < 40;

 --List the tables where the column Patient_ID is present (display column position number as well)

select table_name, ordinal_position as patient_id_column_position
from information_schema.columns
where column_name = 'patient_id'

--Summaries & distributions

-- Find the average, minimum, and maximum systolic blood pressure for patients in each department

WITH bp_values AS (
    SELECT n.inp_no,
        COALESCE(n.blood_pressure_high, n.invasive_sbp) AS systolic_bp --COALESCE to take the first non-null value between blood_pressure_high and invasive_sbp.
    FROM nursingchart n
    WHERE COALESCE(n.blood_pressure_high, n.invasive_sbp) > 0)
SELECT
    b.admitdept AS department,
    ROUND(AVG(bp.systolic_bp)::numeric,2) AS avg_systolic_bp,
    MIN(bp.systolic_bp) AS min_systolic_bp,
    MAX(bp.systolic_bp) AS max_systolic_bp
FROM bp_values bp
JOIN baseline b ON bp.inp_no = b.inp_no
WHERE b.admitdept IS NOT NULL
GROUP BY b.admitdept
ORDER BY b.admitdept;


--3. Diagnostic Analysis (Why did it happen?)

    --Investigating abnormalities

-- List patients whose heart rate increased by over 30% from the previous reading and the time when it happened (use window functions).

with hr_inc as (
    select inp_no, charttime, heart_rate,
        lag(heart_rate) over (partition by inp_no order by charttime) as prev_hr
    from nursingchart)
    select inp_no, charttime, heart_rate, prev_hr,
    (heart_rate - prev_hr) * 100.0 / prev_hr as pct_inc
    from hr_inc
    where prev_hr > 0
    and ((heart_rate - prev_hr) * 100.0 / prev_hr) > 30


--List all patients who had a systolic blood pressure higher than the median value in the ICU (use window functions).

with icu_bp as (
select b.patient_id, n.blood_pressure_high
from nursingchart n, baseline b
where n.inp_no = b.inp_no
and b.admitdept = 'ICU'),
median_bp as (
select percentile_cont (0.5) within group (order by blood_pressure_high) as med_icu_bp
from icu_bp)
select distinct icu_bp.patient_id,icu_bp.blood_pressure_high,median_bp.med_icu_bp
from icu_bp, median_bp
where icu_bp.blood_pressure_high > median_bp.med_icu_bp

--Show all patients whose blood sugar is in the 99th percentile and the time when it was recorded.

SELECT DISTINCT ON (b.patient_id)  ---distinct on used to remove the dulpicate records of patient and time
       b.patient_id, 
       n.charttime, 
       n.blood_sugar
FROM nursingchart n
JOIN baseline b ON b.inp_no = n.inp_no
WHERE n.blood_sugar >= (
    SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY blood_sugar) AS Percentile_99      ---calculate 99th perentile for blood sugar
    FROM nursingchart
)
ORDER BY b.patient_id, n.charttime;


with bs99 as (
    select percentile_cont(0.99) within group (order by blood_sugar) as bl_sugar99
    from nursingchart
)
select inp_no, 
    blood_sugar,
        charttime
from  nursingchart, bs99
where blood_sugar >= bl_sugar99

--List patients with heart rates more than two standard deviations from the average.

WITH stats AS (
    SELECT 
        AVG(heart_rate) AS avg_hr, 
        STDDEV_SAMP(heart_rate) AS std_hr
    FROM public.nursingchart
)
SELECT n.inp_no, n.heart_rate, n.charttime
FROM public.nursingchart n
CROSS JOIN stats s
WHERE n.heart_rate < (s.avg_hr - 2 * s.std_hr) 
   OR n.heart_rate > (s.avg_hr + 2 * s.std_hr)
ORDER BY n.inp_no, n.charttime;


 -- Medical conditions & trends

--Show the highest temperature and highest heart rate recorded of all patients in surgery for each day.

SELECT 
    DATE(n.charttime) AS record_date,
    b.patient_id,
    MAX(n.temperature) AS highest_temperature,
    MAX(n.heart_rate) AS highest_heart_rate
FROM baseline b
JOIN nursingchart n ON n.inp_no = b.inp_no
WHERE b.admitdept = 'Surgery'
GROUP BY DATE(n.charttime), b.patient_id
ORDER BY record_date, b.patient_id;

--  Drug & Antibiotic Usage

--Which drug was most administered among patients who have never been intubated?

select drugname, count(distinct d.patient_id)
from drugs d JOIN  baseline b
on d.patient_id = b.patient_id
JOIN nursingchart  n
on   b.inp_no = n.inp_no
where endotracheal_intubation is null
group by 1
order by 2 desc
limit 1

-- Which drug was administered the most

select drugname, count(*)
from drugs
group by 1
order by 2 desc
limit 1

--List all the drugs that were administered between 4 and 5 AM.

select distinct drugname from public.drugs
where extract(hour from drug_time)=4

SELECT DISTINCT drugname
FROM drugs
WHERE drug_time::time BETWEEN '04:00:00' AND '04:59:59'

/*Produce a list of 100 normally distributed age values. Set the mean as the 3rd 
lowest age in the table, and assume the standard deviation from the mean is 3.*/

WITH mean_age AS (
    SELECT age AS mean
    FROM baseline
    ORDER BY age
    LIMIT 1 OFFSET 2  -- Get the 3rd lowest age
)
SELECT 
    ROUND((SELECT mean FROM mean_age) + 3 * sqrt(-2 * LN(RANDOM())) * COS(2 * PI() * RANDOM())) AS generated_age
FROM generate_series(1, 100);

  Sepsis & Outcomes

--Show patients whose critical-care pain observation tool score is 0.

select distinct b.patient_id,n.cpot_pain_score as critical_care_pain_observation_tool_score
from public.nursingchart n join baseline b
on b.inp_no = n.inp_no
where n.cpot_pain_score= '0'

--Show the percentage of alive patients whose general health was poor after discharge.

WITH alive_patients AS (
    SELECT 
        discharge_dept, 
        COUNT(*) AS total_alive_patients,
        COUNT(CASE WHEN sf36_generalhealth = '5_Poor' THEN 1 END) AS poor_health_count
    FROM outcome
    WHERE follow_vital = 'Alive'
    GROUP BY discharge_dept
)
SELECT 
    discharge_dept,
    total_alive_patients,
    poor_health_count,
    ROUND(COALESCE(poor_health_count, 0) * 100.0 / total_alive_patients, 2) AS percentage_poor_health
FROM alive_patients
ORDER BY discharge_dept;

-- System/Meta Queries

-- Generates 100 values

WITH mean_age AS (
    SELECT age AS mean
    FROM baseline
    ORDER BY age
    LIMIT 1 OFFSET 2  -- 3rd lowest age
),
normal_approx AS (
    SELECT 
        sample,
        (SUM(random()) - 6) * 3 + mean_age.mean AS agedist
    FROM generate_series(1, 100) AS sample
    CROSS JOIN generate_series(1, 12) AS approx
    JOIN mean_age ON TRUE
    GROUP BY sample, mean_age.mean
)
SELECT ROUND(agedist)::int AS generated_age
FROM normal_approx;


--Patient condition trends

--Identify patients whose breathing tube has been removed.

SELECT DISTINCT b.patient_id, n.inp_no, n.extubation AS breathing_tube_removed
FROM nursingchart n, baseline b
WHERE b.inp_no = n.inp_no
AND n.extubation = 'true'
ORDER BY b.patient_id;





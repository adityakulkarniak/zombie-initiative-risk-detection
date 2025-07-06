-- :)identify preojects marked active but no team activity and no positive kpi movement potentially resource draining projects
select 
	p.project_id,
    p.project_name,
    p.department,
    p.owner,
    p.budget_usd,
    k.kpi_name,
    k.kpi_value,
    a.hours_logged
from 
	projects_complex_final p
join 
    activity_logs_complex_final a on p.project_id = a.project_id
join
	kpi_data_complex_final k on p.project_id = k.project_id
where 
	p.status = 'Active' 
    and a.hours_logged = 0
    and k.kpi_value <=0;

-- Finding 'Active' projects that Have no team activity (hours_logged = 0) 2. Deliver no positive KPI movement (kpi_value <= 0) 3) Burn significant budget (> $1 Million)
select 
	p.project_id,
    p.project_name,
    p.department,
    p.owner,
    p.budget_usd,
    k.kpi_name,
    k.kpi_value,
    a.hours_logged
from 
	projects_complex_final p
join
	activity_logs_complex_final a on p.project_id = a.project_id
join
	kpi_data_complex_final k on p.project_id = k.project_id
where
	p.status = 'Active'
    and a.hours_logged = 0 
    and k.kpi_value <= 0
    and p.budget_usd > 1000000;
    
 -- along with finding projects with 1)less activity 2)-ve kpi's movement 3)higher budget we are trying analyse sentiment among employees 
select 
	p.project_id,
	p.project_name,
	p.department,
	p.owner,
	p.budget_usd,
	k.kpi_name,
	k.kpi_value,
	a.hours_logged,
	s.employee_sentiment
from
	projects_complex_final p
join
	activity_logs_complex_final a on p.project_id = a.project_id
join
	kpi_data_complex_final k on p.project_id = k.project_id
join
	sentiment_data_complex_final s on p.project_id = s.project_id 
where
	p.status = 'Active'
    and a.hours_logged = 0 
    AND k.kpi_value <= 0
    AND p.budget_usd > 1000000
    AND s.employee_sentiment IN ('Negative', 'Neutral');
    
 -- Strategic Misalignment Detection: 1)Misaligned with company goals 2)Poorly planned in terms of budget vs. expected output  3)Continuing without leadership realizing they're "off-track
SELECT 
    p.project_id,
    p.project_name,
    p.department,
    p.owner,
    p.target_budget,
    p.budget_usd,
    k.kpi_name,
    k.kpi_value
FROM
    projects_complex_final p
JOIN
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE
    p.status = 'Active'
    AND p.target_budget < 500000
    AND p.budget_usd > 1000000
    AND k.kpi_value <= 0;
    
-- Budget Burn with Zero Output Across Entire Portfolio 1)Total number of Zombie initiatives 2)Total wasted budget 3)Average wasted budget per project
select 
	count(*) as zombie_project_count,
    sum(p.budget_usd) as total_wasted_budget,
    avg(p.budget_usd) as avg_wasted_budget
from 
	projects_complex_final p 
join 
	activity_logs_complex_final a on p.project_id = a.project_id
join 
	kpi_data_complex_final k on p.project_id = k.project_id
where
	p.status = 'Active'
    and a.hours_logged = 0
    and k.kpi_value <= 0;

-- 1) Time-Based Zombie Trends 1)Shows how many zombie projects started each month 2)Helps detect if wasteful initiatives are increasing over time
SELECT 
    DATE_FORMAT(p.start_date, '%Y-%m') AS project_month,
    COUNT(*) AS zombie_count
FROM 
    projects_complex_final p
JOIN 
    activity_logs_complex_final a ON p.project_id = a.project_id
JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE 
    p.status = 'Active'
    AND a.hours_logged = 0
    AND k.kpi_value <= 0
GROUP BY 
    project_month
ORDER BY 
    project_month;

-- 2) Department-Wise Waste Comparison 1)Shows which departments contribute most to zombie projects
select 
	p.department, count(*) as zombie_count,
    sum(p.budget_usd) as total_wasted_budget
from
	projects_complex_final as p
join 
	activity_logs_complex_final a on p.project_id = a.project_id
join
	kpi_data_complex_final k on p.project_id = k.project_id
where 
	p.status = 'Active'
    and a.hours_logged = 0
    and k.kpi_value <= 0
group by p.department
order by zombie_count desc;

-- 3)Termination Reason Pattern Analysis 1)Shows most common reasons projects failed
select 
	termination_reason, count(*) as termination_count
from
	projects_complex_final
where
	status = 'Terminated' and termination_reason is not null
group by termination_reason
order by termination_count desc;

-- 4) Data Quality & Anomaly Detection

-- task 1). Projects missing budgets
SELECT * 
FROM projects_complex_final
WHERE budget_usd IS NULL OR budget_usd <= 0;
-- 2). Negative hours logged (impossible)
SELECT *
FROM activity_logs_complex_final
WHERE hours_logged < 0;

-- 3). KPI records with missing or negative values
SELECT *
FROM kpi_data_complex_final
WHERE kpi_value IS NULL OR kpi_value < 0;

-- task 4). Projects with invalid dates (future start dates)
SELECT *
FROM projects_complex_final
WHERE start_date > CURDATE();

--  Predictive Zombie Risk Scoring 
-- Step 1: Extract risk-relevant project data
-- Step 2: Add risk flags (budget, sentiment, KPI)
-- Step 3: Create simple predictive risk scoring logic
-- Step 4: Interpret results from a consulting/business angle

-- step 1)Extract risk-relevant project data
SELECT 
    p.project_id,
    p.project_name,
    p.department,
    p.budget_usd,
    p.start_date,
    s.employee_sentiment,
    k.kpi_value AS initial_kpi
FROM 
    projects_complex_final p
LEFT JOIN 
    sentiment_data_complex_final s ON p.project_id = s.project_id
LEFT JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE 
    p.status = 'Active'; 

-- step 2)Add risk flags (budget, sentiment, KPI)
select 
	p.project_id,
    p.project_name,
    p.department,
    p.owner,
    p.budget_usd,
    s.employee_sentiment,
    k.kpi_value as initial_kpi,
case when
		p.budget_usd > 1000000 then 1 else 0
        end as high_budget_risk,
case when 
		s.employee_sentiment = 'Negative' THEN 1 ELSE 0
		END AS negative_sentiment_risk,
case when 
		k.kpi_value <= 0 THEN 1 ELSE 0
		END AS weak_kpi_risk
FROM 
    projects_complex_final p
LEFT JOIN 
    sentiment_data_complex_final s ON p.project_id = s.project_id
LEFT JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE 
    p.status = 'Active';    
    
-- Step 3: Predictive Risk Scoring (Total Risk Indicator)
select 
	p.project_id,
    p.project_name,
    p.department,
    p.owner,
    p.budget_usd,
    s.employee_sentiment,
    k.kpi_value as initial_kpi,
case when
	p.budget_usd > 1000000 then 1 else 0 end as high_budget_risk,
case when 
	s.employee_sentiment = 'Negative' then 1 else 0 end as negative_sentiment_risk,
case when 
	k.kpi_value <= 0 then 1 else 0 end as weak_kpi_risk,
-- total risk score
	(case when p.budget_usd > 1000000 THEN 1 ELSE 0 END +
	case when s.employee_sentiment = 'Negative' THEN 1 ELSE 0 END +
	case when k.kpi_value <= 0 THEN 1 ELSE 0 END) AS total_risk_score
from
    projects_complex_final p
LEFT JOIN 
    sentiment_data_complex_final s ON p.project_id = s.project_id
LEFT JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE 
    p.status = 'Active';
    
-- STEP 4: BUSINESS INTERPRETATION - TOTAL ZOMBIE RISK SCORE
-- Risk Scoring Logic:
--    0 = Low Risk (Project appears stable)
--    1 = Minor Risk (Monitor recommended)
--    2 = Moderate Risk (Deeper review advised)
--    3 = High Risk (Strong zombie candidate, flag for leadership)

 -- KPI EFFICIENCY RATIO ANALYSIS
-- Compares budget spent to KPI movement for project efficiency scoring
SELECT 
    p.project_id,
    p.project_name,
    p.department,
    p.budget_usd,
    k.kpi_name,
    k.kpi_value,
    case when p.budget_usd > 0 THEN ROUND(k.kpi_value / p.budget_usd, 4) ELSE NULL
    end as kpi_efficiency_ratio
FROM 
    projects_complex_final p
LEFT JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
WHERE 
    p.status = 'Active';

-- FINAL ZOMBIE RISK SCORING WITH KPI EFFICIENCY INCLUDED
-- Combines sentiment, budget, performance, efficiency into one risk metric


SELECT 
    p.project_id,
    p.project_name,
    p.department,
    p.budget_usd,
    k.kpi_name,
    k.kpi_value,
    
    -- Efficiency Ratio Calculation
case when p.budget_usd > 0 THEN ROUND(k.kpi_value / p.budget_usd, 4) else null
    END AS kpi_efficiency_ratio,

    s.employee_sentiment,

    -- Total Risk Score Calculation
    (CASE WHEN p.budget_usd > 1000000 THEN 1 ELSE 0 END +
     CASE WHEN s.employee_sentiment = 'Negative' THEN 1 ELSE 0 END +
     CASE WHEN k.kpi_value <= 0 THEN 1 ELSE 0 END +
     CASE WHEN (p.budget_usd > 0 AND (k.kpi_value / p.budget_usd) < 0.1) THEN 1 ELSE 0 END
    ) AS total_risk_score

FROM 
    projects_complex_final p
LEFT JOIN 
    kpi_data_complex_final k ON p.project_id = k.project_id
LEFT JOIN 
    sentiment_data_complex_final s ON p.project_id = s.project_id
WHERE 
    p.status = 'Active';
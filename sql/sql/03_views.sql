CREATE SCHEMA IF NOT EXISTS it_reports;

-- KPI: tickets by status and priority
CREATE OR REPLACE VIEW it_reports.v_kpi_status_priority AS
SELECT status, priority, COUNT(*) AS tickets
FROM it_tickets.tickets
GROUP BY status, priority;

-- Backlog summary
CREATE OR REPLACE VIEW it_reports.v_backlog_summary AS
SELECT
  COUNT(*) FILTER (WHERE status IN ('Open','In Progress')) AS backlog_total,
  COUNT(*) FILTER (WHERE status IN ('Open','In Progress') AND technician_id IS NULL) AS backlog_unassigned
FROM it_tickets.tickets;

-- Backlog by technician (includes Unassigned)
CREATE OR REPLACE VIEW it_reports.v_backlog_by_technician AS
SELECT
  COALESCE(t.full_name,'Unassigned') AS technician,
  COUNT(*) AS open_tickets
FROM it_tickets.tickets k
LEFT JOIN it_tickets.technicians t 
  ON t.technician_id = k.technician_id
WHERE k.status IN ('Open','In Progress')
GROUP BY COALESCE(t.full_name,'Unassigned');

-- Resolution by priority
CREATE OR REPLACE VIEW it_reports.v_resolution_by_priority AS
WITH x AS (
  SELECT priority, (resolved_at - created_at) AS duration
  FROM it_tickets.tickets
  WHERE resolved_at IS NOT NULL
)
SELECT
  priority,
  AVG(duration) AS avg_duration,
  ROUND(AVG(EXTRACT(EPOCH FROM duration))/3600.0, 2) AS avg_hours,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration) AS median_duration
FROM x
GROUP BY priority;

-- SLA ticket detail
CREATE OR REPLACE VIEW it_reports.v_sla_ticket_detail AS
SELECT
  k.ticket_id,
  k.priority,
  k.status,
  k.created_at,
  k.resolved_at,
  ROUND(EXTRACT(EPOCH FROM (k.resolved_at - k.created_at))/3600.0,2) AS hours_to_resolve,
  s.max_hours,
  CASE
    WHEN (EXTRACT(EPOCH FROM (k.resolved_at - k.created_at))/3600.0) <= s.max_hours THEN 'OK'
    ELSE 'BREACH'
  END AS sla_result,
  k.technician_id,
  k.category_id
FROM it_tickets.tickets k
JOIN it_tickets.sla s 
  ON s.priority = k.priority
WHERE k.resolved_at IS NOT NULL;

-- SLA by priority
CREATE OR REPLACE VIEW it_reports.v_sla_by_priority AS
SELECT
  priority,
  COUNT(*) AS resolved_tickets,
  COUNT(*) FILTER (WHERE sla_result = 'OK') AS ok_tickets,
  COUNT(*) FILTER (WHERE sla_result = 'BREACH') AS breach_tickets,
  ROUND(100.0 * COUNT(*) FILTER (WHERE sla_result = 'OK') / NULLIF(COUNT(*),0), 1) AS sla_ok_percent,
  ROUND(100.0 * COUNT(*) FILTER (WHERE sla_result = 'BREACH') / NULLIF(COUNT(*),0), 1) AS sla_breach_percent
FROM it_reports.v_sla_ticket_detail
GROUP BY priority;

-- SLA breach by technician
CREATE OR REPLACE VIEW it_reports.v_sla_breach_by_technician AS
SELECT
  t.full_name AS technician,
  COUNT(*) AS resolved_tickets,
  COUNT(*) FILTER (WHERE d.sla_result = 'BREACH') AS breach_tickets,
  ROUND(100.0 * COUNT(*) FILTER (WHERE d.sla_result = 'BREACH') / NULLIF(COUNT(*),0), 1) AS breach_percent
FROM it_reports.v_sla_ticket_detail d
JOIN it_tickets.technicians t 
  ON t.technician_id = d.technician_id
WHERE d.technician_id IS NOT NULL
GROUP BY t.full_name;

-- SLA breach by category
CREATE OR REPLACE VIEW it_reports.v_sla_breach_by_category AS
SELECT
  c.name AS category,
  COUNT(*) AS resolved_tickets,
  COUNT(*) FILTER (WHERE d.sla_result = 'BREACH') AS breach_tickets,
  ROUND(100.0 * COUNT(*) FILTER (WHERE d.sla_result = 'BREACH') / NULLIF(COUNT(*),0), 1) AS breach_percent
FROM it_reports.v_sla_ticket_detail d
JOIN it_tickets.categories c 
  ON c.category_id = d.category_id
GROUP BY c.name;

-- Backlog aging (dynamico)
CREATE OR REPLACE VIEW it_reports.v_backlog_aging AS
SELECT
  k.ticket_id,
  k.priority,
  k.status,
  COALESCE(t.full_name, 'Unassigned') AS technician,
  k.created_at,
  NOW() AS as_of,
  (NOW() - k.created_at) AS age_interval,
  ROUND(EXTRACT(EPOCH FROM (NOW() - k.created_at))/3600.0, 2) AS hours_open
FROM it_tickets.tickets k
LEFT JOIN it_tickets.technicians t 
  ON t.technician_id = k.technician_id
WHERE k.status IN ('Open','In Progress');

-- Re opened stats
CREATE OR REPLACE VIEW it_reports.v_reopened_stats AS
SELECT
  COUNT(*) FILTER (WHERE reopened = TRUE) AS reopened_tickets,
  COUNT(*) AS total_tickets,
  ROUND(100.0 * COUNT(*) FILTER (WHERE reopened = TRUE) / NULLIF(COUNT(*),0),1) AS reopened_percent
FROM it_tickets.tickets;

-- Weekly trend
CREATE OR REPLACE VIEW it_reports.v_trend_weekly AS
SELECT
  DATE_TRUNC('week',created_at) AS week_start,
  COUNT(*) AS tickets_created
FROM it_tickets.tickets
GROUP BY week_start;

--Dashboard summary (KPI single-row)
CREATE OR REPLACE VIEW it_reports.v_dashboard_summary AS
WITH
backlog AS (
  SELECT
    COUNT(*) FILTER (WHERE status IN ('Open','In Progress')) AS backlog_total,
    COUNT(*) FILTER (WHERE status IN ('Open','In Progress') AND technician_id IS NULL) AS backlog_unassigned
  FROM it_tickets.tickets
),
reopened AS (
  SELECT
    COUNT(*) FILTER (WHERE reopened = TRUE) AS reopened_tickets,
    COUNT(*) AS total_tickets,
    ROUND(100.0 * COUNT(*) FILTER (WHERE reopened = TRUE) / NULLIF(COUNT(*),0), 1) AS reopened_percent
  FROM it_tickets.tickets
),
sla AS (
  SELECT
    ROUND(100.0 * AVG(CASE WHEN d.sla_result = 'OK' THEN 1 ELSE 0 END), 1) AS sla_ok_percent_overall,
    ROUND(100.0 * AVG(CASE WHEN d.sla_result = 'BREACH' THEN 1 ELSE 0 END), 1) AS sla_breach_percent_overall
  FROM it_reports.v_sla_ticket_detail d
)
SELECT
  backlog.backlog_total,
  backlog.backlog_unassigned,
  reopened.total_tickets,
  reopened.reopened_tickets,
  reopened.reopened_percent,
  sla.sla_ok_percent_overall,
  sla.sla_breach_percent_overall
FROM backlog, reopened, sla;

-- Ticket lifecycle
CREATE OR REPLACE VIEW it_reports.v_ticket_lifecycle AS
WITH base AS (
  SELECT
    k.ticket_id,
    k.priority,
    k.status,
    u.full_name AS user_name,
    COALESCE(t.full_name,'Unassigned') AS technician_name,
    c.name AS category,
    a.asset_type,
    a.model AS asset_model,
    k.created_at,
    k.assigned_at,
    k.resolved_at,
    k.reopened,
    EXTRACT(EPOCH FROM (k.assigned_at - k.created_at)) AS secs_to_assign,
    EXTRACT(EPOCH FROM (k.resolved_at - k.created_at)) AS secs_to_resolve,
    EXTRACT(EPOCH FROM (NOW() - k.created_at)) AS secs_age_now
  FROM it_tickets.tickets k
  JOIN it_tickets.users u 
      ON u.user_id = k.user_id
  LEFT JOIN it_tickets.technicians t 
      ON t.technician_id = k.technician_id
  JOIN it_tickets.categories c 
      ON c.category_id = k.category_id
  LEFT JOIN it_tickets.assets a 
      ON a.asset_id = k.asset_id
)
SELECT
  ticket_id,
  priority,
  status,
  user_name,
  technician_name,
  category,
  asset_type,
  asset_model,
  to_char(created_at,'YYYY-MM-DD HH24:MI:SS') AS created_at,
  CASE WHEN assigned_at IS NULL THEN NULL ELSE to_char(assigned_at,'YYYY-MM-DD HH24:MI:SS') END AS assigned_at,
  CASE WHEN resolved_at IS NULL THEN NULL ELSE to_char(resolved_at,'YYYY-MM-DD HH24:MI:SS') END AS resolved_at,
  reopened,

  CASE WHEN secs_to_assign IS NULL THEN NULL ELSE ROUND(secs_to_assign/3600.0, 2) END AS hours_to_assign,
  CASE WHEN secs_to_assign IS NULL THEN NULL ELSE
    (LPAD((secs_to_assign/3600)::int::text,2,'0')||':'||
     LPAD(((secs_to_assign%3600)/60)::int::text,2,'0')||':'||
     LPAD((secs_to_assign%60)::int::text,2,'0'))
  END AS time_to_assign_hms,

  CASE WHEN secs_to_resolve IS NULL THEN NULL ELSE ROUND(secs_to_resolve/3600.0,2) END AS hours_to_resolve,
  CASE WHEN secs_to_resolve IS NULL THEN NULL ELSE
    (LPAD((secs_to_resolve/3600)::int::text,2,'0')||':'||
     LPAD(((secs_to_resolve%3600)/60)::int::text,2,'0')||':'||
     LPAD((secs_to_resolve%60)::int::text,2,'0'))
  END AS time_to_resolve_hms,

  CASE WHEN status IN ('Open','In Progress') THEN ROUND(secs_age_now/3600.0,2) ELSE NULL END AS hours_open_now,
  CASE WHEN status IN ('Open','In Progress') THEN
    (LPAD((secs_age_now/3600)::int::text,2,'0')||':'||
     LPAD(((secs_age_now%3600)/60)::int::text,2,'0')||':'||
     LPAD((secs_age_now%60)::int::text,2,'0'))
  ELSE NULL END AS age_hms_now
FROM base;

-- Technician scorecard
CREATE OR REPLACE VIEW it_reports.v_technician_scorecard AS
WITH
resolved AS (
  SELECT
    k.technician_id,
    COUNT(*) AS resolved_tickets,
    ROUND(AVG(EXTRACT(EPOCH FROM (k.resolved_at - k.created_at)))/3600.0,2) AS avg_resolve_hours
  FROM it_tickets.tickets k
  WHERE k.resolved_at IS NOT NULL
    AND k.technician_id IS NOT NULL
  GROUP BY k.technician_id
),
breach AS (
  SELECT
    d.technician_id,
    COUNT(*) AS resolved_with_sla,
    COUNT(*) FILTER (WHERE d.sla_result='BREACH') AS breach_tickets,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.sla_result='BREACH')/NULLIF(COUNT(*),0),1) AS breach_percent
  FROM it_reports.v_sla_ticket_detail d
  WHERE d.technician_id IS NOT NULL
  GROUP BY d.technician_id
),
assign AS (
  SELECT
    k.technician_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (k.assigned_at - k.created_at)))/3600.0,2) AS avg_assign_hours
  FROM it_tickets.tickets k
  WHERE k.assigned_at IS NOT NULL
    AND k.technician_id IS NOT NULL
  GROUP BY k.technician_id
),
backlog AS (
  SELECT
    technician_id,
    COUNT(*) AS open_tickets
  FROM it_tickets.tickets
  WHERE status IN ('Open','In Progress')
    AND technician_id IS NOT NULL
  GROUP BY technician_id
)
SELECT
  t.full_name AS technician,
  t.level,
  COALESCE(r.resolved_tickets,0) AS resolved_tickets,
  COALESCE(b.breach_percent,0.0) AS breach_percent,
  COALESCE(a.avg_assign_hours,0.0) AS avg_assign_hours,
  COALESCE(r.avg_resolve_hours,0.0) AS avg_resolve_hours,
  COALESCE(bl.open_tickets,0) AS current_backlog
FROM it_tickets.technicians t
LEFT JOIN resolved r ON r.technician_id = t.technician_id
LEFT JOIN breach b ON b.technician_id = t.technician_id
LEFT JOIN assign a ON a.technician_id = t.technician_id
LEFT JOIN backlog bl ON bl.technician_id = t.technician_id;

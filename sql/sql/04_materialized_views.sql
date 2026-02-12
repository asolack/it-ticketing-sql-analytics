-- Materialized views
CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_sla_by_priority AS
SELECT * FROM it_reports.v_sla_by_priority;

CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_sla_breach_by_technician AS
SELECT * FROM it_reports.v_sla_breach_by_technician;

CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_sla_breach_by_category AS
SELECT * FROM it_reports.v_sla_breach_by_category;

CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_backlog_aging AS
SELECT * FROM it_reports.v_backlog_aging;

CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_ticket_lifecycle AS
SELECT * FROM it_reports.v_ticket_lifecycle;

CREATE MATERIALIZED VIEW IF NOT EXISTS it_reports.mv_technician_scorecard AS
SELECT * FROM it_reports.v_technician_scorecard;

-- Indexes fast filtering
CREATE INDEX IF NOT EXISTS idx_mv_sla_by_priority_breach
ON it_reports.mv_sla_by_priority (sla_breach_percent DESC);

CREATE INDEX IF NOT EXISTS idx_mv_sla_breach_by_technician_breach
ON it_reports.mv_sla_breach_by_technician (breach_percent DESC);

CREATE INDEX IF NOT EXISTS idx_mv_sla_breach_by_category_breach
ON it_reports.mv_sla_breach_by_category (breach_percent DESC);

CREATE INDEX IF NOT EXISTS idx_mv_backlog_aging_hours
ON it_reports.mv_backlog_aging (hours_open DESC);

CREATE INDEX IF NOT EXISTS idx_mv_ticket_lifecycle_status
ON it_reports.mv_ticket_lifecycle (status);

CREATE INDEX IF NOT EXISTS idx_mv_ticket_lifecycle_priority
ON it_reports.mv_ticket_lifecycle (priority);

CREATE INDEX IF NOT EXISTS idx_mv_ticket_lifecycle_hours_open
ON it_reports.mv_ticket_lifecycle (hours_open_now DESC);

CREATE INDEX IF NOT EXISTS idx_mv_tech_score_breach
ON it_reports.mv_technician_scorecard (breach_percent DESC);

CREATE INDEX IF NOT EXISTS idx_mv_tech_score_resolved
ON it_reports.mv_technician_scorecard (resolved_tickets DESC);

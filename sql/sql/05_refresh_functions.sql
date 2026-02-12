-- Rfrsh funct. for materialized viws

CREATE OR REPLACE FUNCTION it_reports.refresh_core_mviews()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW it_reports.mv_sla_by_priority;
  REFRESH MATERIALIZED VIEW it_reports.mv_sla_breach_by_technician;
  REFRESH MATERIALIZED VIEW it_reports.mv_sla_breach_by_category;
  REFRESH MATERIALIZED VIEW it_reports.mv_technician_scorecard;
END;
$$;

CREATE OR REPLACE FUNCTION it_reports.refresh_all_mviews()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM it_reports.refresh_core_mviews();
  REFRESH MATERIALIZED VIEW it_reports.mv_backlog_aging;
  REFRESH MATERIALIZED VIEW it_reports.mv_ticket_lifecycle;
END;
$$;

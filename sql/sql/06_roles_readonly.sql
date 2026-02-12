-- Read-only reporting role + user
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'report_reader') THEN
    CREATE ROLE report_reader;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'report_guest') THEN
    CREATE ROLE report_guest LOGIN;
  END IF;
END $$;

GRANT report_reader TO report_guest;

-- Grant read access -->only to reporting schema<--
GRANT USAGE ON SCHEMA it_reports TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA it_reports TO report_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA it_reports
GRANT SELECT ON TABLES TO report_reader;

-- Explicitly deny access to core schema
REVOKE ALL ON SCHEMA it_tickets FROM report_guest;
REVOKE ALL ON ALL TABLES IN SCHEMA it_tickets FROM report_guest;

-- Avoid allowing object creation in public (if you have)
REVOKE CREATE ON SCHEMA public FROM report_guest;

ALTER TABLE it_tickets.tickets
  ADD CONSTRAINT ck_tickets_assigned_after_created
  CHECK (assigned_at IS NULL OR assigned_at >= created_at),

  ADD CONSTRAINT ck_tickets_resolved_after_created
  CHECK (resolved_at IS NULL OR resolved_at >= created_at),

  -- if assigned_at exists, technician_id must exist
  ADD CONSTRAINT ck_tickets_assigned_requires_technician
  CHECK (assigned_at IS NULL OR technician_id IS NOT NULL),

  -- if technician is NULL, must be open and not assigned yet
  ADD CONSTRAINT ck_tickets_unassigned_must_be_open
  CHECK (technician_id IS NOT NULL OR (status = 'Open' AND assigned_at IS NULL)),

  -- status and resolved_at must match
  ADD CONSTRAINT ck_tickets_status_matches_resolved_at
  CHECK (
    (status IN ('Resolved','Closed') AND resolved_at IS NOT NULL)
    OR
    (status IN ('Open','In Progress') AND resolved_at IS NULL)
        ),
  ADD CONSTRAINT ck_tickets_resolved_after_assigned
  CHECK (resolved_at IS NULL OR assigned_at IS NULL OR resolved_at >= assigned_at);

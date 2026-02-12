CREATE SCHEMA IF NOT EXISTS it_tickets;

CREATE SCHEMA IF NOT EXISTS it_reports;

CREATE TABLE IF NOT EXISTS it_tickets.users (
  user_id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  department VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS it_tickets.technicians (
  technician_id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  level VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS it_tickets.categories (
  category_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS it_tickets.assets (
  asset_id BIGSERIAL PRIMARY KEY,
  asset_type VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS it_tickets.sla (
  priority VARCHAR(10) PRIMARY KEY,
  max_hours INT NOT NULL
);

CREATE TABLE IF NOT EXISTS it_tickets.tickets (
  ticket_id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  technician_id BIGINT NULL,
  category_id BIGINT NOT NULL,
  asset_id BIGINT NULL,
  priority VARCHAR(10) NOT NULL CHECK (priority IN ('Low','Medium','High','Critical')),
  status VARCHAR(20) NOT NULL CHECK (status IN ('Open','In Progress','Resolved','Closed')),
  created_at TIMESTAMP NOT NULL,
  assigned_at TIMESTAMP NULL,
  resolved_at TIMESTAMP NULL,
  reopened BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES it_tickets.users(user_id),
  CONSTRAINT fk_tech FOREIGN KEY (technician_id) REFERENCES it_tickets.technicians(technician_id),
  CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES it_tickets.categories(category_id),
  CONSTRAINT fk_asset FOREIGN KEY (asset_id) REFERENCES it_tickets.assets(asset_id),
  CONSTRAINT fk_priority FOREIGN KEY (priority) REFERENCES it_tickets.sla(priority)
);

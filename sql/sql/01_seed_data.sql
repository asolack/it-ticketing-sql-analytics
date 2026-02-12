-- Reset (optional for return to runs)
TRUNCATE it_tickets.tickets,
        it_tickets.users,
        it_tickets.technicians,
        it_tickets.categories,
        it_tickets.assets,
        it_tickets.sla
RESTART IDENTITY;

-- SLA
INSERT INTO it_tickets.sla (priority,max_hours) VALUES
('Low',72),
('Medium',48),
('High',24),
('Critical',8);

-- Categories
INSERT INTO it_tickets.categories (name) VALUES
('Hardware'),
('Software'),
('Network'),
('Access/Accounts');

-- Assets
INSERT INTO it_tickets.assets (asset_type, model) VALUES
('Laptop','Dell Latitude 5420'),
('Desktop','HP ProDesk 400'),
('Printer','HP LaserJet Pro'),
('Router','Cisco ISR'),
('Monitor','Dell P2422H'),
('Smartphone','Samsung Galaxy A54');

-- Technicians
INSERT INTO it_tickets.technicians (full_name, level) VALUES
('Alejandro Martín Sánchez','L1'),
('Iker Etxeberria Aramburu','L2'),
('Laia Puig i Ferrer','L2'),
('Daniel Castro Varela','L1');

-- Users (for a international interprise)
INSERT INTO it_tickets.users (full_name,department) VALUES
('María Sánchez García','Finance'),
('Javier López Moreno','Operations'),
('Paula Rodríguez Navarro','HR'),
('Sergio Fernández Ruiz','Sales'),
('Giulia Rossi','HR'),
('Liam O''Connor','Sales'),
('Amina El Amrani','IT'),
('Wei Zhang','Operations'),
('Oksana Shevchenko','Finance'),
('Lucas Silva','Operations');

-- 16 Tickets for exemple
INSERT INTO it_tickets.tickets
(user_id, technician_id, category_id, asset_id, priority, status, created_at, assigned_at, resolved_at, reopened)
VALUES
(1,3,2,1,'Medium','Resolved','2026-01-10 09:10:00','2026-01-10 09:35:00','2026-01-11 11:05:00',FALSE),
(2,2,3,4,'High','Resolved','2026-01-11 10:05:00','2026-01-11 10:12:00','2026-01-11 18:10:00',FALSE),
(5,4,4,NULL,'Low','Closed','2026-01-12 08:20:00','2026-01-12 12:00:00','2026-01-15 09:00:00',FALSE),
(4,1,1,3,'High','Resolved','2026-01-13 14:00:00','2026-01-13 15:30:00','2026-01-14 10:10:00',FALSE),
(2,2,2,2,'Critical','Resolved','2026-01-14 07:45:00','2026-01-14 08:00:00','2026-01-14 12:30:00',TRUE),
(7,1,4,NULL,'Medium','Closed','2026-01-14 11:00:00','2026-01-14 11:20:00','2026-01-16 12:00:00',FALSE),
(3,3,2,6,'Medium','In Progress','2026-01-15 09:05:00','2026-01-15 09:30:00',NULL,FALSE),
(6,2,3,4,'High','In Progress','2026-01-15 10:15:00','2026-01-15 10:45:00',NULL,FALSE),
(8,4,1,5,'Low','In Progress','2026-01-16 08:10:00','2026-01-16 08:40:00',NULL,FALSE),
(9,1,2,1,'High','In Progress','2026-01-16 09:00:00','2026-01-16 09:20:00',NULL,FALSE),
(10,NULL,4, NULL,'Medium','Open','2026-01-16 09:40:00',NULL,NULL,FALSE),
(1,NULL,3,4,'Low','Open','2026-01-16 10:05:00',NULL,NULL,FALSE),
(5,4,1,3,'Medium','Open','2026-01-16 11:30:00','2026-01-16 12:00:00',NULL,FALSE),
(2,2,2,2,'High','Open','2026-01-17 09:10:00','2026-01-17 09:25:00',NULL,FALSE),
(7,1,2,6,'Low','Resolved','2026-01-17 11:00:00','2026-01-17 11:10:00','2026-01-18 09:00:00',FALSE),
(3,3,4,NULL,'Critical','Resolved','2026-01-18 07:20:00','2026-01-18 07:30:00','2026-01-18 13:00:00',FALSE);

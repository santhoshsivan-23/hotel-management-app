-- Roles
INSERT IGNORE INTO roles (name) VALUES
  ('Admin'), ('Manager'), ('Receptionist'), ('Housekeeping'), ('Kitchen');

-- Permissions (fine-grained keys the Users & Roles settings screen can
-- assign per role; route-level access today is enforced by role name via
-- middleware/role.middleware.js, but these are seeded so an admin UI for
-- per-permission overrides can be built against them later without a
-- schema change).
INSERT IGNORE INTO permissions (`key`, description) VALUES
  ('view_rooms', 'View room list and status'),
  ('create_booking', 'Create a new reservation'),
  ('checkin', 'Check a guest in'),
  ('checkout', 'Check a guest out'),
  ('manage_guests', 'Create/edit guest profiles'),
  ('add_food_order', 'Place an in-room food order'),
  ('add_service', 'Request a room service'),
  ('take_payment', 'Record a payment'),
  ('view_assigned_rooms', 'View rooms assigned for housekeeping'),
  ('update_cleaning_status', 'Update housekeeping task status'),
  ('view_housekeeping_requests', 'View housekeeping task queue'),
  ('view_food_orders', 'View kitchen order queue'),
  ('update_food_order_status', 'Update a food order''s status'),
  ('manage_room_types', 'Create/edit room types'),
  ('manage_amenities', 'Create/edit amenities'),
  ('manage_service_types', 'Create/edit service types'),
  ('manage_taxes', 'Create/edit tax rules'),
  ('manage_payment_methods', 'Enable/disable payment methods'),
  ('manage_users', 'Create/edit users and roles'),
  ('view_reports', 'View reports'),
  ('manage_settings', 'Edit hotel/business settings');

-- Role -> permission mapping, matching the example permission sets from
-- the app spec (Receptionist / Housekeeping) plus reasonable defaults for
-- Manager, Kitchen and Admin (full access).
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.name = 'Admin';

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Manager' AND p.`key` != 'manage_users';

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Receptionist' AND p.`key` IN (
  'view_rooms', 'create_booking', 'checkin', 'checkout',
  'manage_guests', 'add_food_order', 'add_service', 'take_payment'
);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Housekeeping' AND p.`key` IN (
  'view_assigned_rooms', 'update_cleaning_status', 'view_housekeeping_requests'
);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Kitchen' AND p.`key` IN (
  'view_food_orders', 'update_food_order_status'
);

INSERT INTO payment_methods (uuid, name, active)
SELECT UUID(), t.name, 1 FROM (
  SELECT 'Cash' AS name UNION ALL SELECT 'Card' UNION ALL SELECT 'UPI'
  UNION ALL SELECT 'Bank Transfer' UNION ALL SELECT 'Online'
) t
WHERE NOT EXISTS (SELECT 1 FROM payment_methods p WHERE p.name = t.name);

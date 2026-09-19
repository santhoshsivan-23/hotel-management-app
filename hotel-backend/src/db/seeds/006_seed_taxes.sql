INSERT INTO taxes (uuid, name, percentage, applicable_to, active)
SELECT UUID(), t.name, t.percentage, t.applicable_to, 1 FROM (
  SELECT 'Room Tax' AS name, 12.00 AS percentage, 'ROOM' AS applicable_to
  UNION ALL SELECT 'Food Tax', 5.00, 'FOOD'
  UNION ALL SELECT 'Service Tax', 5.00, 'SERVICE'
) t
WHERE NOT EXISTS (SELECT 1 FROM taxes x WHERE x.name = t.name);

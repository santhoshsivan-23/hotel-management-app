INSERT INTO amenities (uuid, name, active)
SELECT UUID(), t.name, 1 FROM (
  SELECT 'AC' AS name UNION ALL SELECT 'TV' UNION ALL SELECT 'WiFi'
  UNION ALL SELECT 'Mini Bar' UNION ALL SELECT 'Breakfast'
  UNION ALL SELECT 'Parking' UNION ALL SELECT 'Bathtub' UNION ALL SELECT 'Room Service'
) t
WHERE NOT EXISTS (SELECT 1 FROM amenities a WHERE a.name = t.name);

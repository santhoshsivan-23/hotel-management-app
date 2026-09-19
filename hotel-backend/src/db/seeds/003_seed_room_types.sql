INSERT INTO room_types (uuid, name, description, default_capacity, default_price, active)
SELECT UUID(), t.name, t.description, t.capacity, t.price, 1 FROM (
  SELECT 'Standard' AS name, 'Comfortable standard room' AS description, 2 AS capacity, 2000.00 AS price
  UNION ALL SELECT 'Deluxe', 'Spacious deluxe room with upgraded amenities', 2, 3500.00
  UNION ALL SELECT 'Suite', 'Premium suite with separate living area', 3, 6000.00
  UNION ALL SELECT 'Family', 'Large room suited for families', 4, 4500.00
) t
WHERE NOT EXISTS (SELECT 1 FROM room_types rt WHERE rt.name = t.name);

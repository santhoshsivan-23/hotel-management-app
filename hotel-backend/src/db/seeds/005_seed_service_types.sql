INSERT INTO service_types (uuid, name, category, price, tax_percent, active)
SELECT UUID(), t.name, t.category, t.price, 0, 1 FROM (
  SELECT 'Laundry' AS name, 'Laundry' AS category, 100.00 AS price
  UNION ALL SELECT 'Extra Bed', 'Room', 500.00
  UNION ALL SELECT 'Airport Pickup', 'Transport', 800.00
  UNION ALL SELECT 'Room Cleaning', 'Housekeeping', 0.00
  UNION ALL SELECT 'Towels', 'Housekeeping', 0.00
  UNION ALL SELECT 'Toiletries', 'Housekeeping', 0.00
  UNION ALL SELECT 'Wake-up Call', 'Other', 0.00
) t
WHERE NOT EXISTS (SELECT 1 FROM service_types s WHERE s.name = t.name);

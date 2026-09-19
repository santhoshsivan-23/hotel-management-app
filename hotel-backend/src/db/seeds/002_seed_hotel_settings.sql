INSERT INTO hotel_settings (hotel_name, currency, timezone, checkin_time, checkout_time, invoice_prefix, booking_prefix)
SELECT 'My Hotel', 'INR', 'Asia/Kolkata', '12:00 PM', '11:00 AM', 'INV', 'BK'
WHERE NOT EXISTS (SELECT 1 FROM hotel_settings);

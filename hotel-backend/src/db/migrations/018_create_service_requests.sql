CREATE TABLE IF NOT EXISTS service_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  booking_id INT NOT NULL,
  room_id INT NOT NULL,
  guest_id INT NOT NULL,
  service_type_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  status ENUM('REQUESTED','ACCEPTED','IN_PROGRESS','COMPLETED','DELIVERED','CANCELLED')
    NOT NULL DEFAULT 'REQUESTED',
  notes VARCHAR(255),
  created_by_device VARCHAR(100),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id),
  FOREIGN KEY (room_id) REFERENCES rooms(id),
  FOREIGN KEY (guest_id) REFERENCES guests(id),
  FOREIGN KEY (service_type_id) REFERENCES service_types(id),
  INDEX idx_service_requests_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

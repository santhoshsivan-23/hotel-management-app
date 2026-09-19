CREATE TABLE IF NOT EXISTS guests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uuid CHAR(36) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  mobile VARCHAR(20) NOT NULL,
  email VARCHAR(150),
  id_proof_type VARCHAR(50),
  id_proof_number VARCHAR(100),
  address TEXT,
  created_by_device VARCHAR(100),
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_guests_mobile (mobile),
  INDEX idx_guests_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

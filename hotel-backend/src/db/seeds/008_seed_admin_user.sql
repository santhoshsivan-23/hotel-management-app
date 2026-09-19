-- Default administrator login (CHANGE THIS PASSWORD after first login):
--   username: admin
--   password: admin123
INSERT INTO users (uuid, name, mobile, email, username, password_hash, role_id, status)
SELECT UUID(), 'Hotel Admin', '9999999999', 'admin@example.com', 'admin',
       '$2a$10$ndLkjfBUNimOQEQ4uXeXgug/bzthXg37OrfxJ6sBfa9S3XqkCJnWO',
       (SELECT id FROM roles WHERE name = 'Admin'), 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Create system_config table
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create voucher_packages table
CREATE TABLE IF NOT EXISTS voucher_packages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    profile VARCHAR(50) NOT NULL,
    price INTEGER NOT NULL,
    duration VARCHAR(50) NOT NULL,
    speed VARCHAR(50) NOT NULL,
    description TEXT,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    package_id INTEGER REFERENCES voucher_packages(id),
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_email VARCHAR(100),
    amount INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_reference VARCHAR(100),
    payment_url TEXT,
    voucher_code VARCHAR(20),
    voucher_password VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create activity_logs table
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER REFERENCES transactions(id),
    action VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (username, password_hash) 
VALUES ('admin', '$2b$10$rOzJqQZQQQZQQZQQZQQZQOzJqQZQQQZQQZQQZQQZQOzJqQZQQQZQQZ')
ON CONFLICT (username) DO NOTHING;

-- Insert default system configurations
INSERT INTO system_config (key, value, description) VALUES
('mikrotik_host', '192.168.1.1', 'MikroTik RouterOS IP Address'),
('mikrotik_username', 'admin', 'MikroTik API Username'),
('mikrotik_password', '', 'MikroTik API Password'),
('tripay_merchant_code', 'T42431', 'TriPay Merchant Code'),
('tripay_api_key', 'WfcMqxIr6QCFzeo5PT1PLKphuhqIqpURV9jGgMlN', 'TriPay API Key'),
('tripay_private_key', 'Swu3P-JkeaZ-m9FnW-649ja-H0eD0', 'TriPay Private Key'),
('tripay_mode', 'sandbox', 'TriPay Mode (sandbox/production)'),
('whatsapp_api_url', '', 'WhatsApp Gateway API URL'),
('whatsapp_api_key', '', 'WhatsApp Gateway API Key')
ON CONFLICT (key) DO NOTHING;

-- Insert default voucher packages
INSERT INTO voucher_packages (name, profile, price, duration, speed, description) VALUES
('Paket Hemat 1 Jam', '1jam', 2000, '1 Jam', '2 Mbps', 'Cocok untuk browsing ringan dan media sosial'),
('Paket Super Cepat 6 Jam', '6jam', 5000, '6 Jam', '5 Mbps', 'Ideal untuk streaming dan download'),
('Paket Premium 24 Jam', '1hari', 10000, '24 Jam', '10 Mbps', 'Unlimited browsing untuk seharian penuh'),
('Paket Mingguan', '1minggu', 50000, '7 Hari', '10 Mbps', 'Paket hemat untuk kebutuhan seminggu')
ON CONFLICT DO NOTHING;

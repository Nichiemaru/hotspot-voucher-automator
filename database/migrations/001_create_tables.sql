-- Create voucher_packages table
CREATE TABLE IF NOT EXISTS voucher_packages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    profile VARCHAR(255) NOT NULL,
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
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_email VARCHAR(255),
    amount INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_reference VARCHAR(255),
    payment_url TEXT,
    voucher_code VARCHAR(255),
    voucher_password VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create system_config table
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (username, password_hash, email) 
VALUES ('admin', '$2b$10$rOzJqQqQqQqQqQqQqQqQqOzJqQqQqQqQqQqQqQqQqOzJqQqQqQqQq', 'admin@example.com')
ON CONFLICT (username) DO NOTHING;

-- Insert default system configurations
INSERT INTO system_config (key, value, description) VALUES
('mikrotik_host', '', 'MikroTik RouterOS IP Address'),
('mikrotik_username', '', 'MikroTik RouterOS Username'),
('mikrotik_password', '', 'MikroTik RouterOS Password'),
('tripay_merchant_code', '', 'TriPay Merchant Code'),
('tripay_api_key', '', 'TriPay API Key'),
('tripay_private_key', '', 'TriPay Private Key'),
('tripay_mode', 'sandbox', 'TriPay Mode (sandbox/production)'),
('whatsapp_api_url', '', 'WhatsApp Gateway API URL'),
('whatsapp_api_key', '', 'WhatsApp Gateway API Key')
ON CONFLICT (key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_voucher_packages_enabled ON voucher_packages(enabled);

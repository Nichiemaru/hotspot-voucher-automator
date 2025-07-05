-- Database schema untuk hotspot voucher system

-- Tabel konfigurasi sistem
CREATE TABLE IF NOT EXISTS configurations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    key_name VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel admin users
CREATE TABLE IF NOT EXISTS admin_users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel paket voucher
CREATE TABLE IF NOT EXISTS voucher_packages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    profile VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration VARCHAR(50) NOT NULL,
    speed VARCHAR(50) NOT NULL,
    description TEXT,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel transaksi
CREATE TABLE IF NOT EXISTS transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reference VARCHAR(100) UNIQUE NOT NULL,
    merchant_ref VARCHAR(100) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    package_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'paid', 'failed', 'expired', 'cancelled') DEFAULT 'pending',
    payment_method VARCHAR(50),
    voucher_username VARCHAR(50),
    voucher_password VARCHAR(50),
    voucher_created_at TIMESTAMP NULL,
    whatsapp_sent BOOLEAN DEFAULT FALSE,
    whatsapp_sent_at TIMESTAMP NULL,
    tripay_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES voucher_packages(id)
);

-- Tabel log aktivitas
CREATE TABLE IF NOT EXISTS activity_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    status ENUM('success', 'failed', 'pending') DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (username, password_hash, email) VALUES 
('admin', '$2b$10$rOzJqKqVQQGVzKqVQQGVzOzJqKqVQQGVzKqVQQGVzOzJqKqVQQGVzO', 'admin@hotspotvoucher.com')
ON DUPLICATE KEY UPDATE username = username;

-- Insert default voucher packages
INSERT INTO voucher_packages (name, profile, price, duration, speed, description) VALUES 
('Paket Hemat 1 Jam', '1jam', 2000.00, '1 Jam', '2 Mbps', 'Cocok untuk browsing ringan dan media sosial'),
('Paket Super Cepat 6 Jam', '6jam', 5000.00, '6 Jam', '5 Mbps', 'Ideal untuk streaming dan download'),
('Paket Premium 24 Jam', '1hari', 10000.00, '24 Jam', '10 Mbps', 'Unlimited browsing untuk seharian penuh'),
('Paket Mingguan', '1minggu', 50000.00, '7 Hari', '10 Mbps', 'Paket hemat untuk kebutuhan seminggu')
ON DUPLICATE KEY UPDATE name = name;

-- Insert default configurations
INSERT INTO configurations (key_name, value, description) VALUES 
('mikrotik_ip', '', 'IP Address MikroTik Router'),
('mikrotik_username', '', 'Username API MikroTik'),
('mikrotik_password', '', 'Password API MikroTik'),
('tripay_merchant_code', 'T42431', 'TriPay Merchant Code'),
('tripay_api_key', 'WfcMqxIr6QCFzeo5PT1PLKphuhqIqpURV9jGgMlN', 'TriPay API Key'),
('tripay_private_key', 'Swu3P-JkeaZ-m9FnW-649ja-H0eD0', 'TriPay Private Key'),
('whatsapp_endpoint', '', 'WhatsApp Gateway Endpoint URL'),
('whatsapp_api_key', '', 'WhatsApp Gateway API Key'),
('app_name', 'HotSpot Voucher', 'Application Name'),
('app_url', 'http://localhost:3000', 'Application Base URL')
ON DUPLICATE KEY UPDATE key_name = key_name;

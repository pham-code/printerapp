USE wp_db;

CREATE TABLE IF NOT EXISTS printer_status_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    printer_ip VARCHAR(255) NOT NULL,
    cartridge_id VARCHAR(255) NOT NULL,
    ink_level_percentage INT,
    status_message TEXT,
    execution_timestamp DATETIME NOT NULL,
    email_sent BOOLEAN NOT NULL
);

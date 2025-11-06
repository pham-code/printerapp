#!/bin/bash

# Update and install MariaDB
if command -v dnf >/dev/null 2>&1; then
  package_mgr=dnf
else
  package_mgr=yum
fi

sudo $package_mgr update -y
sudo $package_mgr install -y mariadb105-server

# Start and enable MariaDB
sudo systemctl enable --now mariadb

# Secure the installation and set up the database
# Use template variables for DB credentials
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"

# Wait for MariaDB to be ready
for i in {30..0}; do
  if mysql -e "SELECT 1" &> /dev/null; then
    break
  fi
  echo "MariaDB not ready yet, waiting..."
  sleep 1
done

# Set root password and create database/user
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${db_pass}';"
# Allow root from local network if needed
sudo mysql -u root -p"${db_pass}" -e "CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -p"${db_pass}" -e "CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_pass}';"
sudo mysql -u root -p"${db_pass}" -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'%';"
sudo mysql -u root -p"${db_pass}" -e "FLUSH PRIVILEGES;"
sudo mysql -u root -p"${db_pass}" -e "CREATE TABLE IF NOT EXISTS ${db_name}.printer_status_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    printer_ip VARCHAR(255) NOT NULL,
    cartridge_id VARCHAR(255) NOT NULL,
    ink_level_percentage INT,
    status_message TEXT,
    execution_timestamp DATETIME NOT NULL,
    email_sent BOOLEAN NOT NULL
);"

# Allow remote connections by binding to all interfaces
sudo sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
sudo systemctl restart mariadb
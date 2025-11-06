#!/bin/bash
sudo su

yum update -y
yum install -y httpd php php-cli php-mysqlnd php-gd php-xml php-mbstring php-json php-fpm
systemctl enable --now httpd
systemctl enable --now php-fpm

# WordPress user data template that connects to external DB host
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
# Configure WordPress to use external DB
# Create wp-config.php and set DB constants
DB_NAME_VAL=$DB_NAME
DB_USER_VAL=$DB_USER
DB_PASS_VAL=$DB_PASS
DB_HOST_VAL=$DB_HOST

# Prefer IPv4 over IPv6 for name resolution (avoid IPv6 timeouts in VPC without IPv6 routing)
cat <<'EOF' | sudo tee /etc/gai.conf
# Prefer IPv4 addresses over IPv6 (map ::ffff:0:0/96 higher)
precedence ::ffff:0:0/96  100
EOF

cd /tmp
# Force wget/curl to use IPv4 to avoid IPv6 connection attempts/timeouts
wget -4 https://wordpress.org/latest.tar.gz -O latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/$DB_NAME_VAL/g" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USER_VAL/g" /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASS_VAL/g" /var/www/html/wp-config.php
sed -i "s/localhost/$DB_HOST_VAL/g" /var/www/html/wp-config.php

# Generate salts
SALT_KEYS=$(curl -4 -s https://api.wordpress.org/secret-key/1.1/salt/)
# Replace the placeholder line AUTH_KEY with the full salts block
perl -0777 -pe "s/define\('AUTH_KEY'.*?\n\);/\$ENV{SALT_KEYS}/s" -i /var/www/html/wp-config.php || true

# Create the HTML content
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>WordPress and Server Information</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; line-height: 1.6; }
        .info-box { border: 1px solid #ccc; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        h2 { color: #333; }
        p { margin: 5px 0; }
    </style>
</head>
<body>
    <h1>PRIVATE EC2 and WordPress Details: $(hostname -f)</h1>
    <div class="info-box">
        <h2>WordPress Database Information</h2>
        <p><strong>Database Name:</strong> ${db_name}</p>
        <p><strong>Database User:</strong> ${db_user}</p>
        <p><strong>Database Host:</strong> ${db_host}</p>
    </div>
    <p>Your WordPress installation is complete. To access it, visit <a href="/wp-admin">the WordPress admin page</a>.</p>
</body>
</html>
EOF

chown -R apache:apache /var/www/html/
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf || true

systemctl start httpd.service
systemctl enable httpd.service
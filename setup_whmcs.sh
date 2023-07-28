#!/bin/bash

# WHMCS setup script with LEMP, MariaDB, Let's Encrypt (optional)
# Usage: bash setup_whmcs.sh

# Log file
LOG_FILE="whmcs_setup_log.txt"

# Function to log messages to the log file
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "${LOG_FILE}"
}

# Configuration
WHMCS_INSTALL_DIR="/var/www/whmcs"   # Update this to your preferred installation directory
DB_USER="your_database_user"        # Replace with your database username
DB_PASS="your_database_password"    # Replace with your database password
DB_NAME="whmcs_database"            # Replace with your database name
DB_HOST="localhost"                 # Replace with your database host
DOMAIN="your_domain.com"            # Replace with your domain name

# Inform the user about manual WHMCS download
echo "Before running the script, please ensure you have manually downloaded the 'whmcs.zip' file from the official WHMCS website."
echo "Place the 'whmcs.zip' file in the same directory as this script."

# Ask the user to confirm the presence of the 'whmcs.zip' file
read -p "Have you placed the 'whmcs.zip' file in the same directory as this script? (y/n): " confirm_download

if [[ "${confirm_download}" != "y" && "${confirm_download}" != "Y" ]]; then
    echo "Please download the 'whmcs.zip' file and place it in the same directory as this script before running the setup."
    exit 1
fi

# Step 1: Configure permissions
log_message "Step 1: Configuring permissions..."
chown -R www-data:www-data "${WHMCS_INSTALL_DIR}"
chmod -R 755 "${WHMCS_INSTALL_DIR}/templates_c"
chmod 644 "${WHMCS_INSTALL_DIR}/configuration.php"

# Step 2: Install LEMP (Linux, Nginx, PHP)
log_message "Step 2: Installing LEMP..."
apt update
apt install -y nginx php-fpm php-mysql

# Step 3: Install MariaDB
log_message "Step 3: Installing MariaDB..."
apt install -y mariadb-server

# Step 4: Secure MariaDB installation
log_message "Step 4: Securing MariaDB installation..."
mysql_secure_installation

# Step 5: Configure Nginx
log_message "Step 5: Configuring Nginx..."
cat > /etc/nginx/sites-available/whmcs << EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    root ${WHMCS_INSTALL_DIR};
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock; # Update the PHP version if needed
    }
}
EOF

ln -s /etc/nginx/sites-available/whmcs /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Step 6: Setup Let's Encrypt SSL (optional)
log_message "Step 6: Setting up Let's Encrypt SSL (optional)..."
read -p "Do you want to enable SSL with Let's Encrypt? (y/n): " enable_ssl

if [[ "${enable_ssl}" == "y" || "${enable_ssl}" == "Y" ]]; then
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}

    # Step 7: Restart Nginx with SSL
    log_message "Step 7: Restarting Nginx with SSL..."
    nginx -t
    systemctl restart nginx
else
    log_message "SSL setup skipped."
fi

if [[ "${enable_ssl}" == "y" || "${enable_ssl}" == "Y" ]]; then
    # Step 8: Create database and user
    log_message "Step 8: Creating database and user..."
    mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -p -e "FLUSH PRIVILEGES;"

    # Step 9: Setup configuration file
    log_message "Step 9: Configuring WHMCS..."
    cp "${WHMCS_INSTALL_DIR}/configuration.php.new" "${WHMCS_INSTALL_DIR}/configuration.php"
    sed -i "s/^\$db_username = 'db_username';/\$db_username = '${DB_USER}';/" "${WHMCS_INSTALL_DIR}/configuration.php"
    sed -i "s/^\$db_password = 'db_password';/\$db_password = '${DB_PASS}';/" "${WHMCS_INSTALL_DIR}/configuration.php"
    sed -i "s/^\$db_name = 'db_name';/\$db_name = '${DB_NAME}';/" "${WHMCS_INSTALL_DIR}/configuration.php"

    # Step 10: Install WHMCS
    log_message "Step 10: Installing WHMCS..."
    php "${WHMCS_INSTALL_DIR}/install/install.php"

    # Step 11: Cleanup
    log_message "Step 11: Cleaning up..."
    rm -rf "${WHMCS_INSTALL_DIR}/install"

    log_message "WHMCS setup completed successfully!"
else
    log_message "WHMCS setup completed without SSL configuration."
fi

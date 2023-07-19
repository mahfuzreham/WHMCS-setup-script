#!/bin/bash

# WHMCS setup script
# Usage: bash setup_whmcs.sh

# Log file
LOG_FILE="whmcs_setup_log.txt"

# Function to log messages to the log file
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "${LOG_FILE}"
}

# Configuration
WHMCS_VERSION="8.3.1"                # Update this to the desired WHMCS version
WHMCS_INSTALL_DIR="/var/www/whmcs"   # Update this to your preferred installation directory
DB_USER="your_database_user"        # Replace with your database username
DB_PASS="your_database_password"    # Replace with your database password
DB_NAME="whmcs_database"            # Replace with your database name
DB_HOST="localhost"                 # Replace with your database host

# Step 1: Download WHMCS
log_message "Step 1: Downloading WHMCS..."
wget -qO- "https://www.whmcs.com/getwhmcs.php?version=${WHMCS_VERSION}&type=zip" -O whmcs.zip
unzip whmcs.zip -d "${WHMCS_INSTALL_DIR}"
rm whmcs.zip

# Step 2: Configure permissions
log_message "Step 2: Configuring permissions..."
chown -R www-data:www-data "${WHMCS_INSTALL_DIR}"
chmod -R 755 "${WHMCS_INSTALL_DIR}/templates_c"
chmod -R 755 "${WHMCS_INSTALL_DIR}/configuration.php"

# Step 3: Create database and user
log_message "Step 3: Creating database and user..."
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';"
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "FLUSH PRIVILEGES;"

# Step 4: Setup configuration file
log_message "Step 4: Configuring WHMCS..."
cp "${WHMCS_INSTALL_DIR}/configuration.php.new" "${WHMCS_INSTALL_DIR}/configuration.php"
sed -i "s/^\$db_username = 'db_username';/\$db_username = '${DB_USER}';/" "${WHMCS_INSTALL_DIR}/configuration.php"
sed -i "s/^\$db_password = 'db_password';/\$db_password = '${DB_PASS}';/" "${WHMCS_INSTALL_DIR}/configuration.php"
sed -i "s/^\$db_name = 'db_name';/\$db_name = '${DB_NAME}';/" "${WHMCS_INSTALL_DIR}/configuration.php"

# Step 5: Install WHMCS
log_message "Step 5: Installing WHMCS..."
php "${WHMCS_INSTALL_DIR}/install/install.php"

# Step 6: Cleanup
log_message "Step 6: Cleaning up..."
rm -rf "${WHMCS_INSTALL_DIR}/install"

log_message "WHMCS setup completed successfully!"

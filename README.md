# WHMCS Setup Bash Script

This bash script helps you set up a WHMCS installation on your web server. It will download the specified WHMCS version, configure permissions, create a database and user, and set up the necessary configurations. The setup process will be logged in the `whmcs_setup_log.txt` file.

## Prerequisites

Before running the script, make sure you have the following:

- A web server (e.g., Apache, Nginx) installed and configured.
- PHP installed on your server.
- MySQL (or MariaDB) installed and configured.
- `wget` and `unzip` packages installed.

## Usage

1. Modify the script variables in the `setup_whmcs.sh` file to match your environment:

   - `WHMCS_VERSION`: The desired WHMCS version you want to install.
   - `WHMCS_INSTALL_DIR`: The installation directory for WHMCS on your server.
   - `DB_USER`: Your MySQL database username.
   - `DB_PASS`: Your MySQL database password.
   - `DB_NAME`: The name of the MySQL database you want to create for WHMCS.
   - `DB_HOST`: The MySQL database host (usually `localhost`).

2. Make the script executable:

chmod +x setup_whmcs.sh


3. Run the script:

bash setup_whmcs.sh


The script will download WHMCS, configure permissions, create a database, and set up the necessary configurations. After successful execution, you can access your WHMCS installation from your web browser.

**Note:** This script is a basic example and may not cover all use cases. Review and customize it according to your specific requirements.

## Log File

The setup process will be logged in the `whmcs_setup_log.txt` file in the same directory where the script is executed.
Make sure to place both the setup_whmcs.sh and README.md files in the same directory. When you run the setup_whmcs.sh script, it will create a log file named whmcs_setup_log.txt, which will contain the log of the setup process. The log file will be stored in the same directory where the script is executed.

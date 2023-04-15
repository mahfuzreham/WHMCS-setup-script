#!/bin/bash -x
exec > /tmp/installWHMCS.log 2>&1

# Install nginx
which nginx &> /dev/null
if [ $? -ne 0 ] ; then
  sudo apt-get -y update && sudo apt remove apache2.* && sudo apt-get -y install nginx
fi
# allow https
sudo ufw allow 'Nginx HTTP'
# stop nginx
sudo systemctl stop nginx
# start nginx
sudo systemctl start nginx

# Install mysql-server
which mysql-server &> /dev/null
if [ $? -ne 0 ] ; then
  apt-get -y update &&
  sudo debconf-set-selections <<< 'mysql-server-5.7 mysql-server/root_password password 123' &&
  sudo debconf-set-selections <<< 'mysql-server-5.7 mysql-server/root_password_again password 123' &&
  sudo apt-get -y install mysql-server-5.7
  # finish up mysql install
  if ! grep -q "0.0.0.0" /etc/mysql/conf.d/mysql.cnf; then
      echo "bind-address = 0.0.0.0" >> /etc/mysql/conf.d/mysql.cnf
  else
      echo "Found"
  fi
  sudo service mysql restart
  sudo mysql -uroot -p123 -e "CREATE DATABASE USER_APP"
fi

# uninstall apache
whereis apache2 > keep_temp
sudo service apache2 stop
sudo apt-get -y purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get -y autoremove --purge
sudo apt-get -y update
sudo whereis apache2 > keep_temp
fileString=`cat keep_temp`
length=${#fileString}
if (( $length > 10 )); then
    removefile=${fileString/apache2: /}
    sudo rm -Rf $removefile
fi
sudo rm -Rf keep_temp &&
sudo rm -R /var/www/html/index.html
# Install PHP7.2
which php7.2 &> /dev/null
if [ $? -ne 0 ] ; then
  sudo apt-get -y update && 
  sudo apt-get -y install php7.2 libapache2-mod-php7.2 php7.2-curl php7.2-gd &&
  sudo apt-get -y install php7.2-fpm
fi
sudo apt-get -y update && sudo apt-get -y install php7.2-fpm
sudo cat script/nginx.config > /etc/nginx/sites-available/default
# Install phpmyadmin
which phpmyadmin &> /dev/null
if [ $? -ne 0 ] ; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y install phpmyadmin
fi

# stop nginx
sudo systemctl stop nginx
# start nginx
sudo systemctl start nginx

# install ioncube && configuration
sudo wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz &&
sudo tar xzf ioncube_loaders_lin_x86-64.tar.gz -C /usr/local
sudo rm -R ioncube_loaders_lin_x86-64.tar.gz
if ! grep -q "ioncube_loader_lin_7.2.so" /etc/php/7.2/cli/php.ini; then
    echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.2.so" >> /etc/php/7.2/cli/php.ini
else
    echo "Found"
fi
if ! grep -q "ioncube_loader_lin_7.2.so" /etc/php/7.2/fpm/php.ini; then
    echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.2.so" >> /etc/php/7.2/fpm/php.ini
else
    echo "Found"
fi

# installing whmcs
sudo rm -r /var/www/html/*
sudo apt-get -y update && 
sudo apt-get -y unzip
sudo wget http://95.217.162.157/whmcs_v7102_full.zip
sudo unzip whmcs_v7102_full.zip
sudo cp -a whmcs/. /var/www/html/
sudo cp -i README.txt /var/www/html/
sudo cp -i EULA.txt /var/www/html/
sudo rm -R EULA.txt
sudo rm -R README.txt
sudo rm -R whmcs_v7102_full.zip
sudo rm -R whmcs
sudo mv /var/www/html/configuration.php.new /var/www/html/configuration.php
sudo chmod 777 /var/www/html/configuration.php
# start configuration

# stop nginx
sudo systemctl stop nginx
# start nginx
sudo systemctl start nginx
# start php7.2-fpm
sudo systemctl restart php7.2-fpm 

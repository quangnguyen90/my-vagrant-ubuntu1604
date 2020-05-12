#!/bin/bash

# ******************************************
# General Config
# ******************************************
config_os_name=ubuntu1604
config_os_setup_path=/scripts
config_apache2_user=ubuntu
config_apache2_group=ubuntu
config_mysql_root_password=123456

# ******************************************
# Site1 Config
# ******************************************
config_site1_app_name=vagrantlamp1
config_site1_server_name=vagrantlamp1-local.com
config_site1_port=80
config_site1_root_path=/vagrant/projectone/src

# ******************************************
# Site2 Config
# ******************************************
config_site2_app_name=vagrantlamp2
config_site2_server_name=vagrantlamp2-local.com
config_site2_port=80
config_site2_root_path=/vagrant/projecttwo/src

# ******************************************
# 00 - Before setup
# ******************************************
# Update package
sudo apt-get update -y;
sudo apt-get upgrade -y;
#sudo apt autoremove;

echo "______________________________________ 00-beforeSetup.sh: Done!!!!!";

# ******************************************
# 01 - Common setup
# ******************************************
# CURL, GIT, COMPOSER
# Install CURL
sudo apt-get install -y curl;

# Install GIT
sudo apt-get install -y git;    

# Install Composer
sudo wget https://getcomposer.org/composer.phar
sudo mv composer.phar /usr/local/bin/composer;

# Installing Bower and Gulp
npm install -g bower gulp

echo "______________________________________ 01-common.sh: Done!!!!!";

# ******************************************
# 02 - Setup Apache2
# ******************************************
# APACHE2
# Install Apache
sudo apt-get install -y apache2 apache2-utils;
sudo a2enmod rewrite;
sudo sed -i "s/export APACHE_RUN_USER=www-data$/export APACHE_RUN_USER=ubuntu/" /etc/apache2/envvars;
sudo sed -i "s/export APACHE_RUN_GROUP=www-data$/export APACHE_RUN_GROUP=ubuntu/" /etc/apache2/envvars;

echo "______________________________________ 02-setup-apache2: Done!!!!!";

# ******************************************
# 03 - Setup php70
# ******************************************
# PHP70
# Install PHP7
sudo apt-get install -y; 
# Install module of PHP7
sudo apt-get install -y libapache2-mod-php php php-mcrypt php-curl php-intl;
sudo phpenmod mcrypt;    
# /etc/apache2/mods-enabled/dir.conf
sudo sed -i "s/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm$/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/" /etc/apache2/mods-enabled/dir.conf;

# Update the /etc/php/7.0/apache2/php.ini file.
sudo sed -i "s/post_max_size = 8M$/post_max_size = 1024M/" /etc/php/7.0/apache2/php.ini;
sudo sed -i "s/upload_max_filesize = 2M$/upload_max_filesize = 1024M/" /etc/php/7.0/apache2/php.ini;
sudo sed -i "s/;date\.timezone =$/date\.timezone = Asia\/Tokyo/" /etc/php/7.0/apache2/php.ini;
sudo sed -i "s/; max_input_vars = 1000$/max_input_vars = 10000/" /etc/php/7.0/apache2/php.ini;
sudo sed -i "s/session\.gc_maxlifetime = 1440$/session\.gc_maxlifetime = 56700/" /etc/php/7.0/apache2/php.ini;
    
echo "______________________________________ 03-setup-php70: Done!!!!!";

# ******************************************
# 04 - Setup mysql57
# ******************************************
# MYSQL
sudo echo "mysql-server-5.7 mysql-server/root_password password $config_mysql_root_password" | sudo debconf-set-selections;
sudo echo "mysql-server-5.7 mysql-server/root_password_again password $config_mysql_root_password" | sudo debconf-set-selections;
sudo apt-get install -y mysql-server php-mysql;

# Change MySQL Listening IP Address from local 127.0.0.1 to All IPs 0.0.0.0
sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf;
# Update mysql Table root record to accept incoming remote connections
sudo mysql -uroot --password=$config_mysql_root_password -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;';
# Restart MySQL Service
sudo service mysql restart;

echo "______________________________________ 04-setup-mysql57: Done!!!!!";

# ******************************************
# 05 - Setup PHPMyadmin
# ******************************************
# PHPMYADMIN
sudo echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections;
sudo echo "phpmyadmin phpmyadmin/app-password-confirm password $config_mysql_root_password" | sudo debconf-set-selections;
sudo echo "phpmyadmin phpmyadmin/mysql/admin-pass password $config_mysql_root_password" | sudo debconf-set-selections;
sudo echo "phpmyadmin phpmyadmin/mysql/app-pass password $config_mysql_root_password" | sudo debconf-set-selections;
sudo echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections;
sudo apt-get install -y phpmyadmin;
    
echo "______________________________________ 05-setup-phpmyadmin: Done!!!!!";

# ******************************************
# 06 - Setup sites
# ******************************************
# VIRTUAL HOST
index=1
while :; do
    get_app_name="config_site${index}_app_name"
    get_server_name="config_site${index}_server_name"
    get_port="config_site${index}_port"
    get_root_path="config_site${index}_root_path"

    app_name=${!get_app_name}
    server_name=${!get_server_name}
    port=${!get_port}
    root_path=${!get_root_path}
    
    # Empty is break
    if [ -z "$app_name" ]; then
        break
    fi
    
    block="<VirtualHost *:$port>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin $app_name@localhost
        ServerName $server_name
        ServerAlias www.$server_name
        DocumentRoot $root_path
        <Directory $root_path>
            AllowOverride All
            Require all granted
        </Directory>
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog \${APACHE_LOG_DIR}/$app_name-error.log
        CustomLog \${APACHE_LOG_DIR}/$app_name-access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>
    # vim: syntax=apache ts=4 sw=4 sts=4 sr noet
    "

    sudo echo "$block" > "/etc/apache2/sites-available/$app_name.conf"
    sudo ln -fs "/etc/apache2/sites-available/$app_name.conf" "/etc/apache2/sites-enabled/$app_name.conf"
    index=`expr $index + 1`
done

sudo service apache2 restart;    
echo "______________________________________ 06-sites.sh: Done!!!!!";

# ******************************************
# 07 - Create symbolic link
# ******************************************
# SYMBOLIC LINK
# linking Vagrant directory to Apache 2.4 public directory
rm -rf /var/www
ln -fs /vagrant /var/www

echo "______________________________________ 07-create symbolic link: Done!!!!!";

# ******************************************
# 08 - Setup Nodejs10x
# ******************************************
# NODEJS
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash –
sudo apt-get install -y nodejs;
sudo apt-get install -y build-essential;

echo "______________________________________ 08-setup-nodejs-10x.sh: Done!!!!!";

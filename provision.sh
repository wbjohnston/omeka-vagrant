#!/usr/bin/env bash

# Update the entire system
system::update() {
    yum -y update
}

# Configure repositories
system::initial_setup() {
    yum -y install git epel-release yum-utils
    yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum-config-manager --enable remi-php72
}

# Install httpd(apache2)
httpd::install() { 
    yum -y install httpd
}


# Configure httpd
# - Tell httpd to defer to .htaccess files
# - Tell httpd to look for `index.php` when serving files
# - set Apache user to own `/var/www/html`
httpd::configure() {
    # Create apache user
    # usermod -d /var/www/html -g apache apache
    sed -i "s/AllowOverride None/AllowOverride All/g" /etc/httpd/conf/httpd.conf
    sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/httpd/conf/httpd.conf

    # Own html directory
    chown apache:apache -R /var/www/html
}

# Start and enable httpd
httpd::start_and_enable() {
    systemctl enable httpd
    systemctl start httpd
}

# Instal php and all necessary libraries
php::install() {
    yum -y install php php-pdo php-xml php-pecl-mysql composer
}

# Install mariadb
mariadb::install() {
    yum -y install mariadb-server
}

# Start and enable mariadb
mariadb::enable_and_start() {
    systemctl enable mariadb
    systemctl start mariadb
}

# Secure install mariadb and add omeka user
mariadb::configure() {
    echo '

    vagrant
    vagrant
    y
    y
    y
    y
    y
    ' | mysql_secure_installation

    # Create omeka database
    mysql -u root -pvagrant -e "CREATE DATABASE omeka;"

    # Create omeka user
    mysql -u root -pvagrant -e "CREATE USER 'omeka'@'localhost' IDENTIFIED by 'omeka';"

    # Grant permission to omeka user to do whatever on omeka DB
    mysql -u root -pvagrant -e "GRANT ALL PRIVILEGES ON omeka.* TO omeka@localhost;" 
}

# Install imagemagick
imagemagick::install() {
    yum -y install ImageMagick
}

# Install node and npm
node::install() {
    yum -y install npm
}

# Globall install gulp
gulp::install() {
    npm install --global gulp-cli
}

# Disable SELinux
selinux::disable() {
    setenforce 0
}

# Install omeka to /var/www/html
omeka::install() {
    git clone https://github.com/omeka/omeka-s.git /var/www/html
    cd /var/www/html

    # Permissions
    chown apache:apache -R /var/www/html
    chmod u+w -R /var/www/html/files

    npm install
    gulp init

    cd - 
}

# Set up omeka configuration files
omeka::configure() {
    # Load in database configuration
    echo '
user     = omeka 
password = omeka
dbname   = omeka
host     = localhost
    ' > /var/www/html/config/database.ini
}

system::initial_setup;
system::update;

mariadb::install;
mariadb::enable_and_start;
mariadb::configure;

node::install;

gulp::install;

php::install;

imagemagick::install;

selinux::disable;

httpd::install;
httpd::configure;
httpd::start_and_enable;

omeka::install;
omeka::configure;

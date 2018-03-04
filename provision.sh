#!/usr/bin/env bash

# Steps to install
# 0. install git `yum -y install git`
# 1. install mariadb `# yum -y install mariadb-server`
# 2. enable mariadb `# systemctl enable mariadb`
# 3. start mariadb `# systemctl start mariadb`
# 4. Do secure install `# mysql_secure_installation`
# 5. Create omeka user and grant permissions
# 6. Install apache (httpd) `yum -y install httpd`
# 7. clone omeka to `/var/www/html` `git clone https://github.com/omeka/omeka-s.git /var/www/html`
# x. install epel-release `# yum -y install epel-release`
# x. Install npm and nodejs `# yum -y install nodejs`
# x. create omeka user `CREATE USER 'omeka'@'localhost' IDENTIFIED BY 'omeka';`
# x. grant permissions `GRANT ALL PRIVELEGES on omeka.* TO omeka@localhost;`
# x. install composer `# yum -y install composer`

# Need to add remi repo to be able to install php 7+

# Create user for apache

system::update() {
    yum -y update
}

system::initial_setup() {
    yum -y install git epel-release yum-utils
    yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum-config-manager --enable remi-php72
}

httpd::install() { 
    yum -y install httpd
}

httpd::restart() {
    sytemctl restart httpd
}

httpd::configure() {
    # Create apache user
    # usermod -d /var/www/html -g apache apache
    sed -i "s/AllowOverride None/AllowOverride All/g" /etc/httpd/conf/httpd.conf
    sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/httpd/conf/httpd.conf

    # Own html directory
    chown apache:apache -R /var/www/html
}

httpd::start_and_enable() {
    systemctl enable httpd
    systemctl start httpd
}

php::install() {
    yum -y install php php-pdo php-xml php-pecl-mysql composer
}

mariadb::install() {
    yum -y install mariadb-server
}

mariadb::enable_and_start() {
    systemctl enable mariadb
    systemctl start mariadb
}

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

imagemagick::install() {
    yum -y install ImageMagick
}

node::install() {
    yum -y install npm
}

gulp::install() {
    npm install --global gulp-cli
}

selinux::disable() {
    setenforce 0
}

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

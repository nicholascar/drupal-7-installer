MYSQL_ROOT_PWD=$1
MYSQL_DRUPAL_DB=$2
MYSQL_DRUPAL_USR=$3
MYSQL_DRUPAL_PWD=$4

#
#		Update Aptitude
#
sudo aptitude update

#
#       Configure the OS
#
sudo timedatectl set-timezone Australia/Sydney

#
#       Install MySQL
#
echo mysql-server mysql-server/root_password password $MYSQL_ROOT_PWD | sudo debconf-set-selections
echo mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PWD | sudo debconf-set-selections
sudo apt-get -y install mysql-server mysql-client || echo "MySQL installation failed" && exit

#
#       Set up Drupal user & DB in MySQL
#
mysql -uroot -p$MYSQL_ROOT_PWD -e "CREATE DATABASE $MYSQL_DRUPAL_DB;"
mysql -uroot -p$MYSQL_ROOT_PWD -e "GRANT ALL ON "$MYSQL_DRUPAL_DB".* to '"$MYSQL_DRUPAL_USR"'@'localhost' IDENTIFIED BY 'branches';"
mysql -uroot -p$MYSQL_ROOT_PWD -e "FLUSH PRIVILEGES;"

#
#       Install Apache2 & PHP5
#
sudo aptitude install -y apache2 || echo "Apache2 installation failed" && exit
sudo a2enmod rewrite
sudo service apache2 restart
sudo aptitude install -y php5 libapache2-mod-php5 php5-mysql php5-gd || echo "PHP installation failed" && exit

#
#       Configure Apache2 vhost to work with Drupal site
#
sudo rm /etc/apache2/sites-available/000-default.conf
sudo cp ~/apache-conf.txt /etc/apache2/sites-available/000-default.conf
sudo service apache2 reload

#
#       Install Drush
#
sudo aptitude install -y drush || echo "Drush installation failed" && exit

#
#       Download Drupal 7 and make site
#
cd /var/www/html/
sudo drush dl drupal
sudo mv drupal-7.43/* .
sudo mv drupal-7.43/.* .
sudo rmdir drupal-7.43

#
#		Install site using Drush
#
sudo drush site-install --db-url=mysql://$MYSQL_DRUPAL_USR:$MYSQL_DRUPAL_PWD@localhost:3306/$MYSQL_DRUPAL_DB -y > ~/drupal-admin-creds.txt

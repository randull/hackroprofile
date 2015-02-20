#!/bin/bash
#
# This script deletes virtual hosts and drupal directory.
#
# Prompt user to enter Domain Name
read -p "Site domain to publish: " domain
# Prompt user to enter Git Commit Note
read -p "Please give description of planned changes: " commit
# Create variables from Domain Name
#
hosts=/etc/apache2/sites-available
www=/var/www
tld=`echo $domain  |cut -d"." -f2,3`
name=`echo $domain |cut -f1 -d"."`
shortname=`echo $name |cut -c -16`
machine=`echo $shortname |tr '-' '_'`
# Put Dev & Prod sites into Maintenance Mode
drush @$machine vset maintenance_mode 1 -y && drush @$machine cc all -y
# Fix File and Directory Permissions on Dev
cd /var/www/$domain
sudo chown -R deploy:deploy html/* logs/*
sudo chown -R www-data:www-data public/* private/* tmp/*
sudo chmod -R ug=rw,o=r,a+X logs/* private/* public/* tmp/*
sudo chmod -R u=rw,go=r,a+X html/*
# Git steps on Development
cd /var/www/$domain/html
git add . -A
git commit -a -m "$commit"
git push origin master
# Git steps on Production
sudo -u deploy ssh deploy@prod "cd /var/www/$domain/html && git pull origin master"
# Fix File and Directory Permissions on Prod
cd /var/www/$domain
sudo chown -R deploy:deploy html/* logs/*
sudo chown -R www-data:www-data public/* private/* tmp/*
sudo chmod -R ug=rw,o=r,a+X logs/* private/* public/* tmp/*
sudo chmod -R u=rw,go=r,a+X html/*
# Prepare site for Live Environment
drush @$machine updb -y && drush @$machine cron -y
# Take Dev & Prod sites out of Maintenance Mode
drush @$machine vset maintenance_mode 0 -y && drush @$machine cc all -y

#!/bin/bash
#Copy config file for phpmyadmin and create user
mysql --user='root' --password='vagrant' < /tmp/script.sql
sudo mv /tmp/config.inc.php /etc/phpmyadmin/config.inc.php
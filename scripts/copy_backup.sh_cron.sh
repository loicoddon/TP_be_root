#!/bin/bash
#Copy backup.sh, chmod & chown, mkdir backup, cron
sudo mv /tmp/backup.sh /var/www/html/backup.sh
sudo chmod 776 /var/www/html/backup.sh
sudo chown adminberoot /var/www/html/backup.sh
sudo mkdir /mnt/backup
echo " * * * * * adminberoot sudo /var/www/html/backup.sh" >> /etc/crontab
#Toutes les minutes pour le TP...
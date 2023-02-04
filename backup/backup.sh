#!/bin/bash
################################

# What to backup
backup_files="/home /var/spool/mail /etc /root /boot /opt /etc/phpmyadmin"

# Where to backup to
dest="/mnt/backup"

# Create archive filename
day=$(date +%A)
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Backup the files using tar
tar czf $dest/$archive_file $backup_files
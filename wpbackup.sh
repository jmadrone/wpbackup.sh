#!/usr/bin/env bash
#
# Copyright (C) 2020 Josh Madrone
#
#
# This program is free software: you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#	wpbackup.sh Backup Script
#
# Bash script to backup Wordpress and all associated files and databases.
#
# Configure user options in the included `.config` file.
#
# To setup CRON
# add the next line to crontab of root user to run every day at 3:30am
# 30 3 * * * /path/to/wpbackup.sh >> /path/to/logs/wpbackup_cron.log 2>&1
# 
#
############################# options #########################################
#
# Please edit all USER OPTIONS in the `.config` file first
#
######################## script happens below #################################
#
# Load config values
#source ./.config

AWS_ACCESS_KEY_ID=AKIA4WNIEOOK6TUJVC5Q
AWS_SECRET_ACCESS_KEY=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
today="$(date +%F)"                       # Today's date YYYY-MM-DD
now="$(date -R)"       # Today's date in RFC Email format
USER="$(whoami)"                          # Set the $USER var to logged in user
work_dir="/var/www/html"                  # Path to Wordpress installation (e.g. /var/www/html)
backup_dir="$HOME/backups"                # Path to dir to save backup files
s3_bucket="s3://allcomone.com.s3"         # AWS S3 bucket and prefix
local_days_to_keep=3				      # 0 to keep forever
# deleted logs_dir="${backup_path}/logs"  # Path to save log files
log_file="www-backup-${today}.log"        # Log file name
db_user="root"                            # Database user name
db_name=""                                # Database name




# Check if root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# Change to working directory
cd "$work_dir" || exit

# Create the backup folder
if [ ! -d "$backup_dir" ]; then
  mkdir -p "$backup_dir"
fi

# check if tmp dir was created
#if [[ ! "$backup_dir" || ! -d "$backup_dir" ]]; then
#  echo "Could not create temp dir"
#  exit 1
#fi

# Create the logs folder
logs="${backup_dir}/logs"

if [ ! -d "$logs" ]; then
  mkdir -p "$logs"
fi

# Create the log file
touch "${logs}/${log_file}"


# Backup MySQL database
echo "Backing up MySQL database with mysqldump"
/usr/bin/mysqldump --defaults-extra-file="$HOME/.my.cnf" -u "$db_user" "$db_name" "${work_dir}/wordpress-db-${today}.sql"


# Backup MySQL config file
echo "Backing up MySQL config file"
/usr/bin/cp "$HOME/.my.cnf" "${work_dir}/my.cnf-${today}.txt"

# Backup AWS credentials
echo "Backing up AWS credentials files"
/usr/bin/cp -R "$HOME/.aws" "${work_dir}/aws-${today}"

# Backup Web Server configuration files
echo "Backing up web server config..."
# First some checks
# Are we using Apache
#if [[ $(ps -acx|grep apache|wc -l) > 0 ]]; then
#    echo "VM Configured with Apache"
#fi
# Are we using Nginx
#if [[ $(ps -acx|grep nginx|wc -l) > 0 ]]; then
#    echo "VM Configured with Nginx"
#fi
# Create tarball of entire wordpress directory, including all previous steps
/usr/bin/tar cvf "${work_dir}/nginx-backup-${today}.tar" /etc/nginx

# Compress entire wordpress directory
echo "Creating backup of Wordpress directory..."
/usr/bin/tar -pczf "${backup_dir}/www-backup-$today.tgz $work_dir"

echo Backup complete at "${backup_dir}/www-backup-${today}.tar.gz"

# Move to S3
echo "Moving backup file to S3 $s3_bucket"
/usr/bin/aws s3 cp "${backup_dir}/www-backup-$today.tgz ${s3_bucket}"

#echo "Removing local backup file at $backup_path/www-backup-$today.tgz" >> $log_file
#sudo rm $backup_path/www-backup-$today.tgz >> $log_file 2>&1

# Delete old backups
if [ "$local_days_to_keep" -gt 0 ] ; then
  echo "Deleting local backups older than ${local_days_to_keep} days"
  /usr/bin/find "${backup_dir}/*.tgz" -mtime +"${local_days_to_keep}" -exec rm {} \;
fi

echo "Finished backing up to S3 at $now"
echo "Backup saved to: ${s3_bucket}/www-backup-$today.tgz"


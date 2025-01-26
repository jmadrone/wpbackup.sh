#!/bin/sh

# Backup wordpress and all associated files and databases.
# Bitnami full backup instructions https://docs.bitnami.com/aws/apps/wordpress/#backup

# To setup CRON
# add the next line to crontab of root user to run every day at 3:30am
# 30 3 * * * /home/bitnami/wpbackup.sh > /home/bitnami/backup/logs/scheduledbackup-$(date -I).log 2>&1
# 

#----------------------------------------
# USER OPTIONS - Configure ALL user options in .config file
#----------------------------------------

# Get user options
source .config

# Change to working directory
cd $WORKING_DIR

# Create the backup folder
if [ ! -d $BACKUP_PATH ]; then
  mkdir -p $BACKUP_PATH
fi

# Create the logs folder
LOGS=$BACKUP_PATH/logs

if [ ! -d $LOGS ]; then
  mkdir -p $LOGS
fi

# Create the log file
touch $LOGS/$LOG_FILE


# Stop all services
echo "Stopping Services" >> $LOGS/$LOG_FILE
sudo /opt/bitnami/ctlscript.sh stop >> $LOGS/$LOG_FILE 2>&1

# Compress entire directory
echo "Compressing directory /opt/bitnami" >> $LOGS/$LOG_FILE
sudo tar -pczvf $BACKUP_PATH/www-backup-$NOW.tgz /opt/bitnami >> $LOGS/$LOG_FILE 2>&1

# Restart all services
echo "Starting Services" >> $LOGS/$LOG_FILE
sudo /opt/bitnami/ctlscript.sh start >> $LOGS/$LOG_FILE 2>&1

echo "Backup complete at $BACKUP_PATH/www-backup-$NOW.tgz" >> $LOGS/$LOG_FILE

# Move to S3
echo "Moving backup file to S3 bucket" >> $LOGS/$LOG_FILE
aws s3 cp $BACKUP_PATH/www-backup-$NOW.tgz $BUCKET/wpbackup >> $LOGS/$LOG_FILE 2>&1

#echo "Removing local backup file at $BACKUP_PATH/www-backup-$NOW.tgz" >> $LOG_FILE
#sudo rm $BACKUP_PATH/www-backup-$NOW.tgz >> $LOG_FILE 2>&1

# Delete old backups
if [ "$LOCAL_DAYS_TO_KEEP" -gt 0 ] ; then
  echo "Deleting local backups older than $LOCAL_DAYS_TO_KEEP days" >> $LOGS/$LOG_FILE
  find $BACKUP_PATH/*.tgz -mtime +$LOCAL_DAYS_TO_KEEP -exec rm {} \; >> $LOGS/$LOG_FILE 2>&1
fi

echo "Finished backing up to S3 at" >> $LOGS/$LOG_FILE
echo "$BUCKET/wpbackup/www-backup-$NOW.tgz" >> $LOGS/$LOG_FILE


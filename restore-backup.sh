#!/bin/sh
# Use this script to restore your website to the most recent version.
#

source .config

# Obtain application backup from S3
echo "Obtaining full application backup from the cloud..."
aws s3 


# Stop all services
echo "Stopping Services"
sudo /opt/bitnami/ctlscript.sh stop

# Moving the current stack to a different location
echo "Moving the current stack to a different location"
sudo mv /opt/bitnami /tmp/bitnami-backup

# Uncompress the backup file to the original directory
echo "Unpacking the backup file to the original directory"
sudo tar -pxzvf /home/bitnami/full-application-backup*.tgz -C /

# Starting Services
echo "Starting Services"
sudo /opt/bitnami/ctlscript.sh start
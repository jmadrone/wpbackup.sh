# wpbackup.sh Backup Script

Bash script to backup Wordpress and all associated files and database,
including web server (Apache or Ngninx), amd upload to AWS S3 storage,
though other backup destinations are possible with only minor changes.

Configure user options in the included `.config` file. See

## Pre-requisites

- `aws-cli`

## INSTRUCTIONS

1. SSH into your wordpress server and clone this repository into your user's home folder, then change directory into the newly cloned repo

        git clone https://github.com/jmadrone/wpbackup.sh.git && cd wpbackup.sh

2. Edit the `.config` file to modify USER OPTIONS

        nano .config
        AWS_ACCESS_KEY_ID=[Your AWS Access Key ID Here]
        AWS_SECRET_ACCESS_KEY=[Your AWS Secret Access Key Here]
        Change any other desired options
        Ctrl+x      #write & quit

3. Run the script of your choice as ROOT

        sudo ./wpbackup.sh

## To setup CRON

Add the next line to crontab of root user to run every day at 3:30am

        30 3 ** * /path/to/wpbackup.sh >> /path/to/logs/wpbackup_cron.log 2>&1

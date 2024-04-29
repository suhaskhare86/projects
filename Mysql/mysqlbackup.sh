#!/bin/bash

#
# This script reads mysql credentials from $HOME/.mylogin.cnf file
#

# No of recent backup files to keep
RETENTION=7

# Get today's date in YYYY-MM-DD format
TODAY=$(date +%Y-%m-%d)

# Create backup directory if it doesn't exist
BACKUP_DIR="/root/backups/mysql"
mkdir -p "$BACKUP_DIR"

# List all databases (excluding system databases)
DATABASES=$(/usr/bin/mysql -Bse "SHOW DATABASES" | grep -E 'information_schema|performance_schema|^sys' -v)

# Check if databases list could be obtained
if [ "${PIPESTATUS[0]}" -ne 0 ]
then
  echo "Could not get database list. Aborting."
  exit 1
fi

# Loop through each database and create backup
for database in $DATABASES; do

  # Skip if the backup already exists
  if [ -f "$BACKUP_DIR/$TODAY-$database.sql.gz" ]
  then
    echo "Backup for $database exists for $TODAY. Skipping."
    continue
  fi

  # Dump database and compress with gzip
  /usr/bin/mysqldump "$database" | gzip > "$BACKUP_DIR/$TODAY-$database.sql.gz"

  # Check for mysqldump errors
  if [ "`echo ${PIPESTATUS[@]}`" != "0 0" ]
  then
    echo "Error during backup of database $database"
    rm "$BACKUP_DIR/$TODAY-$database.sql.gz" 2>/dev/null
    exit 1
  fi
 
  # Keep recent $RETENTION days copies and delete older ones
  backup_copies=($(ls -t /root/backups/mysql/*-${database}.sql.gz))

  for i in `seq $RETENTION ${#backup_copies[@]}`
  do
    if [ "${backup_copies[$i]}" == "" ]
    then
      break
    fi
    
    rm ${backup_copies[$i]} &&
    echo "Deleted old backup - ${backup_copies[$i]}..."
  done


done

echo "Daily MySQL backup completed: $BACKUP_DIR/$TODAY.*.sql.gz"


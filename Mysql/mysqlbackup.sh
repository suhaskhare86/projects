#!/bin/bash

# This file was generated using the following command:
# sudo mysql_config_editor set --login-path=client --user=root --host=localhost --password
# Ensure strict permissions on .mylogin.cnf (e.g., 0600)
MYSQL_LOGIN_FILE="/root/.mylogin.cnf"

# Get today's date in YYYY-MM-DD format
TODAY=$(date +%Y-%m-%d)

# Create backup directory if it doesn't exist
BACKUP_DIR="/root/backups/mysql"
mkdir -p "$BACKUP_DIR"

# List all databases (excluding system databases)
DATABASES=$(/usr/bin/mysql -Bse "SHOW DATABASES" | grep -E 'information_schema|performance_schema|^sys' -v)

# Truncate error log
>/tmp/mysqldump_error.log

# Loop through each database and create backup
for database in $DATABASES; do

  # Skip if the backup already exists
  if [ -f "$BACKUP_DIR/$TODAY-$database.sql.gz" ]
  then
    echo "Backup for $database exists for $TODAY. Skipping."
    continue
  fi

  # Dump database and compress with gzip
  /usr/bin/mysqldump --defaults-extra-file="$MYSQL_LOGIN_FILE" "$database" 2>>/tmp/mysqldump_error.log | gzip > "$BACKUP_DIR/$TODAY-$database.sql.gz"

  # Check for mysqldump errors
  if [ "`echo ${PIPESTATUS[@]}`" != "0 0" ]
  then
    echo "Error during backup of database $database. See /tmp/mysqldump_error.log for details."
    rm "$BACKUP_DIR/$TODAY-$database.sql.gz" 2>/dev/null
    exit 1
  fi
done


# Delete backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete

echo "Daily MySQL backup completed: $BACKUP_DIR/$TODAY.*.sql.gz"


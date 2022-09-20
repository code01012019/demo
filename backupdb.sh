#!/bin/sh

echo "### backupdb"
date
echo "Begin Backup..."
mysqldump -udbuser -pDbuser1234 --opt atbdb > /backup/atbdb_$(date +"%Y%m%d").sql
echo "End Backup"
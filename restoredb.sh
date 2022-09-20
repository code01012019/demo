#!/bin/sh

echo "### restoredb"
date
echo "Begin Restore..."
mysql -udbuser -pDbuser1234 restoredb < /backup/atbdb_$(date +"%Y%m%d").sql
echo "End Restore"
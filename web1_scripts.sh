[root@web1 scripts]# cat *.sh
#!/bin/sh

echo "###"
date
echo "Begin Backup..."
mysqldump -udbuser -pDbuser1234 --opt atbdb > /tmp/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End Backup"
#!/bin/sh

echo "###"
date
echo "Begin remote copy..."
scp -p /tmp/backup/atbdb_$(date +"%Y%m%d").sql root@devops1:/tmp/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End remote copy"
#!/bin/sh

echo "###"
date
echo "Begin Remove..."
mysql -udbuser -pDbuser1234 restoredb < /tmp/backup/removedb.sql
sleep 5
echo "End Remove"
#!/bin/sh

echo "###"
date
echo "Begin Restore..."
mysql -udbuser -pDbuser1234 restoredb < /tmp/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End Restore"
#!/bin/sh

echo "###"
date
echo "Begin..."
sleep 3
echo "End"
[root@web1 scripts]# 

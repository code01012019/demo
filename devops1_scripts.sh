[root@devops1 scripts]# cat *.sh
#!/bin/sh

echo "###"
date
echo "Begin Backup..."
mysqldump -uatbuser -patbpass --opt atbdb > /home/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End Backup"
#!/bin/sh

echo "###"
date
echo "Begin remote copy..."
scp -p /home/backup/atbdb_$(date +"%Y%m%d").sql root@web1:/home/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End remote copy"
#!/bin/sh

echo "###"
date
echo "Begin Remove..."
mysql -uatbuser -patbpass restoredb < /home/backup/removedb.sql
sleep 5
echo "End Remove"
#!/bin/sh

echo "###"
date
echo "Begin Restore..."
mysql -uatbuser -patbpass restoredb < /home/backup/atbdb_$(date +"%Y%m%d").sql
sleep 5
echo "End Restore"
#!/bin/sh

echo "###"
date
echo "Begin..."
sleep 3
echo "End"
[root@devops1 scripts]# 

### There are two files:
## aomei_backup_log.ps1
This scripts reads the file C:\ProgramData\AomeiBR\brlog.xml and checks the age of the last successfull backup.
Different ages for each job can be definied in $job_limit_age 



## backup_aomei_check.ps1
This script creates files with the current time stamp in the backup source. The AOMEI Sync Backup copies the files to the backup destination. From there, the files are copied back to a directory that is set up as a file check in Check_MK.

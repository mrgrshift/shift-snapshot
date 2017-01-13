#shift-snapshot
A bash script to automate backups for SHIFT blockchain<br>
v0.3
For more information about SHIFT please visit - http://www.shiftnrg.org/

##Requisites
    - You need to have Shift installed : https://github.com/shiftcurrency/shift
    - You need to have sudo privileges
    - You need to have jq installed: `sudo apt-get install jq`

##Installation
Execute the following commands
```
cd ~/
git clone https://github.com/mrgrshift/shift-snapshot
cd shift-snapshot/
bash shift-snapshot.sh help
```
##Available commands

    - create
    - restore
    - log
    - schedule
		- hourly
		- daily
		- weekly
		- monthly

###create
Command _create_ is for create new snapshot, example of usage:<br>
`bash shift-snapshot.sh create`<br>
Automaticly will create a snapshot file in new folder called snapshot/.<br>
Don't require to stop you node app.js instance.<br>
Example of output:<br>
```
   + Creating snapshot                                
  -------------------------------------------------- 
  01-01-2017 - 05:30:58 -- √ New snapshot created successfully at block 160735 ( 110 MB).
```
Also will create a line in the log, there you can see your snapshot at what block height was created.<br>

###restore
Command _restore_ is for restore the last snapshot found it in snapshot/ folder.<br>
**IMPORTANT** If you are going to use this command you must stop first Shift `node app.js`<br>
Example of usage:<br>
`bash shift-snapshot.sh restore`<br>
<br>
Automaticly will take the last snapshot available in snapshot/ folder to restore the shift_db.<br>
<br>
###log
Display all the log; errors and snapshots created. <br>
Example of usage:<br>
`bash shift-snapshot.sh log`<br>
<br>
Example of output:<br>
```
   + Snapshot Log                                                                  
  --------------------------------------------------                               
  01-01-2017 - 05:30:58 -- √ New snapshot created successfully at block 160735 ( 110 MB).
  02-01-2017 - 05:30:25 -- √ New snapshot created successfully at block 161035 ( 111 MB).
  --------------------------------------------------END                            
```

###schedule
Schedule snapshot creation periodically, with the available parameters:

    - hourly
    - daily
    - weekly
    - monthly

Example: `bash shift-snapshot.sh schedule daily`
<br>

-------------------------------------------------------------

###Notice
You will have a folder in ~/shift-snapshot/ called `snapshot/` where all your snapshots will be created, every new snapshot will replace the previous one.
If you want to use a snapshot from different place (official snapshot for example or other node) you will need to download the snapshot file (with prefix: shift_db*) and copy it to the `~/shift-snapshot/snapshot/` folder.
After you copy the shift_db*.tar file you can restore the blockchain with: `bash shift-snapshot.sh restore` and will use the last file found in the snapshot/ folder.<br>
If you use the `schedule` command be aware you will have a log file located in `~/shift-snapshot/cron.log` with this you will know what is happened with your schedule.

###Upgrade
If you are in a version prior to v0.3 you can upgrade with the following commands:
```
cd ~/shift-snapshot/ 
git checkout .
git pull
```

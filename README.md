#shift-snapshot
A bash script to automate backups for SHIFT blockchain<br>
v0.0.1
For more information about SHIFT please visit - http://www.shiftnrg.org/

##Requisites
    - This script works with postgres and shift_db, configured with shift user
    - You need to have sudo privileges

##Installation
Execute the following commands
```
cd ~/
git clone https://github.com/mrgrshift/shift-snapshot
mv shift-snapshot/shift-snapshot.sh shift/shift-snapshot.sh
cd shift/
```
##Available commands

    - create
    - restore
    - log

###create
Command _create_ is for create new snapshot, example of usage:<br>
`bash shift-snapshot.sh create`<br>
Automaticly will create a snapshot file in new folder called snapshot/.<br>
Don't require to stop you node app.js instance.<br>
Example of output:<br>
```
   + Creating snapshot                                
  -------------------------------------------------- 
  OK snapshot created successfully at block  49037 ( 43 MB).
```
Also will create a line in the log, there you can see your snapshot at what block height was created.<br>

###restore
Command _restore_ is for restore the last snapshot found it in snapshot/ folder.<br>
Example of usage:<br>
`bash shift-snapshot.sh restore`<br>
<br>
Automaticly will pick the last snapshot file in snapshot/ folder to restore the shift_db.<br>
If you want to restore a specific file please (for this version) delete or move the other files in snapshot/ folder.<br>
You can use the _log_ command to better pick up your restore file.<br>
<br>
###log
Display all the snapshots created. <br>
Example of usage:<br>
`bash shift-snapshot.sh log`<br>
<br>
Example of output:<br>
```
   + Snapshot Log                                                                  
  --------------------------------------------------                               
  20-10-2016 - 20:59:06 -- Snapshot created successfully at block  48967 ( 43 MB)  
  20-10-2016 - 21:36:07 -- Snapshot created successfully at block  49037 ( 43 MB)  
  --------------------------------------------------END                            
```
<br>
##Troubleshooting
There's some expecting error due to format, if you have this error:
```
shift-snapshot.sh: line 13: $'\r': command not found
shift-snapshot.sh: line 38: syntax error near unexpected token `$'{\r''
'hift-snapshot.sh: line 38: `create_snapshot() {
```
Please execute the following command:
`sed -i 's/\r$//' shift-snapshot.sh`

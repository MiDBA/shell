#!/bin/ksh
#set -x

# Take system snapshot


#export RUNDATE=$(date "+%Y%m%d%H%M")
HOSTNAME=`hostname`
NODE=${HOSTNAME: -1}
export CALLING_PROC=$(basename ${0})
export SCRIPTDIR=$(dirname ${0})
export LOGDIR=$SCRIPTDIR/logs
export LOG=$LOGDIR/$HOSTNAME_snapshot.$RUNDATE
cd $SCRIPTDIR

OLD_ORA_PATH=$ORACLE_PATH
unset ORACLE_PATH


#Check CRS
ORACLE_SID=+ASM$NODE
ORAENV_ASK=NO
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/bin/:/usr/sbin/
. oraenv >/dev/null
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/bin/:/usr/sbin/
echo CRS Check,
crsctl check crs

#Change to DB Environment
ORACLE_SID=dummy12
ORAENV_ASK=NO
. oraenv >/dev/null
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/bin/:/usr/sbin/

#List Running Instances
#ps -efZ | grep [p]mon | awk '{print $2,$3,$6,$7,$10}'
ps -efZ | grep [p]mon | grep -v "grep" | grep -v "root" | awk '{print $2,$3,$6,$7,$10}'

#Check pdbs
./get_ver -ver

#Check Mounts
#df -h | grep -v "volatile" | grep -v "tmp" | awk '{print $6",",$4}'
df -h | grep -v "volatile" | grep -v "tmp" | awk '{print $1",",$6}'

echo Mounts Check,
touch /u01/app/oracle /u02 /u03 /u04 /arimages

#Check crontab
echo Crontab Check,
crontab -l | head -1

#Check Listener
echo Listener Check,
#lsnrctl status | grep -i uptime
lsnrctl status | head -10 | tail -5
#Check Services
lsnrctl status | grep "Service"

#check ips
ipadm

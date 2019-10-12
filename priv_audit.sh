oracle@hcv171cssotdc01:/u02/orascripts/db_audit/priv$ cat parse_audit.sh
#!/bin/ksh
#set -x
# $1 = Top level path to search for audit files
# $2 = Time in minutes to search back for audit files
# Example: parse_audit.sh /u01/app/oracle/admin/cdb1dv/adump 60

HOST=$( hostname )
MAIN_TS=$(date "+%Y%m%d%H%M")
SCRIPT_DIR=/u02/users/lowej5/sqlldr/audit
LOG=$SCRIPT_DIR/$HOST"_parse_run.log"
HOST_SYSDBA_REPORT=$SCRIPT_DIR/$HOST"_host_sysdba.csv"
USER_SYSDBA_REPORT=$SCRIPT_DIR/$HOST"_user_sysdba.csv"
SYSRAC_REPORT=$SCRIPT_DIR/$HOST"_sysrac.csv"
NONE_REPORT=$SCRIPT_DIR/$HOST"_nonereport.csv"
OTHER_REPORT=$SCRIPT_DIR/$HOST"_otherreport.csv"
TEMPFILE=$SCRIPT_DIR/$HOST"_tempfile"
AUD_FILES=$SCRIPT_DIR/$HOST"_audit_files"

#CALLING_PROC=$(basename ${0})
#FND_SCRIPTDIR=$(dirname ${0})
#$echo $CALLING_PROC
#$echo $FND_SCRIPTDIR

cd $SCRIPT_DIR

## Initialize Files

rm $AUD_FILES
rm $HOST_SYSDBA_REPORT
rm $USER_SYSDBA_REPORT
rm $SYSRAC_REPORT
rm $NONE_REPORT
rm $OTHER_REPORT
rm $LOG

echo $MAIN_TS >> $LOG
echo Input: $1  $2 >> $LOG

#echo find $1 -name "*.aud" -mmin -$2
find $1 -name "*.aud" -mmin -$2 -exec grep -l "pts/" {} \; > $AUD_FILES
find $1 -name "*.aud" -mmin -$2 -exec grep -l "'unknown'" {} \; >> $AUD_FILES

echo Number of *.aud files in $1 >> $LOG
find $1 -name "*.aud" -mmin -$2 | wc -l >> $LOG
echo "" >> $LOG
echo " Log Files Processesed " >> $LOG

echo "TIMESTAMP,INSTANCENAME,ACTION,DATABASEUSER,PRIVILEGE,CLIENTUSER,CLIENTTERMINAL,USERHOST,SESSIONID" >> $HOST_SYSDBA_REPORT
echo "TIMESTAMP,INSTANCENAME,ACTION,DATABASEUSER,PRIVILEGE,CLIENTUSER,CLIENTTERMINAL,USERHOST,SESSIONID,AUDIT_FILE" >> $USER_SYSDBA_REPORT
echo "TIMESTAMP,INSTANCENAME,ACTION,DATABASEUSER,PRIVILEGE,CLIENTUSER,CLIENTTERMINAL,USERHOST,SESSIONID" >> $SYSRAC_REPORT
echo "TIMESTAMP,INSTANCENAME,ACTION,DATABASEUSER,PRIVILEGE,CLIENTUSER,CLIENTTERMINAL,USERHOST,SESSIONID" >> $NONE_REPORT
echo "TIMESTAMP,INSTANCENAME,ACTION,DATABASEUSER,PRIVILEGE,CLIENTUSER,CLIENTTERMINAL,USERHOST,SESSIONID" >> $OTHER_REPORT

#Loop through audit files and write them to the appropriate report file

cat $AUD_FILES | while read aud_file;
do

#echo $aud_file >> $LOG
ls -lthr $aud_file >> $LOG

#AUDIT_NAME=$( cat $1 | grep "<display_name>" | cut -d'>' -f2 | cut -d'<' -f1 )
#echo $AUDIT_NAME

INSTANCENAME=$(cat $aud_file | grep "Instance name" | cut -d':' -f2 )
#echo $INSTANCENAME

#Remove special characters and blank lines from input file
##############cat $1 |  tr -d \"\,\<\> | sed 's/*/"*"/g' > $TEMPFILE
cat $aud_file |  tr -d \"\,\<\> | sed 's/*/"*"/g' > $TEMPFILE


#Initialize Variables for record data

TIMESTAMP=""
LENGTH=""
ACTION=""
DATABASEUSER=""
PRIVILEGE=""
CLIENTUSER=""
CLIENTTERMINAL=""
STATUS=""
DBID=""
SESSIONID=""
USERHOST=""
CLIENTADDRESS=""
ACTIONNUMBER=""

while IFS= read -r line
do

#fword=`echo $line | head -n1 | awk '{print $1;}'`
fword=`echo $line | head -n1 | cut -d':' -f1 | sed 's/ //g'`
fchar=`echo $line | cut -c1-1`
fday=`echo $line | cut -c1-3`

#echo FWORD: $fword
#echo FCHAR: $fchar
#echo LINE: $line
#echo DAY: $fday

# Ignore lines starting with #
if [[ $fchar != "#" ]]; then

# If not end of record, load variables

if [[ $fchar != "/" ]]; then
#echo "-----record data-----"

        if [[ $fday = "Mon" || $fday = "Tue" || $fday = "Wed" || $fday = "Thu" || $fday = "Fri" || $fday = "Sat" || $fday = "Sun" ]]; then
                #echo $fday
                TIMESTAMP=`echo $line`
                #echo $TIMESTAMP
        fi

        #sort data into column variables

        if [[ $fword = "LENGTH" ]]; then
                #echo "--- LENGTH ---"
                LENGTH=`echo $line | cut -d':' -f2`
                #echo $LENGTH
        elif [[ $fword = "ACTION" ]]; then
                #echo $fword
                ACTION=`echo $line | sed 's/"//g' | cut -d':' -f2`
                #echo "$ACTION"
        elif [[ $fword = "DATABASEUSER" ]]; then
                #echo $fword
                DATABASEUSER=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $DATABASEUSER
        elif [[ $fword = "PRIVILEGE" ]]; then
                #echo $fword
                PRIVILEGE=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $PRIVILEGE
        elif [[ $fword = "CLIENTUSER" ]]; then
                #echo $fword
                CLIENTUSER=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $CLIENTUSER
        elif [[ $fword = "CLIENTTERMINAL" ]]; then
                #echo $fword
                CLIENTTERMINAL=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $CLIENTTERMINAL
        elif [[ $fword = "USERHOST" ]]; then
                #echo $fword
                USERHOST=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $USERHOST
       elif [[ $fword = "SESSIONID" ]]; then
                #echo $fword
                SESSIONID=`echo $line | sed 's/"//g' | cut -d':' -f2,3,4`
                #echo $SESSIONID

        fi

else
        echo "no comprendo"
fi
        if [[ $ACTION != "" ]]; then
        if [[ $fchar = "" ]]; then
                #echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID
          if [[ $PRIVILEGE = *"SYSDBA"* ]]; then

                if [[ $CLIENTTERMINAL = *"[0]"* ]]; then
                echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID >> $HOST_SYSDBA_REPORT
                else
                echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID,$aud_file >> $USER_SYSDBA_REPORT
                fi

          elif [[ $PRIVILEGE = *"SYSRAC"* ]]; then
                echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID >> $SYSRAC_REPORT
          elif [[ $PRIVILEGE = *"NONE"* ]]; then
                echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID >> $NONE_REPORT
          else
                echo $TIMESTAMP,$INSTANCENAME,"$ACTION",$DATABASEUSER,$PRIVILEGE,$CLIENTUSER,$CLIENTTERMINAL,$USERHOST,$SESSIONID >> $OTHER_REPORT
          fi
        fi
        fi
fi


done < $TEMPFILE

rm $TEMPFILE
#mv $TEMPFILE $TEMPFILE.$MAIN_TS

END_TS=$(date "+%Y%m%d%H%M")
echo $END_TS >> $LOG

done;

mailx -s "$HOST Privileged User Audit" lowej5@michigan.gov << EOM
`cat $LOG`

`uuencode $USER_SYSDBA_REPORT $HOST"_Priv_User_Actions.csv`

EOM

#mailx -s "$HOST Privileged User Audit" boruszewskir@michigan.gov << EOM
#`cat $LOG`

#`uuencode $USER_SYSDBA_REPORT $HOST"_Priv_User_Actions.csv`

#EOM


oracle@hcv171cssotdc01:/u02/orascripts/db_audit/priv$

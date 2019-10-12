#!/bin/ksh
# ----------------------------------------------------------------------------------------------
# Module Name: purge_master.sh
# Date Written:  Unknown
# Documentation: Purge_Flow_Chart.vsdx (SharePoint)
# Syntax:
# Author: Unknown
# System: Oracle utility
# Purpose: Purge files/logs using ADR and the purge_master.par for all others
# Program calls:
# External:
# Internal:
# Functions: send_email
# Called By:
# Input Files:
# Responsibility: DHHS DBA Support Team
#
# Revision History...
# Date Name Description
# ---------- --------------- --------------------------------------------------------------------
# 07/27/2018    T. Wright         Update script to current environments, remove voids/duplications.
# Revision document:
#   1. DL set but never referenced, dl_list used instead - comment out.
#   2. Added IF for user, grid vs oracle to set env
#   3. grep -v '^$' doesn't pertain currently, comment out.
#   4. par2.temp file not required due to #3., comment out.
#   5. duplicate variable assignment of timestamp, comment out.
#   6. duplicate variable assignment of host, comment out.
#   7. Parsed hostname to last 5 char
#   8. Remove H/M from timestamp, replaced rundate with timestamp
#   9. Move the find files filename to identify the task in filename (see "if" statements)
#  10. Moved 'send email' into a function, call as applicable.
#  11. Purpose of commented "#echo 7" and "#echo 77" unknown
# -----------------------------------------------------------------------------------------------
# Valid arguments:
#
# -----------------------------------------------------------------------------------------------

#Purge all admin files at intervals
set -x

date
export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$PATH:/usr/bin:$ORACLE_HOME/bin
export SCRPT_DIR=/u02/orascripts/purge
export log_dir=/u02/orascripts/purge/logs

#1.DL="lowej5@michigan.gov" -> Not referenced again
timestamp=`date +%Y%m%d`                                                                #8. remove h/m
host=`hostname`
host="${host: -5}"                                                                      #7. Parse hostname
purge_files=$timestamp.$host.purge_files.txt

cd $log_dir

short_purge=+30
mid_purge=+90
long_purge=+180

#2. set env
USER=`whoami`
if [ $USER == "grid" ]; then
        ORACLE_SID=+ASM1
elif [ $USER == "oracle" ]; then
        ORACLE_SID=dummy12
fi
ORAENV_ASK=NO
. oraenv

echo $host $USER                                                                        #2. added $USER
#Load ADR homes into a text file
adrci exec="show homes" | grep -v "ADR Homes" > $host"_purge_homes.txt"

#10. Create Email function
# Every process runs the FIND first, so move find filename based on the task & user (adrci, purge),
# then send email.
send_email()
{
    #8. export rundate=$(date "+%y%m%d") -> use $timestamp
    #6. host=$(hostname) -> duplicated
    echo Sending Email
    echo $host is host

    export report_name=purge_master.sh
    export email_file=$log_dir/$purge_files
    export dl_list=`grep "${report_name}" /u02/orascripts/subscribe`
    echo "************    list     ***************"
    echo ${dl_list}

    for e in ${dl_list}
    do
        if [ $e != $report_name ]; then
            echo $e
            /usr/bin/mailx -s $purge_files $e < $email_file  #10. Change subject to filename
        fi
    done
}

if [[ $1 = "find" ]]; then
    # Show all Files to be deleted
    echo MODE = FIND
    date >> $purge_files
    echo "########## ALERT CDUMP TRACE LOG_ARCHIVE files to delete ##########" >> $purge_files
    echo "########## ALERT CDUMP TRACE LOG_ARCHIVE files to delete ##########"
    for HOME in $(< $host"_purge_homes.txt" ); do
      #echo "********* directory : " $ORACLE_BASE/$HOME >> $purge_files
      find $ORACLE_BASE/$HOME/alert -name "*.xml" -mtime $short_purge -ls | sort -nk6 >> $purge_files
      find $ORACLE_BASE/$HOME/cdump -name "*.*" -mtime $short_purge -ls >> $purge_files
      find $ORACLE_BASE/$HOME/trace -name "*.trc" -mtime $short_purge -ls >> $purge_files
      find $ORACLE_BASE/$HOME/trace -name "*.trm" -mtime $short_purge -ls >> $purge_files
      find $ORACLE_BASE/$HOME/trace/log_archive -name "*.log" -mtime $short_purge -ls >> $purge_files
    done

    echo "########## ADUMP files to delete ##########" >> $purge_files
    echo "########## ADUMP files to delete ##########"

    find $ORACLE_BASE -type d -name adump > $host"_purge_adump.txt"

    for ADUMP in $(< $host"_purge_adump.txt" ); do
      #echo $ADUMP
      #echo "find $ADUMP -name "*.aud" -mtime $short_purge"
      find $ADUMP -name "*.aud" -mtime $short_purge -ls >> $purge_files
      find $ADUMP -name "*.xml" -mtime $short_purge -ls >> $purge_files
    done

    echo "########## FIND files to delete using purge_master.par file  ##########" >> $purge_files
    echo "########## FIND files to delete using purge_master.par file ##########"

    grep -v "#" $SCRPT_DIR/purge_master.par > $SCRPT_DIR/par.temp
    #3. grep -v '^$' $SCRPT_DIR/par.temp > $SCRPT_DIR/par2.temp -> not applicable

    file="$SCRPT_DIR/par.temp"

    while read line
    do
      cmd="find "
      cmd="$cmd $line"
      cmd="$cmd -ls | sort -nk6 >> $purge_files"
      #echo $cmd
      eval ${cmd}
    done < $file

    rm $SCRPT_DIR/par.temp
    #4. rm $SCRPT_DIR/par2.temp
    #11. echo 7

    #5. timestamp=`date +%y%m%d%H%M`
    date >> $purge_files

elif [[ $1 = "adrci" ]]; then
  mv $purge_files $timestamp.$host.$USER.purge_dd.txt                                   #9. new 7/28/18
  purge_files=$timestamp.$host.$USER.purge_dd.txt                                       #9. new 7/28/18
  echo "running adrci"

  for HOME in $(< $host"_purge_homes.txt" ); do
    adrci exec="set home $HOME;set control \(SHORTP_POLICY=720\);set control \(LONGP_POLICY=720\)"
    adrci exec="set home $HOME;show control"
    echo ***** purging $HOME *****
    adrci exec="set home $HOME;purge"
  done

  send_email

elif [[ $1 = "purge" ]]; then
  mv $purge_files $timestamp.$host.$USER.purge_ndd.txt                                  #9. new 7/28/18
  purge_files=$timestamp.$host.$USER.purge_ndd.txt                                      #9. new 7/28/18
  echo "########## ALERT CDUMP TRACE LOG_ARCHIVE deleting ##########"

  for HOME in $(< $host"_purge_homes.txt" ); do
    echo "directory : " $ORACLE_BASE/$HOME
    find $ORACLE_BASE/$HOME/alert -name "*.xml" -mtime $short_purge -exec rm -rf {} \;
    find $ORACLE_BASE/$HOME/cdump -name "*.*" -mtime $short_purge -exec rm -rf {} \;
    find $ORACLE_BASE/$HOME/trace -name "*.trc" -mtime $short_purge -exec rm -rf {} \;
    find $ORACLE_BASE/$HOME/trace -name "*.trm" -mtime $short_purge -exec rm -rf {} \;
    find $ORACLE_BASE/$HOME/trace/log_archive -name "*.log" -mtime $short_purge -exec rm -rf {} \;
  done

  echo "########## ADUMP deleting ##########"

  find $ORACLE_BASE -type d -name adump > $host"_purge_adump.txt"

  for ADUMP in $(< $host"_purge_adump.txt" ); do
    echo $ADUMP
    #echo "find $ADUMP -name "*.aud" -mtime $short_purge"
    find $ADUMP -name "*.aud" -mtime $short_purge -exec rm -rf {} \;
    find $ADUMP -name "*.xml" -mtime $short_purge -exec rm -rf {} \;
  done

  echo "########## PURGE using purge_master.par file ##########"

  grep -v "#" $SCRPT_DIR/purge_master.par > $SCRPT_DIR/par.temp
  #3. grep -v '^$' $SCRPT_DIR/par.temp > $SCRPT_DIR/par2.temp

  file="$SCRPT_DIR/par.temp"
  #11. echo 77

  while read line
  do
    cmd="find "
    cmd="$cmd $line"
    cmd="$cmd -exec rm -rf {} \;"
    echo $cmd
    eval ${cmd}

  done < $file
  echo deleting temp files
  rm $SCRPT_DIR/par.temp
  #4. rm $SCRPT_DIR/par2.temp

  send_email

else
  echo
  echo use purge_master.sh with switch
  echo find to report on files :purge_master.sh find
  echo adrci to purge at 30 days :purge_master.sh adrci
  echo purge to delete all files identified by find :purge_master purge
  echo

fi

cd $SCRPT_DIR
date

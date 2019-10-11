#!/bin/ksh
# run Post patch scripts


HOSTNAME=`hostname`
NODE=${HOSTNAME: -1}
ORACLE_SID=dummy12
ORAENV_ASK=NO
. oraenv

echo NODE: $NODE

INSTANCES=`srvctl config database | while read a; do echo $a$NODE; done;`

echo $INSTANCES

for INST in $INSTANCES; do

echo Connecting to $INST
export ORACLE_SID=$INST
. oraenv

echo ORACLE_HOME: $ORACLE_HOME

if [[ $ORACLE_HOME = "/u01/app/oracle/product/11.2.0.4/dbhome_1" ]]; then
        echo "------------------------------------11g home -----------------------------------------"

        sqlplus -s / as sysdba << EOF

        spool psu_apply.log

        @/u01/app/oracle/product/11.2.0.4/dbhome_1/rdbms/admin/catbundle.sql psu apply

EOF

        echo done $INST


elif [[ $ORACLE_HOME = "/u01/app/oracle/product/12.2.0.1/dbhome_1" ]]; then
        echo "------------------------------------12c home -----------------------------------------"

        #echo /u01/app/oracle/product/12.2.0.1/dbhome_1/OPatch/datapatch -verbose
        #/u01/app/oracle/product/12.2.0.1/dbhome_1/OPatch/datapatch -verbose

        echo done $INST

else
        echo unknown ORACLE HOME

fi

done

#!/bin/bash

FROM=<email>@<domain>
TO=<email>@<domain>
CC=<email>@<domain>
SUBJECT="Ephemeral Storage Report: "
MSG="Your data has been identified as a storage capacity violation. The file is writing to a location not under the mount point of any permanent or temporary storage, and is therefore writing to the container filesystem (overlay), adding to the I/O burden of the underlying node.  Kindly refrain from using ephemeral container storage."
REPORT=/tmp/eph-report.out
#Service Account: ose-ephemeral-usage-report in <project> project - requires cluster-admin role
TOKEN="<token>"
SERVER=”<server>”

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
email_report () {
  EMAIL=$(oc get project $PROJECT -o jsonpath="{.metadata.labels['project\.ocp\.domain/email']}")
  #echo "EMAIL: $EMAIL" #Uncomment for debug
  DOMAIN=$(oc get project $PROJECT -o jsonpath="{.metadata.labels['project\.ocp\.domain/email-domain']}")
  #echo "DOMAIN: $DOMAIN" #Uncomment for debug
  if [ -n "$EMAIL" ]
  then
    	(printf "$MSG\n"; cat $REPORT) | mailx -s "$SUBJECT $PROJECT" -c $CC -r $FROM $EMAIL@$DOMAIN
  else (printf "**MISSING CONTAINER EMAIL LABEL**\n$MSG\n"; cat $REPORT) | mailx -s "$SUBJECT $PROJECT **MISSING EMAIL LABEL**" -r $FROM $TO
  fi
}
 
oc login --token=$TOKEN --server=$SERVER
for PROJECT in $(oc get projects -o custom-columns=name:metadata.name --no-headers|grep -v openshift)
do
    	>$REPORT
    	#echo "==== PROJECT: $PROJECT ====" #Uncomment for debug
    	printf "$(date "+%F %H:%M:%S") "; oc project $PROJECT
   	 for RUNNINGPOD in $(oc get pod --field-selector=status.phase=Running -o custom-columns=name:metadata.name --no-headers)
    	do
            	#echo  "+++ POD: $RUNNINGPOD" #Uncomment for debug
            	for CONTAINER in $(oc get pod $RUNNINGPOD -o jsonpath='{.spec.containers[*].name}')
            	do
                    	#echo  "** CONTAINER: $CONTAINER" #Uncomment for debug
                    	FILE=$(oc exec $RUNNINGPOD -c $CONTAINER -- /bin/bash -c 'for SEARCHDIR in `/bin/ls -lh /proc/1/fd |awk '\''match($11, "/") {print $11}'\''`; do du -ah $SEARCHDIR 2>/dev/null|awk '\''match($1, "[0-9]G") && system("df "$2"|grep -i overlay >/dev/null")==0 {print $1" "$2}'\''; done; exit 0')
                    	#echo "~ FILE: $FILE" #Uncomment for debug
                    	if [ -n "$FILE" ]
                    	then
                                VOLMOUNT=$(oc get pod $RUNNINGPOD -o jsonpath='{.spec.containers[*].volumeMounts[*].mountPath}')
                                printf "\n==== PROJECT: $PROJECT ====\nPOD: $RUNNINGPOD\nCONTAINER: $CONTAINER\nVOLMOUNT: $VOLMOUNT\n$FILE\n" >> $REPORT
                    	fi
            	done
    	done
if [ -s "$REPORT" ]
then
  cat $REPORT
  email_report
fi
done

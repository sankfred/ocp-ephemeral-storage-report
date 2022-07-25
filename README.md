# Ephemeral Storage Report

<i>Problem:</i> The team frequently encounters teams dumping application logs and other large files on ephemeral storage in the container filesystem. 

<i>Solution:</i> A bash script to scan each project in the Openshift Cluster to identify large files (+1GB) residing on container storage (ephemeral-no PVC).  Designed to run daily via cron on the dev jumphost, the application team is sent an email with a summary of the storage violation.

# Cron:
$ cat /etc/cron.d/ose-ephemeral-report<br>
#Generate a daily (Mon-Fri) scan of Openshift ephemeral storage<br>
0 3 * * 1-5 root /usr/local/bin/eph-storage-report.bash > /tmp/eph-storage-report.out<br>
 
# Sample Email Report:

-----Original Message-----<br>
From: Platform Solutions<br>
Sent: Monday, July 11, 2022 12:39 PM<br>
To: App Dev Team<br>
Cc: Platform Solutions <br>
Subject: Ephemeral Storage Report: foo-bar<br><br>

Your data has been identified as a storage capacity violation. The file is writing to a location not under the mount point of any permanent or temporary storage, and is therefore writing to the container filesystem (overlay), adding to the I/O burden of the underlying node.  Kindly refrain from using ephemeral container storage.<br><br>

==== PROJECT: foo-bar ====<br>
POD: pipeline-data-monitor-domain-12-cmvd4<br>
CONTAINER: pipeline-data-monitor-domain<br>
VOLMOUNT: /data/ /var/run/secrets/kubernetes.io/serviceaccount<br>
1.1G /output/app/log/log-current.log<br>


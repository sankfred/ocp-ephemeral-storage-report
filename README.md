# Ephemeral Storage Report

<i>Problem:</i> The Openshift Platform team frequently encounters teams dumping application logs and other large files on ephemeral storage in the container filesystem. 

<i>Solution:</i> A bash script to scan each project in the Openshift Cluster to identify large files (+1GB) residing on container storage (ephemeral-no PVC).  Designed to run daily via cron from an automation host, the application team is sent an email with a summary of the storage violation.

## Dependencies
- Identify a report recipient<br> 
Each project contains a metadata label with the team’s email address. I extracted the email address to compose the report. Should the project not contain an email address label, the Platform team will be notified. <br>
- Report delivery<br>
Requires the ability to send email via postfix or other mail transfer agent. Otherwise, you could configure a different delivery method, i.e. slack or trigger an alert from monitoring software.<br>

## Cron
$ cat /etc/cron.d/ose-ephemeral-report<br>
#Generate a daily (Mon-Fri) scan of Openshift ephemeral storage<br>
0 3 * * 1-5 root /usr/local/bin/eph-storage-report.sh > /tmp/eph-storage-report.out<br>
 
## Sample Email Report

-----Original Message-----<br>
From: Platform Solutions<br>
Sent: Monday, July 11, 2022 12:39 PM<br>
To: App Dev Team<br>
Cc: Platform Solutions <br>
Subject: Ephemeral Storage Report: foo-bar<br>
<br>
Your data has been identified as a storage capacity violation. The file is writing to a location not under the mount point of any permanent or temporary storage, and is therefore writing to the container filesystem (overlay), adding to the I/O burden of the underlying node.  Kindly refrain from using ephemeral container storage.<br>
<br>
==== PROJECT: foo-bar ====<br>
POD: pipeline-data-monitor-domain-12-cmvd4<br>
CONTAINER: pipeline-data-monitor-domain<br>
VOLMOUNT: /data/ <br>
1.1G /output/app/log/log-current.log<br>


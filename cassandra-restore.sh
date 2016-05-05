#!/bin/bash
## Script to restore cassandra volume from s3 - patrick.pierson@ionchannel.io
## Get todays date and format in MM-DD-YYYY
date_time=$(date +%m-%d-%Y)
## Determine cluster from minion file and second arg from id, save to cluster
cluster=$(cat /etc/salt/minion | grep 'id: ' | cut -d\   -f2 | awk -F. '{ print $2}')
## Determine folder name from s3 bucket by searching for cluster, save to folder name
folder_name=$(aws s3 ls s3://bucket/cassandra-backups/ | grep $cluster | awk '{print $2}')
## Traverse folder_names
for i in $folder_name; do
  ## Save current traversed folder_name to i
  folder=$(aws s3 ls s3://bucket/cassandra-backups/$i)
  ## Check if date_time is in folder
  if [[ $folder == *$date_time* ]]; then
    ## If so save that name to latest_node
    latest_node=$(echo $i | sed -e 's_/__g')
  fi
done
## Recover by syncing s3 bucket/latest_node/latest to cassandra directory
aws s3 sync s3://bucket/cassandra-backups/$latest_node/latest/ /cassandra/ --region us-east-1

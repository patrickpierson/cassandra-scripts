#!/bin/bash
## Script to backup cassandra volume to s3 for daily snapshots - patrick.pierson@ionchannel.io
## Use nodetool to get node id.  Grep out just the id and save it to cassandra_id
cassandra_id=$(nodetool info | grep 'ID' | sed -e 's/ID                     : //g')
## Cat minion file, grep id and build name based on cluster.cassandra.env and save to name
name=$(cat /etc/salt/minion | grep 'id: ' | cut -d\   -f2 | awk -F. '{ print $2"."$3"."$5}')
## Build cassandra_name based on cassandra_id and name
cassandra_name=$cassandra_id.$name
## Get todays date and format in MM-DD-YYYY
date_time=$(date +%m-%d-%Y)
## Get cassandra directory size in human readable Bytes
data_size=$(sudo du -h /cassandra/ | tail -n 1 | awk '{printf $1"B"}')
## Sync cassandra directory to s3 bucket/cassandra_name/date_time, this can be run multiple times a day and only the newest or changed data will be synced
aws s3 sync /cassandra s3://bucket/cassandra-backups/$cassandra_name/$date_time/ --region us-east-1
## Clear out previous latest
aws s3 rm --recursive s3://bucket/cassandra-backups/$cassandra_name/latest --region us-east-1
## Copy last s3 bucket/cassandra_name/date_time to latest folder
aws s3 sync s3://bucket/cassandra-backups/$cassandra_name/$date_time/ s3://bucket/cassandra-backups/$cassandra_name/latest --region us-east-1
## Generate text to post to slack
text="$cassandra_name has backed up $data_size to s3"
## Generate json payload
json="{\"channel\": \"#room\", \"username\":\"cassandra\", \"icon_emoji\":\":robot_face:\", \"attachments\":[{\"color\":\"good\" , \"text\": \"$text\"}]}"
## Post to slack
curl -s -d "payload=$json" "https://hooks.slack.com/services/T#####/###dasfa####/#########ASDFAFA##########"

import json
import boto3
import os

def handler(event, context):
    s3 = boto3.client('s3')
    dstBucket = os.environ['dst_bucket']
    for record in event["Records"]:
        srcBucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        path = key.split("/")
        if len(path) < 8 or path[0] != "data":
            print("error: invalid path "+key)
            continue
        databaseType = path[1]
        tableName = path[2]
        year = path[3]
        month = path[4]
        day = path[5]
        hour = path[6]
        fileName = path[7]
        newKey = databaseType + "/" + "json/" + tableName + "/dt=" + year + month + day + "/" + fileName
        copy_source = {
            'Bucket': srcBucket,
            'Key': key
        }
        s3.copy(copy_source, dstBucket, newKey)
        s3.delete_object(Bucket=srcBucket, Key=key)
    return

import boto3
import botocore
from botocore.exceptions import ClientError

def tag_instance(events, context):
  ec2 = boto3.client('ec2')
  ## grab pass parameters
  instance_id = events['instance_id']
  tag_value = events['tag_value']
  tag_key = events['tag_key']

  response = ec2.create_tags(Resources=[ instance_id, ], Tags=[{ 'Key': tag_key, 'Value': tag_value},])
  print('[INFO] 1 EC2 instance is successfully tagged', instance_id)
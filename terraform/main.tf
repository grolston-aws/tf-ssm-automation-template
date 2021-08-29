
provider "aws" {
  profile = "default"
  version = "~> 3.52.0"
  region  = var.aws_region
}
## update backend s3 bucket for state file management
terraform {
  backend "s3" {
    bucket = "tfstate-workload1"
    key    = "ssm-automation-poc/terraform.tfstate"
    region = "us-west-2"
  }
}

## IAM Role for SSM POC
data "aws_iam_policy_document" "ssm_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name = "mypoc-ssm-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.ssm_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_ssm_automation" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

data "aws_iam_policy_document" "ssm_role_ec2tag" {
  statement {
    actions   = ["ec2:CreateTag", "ec2:Describe*"]
    resources = "*"
  }
}

resource "aws_iam_policy" "policy_ec2tag" {
  name        = "poc-ssm-ec2tagging-policy"
  description = "allow ec2 tagging for SSM poc"
  policy      = data.aws_iam_policy_document.ssm_role_ec2tag.json
}

resource "aws_iam_role_policy_attachment" "attach_passrole" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy_passrole.arn
}



## SSM Automation Runbook

resource "aws_ssm_document" "ssm_automation_poc" {
  name            = "POC-EC2TaggingExample"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<DOC
---
description: |
  ### Document name - POC-EC2TaggingExample

  ## What does this document do?
  Applies tag to EC2 instance


  ## Input Parameters
  * instanceID : EC2 Instance ID to tag
  * tagKey: EC2 tag key to apply
  * tagValue: EC2 tag value to apply.
  * AutomationAssumeRoleARN (Optional) The ARN of the role that allows Automation to perform the actions on your behalf.

  ## Output parameters
  * NA

  ## Minimum Permissions Required
  * ec2:CreateTag


schemaVersion: "0.3"
assumeRole: "{{AutomationAssumeRole}}"
parameters:
  AutomationAssumeRole:
    type: String
    description: (Optional) The role ARN to assume during automation execution.
    default: "${aws_iam_role.role.arn}"
  instanceId:
    type: String
    description: (Optional) Amazon S3 bucket where you want to export the result summary.
    default: ""
  tagKey:
    type: String
    description: (Optional) Amazon S3 bucket where you want to export the result summary.
    default: ""
  tagValue:
    type: String
    description: (Optional) Amazon S3 bucket where you want to export the result summary.
    default: ""

mainSteps:
  - name: TagEc2Instance
    action: aws:executeScript
    description: |
      ### What does the step do?
      Adds a tag key and tag value to an EC2 instance

      ### What is the output of the step?
      No output
    inputs:
      Runtime: python3.8
      Handler: tag_instance
      InputPayload:
        instance_id: "{{ instanceId }}"
        tag_value: "{{ tagValue }}"
        tag_key: "{{ tagKey }}"
      Script: |
        import json
        import boto3
        import botocore
        from botocore.exceptions import ClientError

        def tag_instance(events, context):
          ec2 = boto3.client('ec2')
          ## grab pass parameters
          instance_id = events['instance_id']
          tag_value = events['tag_value']
          tag_key = events['tag_key']

          response = ec2.create_tags(Resources=[ instance_id, ], Tags=[{ 'Key': tag_key, 'Value': tag_value},)
          print('[INFO] 1 EC2 instance is successfully launched', instance_id)
DOC
}
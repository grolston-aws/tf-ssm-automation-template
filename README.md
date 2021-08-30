# Terraform POC for AWS SSM Automation Using aws:executeScript

A simple example of how to take common administrative Python Boto3 scripts and put them into AWS [SSM Automation Action](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-actions.html) using the [`aws:executeScript`](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-action-executeScript.html) action.

## Overview

The sample gives a dead-simple example of leveraging  using a step action of [`aws:executeScript`](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-action-executeScript.html). The intent is to give a simple example of how to take current python boto3 scripts teams currently have and implement in them into AWS SSM Automation to support deployed applications. The project creates a simple role that is used to run the AWS SSM Automation document. The Automation document uses a single step which leverages aws:executeScript with python 3.7. The Automation document passes parameters that are created from the Terraform code as well as parameters in which the user is to enter each time they are executing the Automation document. The python script being executed is a simple process of adding a tag to an existing EC2 instance.

## Purpose

The purpose of the *proof of concept* is to give a terraform example of how to create an [AWS SSM Automation Runbook](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html) using the action [`aws:executeScript`](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-action-executeScript.html) functionality. The intent is to give a simple example of how to take existing Python Boto3 scripts teams have and integrate them into AWS SSM Automation to support their AWS environments or deployed applications.

The script being executed is in the poc is intended to be as simple as possible and to show how parameters are passed to an executing script. Given the simple example, the developer/engineer should be able to replace the current script with their own python script and update the SSM Automation Runbook parameters in the terraform main.tf to leverage their for their own solutions.

# Resources Deployed

The following resources are deployed when applying the ./terraform directory:

1. IAM Role - `ssm_role` - The SSM role which will have permissions to execute the SSM Runbook
2. IAM Managed Policy - `ssm_role_ec2tag` - managed policy attached to the `mypoc-ssm-role` giving permissions to necessary resources
3. SSM Document - `ssm_runbook_poc` - SSM Document which executes the python script using the IAM role `mypoc-ssm-role`

## Project Breakdown

Within the repo we have the following directories:

* `./python` - (reference only) - contains the *example* python script we would like to build into our SSM Automation Runbook
* `./ssm` - (reference only) - contains the example *ssm.yml* file which is the SSM document in YAML form and contains the code from our python script `ssm.py`
* `./terraform` - (deployed solution) - contains the deployable terraform files which combines the resources to deploy the SSM Automation Runbook based on our *example* python script

SSM Automation Runbooks pass parameters through declaring `{{ }}` from the Document definition to the steps. The snippet below is from the `./ssm/ssm.yml` within the repo. When creating an SSM Runbook you will need to define parameters which the end-user or automation will provide when executing the runbook. The parameters can will be passed into the executing environment at launch. To make things easier for end-users, you can specify an default value.

```yml
parameters:
  AutomationAssumeRole:
    type: String
    description: (Optional) The role ARN to assume during automation execution.
    default: "{{AutomationAssumeRole}}"
  instanceId:
    type: String
    description: The instance id to tag an EC2 with.
    default: ""
  tagKey:
    type: String
    description: The tag key being applied to the EC2 instance id.
  tagValue:
    type: String
    description: The tag value being applied to the EC2 instance id.
```

The overall document will define the parameters (as seen above) and then are passed to each step by declaring them in the step definition under the step `inputs` within the `InputPayLoad` definition. The payload is passed into the executing environment of the python script in the `events` parameter.

```yml
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
```

Within the python script the parameter values are set (passed) using the events param. Below the example shows how instance id, tag value, and tag key are obtained within the python code executing within the `aws:executeScript` step in the Automation document.

```python
def tag_instance(events, context):
  ## grab pass parameters
  instance_id = events['instance_id']
  tag_value = events['tag_value']
  tag_key = events['tag_key']
```

The `aws:executeScript` step leverages the `AutomationAssumeRole` as the permissions which the script will be executed in. Bringing this all together with terraform, we can use a heredoc and paste the contents of the ./ssm/ssm.yaml file into the resource. Furthermore, we can use the heredoc interpolation to leverage variables defined in terraform to generate the AWS Automation document.

```hcl
resource "aws_ssm_document" "ssm_automation_poc" {
  name            = "POC-EC2TaggingExample"
  document_type   = "Automation"
  document_format = "YAML"
  depends_on      = [aws_iam_role.role]

  content = <<DOC
---
description: |
  ### Document name - POC-EC2TaggingExample

  ## What does this document do?
  Applies tag to EC2 instance

schemaVersion: "0.3"
assumeRole: "{{AutomationAssumeRole}}"
parameters:
  AutomationAssumeRole:
    type: String
    description: (Optional) The role ARN to assume during automation execution.
    default: "${aws_iam_role.role.arn}"
  instanceId:
    type: String
    description: The instance id to tag an EC2 with.
    default: ""
....
DOC
}
```

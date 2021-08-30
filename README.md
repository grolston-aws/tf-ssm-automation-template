# AWS SSM Automation Runbook with aws:executeScript in Terraform

A simple example of how to take common administrative python boto3 scripts and put them into AWS SSM Automation Runbook.

# Overview

The sample gives a dead-simple example of leveraging AWS SSM Automation documents of type aws:executeScript. The intent is to give a simple example of how to take current python boto3 scripts teams currently have and implement in them into AWS SSM Automation to support deployed applications. The project creates a simple role that is used to run the AWS SSM Automation document. The Automation document uses a single step which leverages aws:executeScript with python 3.7. The Automation document passes parameters that are created from the Terraform code as well as parameters in which the user is to enter each time they are executing the Automation document. The python script being executed is a simple process of adding a tag to an existing EC2 instance.

# Purpose

The intent of the example is to give a terraform example of how to create an AWS Automation document using the aws:executeScript functionality and thus port their python boto3 scripts to AWS Automation. The script being executed is intended to be as simple as possible and to show how parameters are passed to an executing script. Given the simple example, the developer/engineer should be able to replace the current script with their own python script and update the SSM Automation document parameters to leverage their own.
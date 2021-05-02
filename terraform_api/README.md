# Welcome to terraform Simple Api project!

This project demonstrate how to build the infrastructure required for a simple api built using CDK.

## Table of contents:
- [Prerequisites](#Prerequisites)
- [Setup](#Setup)

## Prerequisites
To be able to provision the solution you would need the following:

1.	[Install terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)


---
## Setup

You can confirm that the terraform is working fine using the below command

```
terraform --version
```

Then clone this repo and deploy it's infrastructure to your account using below commands.

```
## If you use https clone run below command
git clone https://github.com/eng-moataz/simple_api.git

## If you use ssh then run below
git clone git@github.com:eng-moataz/simple_api.git
```

change location to terraform_api directory

```
$ cd terraform_api
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ terraform plan
$ terraform apply --auto-approve
```

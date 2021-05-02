# Welcome to terraform Simple Api project!

This project demonstrate how to build the infrastructure required for a simple api built using CDK.

## Table of contents:
- [Prerequisites](#Prerequisites)
- [Setup](#Setup)
- [Cleanup](#Cleanup)

## Prerequisites
To be able to provision the solution you would need the following:

1.	[Install terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. [Install](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [configure aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config)


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

change location to terraform_api directory and initialize it to install required packages to provision the infrastruture with the specified provider.

```
$ cd terraform_api
$ terraform init
```

At this point you can now provision the resources in the template for this code.

```
$ terraform plan
$ terraform apply --auto-approve
```

## Useful commands

 * `terraform show`          list all resources in the stack
 * `terraform state show aws_iam_role.lambda_role`    as an example shows the state of the created lambda role


---
## Cleanup

In order to delete all the infrastructure created, you can perform the below command which will delete the resources.

```
terraform destroy --auto-apporve
```
Enjoy!
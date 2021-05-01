
# Welcome to CDK Simple Api project!

This project demonstrate how to build the infrastructure required for a simple api built using CDK.

## Table of contents:
- [Prerequisites](#Prerequisites)
- [Setup](#Setup)

## Prerequisites
To be able to provision the solution you would need the following:

1.	[Install git](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/set-up-git)
2.  [Install python 3.x](https://www.python.org/downloads/)
3.	[Install CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html#getting_started_prerequisites)

---
## Setup

You can confirm that the cdk is working fine using the below command

```
cdk --version
```

Then clone this repo and deploy it's infrastructure to your account using below commands.

```
## If you use https clone run below command
git clone https://github.com/eng-moataz/simple_api.git

## If you use ssh then run below
git clone git@github.com:eng-moataz/simple_api.git
```

To manually create a virtualenv on MacOS and Linux:

```
# change location to cdk_api_python directory
$ cd cdk_api_python
$ python3 -m venv .venv
```

you can use the following step to activate your virtualenv.

```
$ source .venv/bin/activate
```

If you are a Windows platform, you would activate the virtualenv like this:

```
% .venv\Scripts\activate.bat
```

Once the virtualenv is activated, you can install the required dependencies.

```
$ pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ cdk synth
```

To add additional dependencies, for example other CDK libraries, just add
them to your `setup.py` file and rerun the `pip install -r requirements.txt`
command.

## Useful commands

 * `cdk ls`          list all stacks in the app
 * `cdk synth`       emits the synthesized CloudFormation template
 * `cdk deploy`      deploy this stack to your default AWS account/region
 * `cdk diff`        compare deployed stack with current state
 * `cdk docs`        open CDK documentation

Enjoy!

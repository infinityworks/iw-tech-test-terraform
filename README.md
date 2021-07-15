# iw-tech-test-terraform

> I sense a disturbance in the traffic flow

## Task

There is a web server here which is listening on port 80. Modify the Terraform configuration to make it high availability. Anything else to improve?

The Terraform configuration will ask you to enter an SSH key name to setup the EC2 instance.

## Validation

* Can withstand loss of an availability zone.
* Reasonable security.

## DevContainer setup (VSCODE)

Install the extention `ms-vscode-remote.remote-containers`
Reopen the unbalaced directory in the container
wait... (approx 5 minutes) read the log

## AWS credentails (ACloud Guru sandbox)

> Setup aws config

```shell
aws configure --profile=sandbox-acloudguru

```

> Enter the following values

| Property          | Value      |
|-------------------|------------|
| Access Key ID     | #PROVIDED# |
| Secret Access Key | #PROVIDED# |
| region            | us-east-1  |
| output            | json       |

Export the sandbox profile 

```shell
export AWS_PROFILE=sandbox-acloudguru
```

## Create an EC2 Key Pair (to be passed into TF)

create a key pair called `demo`

```shell
aws ec2 create-key-pair --key-name demo | jq -r ".KeyMaterial" > demo.pem
```

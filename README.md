# iw-tech-test-terraform

The task will be provided to you as part of the interview process.

## DevContainer setup (VSCODE)

Install the extention `ms-vscode-remote.remote-containers`
Reopen the unbalaced directory in the container
wait... (approx 5 minutes) read the log

## Docker Setup (Generic IDE)

From the project folder execute `the run-docker'sh` script

```shell
./run-docker.sh
```

wait... (approx 5 minutes)

The workspace is mounted in the directory `/workspaces/iw-tech-test-terraform-aws/`

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

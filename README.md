# iw-tech-test-terraform

The task will be provided to you as part of the interview process.

## Deploy details
The first deployment needs to be done gradually due to [bug](https://github.com/hashicorp/terraform-provider-aws/issues/27386
) in AWS provider (4.51.0 is also affected)
To remove all resources with `terraform destroy`, run the commands in reverse order.

```shell
terraform apply \
-target="aws_vpc.vpc" \
-target="aws_subnet.subnet_1" \
-target="aws_internet_gateway.internet_gateway" \
-target="aws_route_table.rt" \
-target="aws_route.route_to_gateway" \
-target="aws_route_table_association.subnet_1" \
-target="aws_security_group.allow_all" \
-target="aws_security_group.allow_http" \
-target="aws_lb.web-lb" \
-target="aws_lb_listener.web-lb-listener" \
-target="aws_lb_target_group.web-lb-group"

terraform apply \
-target="data.aws_subnet_ids.web_subnets" \
-target="data.ws_instances.web_instances" \
-target="aws_instance.web"

terraform apply \
-target="aws_lb_target_group_attachment.web-lb-group-attach"
```

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

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "test-vpc"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "subnet_1" {
  for_each                = var.cidr_az_blocks
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = "${var.aws_provider_region}${each.value.zone}"
  map_public_ip_on_launch = true
  tags = {
    app       = "web"
    Name      = "web-${each.value.zone}"
    ManagedBy = "terraform"

  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "test-igw"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "route-table"
    ManagedBy = "terraform"
  }
}

resource "aws_route" "route_to_gateway" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
  depends_on             = [aws_route_table.rt]
}
resource "aws_route_table_association" "subnet_1" {
  for_each       = aws_subnet.subnet_1
  subnet_id      = aws_subnet.subnet_1[each.key].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 20
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
data "aws_subnet_ids" "web_subnets" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    app = "web"
  }

  depends_on = [
    aws_subnet.subnet_1
  ]
}
data "aws_instances" "web_instances" {
  instance_tags = {
    App = "web"
  }
  depends_on = [
    aws_subnet.subnet_1,
    aws_instance.web
  ]
}

resource "aws_instance" "web" {
  count         = length(data.aws_subnet_ids.web_subnets.ids)
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  user_data     = "#!/bin/bash\nyum update -y\nyum install -y httpd\nservice httpd start"
  subnet_id     = element(tolist(data.aws_subnet_ids.web_subnets.ids), count.index)
  key_name      = var.ssh_key

  vpc_security_group_ids = [
    aws_security_group.allow_http.id
  ]

  tags = {
    App       = "web"
    Name      = "web-${count.index}"
    ManagedBy = "terraform"
  }
  depends_on = [
    data.aws_subnet_ids.web_subnets
  ]
}

resource "aws_lb" "web-lb" {
  name               = "web-public"
  internal           = false
  load_balancer_type = "network"
  subnets            = tolist(data.aws_subnet_ids.web_subnets.ids)

  tags = {
    Name      = "web-public"
    app       = "web"
    ManagedBy = "terraform"
  }
  depends_on = [
    aws_internet_gateway.internet_gateway
  ]
}

resource "aws_lb_listener" "web-lb-listener" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-lb-group.arn
  }
}

resource "aws_lb_target_group" "web-lb-group" {
  name     = "web-lb-target-group"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "web-lb-group-attach" {
  count            = length(data.aws_instances.web_instances.ids)
  target_group_arn = aws_lb_target_group.web-lb-group.arn
  target_id        = data.aws_instances.web_instances.ids[count.index]
  port             = 80
}

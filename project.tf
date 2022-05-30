resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name      = "test-vpc"
    ManagedBy = "terraform"
  }
}

# Private subnets are for 2 web servers
resource "aws_subnet" "pvt_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = format("%sa", var.aws_provider_region)

  tags = {
    Name      = "Private Subnet 1"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "pvt_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = format("%sb", var.aws_provider_region)

  tags = {
    Name      = "Private Subnet 2"
    ManagedBy = "terraform"
  }
}

# Public subnets are for access to the internet
resource "aws_subnet" "pub_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = format("%sa", var.aws_provider_region)
  map_public_ip_on_launch = true

  tags = {
    Name      = "Public Subnet 1"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "pub_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = format("%sb", var.aws_provider_region)
  map_public_ip_on_launch = true

  tags = {
    Name      = "Public Subnet 2"
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
  subnet_id      = aws_subnet.pub_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "subnet_2" {
  subnet_id      = aws_subnet.pub_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "alb_sg" {
  name        = "ALB Security Group"
  description = "Allow incoming HTTP traffic from the internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web server security group only allows requests from ALB security group
resource "aws_security_group" "web_sg" {
  name        = "Web Server Security Group"
  description = "Allow HTTP traffic from ALB security group"
  vpc_id      = aws_vpc.vpc.id

  # HTTP access from the VPC
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  user_data     = "#!/bin/bash\nyum update -y\nyum install -y httpd\nservice httpd start"
  subnet_id     = aws_subnet.pvt_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id,
  ]

  tags = {
    Name = "web"
  }
}

resource "aws_instance" "web_2" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  user_data     = "#!/bin/bash\nyum update -y\nyum install -y httpd\nservice httpd start"
  subnet_id     = aws_subnet.pvt_subnet_2.id

  vpc_security_group_ids = [
    aws_security_group.web_sg.id,
  ]

  tags = {
    Name = "web_2"
  }
}

resource "aws_lb" "load-balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_subnet_1.id, aws_subnet.pub_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
  tags = {
    Name = "Load Balancer"
  }
}

resource "aws_lb_target_group" "target-group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.web.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "web_2_tg_attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

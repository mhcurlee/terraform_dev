provider "aws" {
  region = "us-east-1"
}

#  vars section

variable "ssh_keyname" {
  description = "key name to use for SSH access"
  default     = "myssh"
}

variable "r53_zone_id" {
  description = "Route53 zone id"
  default     = "Z1EEQ05I8FZVXC"
}

variable "r53_fqdn" {
  description = "FQDN for LB A record"
  default     = "mydemo.gocurlee.com"
}

variable "scale_min" {
  description = "min number of nodes in scale group"
  default     = 3
}

variable "scale_max" {
  description = "max number of nodes in scale group"
  default     = 6
}

#   Create VPC for app

resource "aws_vpc" "webserver-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "webserver-vpc"
  }
}

#  Create Subnets in each AZ

resource "aws_subnet" "testsubnet1" {
  vpc_id                  = aws_vpc.webserver-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "testsubnet1"
  }
}

resource "aws_subnet" "testsubnet2" {
  vpc_id                  = aws_vpc.webserver-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "testsubnet2"
  }
}

resource "aws_subnet" "testsubnet3" {
  vpc_id                  = aws_vpc.webserver-vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "testsubnet3"
  }
}

# creat IGW for VPC

resource "aws_internet_gateway" "test_vpc_gw" {
  vpc_id = aws_vpc.webserver-vpc.id

  tags = {
    Name = "testvpn_gw"
  }
}

resource "aws_route_table" "test_vpc_route_table" {
  vpc_id = aws_vpc.webserver-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_vpc_gw.id
  }
}

resource "aws_route_table_association" "test_vpc_route_table_association1" {
  subnet_id      = aws_subnet.testsubnet1.id
  route_table_id = aws_route_table.test_vpc_route_table.id
}

resource "aws_route_table_association" "test_vpc_route_table_association2" {
  subnet_id      = aws_subnet.testsubnet2.id
  route_table_id = aws_route_table.test_vpc_route_table.id
}

resource "aws_route_table_association" "test_vpc_route_table_association3" {
  subnet_id      = aws_subnet.testsubnet3.id
  route_table_id = aws_route_table.test_vpc_route_table.id
}

resource "aws_launch_template" "lt-webserver" {
  image_id               = "ami-011b3ccf1bd6db744"
  instance_type          = "t2.micro"
  key_name               = var.ssh_keyname
  vpc_security_group_ids = [aws_security_group.elb.id, aws_security_group.webservers_base.id]
  user_data              = "IyEvYmluL2Jhc2gKCiMgYWRkIGFuc2libGUgYW5kIGdpdAp5dW0tY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgcmh1aS1SRUdJT04tcmhlbC1zZXJ2ZXItZXh0cmFzCnl1bSBpbnN0YWxsIGFuc2libGUgZ2l0IC15CgoKIyBjb25maWcgbm9kZSB2aWEgQW5zaWJsZQoKbWtkaXIgLXAgL29wdC9idWlsZApjZCAvb3B0L2J1aWxkCmdpdCBjbG9uZSBodHRwczovL2dpdGh1Yi5jb20vbWhjdXJsZWUvYW5zaWJsZS1idWlsZC5naXQKY2QgYW5zaWJsZS1idWlsZAphbnNpYmxlLXBsYXlib29rIGJ1aWxkLnltbAoKCg=="
}

resource "aws_alb" "webserver-al" {
  name               = "webserver-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id, aws_security_group.webservers_base.id]
  subnets            = [aws_subnet.testsubnet1.id, aws_subnet.testsubnet2.id, aws_subnet.testsubnet3.id]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_alb.webserver-al.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.webservers-targets.arn
  }
}

resource "aws_alb_target_group" "webservers-targets" {
  name     = "webserver-targets"
  vpc_id   = aws_vpc.webserver-vpc.id
  port     = 80
  protocol = "HTTP"
}

resource "aws_autoscaling_group" "webserver-asg" {
  vpc_zone_identifier = [aws_subnet.testsubnet1.id, aws_subnet.testsubnet2.id, aws_subnet.testsubnet3.id]
  desired_capacity    = var.scale_min
  max_size            = var.scale_max
  min_size            = var.scale_min

  launch_template {
    id = aws_launch_template.lt-webserver.id
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_webservers" {
  autoscaling_group_name = aws_autoscaling_group.webserver-asg.id
  alb_target_group_arn   = aws_alb_target_group.webservers-targets.arn
}

resource "aws_security_group" "webservers_base" {
  name   = "webserver_sec_grp"
  vpc_id = aws_vpc.webserver-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "elb" {
  name   = "webserver_elb_80"
  vpc_id = aws_vpc.webserver-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "web-demo" {
  zone_id = var.r53_zone_id
  name    = var.r53_fqdn
  type    = "CNAME"
  ttl     = "300"
  records = [aws_alb.webserver-al.dns_name]
}


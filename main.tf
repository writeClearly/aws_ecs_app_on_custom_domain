terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
  backend "s3" {
    # Terraform doesn't support variables in backend thus workaround is done by backend.tfvars
    # bucket      = var.backend["bucket_name"]
    # key         = var.backend["key"]
    # region      = var.backend["region"]
  }
  
}
provider "aws" {
    region      = var.region["cheapest"]
}

resource "aws_ecs_cluster" "main" {
  name          = var.ecs_cluster
}

resource "aws_ecs_task_definition" "app" {
  family                    = var.ecs_app_task_definition["family"]
  requires_compatibilities  = ["FARGATE"]
  task_role_arn             = var.ecs_app_task_definition["task_role_arn"]
  execution_role_arn        = var.ecs_app_task_definition["execution_role_arn"]
  network_mode              = "awsvpc"
  cpu                       = var.ecs_app_task_definition["cpu"]
  memory                    = var.ecs_app_task_definition["memory"]
  container_definitions     = <<TASK_DEFINITION
  [
    {
      "name":         "${var.ecs_app_container_definition["name"]}",
      "image":        "${var.ecs_app_container_definition["image"]}",
      "essential":    true,
      "portMappings": [
        {
          "containerPort": ${var.ecs_app_container_definition["container_port"]}
        }
      ]
    }
  ]
  TASK_DEFINITION
}
resource "aws_vpc" "custom" {
  cidr_block        =   "10.0.0.0/16"
  instance_tenancy  =   "default"
  tags = {
    name = "SomeAppVPC"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            =   aws_vpc.custom.id
  cidr_block        =   "10.0.128.0/17"
  availability_zone =   "${var.region["cheapest"]}a"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            =   aws_vpc.custom.id
  cidr_block        =   "10.0.0.0/17"
  availability_zone =   "${var.region["cheapest"]}b"
}

resource "aws_internet_gateway" "gw"{
  vpc_id  = aws_vpc.custom.id
}
resource "aws_route_table" "routes" {
  vpc_id      = aws_vpc.custom.id
  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.gw.id
  }
  tags = {
    name = "SomeAppRouteTable"
  }
}

resource "aws_route_table_association" "subnet_a"{
  subnet_id         = aws_subnet.public_subnet_a.id
  route_table_id    = aws_route_table.routes.id
}

resource "aws_route_table_association" "subnet_b"{
  subnet_id         = aws_subnet.public_subnet_b.id
  route_table_id    = aws_route_table.routes.id
}

resource "aws_security_group" "allow_https"{
  name              = "allowHTTPandHTTPSforALL"
  vpc_id            = aws_vpc.custom.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "allow_https_for_all"
  }
}

resource "aws_lb" "alb"{
  name                = var.app_alb["name"]
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.allow_https.id]
  subnets             = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb_target_group" "HTTP" {
  name                = var.alb_lb_target_group_HTTP["name"]
  port                = 80
  protocol            = "HTTP"
  target_type         = "ip"
  vpc_id              = aws_vpc.custom.id
}

resource "aws_lb_listener" "HTTP" {
  load_balancer_arn   = aws_lb.alb.id
  port                = 80
  protocol            = "HTTP"
  
  
  default_action {
    type              = "redirect"
    
      redirect {
      port              = "443"
      protocol          = "HTTPS"
      status_code       = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "HTTPS" {
  load_balancer_arn   = aws_lb.alb.id
  port                = 443
  protocol            = "HTTPS"
  ssl_policy          = "ELBSecurityPolicy-2016-08"
  certificate_arn     = var.alb_lb_listener_HTTPS["ssl_arn"]
  
  
  default_action {
    target_group_arn  = aws_lb_target_group.HTTP.id
    type              = "forward"
  }
}

resource "aws_route53_record" "ecs" {
  zone_id   = var.ecs_route53_record["zone_id"]
  name      = var.ecs_route53_record["name"]
  type      = "A"
  alias {
    name    = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}


resource "aws_ecs_service" "app" {
  name            = var.ecs_app_service["name"]
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_app_service["desired_count"]
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets           = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups   = [aws_security_group.allow_https.id]
    assign_public_ip  = true
  }

  load_balancer {
    target_group_arn  = aws_lb_target_group.HTTP.id
    container_name    = var.ecs_app_container_definition["name"]
    container_port    = var.ecs_app_container_definition["container_port"]
  }
  depends_on          = [aws_lb_listener.HTTP, aws_lb_listener.HTTPS]
}

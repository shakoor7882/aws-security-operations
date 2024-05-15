# To prevent crashes in GuardDuty association when creating/destroying
resource "random_string" "ecs" {
  length    = 10
  min_lower = 10
  special   = false
}

locals {
  app_name = "app-${var.workload}"
  affix    = random_string.ecs.result
}

resource "aws_ecs_cluster" "main" {
  name = "cluster-${var.workload}-${local.affix}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "main" {
  family                   = "ecs-task-${var.workload}-${local.affix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  skip_destroy             = false

  container_definitions = jsonencode([
    {
      "name" : "${local.app_name}",
      "image" : "${var.ecr_repository_url}:latest",
      "healthCheck" : {
        "retries" : 3,
        "command" : [
          "CMD-SHELL",
          "curl -f http://localhost:80/health || exit 1",
        ],
        "timeout" : 5,
        "interval" : 10,
        "startPeriod" : 10,
      },
      "essential" : true,
      "portMappings" : [
        {
          "protocol" : "tcp",
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${var.region}",
          "awslogs-group" : "${aws_cloudwatch_log_group.ecs.name}",
          "awslogs-stream-prefix" : "${local.app_name}",
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "ecs-${var.workload}-${local.affix}"
  retention_in_days = 365
  skip_destroy      = false
}

resource "aws_ecs_service" "main" {
  count                              = var.enable_service ? 1 : 0
  name                               = "ecs-service-${var.workload}-${local.affix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  platform_version                   = "LATEST"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    assign_public_ip = false
    subnets          = var.subnets
    security_groups  = [aws_security_group.all.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.app_name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}


### Network ###
data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "all" {
  name        = "fargate-${var.workload}-${local.affix}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-fargate-${var.workload}"
  }
}

# FIXME: Implement an exploit for this
resource "aws_security_group_rule" "ingress_http" {
  description       = "Allows HTTP ingress from ELB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.all.id
}

resource "aws_security_group_rule" "egress_http" {
  description       = "Allows HTTP egress, required to get credentials"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.all.id
}

resource "aws_security_group_rule" "egress_https" {
  description       = "Allows HTTPS egress"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.all.id
}

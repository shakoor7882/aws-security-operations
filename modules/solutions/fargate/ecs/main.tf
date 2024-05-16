resource "random_string" "ecs" {
  # To prevent crashes in GuardDuty association when creating/destroying
  length    = 10
  min_lower = 10
  special   = false
}

locals {
  vulnernapp_app_name  = "vulnerapp"
  cryptominer_app_name = "cryptominer"
  affix                = random_string.ecs.result

  vulnerapp_port   = 80
  cryptominer_port = 8080
}

resource "aws_ecs_cluster" "main" {
  name = "infected-cluster-${var.workload}-${local.affix}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "vulnerapp" {
  name              = "ecs-${local.vulnernapp_app_name}-${var.workload}-${local.affix}"
  retention_in_days = 1
  skip_destroy      = false
}

resource "aws_cloudwatch_log_group" "cryptominer" {
  name              = "ecs-${local.cryptominer_app_name}-${var.workload}-${local.affix}"
  retention_in_days = 1
  skip_destroy      = false
}

resource "aws_ecs_task_definition" "vulnerapp" {
  family                   = "ecs-task-${local.vulnernapp_app_name}-${local.affix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  skip_destroy             = false

  container_definitions = jsonencode([
    {
      "name" : "${local.vulnernapp_app_name}",
      "image" : "${var.ecr_vulnerapp_repository_url}:latest",
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
          "containerPort" : "${local.vulnerapp_port}",
          "hostPort" : "${local.vulnerapp_port}"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${var.region}",
          "awslogs-group" : "${aws_cloudwatch_log_group.vulnerapp.name}",
          "awslogs-stream-prefix" : "${local.vulnernapp_app_name}",
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "cryptominer" {
  family                   = "ecs-task-${local.cryptominer_app_name}-${var.workload}-${local.affix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  skip_destroy             = false

  container_definitions = jsonencode([
    {
      "name" : "${local.cryptominer_app_name}",
      "image" : "${var.ecr_cryptominer_repository_url}:latest",
      # "healthCheck" : {
      #   "retries" : 3,
      #   "command" : [
      #     "CMD-SHELL",
      #     "curl -f http://localhost:8081/ || exit 1",
      #   ],
      #   "timeout" : 5,
      #   "interval" : 10,
      #   "startPeriod" : 10,
      # },
      "essential" : true,
      "portMappings" : [
        {
          "protocol" : "tcp",
          "containerPort" : "${local.cryptominer_port}",
          "hostPort" : "${local.cryptominer_port}"
        },
        {
          "protocol" : "tcp",
          "containerPort" : 8081,
          "hostPort" : 8081
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${var.region}",
          "awslogs-group" : "${aws_cloudwatch_log_group.cryptominer.name}",
          "awslogs-stream-prefix" : "${local.cryptominer_app_name}",
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  count                              = var.enable_service ? 1 : 0
  name                               = "${local.vulnernapp_app_name}-${local.affix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.vulnerapp.arn
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
    container_name   = local.vulnernapp_app_name
    container_port   = local.vulnerapp_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "cryptominer" {
  count                              = var.enable_service ? 1 : 0
  name                               = "${local.cryptominer_app_name}-${local.affix}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.cryptominer.arn
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
    target_group_arn = var.cryptominer_target_group_arn
    container_name   = local.cryptominer_app_name
    container_port   = local.cryptominer_port
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

resource "aws_security_group_rule" "ingress_http_8080" {
  description       = "Allows HTTP ingress from ELB on port 8080"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.all.id
}

resource "aws_security_group_rule" "ingress_http_8081" {
  description       = "Allows HTTP ingress from ELB on port 8081"
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
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

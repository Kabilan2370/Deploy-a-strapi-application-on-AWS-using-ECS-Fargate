
# Get default VPC
data "aws_vpcs" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

locals {
  default_vpc_id = data.aws_vpcs.default.ids[0]
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.default_vpc_id]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "docker-strapi-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "docker-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role      = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group
data "aws_security_groups" "strapi_sg" {
  filter {
    name   = "vpc-id"
    values = [local.default_vpc_id]
  }

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_ecs_task_definition" "strapi" {
  family                   		= "docker-strapi-task"
  requires_compatibilities 	= ["FARGATE"]
  network_mode             	= "awsvpc"
  cpu                      		= 512
  memory                   		= 1024
  execution_role_arn       	= aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  		= "docker-strapi"
      image 		= var.image_uri
      portMappings = [
        {
          containerPort = 1337
        }
      ]
      essential = true
    }
  ])
}

resource "aws_ecs_service" "strapi" {
  # name            	= "docker-strapi-service"
  cluster         	= aws_ecs_cluster.cluster.id
  task_definition 	= aws_ecs_task_definition.strapi.arn
  desired_count   	= 1
  launch_type     	= "FARGATE"

  network_configuration {
    subnets                 = data.aws_subnets.default.ids
    security_groups        = data.aws_security_groups.strapi_sg.ids
    assign_public_ip = true
  }
}

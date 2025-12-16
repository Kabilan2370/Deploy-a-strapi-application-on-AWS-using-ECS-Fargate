
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
  # name = "docker-ecsTaskExecutionRole"

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
resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "strapi" {
  family                   		= "docker-strapi-task"
  requires_compatibilities 	  = ["FARGATE"]
  network_mode             	  = "awsvpc"
  cpu                      		= 512
  memory                   		= 1024
  execution_role_arn       	  = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
  {
    name      = "docker-strapi"
    image     = var.image_uri
    essential = true

    portMappings = [
      { containerPort = 1337 }
    ]

    environment = [
      { name = "NODE_ENV", value = "production" },

      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST", value = aws_db_instance.strapi.address },
      { name = "DATABASE_PORT", value = "5432" },
      { name = "DATABASE_NAME", value = "strapi" },
      { name = "DATABASE_USERNAME", value = "strapi" },
      { name = "DATABASE_PASSWORD", value = "StrapiPassword123!" },

      { name = "APP_KEYS", value = "key1,key2,key3,key4" },
      { name = "API_TOKEN_SALT", value = "randomTokenSalt" },
      { name = "ADMIN_JWT_SECRET", value = "adminJwtSecret" },
      { name = "JWT_SECRET", value = "jwtSecret" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/strapi"
        awslogs-region        = "eu-north-1"
        awslogs-stream-prefix = "ecs"
      }
    }

    }
  ])
}

resource "aws_ecs_service" "strapi" {
  name            	= "docker-strapi-service"
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

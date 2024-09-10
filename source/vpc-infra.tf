resource "aws_vpc" "cloudsec" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_sn1" {
  vpc_id            = aws_vpc.cloudsec.id
  cidr_block        = var.subnet1_cidr
  availability_zone = var.az[0]
  tags = {
    Name = var.subnetnames[1]
  }
}

resource "aws_subnet" "public_sn2" {
  vpc_id            = aws_vpc.cloudsec.id
  cidr_block        = var.subnet2_cidr
  availability_zone = var.az[1]
  tags = {
    Name = var.subnetnames[2]
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.cloudsec.id
  tags = {
    Name = "wp-public-route-table"
  }
}

resource "aws_route_table_association" "public_sn1_association" {
  subnet_id      = aws_subnet.public_sn1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public_sn2_association" {
  subnet_id      = aws_subnet.public_sn2.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.cloudsec.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_route" "public-route-table-route-for-igw" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gw.id
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "security group for rds"
  vpc_id      = aws_vpc.cloudsec.id

  ingress {
    from_port   = var.web_ports[0]
    protocol    = "TCP"
    to_port     = var.web_ports[0]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_security_group" {
  name        = "ecs_security_group"
  description = "security group for ecs"
  vpc_id      = aws_vpc.cloudsec.id

  ingress {
    from_port       = var.web_ports[2]
    protocol        = "TCP"
    to_port         = var.web_ports[2]
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow traffic from the internet"
  }

  ingress {
    from_port       = var.web_ports[2]
    protocol        = "TCP"
    to_port         = var.web_ports[2]
    security_groups = [aws_security_group.elb_security_group.id]
    description     = "Allow traffic from elb"
  }


   ingress {
    from_port       = var.web_ports[3]
    protocol        = "TCP"
    to_port         = var.web_ports[3]
    security_groups = [aws_security_group.elb_security_group.id]
    description     = "Allow traffic from elb"
  }

  ingress {
    from_port       = var.web_ports[3]
    protocol        = "TCP"
    to_port         = var.web_ports[3]
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow traffic from elb"
  }
 
  egress {
    from_port   = var.web_ports[0]
    protocol    = "TCP"
    to_port     = var.web_ports[0]
    security_groups = [aws_security_group.rds_security_group.id]
  }

    egress {
    from_port   = var.web_ports[1]
    protocol    = "TCP"
    to_port     = var.web_ports[1]
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
    from_port   = var.web_ports[2]
    protocol    = "TCP"
    to_port     = var.web_ports[2]
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
    from_port   = var.web_ports[3]
    protocol    = "TCP"
    to_port     = var.web_ports[3]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs_security_group" {
  name        = "efs_sg"
  description = "route traffic to ecs security group"
  vpc_id      = aws_vpc.cloudsec.id

  ingress {
    from_port   = var.web_ports[1]
    protocol    = "TCP"
    to_port     = var.web_ports[1]
    security_groups = [aws_security_group.ecs_security_group.id]
    description = "Allow traffic from ecs"
  }
}

resource "aws_security_group" "elb_security_group" {
  name        = "elb_sg"
  description = "route traffic to ecs"
  vpc_id      = aws_vpc.cloudsec.id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow web traffic to load balancer"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "cloudsec_subnet_group" {
  name       = "cloudsec_subnet_group"
  subnet_ids = [aws_subnet.public_sn1.id, aws_subnet.public_sn2.id]
                 
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "cloudsec_rds" {
  allocated_storage                   = 20
  identifier                          = var.rds_identifier
  db_name                             = var.rds_db_name
  engine                              = "mysql"
  engine_version                      = "8.0.35"
  instance_class                      = var.instance_class
  username                            = data.aws_ssm_parameter.database_username.value
  password                            = data.aws_ssm_parameter.database_password.value
  port                                = "3306"
  storage_type                        = "gp3"
  db_subnet_group_name                = "cloudsec_subnet_group"
  vpc_security_group_ids              = [aws_security_group.rds_security_group.id]
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  deletion_protection                 = false
  publicly_accessible                 = var.public_access
}


resource "aws_efs_file_system" "cloudsec_efs" {
  encrypted      =  true
    tags = {
    Name = "cloudsec_efs"
  }
}

resource "aws_efs_mount_target" "cloudsec_efs_mt1" {
  file_system_id = aws_efs_file_system.cloudsec_efs.id
  subnet_id      = aws_subnet.public_sn1.id
  security_groups = [ aws_security_group.efs_security_group.id ]
}

resource "aws_efs_mount_target" "cloudsec_efs_mt2" {
  file_system_id = aws_efs_file_system.cloudsec_efs.id
  subnet_id      = aws_subnet.public_sn2.id
  security_groups = [ aws_security_group.efs_security_group.id ]
  }

resource "aws_efs_access_point" "cloudsec_access_pt" {
  file_system_id = aws_efs_file_system.cloudsec_efs.id

  tags = {
    name        = var.aws_efs_access_point
    description = "Allow access to EFS"
  }
}

resource "aws_ecs_cluster" "cloudsec_cluster" {
  name = "cloudsec_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "cloudsec_cluster_capacity" {
  cluster_name = aws_ecs_cluster.cloudsec_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_cloudwatch_log_group" "cloudsec_ecs_logs" {
  name = "/ecs/cloudsec_logs"

}


resource "aws_ecs_task_definition" "cloudsec_task_definition" {
  family                   = "cloudsec_family"
  task_role_arn            = var.ecs_task_role
  execution_role_arn       = var.ecs_task_execution_role
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  requires_compatibilities = ["FARGATE"]
  
  container_definitions    = jsonencode([
    {
      name      = "wordpress",
      image     = "wordpress:php8.3-apache",
      cpu       = 1024,  # 1 vCPU = 1024 units
      memory    = 3072,  # 3 GB = 3072 MB
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-region        = "us-east-2",
          awslogs-group         = "/ecs/cloudsec_logs",
          awslogs-stream-prefix = "ecs",
          awslogs-create-group  = "true"                # Ensure the log group is created automatically if it doesn't exist
        }
      },
      environment = [
        {
          name  = "WORDPRESS_DB_HOST",
          value = aws_db_instance.cloudsec_rds.endpoint
        },
        {
          name  = "WORDPRESS_DB_USER",
          value = data.aws_ssm_parameter.database_username.value
        },
        {
          name  = "WORDPRESS_DB_PASSWORD",
          value = data.aws_ssm_parameter.database_password.value
        },
        {
          name  = "WORDPRESS_DB_NAME",
          value = var.rds_db_name
        }
      ]
    }
  ])

  volume {
    name = "cloudsec_efs_volume"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.cloudsec_efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = aws_efs_access_point.cloudsec_access_pt.id
        iam             = "ENABLED"
      }
    }
  }
}


resource "aws_lb_target_group" "cloudsec_target_group" {
  name        = var.target_group_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.cloudsec.id

  health_check {
    path     = "/wp-admin/install.php"
    protocol = "HTTP"
  }
}


resource "aws_lb" "cloudsec_elb" {
  name               = var.elb_name
  internal           = false
  load_balancer_type = var.elb_type
  security_groups    = [aws_security_group.elb_security_group.id]
  subnets            = [aws_subnet.public_sn1.id, aws_subnet.public_sn2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "cloudsec_listener" {
  load_balancer_arn = aws_lb.cloudsec_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = var.listener_forward_type
    target_group_arn = aws_lb_target_group.cloudsec_target_group.arn
  }
}


resource "aws_lb_listener" "cloudsec_listener_SSL" {
  load_balancer_arn = aws_lb.cloudsec_elb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = var.listener_forward_type
    target_group_arn = aws_lb_target_group.cloudsec_target_group.arn
  }
}


resource "aws_ecs_service" "cloudsec_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.cloudsec_cluster.id
  task_definition = aws_ecs_task_definition.cloudsec_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets         = [aws_subnet.public_sn1.id, aws_subnet.public_sn2.id]
    security_groups = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cloudsec_target_group.arn
    container_name   = "wordpress"
    container_port   = 80
  }
}


resource "aws_route53_record" "cloudsec_dns" {
  zone_id = var.hosted_zone_id
  allow_overwrite = true
  name    = "seyramgabriel.com"
  type    = "A"

  alias {
    name                   = aws_lb.cloudsec_elb.dns_name
    zone_id                = aws_lb.cloudsec_elb.zone_id
    evaluate_target_health = true
  }
}

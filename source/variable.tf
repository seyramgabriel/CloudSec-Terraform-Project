variable "region" {
  default = "us-east-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "cloudsec_vpc"
}

variable "subnetnames" {
  default = ["wp_private_sn1", "wp_public_sn1", "wp_public_sn2"]
  type    = list(any)
}

variable "subnet1_cidr" {
  default = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  default = "10.0.2.0/24"
}

variable "subnet3_cidr" {
  default = "10.0.3.0/24"
}

variable "az" {
  default = ["us-east-2a", "us-east-2b"]
  type    = list(any)
}

variable "internet_gateway_name" {
  default = "cloudsec_igw"
}


variable "web_ports" {
  default = [ 3306, 2049, 80, 443 ]
  type    = list
}

variable "public_access" {
  type    = bool
  default = false
}

variable "rds_identifier" {
  type = string
  default = "cloudsec"
  }

variable "rds_db_name" {
    type    = string
    default = "cloudsec_db"
  }

variable "instance_class" {
  default = "db.t3.micro"
}

variable "iam_database_authentication_enabled" {
  default = false
}

/*variable "ecs_task_role" { 
  default = "arn:aws:iam::431877974142:role/ECS_Task_Definition"
}


variable "ecs_task_execution_role" {
  default = "arn:aws:iam::431877974142:role/ecsTaskExecutionRole"
}*/

variable "target_group_name" {
    type    = string
    default = "cloudsec-alb-group"
  }

variable "elb_name" {
    type    = string
    default = "cloudsec-alb"
  }


variable "elb_type" {
  default = "application"
  type    = string
}

variable "certificate_arn" {
  type  = string
  default = "arn:aws:acm:us-east-2:431877974142:certificate/554b507e-65b1-4194-bc68-05293aa55694"
}

variable "aws_efs_access_point" {
  type = string
  default = "cloudsec_efs_access_point"
}

variable "ecs_service_name" {
  default = "ecs_cloudsec-service"
  type    = string
}

variable "listener_forward_type" {
  default = "forward"
}

variable "hosted_zone_id" {
  default = "Z0024725E6TXJWBO3XTZ"
  type    = string
}
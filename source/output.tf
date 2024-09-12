output "vpc_id" {
  value     = aws_vpc.cloudsec.id
  sensitive = true
}

output "public_sn1_id" {
  value     = aws_subnet.public_sn1.id
  sensitive = true
}

output "public_sn2_id" {
  value     = aws_subnet.public_sn2.id
  sensitive = true
}

output "rds_endpoint" {
  value = aws_db_instance.cloudsec_rds.endpoint
}


output "file_system_id" {
  value = aws_efs_file_system.cloudsec_efs.id
}

output "efs_security_group" {
  value = aws_security_group.efs_security_group.id
}

output "elb_dns" {
  value = aws_lb.cloudsec_elb.dns_name
}

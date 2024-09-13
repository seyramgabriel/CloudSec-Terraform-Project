output "rds_endpoint" {
  value = aws_db_instance.cloudsec_rds.endpoint
}

output "elb_dns" {
  value = aws_lb.cloudsec_elb.dns_name
}

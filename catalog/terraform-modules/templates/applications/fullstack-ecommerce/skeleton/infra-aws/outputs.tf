output "store_url" {
  description = "Address of the store."
  value       = var.enable_cdn ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : "http://${aws_lb.main.dns_name}"
}

output "load_balancer_url" {
  description = "Address of the load balancer, behind the content delivery network."
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_host" {
  description = "Host name of the PostgreSQL database."
  value       = aws_db_instance.main.address
}

output "admin_token" {
  description = "Bearer token of the admin API."
  value       = random_password.admin_token.result
  sensitive   = true
}

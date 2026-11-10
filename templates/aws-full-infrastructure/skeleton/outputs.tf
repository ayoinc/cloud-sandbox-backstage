output "name" {
  description = "Prefix of every resource name"
  value       = local.name
}

output "kms_key_arn" {
  description = "ARN of the encryption key of this stack"
  value       = aws_kms_key.main.arn
}

output "vpc_id" {
  description = "ID of the VPC the stack deploys into"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs by subnet name"
  value       = { for name, subnet in aws_subnet.main : name => subnet.id }
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT gateway"
  value       = one(aws_eip.nat[*].public_ip)
}

output "transit_gateway_id" {
  description = "ID of the transit gateway"
  value       = one(aws_ec2_transit_gateway.main[*].id)
}

output "autoscaling_group_name" {
  description = "Name of the EC2 Auto Scaling group"
  value       = one(aws_autoscaling_group.compute[*].name)
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = one(aws_eks_cluster.main[*].name)
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the Kubernetes API server"
  value       = one(aws_eks_cluster.main[*].endpoint)
}

output "ecr_repository_url" {
  description = "URL of the container registry"
  value       = one(aws_ecr_repository.main[*].repository_url)
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = one(aws_s3_bucket.main[*].bucket)
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = one(aws_efs_file_system.main[*].id)
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL database"
  value       = one(aws_db_instance.main[*].endpoint)
}

output "rds_master_secret_arn" {
  description = "ARN of the Secrets Manager secret with the database master password"
  value       = one(flatten(aws_db_instance.main[*].master_user_secret[*].secret_arn))
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = one(aws_dynamodb_table.main[*].name)
}

output "redis_primary_endpoint" {
  description = "Primary endpoint of the Redis replication group"
  value       = one(aws_elasticache_replication_group.main[*].primary_endpoint_address)
}

output "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives alarms"
  value       = one(aws_sns_topic.alarms[*].arn)
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis data stream"
  value       = one(aws_kinesis_stream.main[*].name)
}

output "queue_url" {
  description = "URL of the SQS queue"
  value       = one(aws_sqs_queue.main[*].url)
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role"
  value       = one(aws_iam_role.sagemaker[*].arn)
}

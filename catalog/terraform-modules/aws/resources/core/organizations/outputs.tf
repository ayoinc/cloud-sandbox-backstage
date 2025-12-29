output "organization_id" {
  description = "The ID of the organization."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The ARN of the organization."
  value       = aws_organizations_organization.this.arn
}

output "organization_master_account_id" {
  description = "The AWS account ID of the organization's master account."
  value       = aws_organizations_organization.this.master_account_id
}

output "roots" {
  description = "List of organization roots."
  value       = aws_organizations_organization.this.roots
}

output "organizational_unit_ids" {
  description = "Map of organizational unit names to their IDs."
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.id }
}

output "account_ids" {
  description = "Map of account names to their IDs."
  value       = { for name, account in aws_organizations_account.this : name => account.id }
}

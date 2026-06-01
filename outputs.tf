output "production_account_id" {
  description = "Production AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "trusted_account_id" {
  description = "Trusted Development Account ID"
  value       = var.trusted_account_id
}

output "readonly_role_arn" {
  description = "ReadOnly Cross-Account Role ARN"
  value       = try(aws_iam_role.readonly_role[0].arn, null)
}

output "readonly_role_name" {
  description = "ReadOnly Cross-Account Role Name"
  value       = try(aws_iam_role.readonly_role[0].name, null)
}

output "developer_role_arn" {
  description = "Developer Cross-Account Role ARN"
  value       = try(aws_iam_role.developer_role[0].arn, null)
}

output "developer_role_name" {
  description = "Developer Cross-Account Role Name"
  value       = try(aws_iam_role.developer_role[0].name, null)
}

output "auditor_role_arn" {
  description = "Auditor Cross-Account Role ARN"
  value       = try(aws_iam_role.auditor_role[0].arn, null)
}

output "auditor_role_name" {
  description = "Auditor Cross-Account Role Name"
  value       = try(aws_iam_role.auditor_role[0].name, null)
}

output "cloudtrail_s3_bucket" {
  description = "CloudTrail Logs S3 Bucket"
  value       = try(aws_s3_bucket.cloudtrail_logs[0].id, null)
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = try(aws_cloudtrail.cross_account_audit[0].arn, null)
}

output "iam_audit_log_group" {
  description = "IAM Audit CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.iam_audit.name
}

output "assume_readonly_role_command" {
  description = "Command to assume ReadOnly role from Development account"
  value       = var.create_readonly_role ? "aws sts assume-role --role-arn ${aws_iam_role.readonly_role[0].arn} --role-session-name cross-account-session" : null
}

output "assume_developer_role_command" {
  description = "Command to assume Developer role from Development account"
  value       = var.create_developer_role ? "aws sts assume-role --role-arn ${aws_iam_role.developer_role[0].arn} --role-session-name cross-account-session" : null
}

output "assume_auditor_role_command" {
  description = "Command to assume Auditor role from Development account"
  value       = var.create_auditor_role ? "aws sts assume-role --role-arn ${aws_iam_role.auditor_role[0].arn} --role-session-name cross-account-session" : null
}

output "cross_account_summary" {
  description = "Cross-Account IAM Setup Summary"
  value = {
    production_account_id = data.aws_caller_identity.current.account_id
    trusted_account_id    = var.trusted_account_id
    readonly_role         = try(aws_iam_role.readonly_role[0].name, null)
    developer_role        = try(aws_iam_role.developer_role[0].name, null)
    auditor_role          = try(aws_iam_role.auditor_role[0].name, null)
    session_duration      = var.cross_account_session_duration
    cloudtrail_enabled    = var.enable_cloudtrail
    cloudtrail_bucket     = try(aws_s3_bucket.cloudtrail_logs[0].id, null)
    audit_log_group      = aws_cloudwatch_log_group.iam_audit.name
  }
}
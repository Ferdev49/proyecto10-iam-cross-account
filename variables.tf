variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "proyecto10"
}

variable "production_account_id" {
  description = "Production AWS Account ID"
  type        = string
  default     = "905308587972"  # Tu cuenta actual (simularemos que es Production)
}

variable "trusted_account_id" {
  description = "Development AWS Account ID (que confía Production)"
  type        = string
  default     = "111111111111"  # Cuenta de desarrollo (remota)
}

variable "enable_mfa_requirement" {
  description = "Require MFA for critical actions"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "cross_account_session_duration" {
  description = "Duration of cross-account session in seconds"
  type        = number
  default     = 3600  # 1 hora
}

variable "create_readonly_role" {
  description = "Create read-only cross-account role"
  type        = bool
  default     = true
}

variable "create_developer_role" {
  description = "Create developer cross-account role"
  type        = bool
  default     = true
}

variable "create_auditor_role" {
  description = "Create auditor cross-account role"
  type        = bool
  default     = true
}
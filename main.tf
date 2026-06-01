# ===== CLOUDTRAIL FOR AUDIT LOGGING =====
resource "aws_s3_bucket" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.project_name}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-cloudtrail-logs"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "cross_account_audit" {
  count                      = var.enable_cloudtrail ? 1 : 0
  name                       = "${var.project_name}-audit-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail_logs[0].id
  include_global_service_events      = true
  is_multi_region_trail      = true
  enable_log_file_validation = true
  depends_on                 = [aws_s3_bucket_policy.cloudtrail_logs[0]]

  tags = {
    Name = "${var.project_name}-audit-trail"
  }
}

# ===== GET CURRENT ACCOUNT ID =====
data "aws_caller_identity" "current" {}

# ===== POLICY DOCUMENT: READ ONLY =====
data "aws_iam_policy_document" "readonly_policy" {
  statement {
    sid    = "RDSReadOnly"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2ReadOnly"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:ListBucketVersions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchReadOnly"
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudTrailReadOnly"
    effect = "Allow"
    actions = [
      "cloudtrail:LookupEvents",
      "cloudtrail:DescribeTrails",
      "cloudtrail:ListTrails"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyDangerousActions"
    effect    = "Deny"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteVolume",
      "rds:DeleteDBInstance",
      "rds:DeleteDBCluster",
      "s3:DeleteObject",
      "s3:DeleteBucket"
    ]
    resources = ["*"]
  }
}

# ===== POLICY DOCUMENT: DEVELOPER =====
data "aws_iam_policy_document" "developer_policy" {
  statement {
    sid    = "RDSModify"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:ModifyDBInstance",
      "rds:ModifyDBCluster",
      "rds:CreateDBSnapshot",
      "rds:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2Operations"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:RebootInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:ModifySecurityGroupRules"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3Operations"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:ListBucketVersions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchFullAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudTrailReadOnly"
    effect = "Allow"
    actions = [
      "cloudtrail:LookupEvents",
      "cloudtrail:DescribeTrails",
      "cloudtrail:ListTrails"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyIAMChanges"
    effect    = "Deny"
    actions = [
      "iam:*"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyDeletion"
    effect    = "Deny"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteVolume",
      "rds:DeleteDBInstance",
      "rds:DeleteDBCluster",
      "s3:DeleteObject",
      "s3:DeleteBucket"
    ]
    resources = ["*"]
  }
}

# ===== POLICY DOCUMENT: AUDITOR =====
data "aws_iam_policy_document" "auditor_policy" {
  statement {
    sid    = "CloudTrailAudit"
    effect = "Allow"
    actions = [
      "cloudtrail:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMReadOnly"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CostExplorer"
    effect = "Allow"
    actions = [
      "ce:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BudgetsReadOnly"
    effect = "Allow"
    actions = [
      "budgets:Describe*",
      "budgets:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyAllModifications"
    effect    = "Deny"
    actions = [
      "*"
    ]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["global"]
    }
  }
}

# ===== READONLY ROLE =====
resource "aws_iam_role" "readonly_role" {
  count              = var.create_readonly_role ? 1 : 0
  name               = "${var.project_name}-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = var.cross_account_session_duration

  tags = {
    Name = "${var.project_name}-readonly-role"
  }
}

resource "aws_iam_role_policy" "readonly_policy" {
  count  = var.create_readonly_role ? 1 : 0
  name   = "${var.project_name}-readonly-policy"
  role   = aws_iam_role.readonly_role[0].id
  policy = data.aws_iam_policy_document.readonly_policy.json
}

# ===== DEVELOPER ROLE =====
resource "aws_iam_role" "developer_role" {
  count              = var.create_developer_role ? 1 : 0
  name               = "${var.project_name}-developer-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = var.cross_account_session_duration

  tags = {
    Name = "${var.project_name}-developer-role"
  }
}

resource "aws_iam_role_policy" "developer_policy" {
  count  = var.create_developer_role ? 1 : 0
  name   = "${var.project_name}-developer-policy"
  role   = aws_iam_role.developer_role[0].id
  policy = data.aws_iam_policy_document.developer_policy.json
}

# ===== AUDITOR ROLE =====
resource "aws_iam_role" "auditor_role" {
  count              = var.create_auditor_role ? 1 : 0
  name               = "${var.project_name}-auditor-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = var.cross_account_session_duration

  tags = {
    Name = "${var.project_name}-auditor-role"
  }
}

resource "aws_iam_role_policy" "auditor_policy" {
  count  = var.create_auditor_role ? 1 : 0
  name   = "${var.project_name}-auditor-policy"
  role   = aws_iam_role.auditor_role[0].id
  policy = data.aws_iam_policy_document.auditor_policy.json
}

# ===== CLOUDWATCH LOG GROUP FOR IAM ACTIONS =====
resource "aws_cloudwatch_log_group" "iam_audit" {
  name              = "/aws/iam/${var.project_name}-audit"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-iam-audit"
  }
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "label_original" {
  source    = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.24.1"
  enabled   = var.enabled
  namespace = var.namespace
  stage     = var.stage
  name      = var.name
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.24.1"
  enabled    = var.enabled
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

resource "aws_iam_role" "default" {
  count              = var.enabled ? 1 : 0
  name               = module.label.id
  assume_role_policy = data.aws_iam_policy_document.role.json
}

data "aws_iam_policy_document" "role" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_policy" "default" {
  count  = var.enabled ? 1 : 0
  name   = module.label.id
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.permissions.json
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid = ""

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "iam:PassRole",
      "ecs:RegisterTaskDefinition", # Required by AWS to be granted on resources: *
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }

  dynamic "statement" {
    for_each = length(var.ecr_arns) > 0 ? ["true"] : []
    content {
      sid = "EcrPermissions"
      actions = [
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]
      effect    = "Allow"
      resources = var.ecr_arns
    }
  }

  statement {
    sid = "DedicatedEcsPermissions"
    actions = [
      "ecs:DescribeTasks",
      "ecs:StopTask",
      "ecs:RunTask",
      "ecs:UpdateService",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${module.label_original.id}*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${module.label_original.id}",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${module.label_original.id}*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.label_original.id}*",
    ]
  }

  statement {
    sid = "LogsPermissions"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.label_original.id}*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${module.label_original.id}*:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:destination:${module.label_original.id}*",
    ]
  }
  statement {
    sid = "ParametersPermissions"
    actions = [
      "ssm:GetParameters",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/drone/${module.label_original.id}/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = var.enabled ? 1 : 0
  policy_arn = join("", aws_iam_policy.default.*.arn)
  role       = join("", aws_iam_role.default.*.id)
}

resource "aws_iam_user" "builder" {
  count = var.enabled ? 1 : 0

  name = module.label.id
  //path = "/system/"

  tags = var.tags
}

resource "aws_iam_access_key" "builder_key" {
  count = var.enabled ? 1 : 0
  user  = join("", aws_iam_user.builder.*.name)
}

resource "aws_iam_user_policy_attachment" "default" {
  count      = var.enabled ? 1 : 0
  user       = join("", aws_iam_user.builder.*.name)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_ssm_parameter" "secret_key" {
  count       = var.enabled ? 1 : 0
  name        = "/drone/${module.label.id}/iam_user_secret_key"
  description = "IAM secret key"
  type        = "SecureString"
  value       = join("", aws_iam_access_key.builder_key.*.secret)
  tags        = var.tags
}

resource "aws_ssm_parameter" "access_key" {
  count       = var.enabled ? 1 : 0
  name        = "/drone/${module.label.id}/iam_user_access_key"
  description = "IAM access key"
  type        = "SecureString"
  value = element(
    concat(
      aws_iam_access_key.builder_key.*.id,
      [""],
    ),
    0,
  )
  tags = var.tags
}


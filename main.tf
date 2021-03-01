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
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:RunTask",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
    ]

    effect = "Allow"

    resources = [
      "*",
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


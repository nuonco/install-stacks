data "aws_caller_identity" "current" {}

# The region is derived rather than taken as a variable on purpose. The same value has
# to appear in three places — kms:ViaService below, ctl-api's MANAGEMENT_REGION, and the
# NUON_PHONE_HOME_SECRET_REGION baked into every customer's Lambda — and deriving it
# from the provider makes all three agree by construction. It is surfaced as the
# `management_region` output so there is nothing to retype.
data "aws_region" "current" {}

#
# CMK
#
# A customer-managed key is required rather than aws/secretsmanager: the AWS-managed
# key's policy cannot be edited and is scoped to kms:CallerAccount, so a customer
# principal fails kms:Decrypt no matter how permissive the secret's resource policy is.
#
data "aws_iam_policy_document" "phone_home_key" {
  # Standard non-orphaning statement. It is also why the ctl-api role needs no entry of
  # its own: same-account access resolves through its identity policy.
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # The cross-account read, granted once rather than per customer account.
  #
  # Enumerating target accounts here was the original design and does not work alongside
  # Terraform: PutKeyPolicy is a full replacement, so ctl-api adding a customer would
  # revert on the next apply and show as drift in between. It also caps out at the 32KB
  # key-policy limit, somewhere in the low hundreds of accounts.
  #
  # This is not looser in practice. kms:ViaService means the key can only be used
  # *through* Secrets Manager on a caller's behalf, and to get there the caller must
  # already hold GetSecretValue on a specific secret — which each secret's own resource
  # policy grants to exactly one role. The PrincipalArn condition is defence in depth on
  # top of that: phone-home Lambda roles are deterministically named
  # <install_id>-phone-home.
  #
  # Note kms:ViaService names the region of the *secret* — this account's region — not
  # the customer's install region. One statement therefore covers every region.
  statement {
    sid    = "AllowPhoneHomeLambdaDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/${local.phone_home_role_name_pattern}"]
    }
  }
}

resource "aws_kms_key" "phone_home" {
  description             = "Encrypts Nuon install phone-home secrets."
  policy                  = data.aws_iam_policy_document.phone_home_key.json
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = var.tags
}

resource "aws_kms_alias" "phone_home" {
  name          = "alias/${var.name_prefix}-phone-home"
  target_key_id = aws_kms_key.phone_home.key_id
}

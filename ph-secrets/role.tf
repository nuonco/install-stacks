#
# The role ctl-api assumes to manage phone-home secrets
#
# ctl-api holds no AWS credentials on GCP. Its service account mints a Google-signed
# OIDC token from the GKE metadata server and exchanges it for temporary AWS credentials
# via sts:AssumeRoleWithWebIdentity. accounts.google.com is a built-in AWS web-identity
# provider, so no aws_iam_openid_connect_provider is required.
#
data "aws_iam_policy_document" "phone_home_secrets_trust" {
  statement {
    sid     = "AllowCtlAPIGoogleSAWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["accounts.google.com"]
    }

    # Bound on :sub only, and deliberately not on :aud. For the accounts.google.com
    # issuer AWS substitutes the token's `azp` (authorized party) claim for the
    # accounts.google.com:aud condition key whenever azp is present, and Google service
    # account identity tokens always set azp to the SA's numeric id — so an :aud
    # condition would be compared against the same value as :sub and can never match the
    # requested audience. :sub uniquely pins the service account, which is the binding
    # that matters.
    condition {
      test     = "StringEquals"
      variable = "accounts.google.com:sub"
      values   = [var.ctl_api_sa_unique_id]
    }
  }

  dynamic "statement" {
    for_each = length(var.additional_trusted_role_arns) > 0 ? [1] : []

    content {
      sid     = "AllowAdditionalPrincipals"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.additional_trusted_role_arns
      }
    }
  }
}

data "aws_iam_policy_document" "phone_home_secrets_access" {
  # Every verb maps to a call in ctl-api's internal/pkg/secretsmanager/service.go.
  # PutResourcePolicy is the cross-account grant; RestoreSecret is what lets an install
  # be re-provisioned after its secret was deleted. The trailing wildcard covers the
  # random 6-char suffix AWS appends to every secret ARN.
  statement {
    sid    = "ManagePhoneHomeSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:DeleteSecret",
      "secretsmanager:RestoreSecret",
      "secretsmanager:TagResource",
    ]
    resources = [local.secret_arn_pattern]
  }

  # No GetKeyPolicy/PutKeyPolicy: the key policy is static and Terraform owns it.
  statement {
    sid    = "UsePhoneHomeCMK"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.phone_home.arn]
  }
}

resource "aws_iam_role" "phone_home_secrets" {
  name               = "${var.name_prefix}-phone-home-secrets"
  description        = "Assumed by the Nuon ctl-api GCP service account to manage install phone-home secrets."
  assume_role_policy = data.aws_iam_policy_document.phone_home_secrets_trust.json

  tags = var.tags
}

resource "aws_iam_policy" "phone_home_secrets_access" {
  name   = "${var.name_prefix}-phone-home-secrets"
  policy = data.aws_iam_policy_document.phone_home_secrets_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "phone_home_secrets_access" {
  role       = aws_iam_role.phone_home_secrets.name
  policy_arn = aws_iam_policy.phone_home_secrets_access.arn
}

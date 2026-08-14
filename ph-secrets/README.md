# ph-secrets

Terraform module that creates the **AWS-side infrastructure for Nuon phone-home authentication**, for operators running
`ctl-api` on GCP.

Apply it in the AWS account you want your installs' phone-home secrets to live in. It creates:

- a **KMS CMK** (`alias/<name_prefix>-phone-home`) that encrypts every phone-home secret, with a key policy allowing
  your installs' phone-home Lambdas to decrypt cross-account,
- an **IAM role** (`<name_prefix>-phone-home-secrets`) that your GCP `ctl-api` service account assumes via web-identity
  federation, with exactly the Secrets Manager and KMS permissions ctl-api needs.

The **secrets themselves are not managed here.** They are per install, named `nuon/phone-home/<install_id>`, and created
at runtime by ctl-api. Each holds a `phone_home_id → Nuon token` map that the install's phone-home Lambda fetches at
invocation, and carries a resource policy naming exactly one role in exactly one of your customers' accounts. That
resource policy is where per-install isolation lives; this module is the account-level scaffolding it needs.

## Why the secret lives in AWS even though ctl-api runs on GCP

The reader is a CloudFormation custom-resource Lambda in your customer's AWS account, and Secrets Manager is the only
secret store it can reach. Where the control plane runs changes only _how ctl-api authenticates to AWS_, which is what
the federated role below is for.

## Usage

```hcl
provider "aws" {
  region = "us-west-2"
}

module "phone_home_secrets" {
  source = "github.com/nuonco/install-stacks//ph-secrets"

  ctl_api_sa_unique_id = "112925175524898131819"
}

output "ctl_api_config" {
  value = module.phone_home_secrets.ctl_api_config
}
```

## Getting `ctl_api_sa_unique_id`

The **numeric `unique_id`** of the GCP service account ctl-api runs as — **not its email**:

```bash
gcloud iam service-accounts describe <sa-email> --format='value(uniqueId)'
```

Passing the email is the most common mistake here. The module rejects it at plan time; without that check it would
surface much later as an opaque `AccessDenied` the first time an install provisions.

**Prerequisite:** the service account must be bound to the ctl-api pod via GKE Workload Identity. If it is not, the
metadata server hands out the _node's_ default service account instead, whose `sub` will not match the trust policy.

## Configuring ctl-api

Three values, all in the `ctl_api_config` output:

| Output field                      | ctl-api config                    | Notes                                        |
| --------------------------------- | --------------------------------- | -------------------------------------------- |
| `AWS_PHONE_HOME_SECRETS_ROLE_ARN` | `aws_phone_home_secrets_role_arn` | The role ctl-api assumes; required on GCP    |
| `AWS_PHONE_HOME_CMK_ARN`          | `aws_phone_home_cmk_arn`          | Encrypts the secrets                         |
| `MANAGEMENT_REGION`               | `management_region`               | Region of the _secret_, not of your installs |

All three must be set. If `aws_phone_home_secrets_role_arn` is missing, ctl-api cannot reach Secrets Manager and
silently skips phone-home auth for every install — it logs a warning and returns success, so the feature is simply off.

`MANAGEMENT_REGION` is derived from your provider's region rather than taken as a variable, because the same value has
to reach three places that must agree: `kms:ViaService` in the key policy, ctl-api's config, and the
`NUON_PHONE_HOME_SECRET_REGION` environment variable baked into each customer's Lambda.

## How ctl-api reaches AWS from GCP

1. Its GCP service account (bound to the pod via Workload Identity) mints a Google-signed OIDC token from the metadata
   server.
2. ctl-api calls `sts:AssumeRoleWithWebIdentity` against `<name_prefix>-phone-home-secrets`.
3. The returned temporary credentials are used with the Secrets Manager and KMS SDKs.

`accounts.google.com` is a built-in AWS web-identity provider, so no `aws_iam_openid_connect_provider` resource is
required.

The trust policy is scoped to `accounts.google.com:sub == ctl_api_sa_unique_id` **and nothing else** — in particular,
not to `aud`. For the `accounts.google.com` issuer, AWS substitutes the token's `azp` (authorized party) claim for the
`accounts.google.com:aud` condition key whenever `azp` is present, and Google service-account identity tokens always set
`azp` to the SA's numeric id. An `aud` condition would therefore be compared against the same value as `sub` and could
never match the requested audience. `sub` uniquely pins the service account, which is the binding that matters.

## The CMK key policy

One statement grants `kms:Decrypt` to `Principal: "*"`, conditioned on both:

- `kms:ViaService = secretsmanager.<region>.amazonaws.com`, and
- `aws:PrincipalArn` matching `arn:aws:iam::*:role/*-phone-home`.

This is deliberate, and less permissive than it reads. `kms:ViaService` means the key can only be used _through_ Secrets
Manager on a caller's behalf, and to get there the caller must already hold `GetSecretValue` on a specific secret —
which that secret's own resource policy grants to exactly one role in exactly one account. The `aws:PrincipalArn`
condition is defence in depth on top of that.

The alternative — one statement per customer account — was the original design and does not work alongside Terraform:
`PutKeyPolicy` is a full replacement, so ctl-api adding a customer at runtime would revert on the next apply and show as
drift in between. It also caps out at the 32KB key-policy limit somewhere in the low hundreds of accounts.

## Inputs

| Name                           | Type           | Default  | Required | Description                                                 |
| ------------------------------ | -------------- | -------- | :------: | ----------------------------------------------------------- |
| `ctl_api_sa_unique_id`         | `string`       | —        |   yes    | Numeric `unique_id` of the ctl-api GCP service account      |
| `name_prefix`                  | `string`       | `"nuon"` |    no    | Prefix for the role, policy and KMS alias                   |
| `additional_trusted_role_arns` | `list(string)` | `[]`     |    no    | Extra IAM roles allowed to assume the role, for break-glass |
| `kms_deletion_window_in_days`  | `number`       | `7`      |    no    | Waiting period before the CMK is destroyed                  |
| `enable_key_rotation`          | `bool`         | `true`   |    no    | Annual automatic CMK rotation                               |
| `tags`                         | `map(string)`  | `{}`     |    no    | Tags applied to created resources                           |

The Secrets Manager path (`nuon/phone-home`) and the phone-home role-name pattern (`*-phone-home`) are **not** inputs.
Both are hardcoded in ctl-api, so the only reachable effect of changing them here would be to make the IAM grant stop
matching what ctl-api does. They are `locals` in [variables.tf](./variables.tf) with comments naming the Go functions
they track.

## Outputs

| Name                           | Description                                                     |
| ------------------------------ | --------------------------------------------------------------- |
| `ctl_api_config`               | Map of all three ctl-api config values                          |
| `phone_home_cmk_arn`           | CMK ARN                                                         |
| `phone_home_cmk_alias`         | CMK alias                                                       |
| `phone_home_secrets_role_arn`  | Role ARN ctl-api assumes                                        |
| `phone_home_secrets_role_name` | Role name                                                       |
| `management_region`            | Region the CMK and secrets live in                              |
| `secret_arn_pattern`           | ARN pattern the role is scoped to, for debugging `AccessDenied` |

## Troubleshooting

**Installs provision but `phone_home_auth.secret_arn` is never set.** ctl-api is skipping. Check that all three config
values are set; a missing role ARN makes ctl-api log `no path to management secrets manager` and continue.

**`AccessDenied` on `CreateSecret`.** Compare the secret name ctl-api is using against the `secret_arn_pattern` output.

**`Not authorized to perform sts:AssumeRoleWithWebIdentity`.** Either `ctl_api_sa_unique_id` is not the SA actually
bound to the pod, or Workload Identity is not configured and the metadata server is returning the node SA. Confirm with:

```bash
gcloud iam service-accounts describe <sa-email> --format='value(uniqueId)'
```

**The customer's Lambda fails on `kms:Decrypt`.** Its role must be named `<install_id>-phone-home` to match the key
policy's `aws:PrincipalArn` condition. ctl-api names it that way; a stack whose role predates named roles needs a stack
update.

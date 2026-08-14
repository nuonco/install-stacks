# Stack templates

An **install stack template** is the infrastructure-as-code module that a customer applies in their own cloud account to provision an install stack and boot up the Nuon runner.

A stack template needs to perform the following tasks, in this order.

1. Provision the network the app will be deployed into.
1. Provision the roles the runner will assume to manage resources in the network.
1. Provision the runner host.
1. Phone home to the control plane to signal that the stack is provisioned.

If deploying the runner into an existing network, most or all of the network resources may already exist.
You may already have a VPC or even a Kubernetes cluster you want to deploy the runner into.
In that case, the stack can simply gather information about those resources — using, for example, Terraform data sources — and export it so it's available in the install state for the app to reference.
See [Required outputs](#required-outputs) for details.

## Lifecycle

1. When an install is created, the control plane generates an `install.auto.tfvars` file with the required variable values.
2. The customer applies the stack to their account.
3. On every successful apply, the stack phones home to the control plane to signal that it is active.
4. When a stack is destroyed, the stack phones home with `request_type: "Delete"`, signaling that it is no longer active.

## Inputs the control plane provides

The values for all required inputs will be provided by the control plane.

| Input                                                   | Purpose                                                                                                         |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `nuon_install_id`, `nuon_org_id`, `nuon_app_id`         | Identity of the install; `nuon_install_id` is the naming prefix                                                 |
| `runner_id`, `runner_api_url`                           | Passed through to the runner host (see the bootstrap contract in [The Nuon runner](the-nuon-runner.md)) |
| `phone_home_url`                                        | Where to POST results                                                                                           |
| `nuon_support_iam_role_arns`                            | Principals that must be able to assume the operation roles                                                      |
| `provision_*` / `maintenance_*` / `deprovision_*`       | Permissions for the three operation roles                                                                       |
| `break_glass_roles` / `custom_roles`                    | Optional named roles, each with an `enabled` flag                                                               |
| `secrets` / `auto_generate_secrets`                     | Secrets to store / generate                                                                                     |
| `install_inputs`                                        | Customer-supplied input values, echoed back in phone-home                                                       |
| Deployment target (`aws_region`, GCP project/region, …) | Selected when the install is created                                                                            |

> [!NOTE]
> GCP does not require a region or project ID to be provided at install creation time. The customer may have to provide these themselves when running the stack.

## What the stack must provision

### Network

The network topology the app will be deployed into. The stacks in this repo create a dedicated VPC/network with the following resources.

- **Public subnets** — for internet-facing resources (load balancers, NAT/internet gateways).
- **Private subnets** — for the app's workload infrastructure (e.g. Kubernetes clusters), with outbound internet access via NAT.
- A **runner subnet** — a private subnet dedicated to the runner host with outbound internet access.

The exact layout is up to the template, but all templates must fulfill the following requirements.

- The runner's subnet must have **outbound internet access** in order to reach the Nuon control plane.
- Subnets should carry the discovery tags described in [Naming and tagging](#naming-and-tagging) if you are using one of our open-source sandboxes.
- Report network info in the phone-home request (see [Required output keys](#required-outputs) for details).

### Runner host

A host in the runner subnet that boots the runner. The full host contract (tags, instance profile, init script, outbound destinations) is in [The Nuon runner](the-nuon-runner.md).

### Operation roles

The runner assumes one of the provisioned roles for every job it runs.

- **provision** — used by default for provision workflows and secret syncs
- **deprovision** — used by default for deprovision workflows
- **maintenance** — used by default for all other jobs
- **customer** — used as configured in the app config, overriding the default roles
- **break-glass** — used for special break-glass operations when elevated permissions are needed. Disabled by default

Rules the template must follow:

- **Trust policy**: each role must be assumable by (a) the `nuon_support_iam_role_arns` principals (fall back to the account root if the list is empty) and (b) the runner's own identity. On AWS this means an IAM trust policy naming both; on GCP the equivalent is `roles/iam.serviceAccountTokenCreator` grants on per-operation service accounts.
- **Permission shapes**: `inline_policy_document` (full policy JSON, preserves resource/condition scoping) takes precedence over `permissions` (a list of action strings, granted on all resources), and `managed_policy_arns` attach in addition.
- **Enable semantics**: an operation role is created only if it has any permissions; a disabled role must still appear in the phone-home payload with an **empty string** ARN — omit the key and role lookup breaks.
- The runner's identity must be allowed to assume every enabled role (on AWS: `sts:AssumeRole` on each role ARN).

If a job's configuration names a role that is missing from the stack outputs, the job fails with a "role not found in install stack outputs" error — so custom/break-glass roles referenced by the app config must exist and be reported.

### Secrets

- Store each entry in the platform's secret manager, named `<install-id>-<secret-name>`.
- For `auto_generate_secrets`, generate the value in the stack (the stacks in this repo use 63-char random strings, no special characters) and never rotate it on re-apply.
- Create an **empty** `nuon/<install-id>/telemetry-export-config` secret; the customer uploads its value out-of-band.
- Grant the runner's identity read access.
- Report each secret's identifier in phone-home as `<secret_name>_arn` (AWS), `<secret_name>_secret_name` (GCP), or `<secret_name>_secret_id` (Azure). A `required` secret missing from the outputs makes secret-sync jobs fail.

### Naming and tagging

- Prefix all resources with the install ID.
- Tag resources with `install.nuon.co/id` and `nuon_install_id`.
- If the install will host a Kubernetes cluster, tag the subnets with `kubernetes.io/cluster/<cluster_name>` (where `cluster_name` is the install input of that name, defaulting to the install ID) and with `network.nuon.co/domain` = `public` / `internal` / `runner` so downstream components can discover them.

## Phone home

**Endpoint:** `POST {phone_home_url}` — which resolves to `/v1/installs/{install_id}/phone-home/{phone_home_id}` on the Nuon API.

**When:** on every apply (the Terraform stacks in this repo use a `null_resource` with a `timestamp()` trigger, depending on all roles/secrets/network resources so outputs are complete), and once with `request_type: "Delete"` on teardown (no auth required for delete).

**Body:** a flat JSON object containing:

- `request_type` — `"Create"`, `"Update"`, or `"Delete"` (required)
- The output keys below, at the top level

See [`aws/phone_home.tf`](../aws/phone_home.tf) and [`gcp/phone_home.tf`](../gcp/phone_home.tf) for working payloads.

**Auth:** if the org has phone-home auth enabled, include the minted phone-home token as `Authorization: Bearer <token>` (the control plane delivers it via a secret in the customer account). The reported `account_id` is also validated against the install's expected account — a mismatch is rejected.

### Required outputs

The control plane detects the cloud from the keys present (`runner_service_account_email` ⇒ GCP, `resource_group_id` ⇒ Azure, otherwise AWS).

AWS:

| Key                                                                              | Notes                                                                                                                  |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `account_id`                                                                     | **Required for runner auth** — instance-identity auth compares against it; if empty, every runner authentication fails |
| `region`, `vpc_id`, `runner_subnet`, `public_subnets`, `private_subnets`         | Network facts; list values are sent comma-joined; consumed as template vars by sandbox/component runs                  |
| `provision_iam_role_arn`, `maintenance_iam_role_arn`, `deprovision_iam_role_arn` | Per-job role selection; empty string if the role wasn't created                                                        |
| `runner_iam_role_arn`                                                            | Written into the runner group settings                                                                                 |
| `break_glass_role_arns`, `custom_role_arns`                                      | Maps of role name → ARN                                                                                                |
| `<secret_name>_arn`                                                              | One per secret, flattened at the top level                                                                             |
| `install_inputs`                                                                 | Echo of the customer inputs; back-fills install state                                                                  |

The GCP equivalents are `project_id`, `region`, `network_name`/`network_id`, `*_subnet_name`, `runner_service_account_email`, `{provision,maintenance,deprovision}_sa_email`, `break_glass_sa_emails`, `custom_sa_emails`, plus the same `install_inputs`.

Two GCP keys deserve extra care:

- `project_id` is **required for runner auth** — the control plane compares it against the project in the runner's identity token and rejects the runner on a mismatch or if it's empty (the GCP analog of `account_id` on AWS).
- `runner_service_account_email` is also the **cloud-detection key** — if it's missing, the control plane parses the payload as an AWS stack.

Expose the same keys as stack outputs (e.g. `terraform output`) so they're inspectable and available as `nuon.install_stack.outputs.*` in app configs.

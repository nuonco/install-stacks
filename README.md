# Nuon Install Stacks

Terraform modules for provisioning the infrastructure required to run the [Nuon runner](https://docs.nuon.co/architecture/platform#install-runner) in a customer's cloud account. Each subdirectory targets a different cloud provider.

- [Amazon Web Services](/aws)
- [Google Cloud Platform](/gcp)
- Microsoft Azure (Coming soon)

Supporting modules for operators running the control plane on GCP:

- [gcp-bucket](/gcp-bucket) — the S3 bucket CloudFormation needs when deploying AWS installs from a GCP-hosted control plane
- [ph-secrets](/ph-secrets) — AWS-side KMS key and role for phone-home authentication secrets

## How to use these modules

When an install is created, the Nuon control plane generates an `install.auto.tfvars` file with the required input values. Save it into the directory for your cloud provider (e.g. `aws/` or `gcp/`), then init and apply the Terraform:

```bash
cd aws/  # or gcp/
terraform init
terraform apply
```

## How to customize or replace these modules

The Nuon runner does not depend on these specific Terraform modules. As long as certain requirements are fulfilled you can create a custom module, or even manage the runner directly. See the stack and runner requirements docs for more information.

- [Stack templates](docs/stack-templates.md) — the contract between the control plane and a stack template (provided inputs, required roles and secrets, the phone-home payload). Start here to build your own stack template for any cloud platform.
- [The Nuon runner](docs/the-nuon-runner.md) — what the Nuon runner needs to start and to pick up and execute jobs (configuration, authentication, network access, host setup). Start here to run the runner yourself.

## GCP

### What gets created

- **VPC & Subnets** – A dedicated VPC with public, private, and runner subnets, a Cloud Router, and a Cloud NAT for outbound internet access.
- **Firewall Rules** – Internal traffic between subnets is allowed; all egress is permitted.
- **Service Account & IAM** – A runner service account with roles for GKE, Compute networking, Artifact Registry, Cloud DNS, and security administration.
- **Runner Instance** – A single-instance managed instance group running an `e2-standard-4` (configurable) Compute Engine VM (Ubuntu 24.04) that bootstraps itself using the Nuon runner init script.
- **Secrets** – Secret Manager entries for auto-generated, customer-provided, and telemetry export configuration.
- **Phone Home** – A `local-exec` provisioner that reports provisioning results back to Nuon.

### Prerequisites

- Terraform ≥ 1.11.0
- Google Cloud provider ≥ 5.0
- A GCP project with the Compute Engine and IAM APIs enabled
- Credentials configured for the `google` provider (e.g. `gcloud auth application-default login`)

### Usage

Your Nuon vendor will provide a `.tfvars` file containing the configuration for your install. It will look like this:

```hcl
nuon_install_id        = "inl4xabsyaqxp0cb2oy5l8urvf"
nuon_org_id            = "orgnwi4odoca7y0z9wddc1767e"
nuon_app_id            = "appk2o58477kw8jbounuxpkaqr"
runner_api_url         = "https://api.nuon.co/runner"
runner_id              = "run4dbg9i5fzwdlq7zk1llbout"
runner_init_script_url = "https://raw.githubusercontent.com/nuonco/runner/refs/heads/main/scripts/gcp/init.sh"
phone_home_url         = "https://api.nuon.co/api/v1/installs/inl4xabsyaqxp0cb2oy5l8urvf/phone-home/aws3no0qz8sxsbqa13dgs2pfb3"
```

Save this file as `install.auto.tfvars` (or any `*.auto.tfvars` name) inside the `gcp/` directory so Terraform loads it automatically. If you use a different name (e.g. `install.tfvars`), pass it explicitly with `-var-file=install.tfvars` on every plan and apply.

The vendor will also provide a **runner API token**. Export it as an environment variable so Terraform can pick it up without storing it on disk:

```bash
export TF_VAR_runner_api_token="<token provided by your vendor>"
```

Then run:

```bash
cd gcp/

# Optionally configure a remote backend
cp backend.tf.example backend.tf
# Edit backend.tf with your GCS bucket details

terraform init
terraform plan
terraform apply
```

To export runner audit logs and other telemetry to your own backend, see [Telemetry export](docs/the-nuon-runner.md#telemetry-export-optional).

If the GCP project and region were selected when the install was created, they are included in the generated tfvars; otherwise Terraform prompts for them at apply time:

| Variable         | Description                       |
| ---------------- | --------------------------------- |
| `gcp_project_id` | The GCP project to provision into |
| `gcp_region`     | The GCP region for all resources  |

### Outputs

| Output                                                  | Description                                        |
| ------------------------------------------------------- | -------------------------------------------------- |
| `project_id`                                            | GCP project ID                                     |
| `region`                                                | Provisioned region                                 |
| `network_name`, `network_id`                            | VPC network name and ID                            |
| `public_subnet_name`, `private_subnet_name`, `runner_subnet_name` | Subnet names                             |
| `runner_service_account_email`                          | Runner service account email                       |
| `{provision,maintenance,deprovision}_sa_email`          | Operation service account emails (empty if not created) |
| `break_glass_sa_emails`, `custom_sa_emails`             | Maps of role name → service account email          |
| `gke_node_pool_sa_email`                                | GKE node pool service account email                |
| `secret_names`                                          | Map of secret name → Secret Manager secret ID      |
| `install_inputs`                                        | Echo of the customer-supplied install inputs       |
| `custom_nested_stacks`                                  | Outputs of any curated custom stack modules        |

Each service account output also has a `*_unique_id` counterpart. See [`gcp/outputs.tf`](gcp/outputs.tf) for the full list.

## License

See [LICENSE](LICENSE) for details.

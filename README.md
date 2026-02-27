# Nuon Install Stacks

Terraform modules that provision the infrastructure required to run [Nuon](https://nuon.co) in your cloud account. Each subdirectory targets a specific cloud provider and sets up networking, IAM, and a runner instance that phones home to the Nuon control plane.

## Supported Clouds

| Provider | Directory | Status |
|----------|-----------|--------|
| GCP      | [`gcp/`](gcp/) | ✅ Available |

## GCP

### What gets created

- **VPC & Subnets** – A dedicated VPC with public, private, and runner subnets, a Cloud Router, and a Cloud NAT for outbound internet access.
- **Firewall Rules** – Internal traffic between subnets is allowed; all egress is permitted.
- **Service Account & IAM** – A runner service account with roles for GKE, Compute networking, Artifact Registry, Cloud DNS, and security administration.
- **Runner Instance** – An `e2-medium` Compute Engine VM (Ubuntu 22.04) that bootstraps itself using the Nuon runner init script.
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
phone_home_url         = "https:/api.nuon.co/api/v1/installs/inl4xabsyaqxp0cb2oy5l8urvf/phone-home/aws3no0qz8sxsbqa13dgs2pfb3"
```

Save this file as `terraform.tfvars` (or any `*.tfvars` name) inside the `gcp/` directory.

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

You will be prompted for the two customer-supplied values:

| Variable | Description |
|----------|-------------|
| `gcp_project_id` | The GCP project to provision into |
| `gcp_region` | The GCP region for all resources |

### Outputs

| Output | Description |
|--------|-------------|
| `project_id` | GCP project ID |
| `region` | Provisioned region |
| `network_name` | VPC network name |
| `network_id` | VPC network ID |
| `public_subnet_name` | Public subnet name |
| `private_subnet_name` | Private subnet name |
| `runner_subnet_name` | Runner subnet name |
| `runner_service_account_email` | Runner service account email |

## License

See [LICENSE](LICENSE) for details.

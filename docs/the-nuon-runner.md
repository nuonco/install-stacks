# The Nuon runner

The Nuon runner does not depend on any specific install stack template. As long as the requirements below are fulfilled, you can bring your own Terraform, use another provisioning tool, or run the runner directly on infrastructure you manage. (If you're building a custom template rather than running the runner by hand, see [Stack templates](stack-templates.md) for the provisioning contract.)

## What the runner is

The runner is a Go binary that runs in two cooperating processes:

- **Management process (`mng`)** – runs on the host (as a systemd service on VMs), supervises the install process, and handles management jobs from the control plane (update, restart, shutdown).
- **Install process (`runner install`)** – runs in a Docker container started by `mng`, polls the control plane for jobs (Terraform, Helm, Pulumi, Kubernetes manifests, secret syncs, action workflows) and executes them.

Both processes are outbound-only: they poll the Nuon control plane over HTTPS. The control plane never opens a connection to the runner.

## Configuration

All configuration is read from environment variables:

| Variable             | Required | Purpose                                                                                                             |
| -------------------- | -------- | ------------------------------------------------------------------------------------------------------------------- |
| `RUNNER_ID`          | yes      | The runner's identity, issued when the install is created. Appears in every API path (`/v1/runners/<runner_id>/…`). |
| `RUNNER_API_URL`     | yes      | Base URL of the Nuon runner API (e.g. `https://api.nuon.co`).                                                       |
| `RUNNER_API_TOKEN`   | no       | Bearer token for the runner API. If unset, the runner authenticates itself using its cloud identity (see below).    |
| `RUNNER_PLATFORM`    | no       | `aws`, `azure`, or `gcp`; selects the cloud-auth path when no token is set.                                         |
| `RUNNER_AUTH_METHOD` | no       | AWS only: `iid` (instance identity document, default) or `sts` (presigned STS requests).                            |

Everything else — heartbeat interval, job groups, polling mode, the install-process container image and tag, logging/metrics settings — is fetched from the control plane at boot via `GET /v1/runners/<runner_id>/settings` and requires no local configuration.

## Authentication

The runner needs a bearer token for the runner API. There are two ways to get one:

1. **Static token** – set `RUNNER_API_TOKEN` directly (this is how the GCP stack and local/dev setups work). You are responsible for delivering the token to the host securely.
2. **AWS instance identity (used by the AWS stack)** – the runner reads its signed instance identity document (IID) from IMDS and POSTs it (with `RUNNER_ID`) to `/v1/runner-auth/aws-iid`; the control plane verifies it and mints a token. No credential ever needs to be provisioned.

## Network requirements

No inbound connectivity is required. The runner's listeners (local OCI registry cache, health endpoints) bind to localhost only.

Outbound HTTPS must be able to reach:

| Destination                                             | Purpose                                                                                            |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `RUNNER_API_URL` (Nuon control plane)                   | auth, settings, heartbeats, job polling, results, log/trace ingest, Terraform/Pulumi state backend |
| Cloud metadata service (`169.254.169.254`, link-local)  | identity attestation, instance metadata/tags                                                       |
| Cloud provider APIs (STS/EC2, secrets manager, logging) | per-job role assumption, secrets, log shipping                                                     |
| Container registries                                    | pulling the install-process image and job images                                                   |
| `releases.hashicorp.com`, Helm chart repos, git remotes | job tooling and component sources                                                                  |
| `raw.githubusercontent.com`                             | fetching the init script                                                                           |
| Customer OTLP endpoint (optional)                       | telemetry export, if configured                                                                    |

## Host requirements

To run the standard VM setup (what the AWS/GCP stacks provision):

- A Linux host with **systemd** and **Docker** (the init script installs Docker if missing).
- Outbound internet access at boot — the host downloads the init script and container images.
- On AWS: instance tags `nuon_runner_id`, `nuon_runner_api_url`, and `nuon_install_id` on the instance, an instance profile allowing `ec2:DescribeTags`, and IMDSv2 reachable. The init script (`scripts/aws/init-mng-v2.sh` in [nuonco/runner](https://github.com/nuonco/runner)) reads its configuration from these tags.
- Writable `/opt/nuon/runner/` — the init script and `mng` keep the env file, image spec, and API token (mode 0600) there.

Alternatively, you can skip the VM contract entirely and run the runner as a container (ECS, Kubernetes, etc.) by setting `RUNNER_ID`, `RUNNER_API_URL`, and `RUNNER_API_TOKEN` in the container environment.

## Cloud permissions

The runner itself needs only a small standing footprint; job workloads get their permissions from separate, per-operation roles that the runner assumes:

- **Standing (instance/service identity)**: read its own secrets (on AWS: Secrets Manager entries prefixed `<install-id>-` and `nuon/<install-id>/telemetry-export-config`), write logs (CloudWatch log groups `/nuon/<install-id>/runner` and `runner-*`), read its own instance tags, and `sts:AssumeRole` on the operation roles.
- **Per-job (assumed)**: operation roles scoped to what the app's infrastructure actually needs. These are defined by the vendor's app config, not by the runner:
  - **provision** — used by default for provision workflows and secret syncs
  - **deprovision** — used by default for deprovision workflows
  - **maintenance** — used by default for all other jobs
  - **customer** — used as configured in the app config, overriding the default roles
  - **break-glass** — used for special break-glass operations when elevated permissions are needed. Disabled by default

## Telemetry export (optional)

The runner can export its audit logs and other telemetry to a customer-owned backend. The install process runs a telemetry-export supervisor that reads its configuration from a dedicated secret in the customer's secret manager; the stacks in this repo create this secret **without a value** and grant read access only to the runner's identity:

- AWS: Secrets Manager secret `nuon/<install-id>/telemetry-export-config`
- GCP: Secret Manager secret `<install-id>-telemetry-export-config`

To enable export, write a config file (see the [telemetry export reference](https://docs.nuon.co/guides/export-runner-audit-logs) for available settings):

```yaml
version: v1

telemetry:
  logs:
    audit:
      enabled: true

exporters:
  otlphttp:
    endpoint: https://otlp.example.com
    headers:
      Authorization: Bearer <token>
```

Then upload it as a secret version:

```bash
# AWS
aws secretsmanager put-secret-value \
  --secret-id "nuon/<install-id>/telemetry-export-config" \
  --secret-string file://telemetry-export-config.yaml \
  --region "<aws-region>"

# GCP
gcloud secrets versions add "<install-id>-telemetry-export-config" \
  --data-file="telemetry-export-config.yaml" \
  --project="<gcp-project-id>"
```

The configuration stays out of Terraform state. While the secret has no value, telemetry export stays disabled.

## Boot process

The runner boot process has two levels: booting up the runner host, and starting the runner process itself.

### Runner host

On the runner host, the boot process can vary a little per platform, but at a high level follows these steps.

1. The stack launches a VM into the runner subnet with the runner's cloud identity attached and the runner's configuration (`nuon_runner_id`, `nuon_runner_api_url`, `nuon_install_id`) attached as instance tags or metadata.
2. A **boot script** (user data / startup script) waits for outbound HTTPS to succeed — the NAT route may not be ready at first boot — then downloads and runs the Nuon init script from [nuonco/runner](https://github.com/nuonco/runner).
3. The **init script** reads the runner's configuration from the instance tags or metadata, installs Docker if missing, writes the runner's env and token files under `/opt/nuon/runner/`, and starts the runner **management (`mng`) process** as a systemd service.
4. The **mng process** acquires an API token (see [Authentication](#authentication)), fetches its settings from the control plane, registers a process, starts heartbeating, and supervises a Docker container running the **install process** (pulling the runner image the control plane specifies, restarting/updating it as management jobs instruct).
5. The **install process** authenticates the same way, then polls (or long-polls) the control plane for jobs and executes them — Terraform, Helm, Pulumi, Kubernetes manifests, secret syncs, and action workflows — assuming the appropriate operation role per job and streaming status and logs back to the control plane and the platform's log service.

### Runner process

Regardless of how the host is provisioned, when the runner process starts it goes through the following steps.

1. Load config from environment (fail fast if `RUNNER_ID`/`RUNNER_API_URL` missing).
2. Acquire an API token (env var, or cloud-identity auth).
3. Fetch settings from `GET /v1/runners/<runner_id>/settings`.
4. Register a process (`POST /v1/runners/<runner_id>/processes`) and start heartbeating.
5. Poll (or long-poll) `/jobs` per job group and execute jobs, streaming status and logs back to the control plane.

### Updating and restarting

If the control plane needs to update or restart the runner, it does so by enqueueing a management job that the runner picks up on its next poll — never by connecting in.

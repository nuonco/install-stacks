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

## License

See [LICENSE](LICENSE) for details.

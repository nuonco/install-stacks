provider "aws" {
  region = var.aws_region

  # Canonical Nuon tag keys, matching the CloudFormation tagger so customer
  # components see identical tags regardless of which install path was used.
  default_tags {
    tags = {
      "install.nuon.co/id" = var.nuon_install_id
      "nuon_install_id"    = var.nuon_install_id
    }
  }
}

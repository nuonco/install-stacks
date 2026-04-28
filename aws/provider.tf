provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "nuon-install-id" = var.nuon_install_id
      "nuon-org-id"     = var.nuon_org_id
      "nuon-app-id"     = var.nuon_app_id
      "managed-by"      = "nuon"
    }
  }
}

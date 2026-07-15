provider "aws" {
  region = local.region

  default_tags {
    tags = {
      "install.nuon.co/id" = local.nuon_install_id
      "nuon_install_id"    = local.nuon_install_id
    }
  }
}

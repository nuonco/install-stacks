terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.x for data.aws_region.current.region; the 5.x spelling (.name) is
      # deprecated there.
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "teamcity" {
  source = "./modules/teamcity-setup"

  vpc_network = {
    primary_cidr_range   = "192.168.0.0/16"
    availability_zones   = ["a", "b"]
  }
}

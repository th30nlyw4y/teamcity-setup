provider "aws" {
  region = "eu-central-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module "teamcity" {
  source = "./modules/teamcity-setup"

  vpc_network = {
    primary_cidr_range   = "192.168.0.0/16"
    secondary_cidr_range = "192.168.0.0/16"
    availability_zones   = ["a", "b"]
  }
}

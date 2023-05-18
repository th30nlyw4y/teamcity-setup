terraform {
  required_version = "~> 1.4"
  required_providers {
    aws = {
      version = "~> 4.0"
    }
    kubernetes = {
      version = "~> 2.0"
    }
    random = {
      version = "~> 3.5"
    }
  }
}

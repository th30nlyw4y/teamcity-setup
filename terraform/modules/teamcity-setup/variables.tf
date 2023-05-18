# VPC
# ------------------------------------------------------------------------------

variable "vpc_network" {
  description = "VPC configuration"
  type        = object(
    {
      primary_cidr_range   = string
      secondary_cidr_range = string
      availability_zones   = optional(set(string), [])
    }
  )
  default = {
    primary_cidr_range   = ""
    secondary_cidr_range = ""
    availability_zones   = []
  }
}

# EKS
# ------------------------------------------------------------------------------

variable "cluster_name" {
  description = "TeamCity cluster name"
  type        = string
  default     = "tc-eks-cluster"
}

variable "cluster_version" {
  description = "TeamCity cluster version"
  type        = string
  default     = ""
}

variable "server_scaling_config" {
  description = "Scaling config setup for server node pool"
  type        = object({
    desired_nodes = number
    min_nodes     = number
    max_nodes     = number
  })
  default = {
    desired_nodes = 1
    min_nodes     = 1
    max_nodes     = 1
  }
}

variable "agents_scaling_config" {
  description = "Scaling config setup for agents node pool"
  type        = object({
    desired_nodes = number
    min_nodes     = number
    max_nodes     = number
  })
  default = {
    desired_nodes = 1
    min_nodes     = 1
    max_nodes     = 1
  }
}

variable "server_capacity_type" {
  description = "Capacity type selection for server node pool (SPOT|ON_DEMAND)"
  type        = string
  default     = "ON_DEMAND"
}

variable "agents_capacity_type" {
  description = "Capacity type selection for agents node pool (SPOT|ON_DEMAND)"
  type        = string
  default     = "ON_DEMAND"
}

variable "server_machine_types" {
  description = "Machine type selection for server node pool"
  type        = list(string)
  default     = ["ON_DEMAND"]
}

variable "agents_machine_types" {
  description = "Machine type selection for agents node pool"
  type        = list(string)
  default     = ["ON_DEMAND"]
}

# IAM
# ------------------------------------------------------------------------------

variable "cluster_iam_role" {
  description = "User-provided cluster IAM role"
  type        = string
  default     = ""
}

variable "node_iam_role" {
  description = "User-provided node IAM role"
  type        = string
  default     = ""
}

variable "cluster_iam_role_policies" {
  description = "Additional cluster IAM role policies, that need to be attached"
  type        = list(string)
  default     = []
}

variable "node_iam_role_policies" {
  description = "Additional cluster IAM role policies, that need to be attached"
  type        = list(string)
  default     = []
}

# S3
# ------------------------------------------------------------------------------
variable "artifacts_bucket_name" {
  description = "Name for bucket, which will be used to store build artifacts from TeamCity agents"
  type        = string
  default     = "artifacts"
}

# RDS
# ------------------------------------------------------------------------------
variable "database_name" {
  description = "TeamCity database name"
  type        = string
  default     = "teamcity"
}

variable "database_machine_type" {
  description = "Machine type for TeamCity database instance"
  type        = string
  default     = "db.r5b.xlarge"
  // not sure this is enough, so might be changed in the future
}

variable "database_size" {
  description = "TeamCuty database size in GiB"
  type        = number
  default     = 5
}

variable "database_engine" {
  description = "TeamCuty database engine"
  type        = string
  default     = "postgres"
}

variable "database_user" {
  description = "TeamCity database user"
  type        = string
  default     = "teamcity"
}

# Despite it exists, should never be used. It's better to use Vault or some other k/v secret storage
variable "database_password" {
  description = "TeamCity database pasword"
  type        = string
  default     = ""
  sensitive   = true
}

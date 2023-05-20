# Cluster
# ------------------------------------------------------------------------------
output "cluster" {
  description = "Cluster outputs"
  value       = {
    endpoint = aws_eks_cluster.this.endpoint
  }
}

# RDS
# ------------------------------------------------------------------------------
output "rds" {
  description = "RDS outputs"
  value       = {
    hostname = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    username = aws_db_instance.this.username
    database = aws_db_instance.this.db_name
  }
}

# S3
# ------------------------------------------------------------------------------
output "s3" {
  description = "S3 outputs"
  value       = {
    bucket = aws_s3_bucket.artifacts.bucket
  }
}
# ------------------------------------------------------------------------------

locals {

  # Check if we need to create cluster roles automatically
  create_cluster_iam_role = var.cluster_iam_role != "" ? false : true
  create_node_iam_role    = var.node_iam_role != "" ? false : true

  # Minimal required policies for cluster
  #  https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
  cluster_role_default_policies = [
    "AmazonEKSClusterPolicy",
    "AmazonEKSVPCResourceController"
  ]
  #  https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
  node_role_default_policies = [
    "AmazonEBSCSIDriverPolicy",
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly"
  ]

  # Combine defaults + additional roles
  cluster_role_policies = toset(concat(local.cluster_role_default_policies, var.cluster_iam_role_policies))
  node_role_policies    = toset(concat(local.node_role_default_policies, var.node_iam_role_policies))

}

# ------------------------------------------------------------------------------

# Create cluster IAM role if needed
resource "aws_iam_role" "cluster" {
  count = local.create_cluster_iam_role ? 1 : 0

  name               = "teamcity-cluster-role"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "eks.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "teamcity-cluster-role"
    Description = "IAM role for TeamCity cluster"
  }
}

# Add all needed policies to cluster role (AWS-managed)
resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = local.create_cluster_iam_role ? local.cluster_role_policies : []

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.cluster[0].name

  depends_on = [aws_iam_role.cluster]
}

# Create node IAM role if needed
resource "aws_iam_role" "node" {
  count = local.create_cluster_iam_role ? 1 : 0

  name               = "teamcity-node-role"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "ec2.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "teamcity-node-role"
    Description = "IAM role for TeamCity EKS-managed nodes"
  }
}

# Add all needed policies to node role (AWS-managed)
resource "aws_iam_role_policy_attachment" "node" {
  for_each = local.create_node_iam_role ? local.node_role_policies : []

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.node[0].name

  depends_on = [aws_iam_role.node]
}

# Custom policies
# ------------------------------------------------------------------------------

# Required for load balancer provisioning
resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = local.create_node_iam_role ? 1 : 0

  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/files/aws-lb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_lbc_attachment" {
  count = local.create_node_iam_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/${aws_iam_policy.aws_load_balancer_controller[0].name}"
  role       = aws_iam_role.node[0].name

  depends_on = [aws_iam_policy.aws_load_balancer_controller, aws_iam_role.node]
}

# Required for cluster autoscaler controller
resource "aws_iam_policy" "cluster_autoscaler" {
  count = local.create_node_iam_role ? 1 : 0

  name   = "AWSClusterAutoscalerIAMPolicy"
  policy = file("${path.module}/files/cluster-autoscaler-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_cluster_autoscaler_attachment" {
  count = local.create_node_iam_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/${aws_iam_policy.cluster_autoscaler[0].name}"
  role       = aws_iam_role.node[0].name

  depends_on = [aws_iam_policy.cluster_autoscaler, aws_iam_role.node]
}

# Allow S3 access for agents & server
resource "aws_iam_policy" "bucket_read_writer" {
  count = local.create_node_iam_role ? 1 : 0

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.node[0].arn
        },
        Action : [
          "s3:*" // Most likely permissions should be restricted
        ]
        Resource : [
          "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
        ]
      }
    ]
  })

  depends_on = [aws_iam_role.node, aws_s3_bucket.artifacts]
}

resource "aws_iam_role_policy_attachment" "aws_bucket_read_writer_attachment" {
  count = local.create_node_iam_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/${aws_iam_policy.bucket_read_writer[0].name}"
  role       = aws_iam_role.node[0].name

  depends_on = [aws_iam_policy.bucket_read_writer, aws_iam_role.node]
}

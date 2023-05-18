# ------------------------------------------------------------------------------

locals {}

# ------------------------------------------------------------------------------

# Main EKS cluster for TeamCity
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster[0].arn
  version  = var.cluster_version
  vpc_config {
    subnet_ids = [
      for k, v in merge(aws_subnet.public, aws_subnet.private) : v.id
    ]
  }
  # Requires VPC CNI plugin, disabled by default
#  kubernetes_network_config {
#    service_ipv4_cidr = var.vpc_network.secondary_cidr_range
#  }

  depends_on = [aws_subnet.public, aws_subnet.private]
}

# TC server node group
resource "aws_eks_node_group" "servers" {
  cluster_name  = aws_eks_cluster.this.name
  node_role_arn = aws_iam_role.node[0].arn
  subnet_ids    = [
    for k, v in aws_subnet.public : v.id
  ]
  scaling_config {
    desired_size = var.server_scaling_config.desired_nodes
    max_size     = var.server_scaling_config.max_nodes
    min_size     = var.server_scaling_config.min_nodes
  }
  version        = aws_eks_cluster.this.version
  capacity_type  = var.server_capacity_type
  disk_size      = 100
  instance_types = var.server_machine_types

  depends_on = [aws_eks_cluster.this]
}


# TC agents node group
resource "aws_eks_node_group" "agents" {
  cluster_name  = aws_eks_cluster.this.name
  node_role_arn = aws_iam_role.node[0].arn
  subnet_ids    = [
    for k, v in aws_subnet.private : v.id
  ]
  scaling_config {
    desired_size = var.agents_scaling_config.desired_nodes
    max_size     = var.agents_scaling_config.max_nodes
    min_size     = var.agents_scaling_config.min_nodes
  }
  version        = aws_eks_cluster.this.version
  capacity_type  = var.agents_capacity_type
  disk_size      = 100
  instance_types = var.agents_machine_types

  depends_on = [aws_eks_cluster.this]
}

# Necessary addons
resource "aws_eks_addon" "kube_proxy_eks_addon" {
  addon_name   = "kube-proxy"
  cluster_name = aws_eks_cluster.this.name
  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.this
    ]
  }

  depends_on = [aws_eks_node_group.servers, aws_eks_node_group.agents]
}

resource "aws_eks_addon" "coredns_eks_addon" {
  addon_name   = "coredns"
  cluster_name = aws_eks_cluster.this.name
  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.this
    ]
  }

  depends_on = [aws_eks_node_group.servers, aws_eks_node_group.agents]
}

# Disabled by default
#resource "aws_eks_addon" "vpc_cni_eks_addon" {
#  addon_name   = "vpc-cni"
#  cluster_name = aws_eks_cluster.this.name
#  lifecycle {
#    replace_triggered_by = [
#      aws_eks_cluster.this
#    ]
#  }
#
#  depends_on = [aws_eks_node_group.servers, aws_eks_node_group.agents]
#}

resource "aws_eks_addon" "ebs_csi_eks_addon" {
  addon_name   = "aws-ebs-csi-driver"
  cluster_name = aws_eks_cluster.this.name
  lifecycle {
    replace_triggered_by = [
      aws_eks_cluster.this
    ]
  }

  depends_on = [aws_eks_node_group.servers, aws_eks_node_group.agents]
}

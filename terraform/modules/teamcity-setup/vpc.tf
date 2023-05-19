# ------------------------------------------------------------------------------

locals {
  # List of availability zones, in which subnets should be created
  # Will use all zones by default
  availability_zones = length(var.vpc_network.availability_zones) > 0 ? [
    for az in var.vpc_network.availability_zones : "${data.aws_region.current.name}${az}"
  ] : data.aws_availability_zones.current.names

  # Generate cidr blocks for public subnets
  public_subnets = {
    for idx, az in zipmap(range(length(local.availability_zones)), local.availability_zones) :
    az => cidrsubnet(
      var.vpc_network.primary_cidr_range,
      length(local.availability_zones),
      idx
    )
  }

  # Generate cidr blocks for private subnets
  private_subnets = {
    for idx, az in zipmap(range(length(local.availability_zones)), local.availability_zones) :
    az => cidrsubnet(
      var.vpc_network.primary_cidr_range,
      length(local.availability_zones),
      idx + length(local.availability_zones)
    )
  }
}

# ------------------------------------------------------------------------------

# Main VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_network.primary_cidr_range
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "teamcity-vpc"
    Description = "TeamCity VPC"
  }
}

# Public subnet(s), which will hold TeamCity server, ELB(s) and Gateway(s)
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  availability_zone       = each.key
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = {
    Name                     = "teamcity-${each.key}-public"
    Description              = "Public subnet for ${each.key} availability zone"
    "kubernetes.io/role/elb" = 1
  }

  depends_on = [aws_vpc.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "route-table-${data.aws_region.current.name}-public"
    Description = "Route table for public subnets in ${data.aws_region.current.name} VPC"
  }

  depends_on = [aws_vpc.this]
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id

  depends_on = [aws_route_table.public, aws_subnet.public]
}

# Private subnets, which will hold nodes with TeamCity agent pods
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  availability_zone = each.key
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value

  tags = {
    Name        = "teamcity-${each.key}-private"
    Description = "Private subnet for ${each.key} availability zone"
  }

  depends_on = [aws_vpc.this]
}

resource "aws_route_table" "private" {
  for_each = toset(local.availability_zones)

  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[each.value].id
  }

  route {
    cidr_block      = aws_vpc_endpoint.s3.prefix_list_id
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
  }

  tags = {
    Name        = "route-table-${each.value}-private"
    Description = "Route table for private subnet in ${each.value} AZ"
  }

  depends_on = [aws_vpc.this, aws_vpc_endpoint.s3]
}

resource "aws_route_table_association" "private" {
  for_each = toset(local.availability_zones)

  route_table_id = aws_route_table.private[each.value].id
  subnet_id      = aws_subnet.private[each.value].id

  depends_on = [aws_route_table.private, aws_subnet.private]
}

# Required for the Internet access from created VPC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "igw-${data.aws_region.current.name}"
    Description = "Gateway for the Internet access from TeamCity VPC"
  }

  depends_on = [aws_vpc.this]
}

# Required for each NAT gateway
resource "aws_eip" "nat" {
  for_each = toset(local.availability_zones)

  tags = {
    Name        = "nat-gw-${each.value}-eip"
    Description = "IP address for NAT gateway in a public subnet"
  }
}

# Required for outbound connections to the Internet from private subnets
resource "aws_nat_gateway" "this" {
  for_each = toset(local.availability_zones)

  subnet_id     = aws_subnet.public[each.value].id
  allocation_id = aws_eip.nat[each.value].id

  tags = {
    Name        = "nat-gw-${each.value}"
    Description = "NAT gateway for private subnetwork in ${each.value} availability zone"
  }

  depends_on = [aws_subnet.public, aws_eip.nat]
}

# Access to s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

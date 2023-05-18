resource "aws_route53_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  name = var.dns_zone_name
}

# Records would be added by external-dns controller
# (https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws-load-balancer-controller.md)

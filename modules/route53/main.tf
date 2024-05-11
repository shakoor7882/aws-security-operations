resource "aws_route53_zone" "private" {
  name = "intranet.wms.com"

  vpc {
    vpc_id = var.solution_vpc_id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "security" {
  zone_id = aws_route53_zone.private.zone_id
  vpc_id  = var.security_vpc_id
}

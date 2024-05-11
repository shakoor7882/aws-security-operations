resource "aws_route53_zone" "private" {
  name = "example.com"

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "infected"
  type    = "CNAME"
  ttl     = 300
  records = [var.instance_private_dns]
}


resource "aws_route53_record" "secops_jumpserver" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "secops"
  type    = "CNAME"
  ttl     = 300
  records = [var.security_jump_private_dns]
}

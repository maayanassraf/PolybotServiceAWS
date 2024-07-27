resource "aws_acm_certificate" "alb_cert" {
  domain_name       = aws_route53_record.alb_record.fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.alb_cert.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.hosted_zone_id.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "validate_alb_cert" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "cloudfront-s3-oac-${var.env}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "index.html"
  aliases = ["artistsearch-${var.env}.gusmarko.com"]

origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id = aws_s3_bucket.main.id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  

custom_error_response {
     error_caching_min_ttl = 10 
     error_code            = 403 
     response_code         = 403 
     response_page_path    = "/index.html" 
  }

  custom_error_response {
     error_caching_min_ttl = 10 
     error_code            = 404 
     response_code         = 404
     response_page_path    = "/index.html" 
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.main.id

    compress               = true
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_All"
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

 viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.gusmarko.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "cloudfront-s3-${var.env}"
    Environment = "${var.env}"
  }
}

data "aws_acm_certificate" "gusmarko" {
  domain   = "*.gusmarko.com"
  statuses = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "gusmarko_com" {
  name = "gusmarko.com"
}

resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.gusmarko_com.zone_id
  name    = "artistsearch-${var.env}.gusmarko.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false 
  }
}
resource "aws_cloudfront_distribution" "main" {
  enabled     = true
  comment     = "${var.project_name} CDN"
  price_class = "PriceClass_100" # US/Canada/Europe edge locations only — cheapest tier, sufficient for a learning project

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "${var.project_name}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port              = 443
      origin_protocol_policy  = "http-only" # ALB listener is HTTP-only in this project; would be https-only in production with ACM cert
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "${var.project_name}-alb-origin"
    viewer_protocol_policy  = "redirect-to-https" # force HTTPS to the viewer, even though origin is HTTP
    compress                = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 300   # 5 min — short since our "app" is dynamic HTML, not real static assets
    max_ttl     = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # using CloudFront's default *.cloudfront.net cert since we have no custom domain/ACM cert
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}

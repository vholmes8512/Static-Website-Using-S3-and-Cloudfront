#Static website using S3 and Cloudfront
#Contributor: Vincent Holmes


#define provider 
provider "aws" {
  region = "us-west-2"
}

#define s3
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "holmes-static-website"
  
}



#determine public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



#define bucket policy
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_website_bucket.arn}/*"
      }
    ]
  })
}

#define bucket object
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.static_website_bucket.bucket
  key    = "index.html"
  source = "/Users/vincentholmes/static-website-project/index.html"
  content_type = "text/html"

}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}


#define cloudfront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.static_website_bucket.bucket}.s3.amazonaws.com"
    origin_id   = "S3-${aws_s3_bucket.static_website_bucket.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "S3 static website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_website_bucket.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for S3 static website"
}

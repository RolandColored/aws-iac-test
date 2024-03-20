
provider "aws" {
  region = var.aws_region
}


// bucket
resource "random_pet" "lambda_bucket_name" {
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

// route53
/*
FIXME not working because we do not own the example.com domain

resource "aws_route53_zone" "primary_domain" {
  name = "example.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary_domain.zone_id
  name    = "tenant.example.com"
  type    = "A"
  alias {
    name                   = aws_apigatewayv2_domain_name.teant_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.teant_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "tenant.example.com"
  validation_method = "DNS"
}

resource "aws_apigatewayv2_domain_name" "teant_domain" {
  domain_name = "tenant.example.com"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
*/

// lambda code
data "archive_file" "lambda_server" {
  type = "zip"

  source_dir  = "${path.module}/server"
  output_path = "${path.module}/server.zip"
}

resource "aws_s3_object" "lambda_server" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "server.zip"
  source = data.archive_file.lambda_server.output_path

  etag = filemd5(data.archive_file.lambda_server.output_path)
}

// api gateway
resource "aws_apigatewayv2_api" "gateway" {
  name          = "multitenant_gateway_stage"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "gateway_stage" {
  api_id = aws_apigatewayv2_api.gateway.id
  name        = "multitenant_gateway_stage"
  auto_deploy = true
}

module "tenant" {
  for_each = toset(var.tenants)
  source = "./modules/tenant"

  tenant_name           = each.key
  bucket_id             = aws_s3_bucket.lambda_bucket.id
  bucket_key            = aws_s3_object.lambda_server.key
  source_code_hash      = aws_s3_object.lambda_server.etag
  apigateway_id         = aws_apigatewayv2_api.gateway.id
  apigateway_source_arn = aws_apigatewayv2_api.gateway.execution_arn
}

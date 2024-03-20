
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
data "aws_route53_zone" "root_domain" {
  name         = "${var.root_domain}"
  private_zone = false
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
  root_domain           = var.root_domain
}

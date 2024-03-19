
provider "aws" {
  region = var.aws_region
}


// bucket
resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
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


// lambda
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

resource "aws_lambda_function" "server" {
  function_name = "Server"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_server.key

  runtime = "nodejs20.x"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_server.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

// api gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "server" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.server.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "server" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /server"
  target    = "integrations/${aws_apigatewayv2_integration.server.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.server.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}



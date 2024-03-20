
// lambda
resource "aws_lambda_function" "server" {
  function_name = "${var.tenant_name}_server"

  s3_bucket = var.bucket_id
  s3_key    = var.bucket_key

  runtime = "nodejs20.x"
  handler = "hello.handler"

  source_code_hash = var.source_code_hash

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.tenant_name}_lambda_exec_role"

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

// api gateway integration
resource "aws_apigatewayv2_integration" "server" {
  api_id = var.apigateway_id
  integration_uri    = aws_lambda_function.server.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "server" {
  api_id = var.apigateway_id
  // FIXME routing should be based on tenant subdomain
  route_key = "GET /${var.tenant_name}"
  target    = "integrations/${aws_apigatewayv2_integration.server.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.server.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.apigateway_source_arn}/*/*"
}


// database
resource "aws_db_instance" "database" {
  allocated_storage           = 10
  db_name                     = "${var.tenant_name}_database"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t3.micro"
  username                    = "databaseowner"
  manage_master_user_password = true
  parameter_group_name        = "default.mysql5.7"
  skip_final_snapshot         = true
}

/*
resource "aws_db_proxy" "db_proxy" {
  TODO: connect to the database and lambda function
}
*/
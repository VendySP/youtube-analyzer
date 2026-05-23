resource "aws_apigatewayv2_api" "api_gateway_ytAnalyzer" {
  name          = "youtubeAnalyzer-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["http://${var.bucket_name}.s3-website.${var.aws_region}.amazonaws.com"]
    #allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}

resource "aws_apigatewayv2_integration" "api_lambda_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway_ytAnalyzer.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.lambda_ytAnalyzer.arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api_gateway_ytAnalyzer.id
  route_key = "POST /analyze"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway_ytAnalyzer.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}

# add resource-based policy statements on the lambda to allow api gateway
resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_ytAnalyzer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway_ytAnalyzer.execution_arn}/*/*"
}
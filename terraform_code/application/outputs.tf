output "website_url" {
  value = aws_s3_bucket_website_configuration.s3_static_website_hosting.website_endpoint
}

output "api_gateway_url" {
  value       = aws_apigatewayv2_api.api_gateway_ytAnalyzer.api_endpoint
  description = "The backend URL base endpoint. Copy paste it inside the index.html file (const API_ENDPOINT = 'xxx'/analyze)"
}
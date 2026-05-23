data "archive_file" "lambda_function_zip_builder" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "${path.module}/src/ytAnalyzer_api_layer.zip"
  layer_name          = "ytAnalyzer-layer"
  compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_function" "lambda_ytAnalyzer" {
  filename         = data.archive_file.lambda_function_zip_builder.output_path
  source_code_hash = data.archive_file.lambda_function_zip_builder.output_base64sha256 # hash code to track changes inside lambda function

  function_name = "youtubeAnalyzer-function"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler" # <file_name>.<function_name>
  runtime       = "python3.12"


  timeout     = 20
  memory_size = 128


  layers = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      YOUTUBE_API_KEY      = var.youtube_api_key
      TARGET_COMMENT_COUNT = var.target_comment_count
    }
  }

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}
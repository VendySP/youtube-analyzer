data "aws_iam_policy_document" "lambda_trust_relationship" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "ytAnalyzer-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_relationship.json

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}


resource "aws_iam_role_policy_attachment" "lambda_basic_logs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "comprehend_full_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
}

resource "aws_iam_role_policy_attachment" "translate_full_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/TranslateFullAccess"
}


data "aws_iam_policy_document" "bedrock_nova_only" {
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:*:*:inference-profile/apac.amazon.nova-micro-v1:0",
      "arn:aws:bedrock:*:*:foundation-model/amazon.nova-micro-v1:0"
    ]
  }
}


resource "aws_iam_policy" "bedrock_custom_policy" {
  name   = "ytAnalyzer-bedrock-policy"
  policy = data.aws_iam_policy_document.bedrock_nova_only.json
}

resource "aws_iam_role_policy_attachment" "bedrock_custom_policy_join" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.bedrock_custom_policy.arn
}
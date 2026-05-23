resource "aws_s3_bucket" "s3_frontend_bucket" {
  bucket = var.bucket_name

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}

resource "aws_s3_bucket_website_configuration" "s3_static_website_hosting" {
  bucket = aws_s3_bucket.s3_frontend_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_allow_public_access" {
  bucket = aws_s3_bucket.s3_frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_frontend_bucket.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}


resource "aws_s3_bucket_policy" "s3_policy_join" {
  bucket = aws_s3_bucket.s3_frontend_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json

  depends_on = [aws_s3_bucket_public_access_block.s3_allow_public_access]
}


resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.s3_frontend_bucket.id
  key          = "index.html"
  source       = "${path.module}/src/index.html"
  content_type = "text/html"                              # Forces browsers to render the file as a webpage
  source_hash  = filemd5("${path.module}/src/index.html") # track changes inside index.html file.

  tags = {
    Environment = "production"
    Project     = "youtube-analyzer"
  }
}
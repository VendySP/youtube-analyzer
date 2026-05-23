provider "aws" {
  region = "ap-southeast-3"
}

resource "aws_s3_bucket" "s3_tf_state" {
  bucket        = "tf-state-yt-analyzer-kdklooiuwoe2220"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "s3_tf_state_versioning" {
  bucket = aws_s3_bucket.s3_tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
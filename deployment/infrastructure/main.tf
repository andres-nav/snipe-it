resource "aws_s3_bucket" "backup" {
  bucket_prefix = var.backup_bucket_prefix
}

resource "aws_s3_bucket_public_access_block" "backup_access" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup_versioning" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

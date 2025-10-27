resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0
  name  = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.root}/src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  description   = var.description
  role          = coalesce(var.role_arn, try(aws_iam_role.this[0].arn, null))
  runtime       = var.runtime
  handler       = var.handler
  filename      = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = merge(var.environment, {
      DATASET_BUCKET = coalesce(var.dataset_bucket, "")
      DATASET_KEY    = coalesce(var.dataset_key, "cities.json")
    })
  }

  tags = var.tags
}

resource "aws_iam_role_policy" "s3_read" {
  count = var.create_role ? 1 : 0
  name  = "${var.name}-s3-read"
  role  = aws_iam_role.this[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.dataset_bucket}/${var.dataset_key}"
        ]
      }
    ]
  })
}

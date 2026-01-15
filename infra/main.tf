# ===================================================================
# Terraform Starter for DistilBERT MLOps Demo
# Resources: Remote backend, S3 bucket, IAM role, Lambda (ECR image), API Gateway
# ===================================================================

terraform {
  backend "s3" {
    bucket         = "distilbert-mlops-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

# -------------------------------
# Remote Backend Resources
# -------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "distilbert-mlops-terraform-state"

  tags = {
    Project = "DistilBERT-MLOps"
    Owner   = "JeyaPrakashI"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "DistilBERT-MLOps"
    Owner   = "JeyaPrakashI"
  }
}

# -------------------------------
# S3 Bucket for Metrics/Artifacts
# -------------------------------
resource "aws_s3_bucket" "mlops_metrics" {
  bucket = "distilbert-mlops-metrics"

  tags = {
    Project = "DistilBERT-MLOps"
    Owner   = "JeyaPrakashI"
  }
}

# -------------------------------
# IAM Role for Lambda Execution
# -------------------------------
resource "aws_iam_role" "lambda_exec" {
  name               = "lambda_exec_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -------------------------------
# Lambda Function (Container Image)
# -------------------------------
# ⚠️ Option A: Import existing Lambda into Terraform
# terraform import aws_lambda_function.inference distilbert_infer
#
# ⚠️ Option B: Rename function to avoid conflict
resource "aws_lambda_function" "inference" {
  function_name = "distilbert_infer_v2"   # renamed to avoid conflict
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "867725336535.dkr.ecr.eu-north-1.amazonaws.com/mlops-lambda:latest"
  timeout       = 30
  memory_size   = 1024

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.mlops_metrics.bucket
    }
  }
}

# -------------------------------
# API Gateway (HTTP API)
# -------------------------------
resource "aws_apigatewayv2_api" "api" {
  name          = "distilbert-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.inference.invoke_arn
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /infer"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# -------------------------------
# Outputs
# -------------------------------
output "api_endpoint" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}

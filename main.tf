terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

terraform {
  backend "s3" {
    bucket         = "terraformstatestorage-salpal1"
    key            = "terraformstate/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraformstatedb-salpal1"
  }
}

resource "aws_api_gateway_rest_api" "salpal" {
  name        = "salpal-api"
  description = "Salpal API"
}

resource "aws_api_gateway_resource" "salpal" {
  rest_api_id = aws_api_gateway_rest_api.salpal.id
  parent_id   = aws_api_gateway_rest_api.salpal.root_resource_id
  path_part   = "file-upload"
}

resource "aws_api_gateway_method" "salpal" {
  rest_api_id   = aws_api_gateway_rest_api.salpal.id
  resource_id   = aws_api_gateway_resource.salpal.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_lambda_permission" "salpal" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.saveFileToS3.arn
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_integration" "salpal" {
  rest_api_id             = aws_api_gateway_rest_api.salpal.id
  resource_id             = aws_api_gateway_resource.salpal.id
  http_method             = aws_api_gateway_method.salpal.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.saveFileToS3.invoke_arn
}

resource "aws_api_gateway_deployment" "salpal" {
  depends_on  = [aws_api_gateway_integration.salpal]
  rest_api_id = aws_api_gateway_rest_api.salpal.id
  stage_name  = "prod"
  variables = {
    "lambdaAlias" = aws_lambda_alias.salpal.name
  }
}

resource "aws_lambda_alias" "salpal" {
  name             = "prod"
  function_name    = aws_lambda_function.saveFileToS3.function_name
  function_version = "$LATEST"
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name        = "api_gateway_policy"
  role        = "api_gateway_role"

  # description = "IAM policy for API Gateway"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:*:*:*/*"
      }
    ]
  })
}

resource "aws_iam_role" "api_gateway_role" {
  name               = "api_gateway_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch_policy"
  description = "Policy for API Gateway to publish metrics to CloudWatch"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:PutMetricData"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.api_gateway_role.name
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "resumeuploads4" {
  bucket = "resumeuploads4"
}

resource "aws_iam_role_policy_attachment" "lambda_textract_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
  role       = aws_iam_role.lambda_role.name
}

data "aws_iam_policy_document" "textract_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "textract:DetectDocumentText"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "textract_lambda_policy" {
  name   = "textract-lambda-policy"
  policy = data.aws_iam_policy_document.textract_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "textract_lambda_attachment" {
  policy_arn = aws_iam_policy.textract_lambda_policy.id
  role       = aws_iam_role.lambda_role.id
}

resource "aws_iam_role_policy_attachment" "s3_fullaccess_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "getTextFromFile" {
  filename         = "getTextFromFile.zip"
  function_name    = "getTextFromFile"
  role             = aws_iam_role.lambda_role.arn
  handler          = "getTextFromFile/handler.readS3File"
  source_code_hash = filebase64sha256("getTextFromFile.zip")
  runtime          = "nodejs14.x"
  timeout          = var.LAMBDA_TIMEOUT  // Update the timeout value in seconds
  environment {
    variables = {
      BUCKET_NAME       = aws_s3_bucket.resumeuploads4.id
      OPENAI_API_KEY    = var.OPENAI_API_KEY
      CLIENT_ID         = var.CLIENT_ID
      CLIENT_SECRET     = var.CLIENT_SECRET
      SF_USERNAME       = var.SF_USERNAME
      SF_PASSWORD       = var.SF_PASSWORD
      SF_SECURITY_TOKEN = var.SF_SECURITY_TOKEN
      SF_PATCH_URL      = var.SF_PATCH_URL
      LAMBDA_TIMEOUT    = var.LAMBDA_TIMEOUT
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_policy,
    aws_iam_role_policy_attachment.lambda_textract_policy
  ]
}

resource "aws_lambda_function" "saveFileToS3" {
  filename         = "saveFileToS3.zip"
  function_name    = "saveFileToS3"
  role             = aws_iam_role.lambda_role.arn
  handler          = "saveFileToS3/handler.getFile"
  source_code_hash = filebase64sha256("saveFileToS3.zip")
  runtime          = "nodejs14.x"
  timeout          = var.LAMBDA_TIMEOUT
  environment {
    variables = {
      BUCKET_NAME       = aws_s3_bucket.resumeuploads4.id
      LAMBDA_TIMEOUT    = var.LAMBDA_TIMEOUT
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_policy
  ]
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/getTextFromFile"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "saveFileToS3" {
  name              = "/aws/lambda/saveFileToS3"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.resumeuploads4.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.getTextFromFile.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "s3_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getTextFromFile.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.resumeuploads4.arn
}

resource "aws_lambda_permission" "allow_textract_invoke" {
  statement_id    = "AllowTextractInvoke"
  action          = "lambda:InvokeFunction"
  function_name   = aws_lambda_function.getTextFromFile.arn
  principal       = "textract.amazonaws.com"
  source_account  = "690711176673"  # Update with your AWS account ID
  source_arn      = "arn:aws:textract:us-east-1:690711176673:document-understanding-pipeline/*"
}
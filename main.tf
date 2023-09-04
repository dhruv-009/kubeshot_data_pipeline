# Define the AWS provider with the region set to us-east-1
provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket for scripts
resource "aws_s3_bucket" "script_bucket" {
  bucket = var.script_bucket_name
}

# Create an S3 bucket object for the 'lib' folder in the script bucket
resource "aws_s3_bucket_object" "script_lib" {
  bucket = aws_s3_bucket.script_bucket.id
  key    = "lib/"
  source = ""
}

# Create an S3 bucket object for the 'script' folder in the script bucket
resource "aws_s3_bucket_object" "script_script" {
  bucket = aws_s3_bucket.script_bucket.id
  key    = "script/"
  source = ""
}

# Create an S3 object for the script 'app.py' in the 'script' folder
resource "aws_s3_object" "script_object" {
  bucket = aws_s3_bucket.script_bucket.id
  key    = "script/app.py"
  source = "./dist/app.py"
}

# Create an S3 object for the Python library in the 'lib' folder
resource "aws_s3_object" "script_object_1" {
  bucket = aws_s3_bucket.script_bucket.id
  key    = "lib/${var.wheel_file_name}"
  source = "./dist/app.py"
}

# Create an S3 bucket for JSON data processing
resource "aws_s3_bucket" "json_bucket" {
  bucket = var.json_bucket_name

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# Create an S3 bucket for report data
resource "aws_s3_bucket" "report_bucket" {
  bucket = var.report_bucket_name

  tags = {
    Name        = "Report bucket"
    Environment = "Dev"
  }
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the Lambda role
resource "aws_iam_policy_attachment" "lambda_policy" {
    name       = "test-role"
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    roles      = [aws_iam_role.lambda_role.id]
}

# Create an AWS Lambda function for data processing
resource "aws_lambda_function" "data_processing_lambda" {
  function_name = var.lambda_function_name
  handler      = "index.handler"
  runtime      = "python3.10"
  role         = aws_iam_role.lambda_role.arn

  filename     = "./lambda_function.zip"
  source_code_hash = filebase64sha256("./lambda_function.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.json_bucket.id
    }
  }
  depends_on = [aws_iam_policy_attachment.lambda_policy]
}

# Create a CloudWatch log group for the Lambda function
resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.data_processing_lambda.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

# Create an IAM policy for function logging
resource "aws_iam_policy" "function_logging_policy" {
  name   = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the function logging policy to the Lambda role
resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

# Create an AWS SNS Topic with the specified name.
resource "aws_sns_topic" "example_topic" {
  name = var.sns_name
}

# Subscribe an email address to the SNS topic for notifications.
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.example_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# Grant permission to the Lambda function to be invoked by the SNS topic.
resource "aws_lambda_permission" "sns_permission" {
  statement_id  = "AllowExecutionFromSNSTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processing_lambda.arn
  principal     = "sns.amazonaws.com"
  
  source_arn = aws_sns_topic.example_topic.arn
}

# Create an IAM policy for Glue job permissions
resource "aws_iam_policy" "glue_job_policy" {
  name        = "GlueJobPolicy"
  description = "IAM policy for Glue job permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "glue:StartJobRun",
        Effect = "Allow",
        Resource = "*",
      },
      {
        Action = "glue:GetJobRun",
        Effect = "Allow",
        Resource = "*",
      },
    ],
  })
}

# Attach the Glue job policy to the Lambda role
resource "aws_iam_policy_attachment" "glue_job_policy_attachment" {
  name       = "glue-job-policy-attachment"
  policy_arn = aws_iam_policy.glue_job_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}

# Configure permissions to invoke the Lambda function from S3 bucket events
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processing_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.json_bucket.arn
}

# Configure S3 bucket notification to trigger the Lambda function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.json_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processing_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Create an AWS Glue job for data processing
resource "aws_glue_job" "data_processing_glue_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.lambda_role.arn
  command {
    name = "pythonshell"
    python_version = "3"
    script_location = "s3://${aws_s3_bucket.script_bucket.bucket}/script/app.py"
  }

  default_arguments = {
    "--input_bucket" = aws_s3_bucket.json_bucket.id
    "--job-language" = "python"
   "--extra-py-files" = "s3://${aws_s3_bucket.script_bucket.bucket}/lib/${var.wheel_file_name}"
  }
}

# Create a QuickSight data source
resource "aws_quicksight_data_source" "default" {
  data_source_id = var.quick_sight_data_source_id
  name           = var.data_source_quicksight

  parameters {
    s3 {
      manifest_file_location {
        bucket = aws_s3_bucket.json_bucket.id
        key    = "test.json"
      }
    }
  }

  type = "S3"
}

# Create a QuickSight data set
resource "aws_quicksight_data_set" "dataset" {
  name      = var.quick_sight_dataset_name
  aws_account_id = var.aws_account_id
  import_mode = "SPICE"
  data_set_id = "dataset-id"

  physical_table_map {
    physical_table_map_id = "DataSet"
    
    s3_source {
      data_source_arn = aws_quicksight_data_source.default.arn
    input_columns {
    name    = "customer_name"
    type    = "STRING"
}

    input_columns {
        name    = "product_name"
        type    = "STRING"
    }

    input_columns {
        name    = "quantity"
        type    = "INTEGER"
    }
      upload_settings {
        format = "CSV"
        start_from_row = 1
        delimiter = ","
        text_qualifier = "DOUBLE_QUOTE"
      }
    }
  }
}
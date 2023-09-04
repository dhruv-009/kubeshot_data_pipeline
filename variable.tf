variable "aws_account_id" {
  description = "AWS Account ID"
  type = string
}

variable "script_bucket_name" {
  description = "Name of the script S3 bucket"
  type        = string
  default     = "script-bucket-glue-pipeline"
}

variable "json_bucket_name" {
  description = "Name of the JSON S3 bucket"
  type        = string
  default     = "job-processing-bucket"
}

variable "report_bucket_name" {
  description = "Name of the report S3 bucket"
  type        = string
  default     = "processing-report-bucket"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "data-processing-lambda"
}

variable "quick_sight_data_source_id" {
  description = "ID of the QuickSight data source"
  type        = string
  default     = "example-id"
}

variable "quick_sight_dataset_name" {
  description = "Name of the QuickSight dataset"
  type        = string
  default     = "etl-piepline-dataset"
}

variable "email_address" {
  description = "Email address for subscription"
  type        = string
}

variable "sns_name" {
    description = "Name of SNS topic"
    type = string
}

variable "glue_job_name" {
    description = "Name of the Glue Job"
    type = string
}

variable "data_source_quicksight" {
    description = "Name of the data source"
    type = string
}

variable "wheel_file_name" {
  description = "Name of the wheel file"
  type        = string
}
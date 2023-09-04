# Data Processing AWS Infrastructure

This project sets up AWS infrastructure for data processing and reporting. It includes AWS Lambda functions, S3 buckets, AWS Glue jobs, AWS SNS and AWS Quicksight resources.

## Project Structure

main.tf: Defines the main Terraform configuration for creating AWS resources.
variables.tf: Declares the input variables used in the main.tf configuration.
terraform.tfvars: Stores the values for input variables (not included in this example).
setup.py: Python setup script to prepare the environment.
Prerequisites

## Before running the Terraform scripts, make sure you have:

AWS CLI configured with appropriate access and secret keys.
Terraform installed on your local machine.

## Setup Instructions

* Prepare the Environment
Before running Terraform, execute the following commands:

```bash
#Install dependencies and create a virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

* Build the Lambda Deployment Package
Run the following command to build the Lambda deployment package:

```bash
python3 setup.py bdist_wheel
```
This will create a dist directory containing the Lambda deployment package.

* Deploy AWS Resources
Now, you can deploy the AWS resources using Terraform:

```bash
#Initialize Terraform (only required once)

terraform init

terraform plan

terraform apply
```

* Clean Up (Optional)
To destroy the AWS resources and clean up:

```bash
#Destroy AWS resources
terraform destroy
```
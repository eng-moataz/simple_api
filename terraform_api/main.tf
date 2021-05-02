terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region = "eu-west-1"
}

# creating a data record for lambda execution role managed policy
data "aws_iam_policy" "ExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# creating a data record for api gateway push logs role managed policy
data "aws_iam_policy" "ApiLogsRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}


# dynamo table
resource "aws_dynamodb_table" "hits_table" {
  name           = "hits_table_terraform"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "millisec_epoch_time_stamp"
  range_key = "path"

  attribute {
    name = "millisec_epoch_time_stamp"
    type = "N"
  }

  attribute {
    name = "path"
    type = "S"
  }

  global_secondary_index {
    name               = "millisec_epoch_time_stamp"
    hash_key           = "millisec_epoch_time_stamp"
    projection_type    = "ALL"
    write_capacity     = 5
    read_capacity      = 5
  }

}

# creat IAM role for lambda with managed policy
resource "aws_iam_role" "lambda_role" {

  # Terraform's "jsonencode" function converts a
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["${data.aws_iam_policy.ExecutionRole.arn}"]
}

# create required dynamo permissions to attach to lambda
resource "aws_iam_policy" "dynamo_permissions" {
  name = "dynamo_permissions_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
                "dynamodb:BatchGetItem",
                "dynamodb:GetRecords",
                "dynamodb:GetShardIterator",
                "dynamodb:Query",
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
                ]
        Effect   = "Allow"
        Resource = [ 
        "${aws_dynamodb_table.hits_table.arn}",
        "${aws_dynamodb_table.hits_table.arn}/index/*"
        ]
      },
    ]
  })
}

# attach policy to lambda role
resource "aws_iam_policy_attachment" "attaching_lambda_dynamo" {
  name       = "attaching_lambda_dynamo_permission"
  roles      = [aws_iam_role.lambda_role.id]
  policy_arn = aws_iam_policy.dynamo_permissions.arn
}

# creating the api lambda
resource "aws_lambda_function" "api_lambda" {
  filename      = "lambda-code.zip"
  function_name = "api_handler_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_api.handler"
  runtime = "python3.7"
  source_code_hash = filebase64sha256("lambda-code.zip")
  depends_on = [
      aws_iam_role.lambda_role,
      aws_iam_policy.dynamo_permissions
  ]
  environment {
    variables = {
      HITS_TABLE_NAME = aws_dynamodb_table.hits_table.id
    }
  }
   
}

# creating the rest api
resource "aws_api_gateway_rest_api" "api_gw" {
  name = "api_endpoint"
}

# creating api deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  depends_on = [
      aws_api_gateway_method.ApiAnyMethod,
      aws_api_gateway_method.ApiAnyMethodRestParent,
      aws_api_gateway_resource.APIResource,
      aws_api_gateway_integration.integrationMethodRestRoot,
      aws_api_gateway_integration.integrationMethod
  ]
}

# creating prod stage
resource "aws_api_gateway_stage" "api_stage_prod_deployment" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  stage_name    = "prod"
}


# creat IAM role for api gateway with managed policy
resource "aws_iam_role" "apigw_role" {

  # Terraform's "jsonencode" function converts a
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["${data.aws_iam_policy.ApiLogsRole.arn}"]
}

# sepcifying api gateway role
resource "aws_api_gateway_account" "api_endpoint_account" {
  cloudwatch_role_arn = aws_iam_role.apigw_role.arn
  depends_on = [
      aws_api_gateway_rest_api.api_gw
  ]
}

# configuring the apigateway as proxy for lambda
resource "aws_api_gateway_resource" "APIResource" {
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = "{proxy+}"
}

# lambda permission to invoke from any proxied locations/any locations
resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowExecutionFrompProdLocations"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_stage.api_stage_prod_deployment.execution_arn}/*/{proxy+}"
}

# lambda permission to invoke from any proxied locations
resource "aws_lambda_permission" "allow_gateway_any" {
  statement_id  = "AllowExecutionFromAnyLocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_stage.api_stage_prod_deployment.execution_arn}/*/"
}



# creating any method for api_gw
resource "aws_api_gateway_method" "ApiAnyMethod" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.APIResource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# creating any method for api_gw Root resource id
resource "aws_api_gateway_method" "ApiAnyMethodRestParent" {
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# proxy POST method
resource "aws_api_gateway_integration" "integrationMethod" {
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_resource.APIResource.id
  http_method             = aws_api_gateway_method.ApiAnyMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

# proxy POST method
resource "aws_api_gateway_integration" "integrationMethodRestRoot" {
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_rest_api.api_gw.root_resource_id
  http_method             = aws_api_gateway_method.ApiAnyMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

output "api_url" {
   value = aws_api_gateway_stage.api_stage_prod_deployment.invoke_url
}
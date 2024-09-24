#!/bin/bash

set -e

handle_error() {
    echo "Error occurred in script at line: $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Create API Gateway
API_ID=$(awslocal apigateway create-rest-api --name 'test-api' --query 'id' --output text)
echo "API_ID: $API_ID"

# Get the root resource ID
PARENT_RESOURCE_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)
echo "PARENT_RESOURCE_ID: $PARENT_RESOURCE_ID"

# Create a new resource
RESOURCE_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_RESOURCE_ID --path-part 'proxy' --query 'id' --output text)
echo "RESOURCE_ID: $RESOURCE_ID"

# Create method and integration
awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --authorization-type "NONE"
awslocal apigateway put-integration --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:lambda_loader_to_s3/invocations"
echo "Integrated POST method with Lambda function"

# Deploy API
STAGE_NAME=test
DEPLOYMENT_ID=$(awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name $STAGE_NAME --query 'id' --output text)
echo "DEPLOYMENT_ID: $DEPLOYMENT_ID"
echo "API deployed to stage '$STAGE_NAME'"

# Construct the invoke URL manually
API_URL="http://localstack:4566/restapis/$API_ID/$STAGE_NAME/_user_request_/proxy"
echo "Constructed API URL: $API_URL"

# Create the api_url.env file if it doesn't exist
touch /shared/api_url.env

# Write the API_URL to the file
echo "API_URL=${API_URL}" > /shared/api_url.env
echo "API URL written to /shared/api_url.env"
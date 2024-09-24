#!/bin/bash

set -e

# Function to handle errors
error_handler() {
    echo "Error occurred in script at line: $1"
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Define bucket name
BUCKET_NAME="user-behavior-data"

echo "Starting script execution..."

# 7. Создаем S3 бакет
echo "Creating S3 bucket '$BUCKET_NAME'..."
if awslocal s3 mb s3://$BUCKET_NAME; then
    echo "Created S3 bucket '$BUCKET_NAME'"
else
    echo "Failed to create S3 bucket '$BUCKET_NAME'"
    exit 1
fi

# 8. Загружаем пример данных в S3 бакет
echo "Creating sample data file..."
echo "Sample data" > sample_data.txt
echo "Uploading sample data to S3 bucket '$BUCKET_NAME'..."
if awslocal s3 cp sample_data.txt s3://$BUCKET_NAME/sample_data.txt; then
    echo "Uploaded sample data to S3 bucket '$BUCKET_NAME'"
else
    echo "Failed to upload sample data to S3 bucket '$BUCKET_NAME'"
    exit 1
fi

# 8. Настраиваем триггер S3 для Lambda-функции
LAMBDA_FUNCTION_NAME="lambda_etl"

echo "Retrieving ARN for Lambda function '$LAMBDA_FUNCTION_NAME'..."
# Получаем ARN Lambda-функции
LAMBDA_ARN=$(awslocal lambda get-function --function-name $LAMBDA_FUNCTION_NAME --query 'Configuration.FunctionArn' --output text)
echo "Lambda function ARN: $LAMBDA_ARN"

echo "Setting up permission for S3 to invoke Lambda function..."
# Настраиваем политику для разрешения вызова Lambda-функции из S3
awslocal lambda add-permission --function-name $LAMBDA_FUNCTION_NAME --principal s3.amazonaws.com --statement-id some-unique-id --action "lambda:InvokeFunction" --source-arn arn:aws:s3:::$BUCKET_NAME

echo "Configuring S3 bucket notification to trigger Lambda function on object creation..."
# Настраиваем уведомление S3 для вызова Lambda-функции при загрузке объекта
NOTIFICATION_CONFIGURATION=$(cat <<EOF
{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "$LAMBDA_ARN",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}
EOF
)

echo $NOTIFICATION_CONFIGURATION > notification.json

awslocal s3api put-bucket-notification-configuration --bucket $BUCKET_NAME --notification-configuration file://notification.json

rm notification.json

echo "Configured S3 bucket '$BUCKET_NAME' to trigger Lambda function '$LAMBDA_FUNCTION_NAME' on object creation"

# Удаляем временный файл
echo "Deleting local temporary file 'sample_data.txt'..."
if rm sample_data.txt; then
    echo "Deleted local temporary file 'sample_data.txt'"
else
    echo "Failed to delete local temporary file 'sample_data.txt'"
    exit 1
fi

# Удаляем файл из S3 бакета
echo "Deleting 'sample_data.txt' from S3 bucket '$BUCKET_NAME'..."
if awslocal s3 rm s3://$BUCKET_NAME/sample_data.txt; then
    echo "Deleted 'sample_data.txt' from S3 bucket '$BUCKET_NAME'"
else
    echo "Failed to delete 'sample_data.txt' from S3 bucket '$BUCKET_NAME'"
    exit 1
fi

echo "Script execution completed successfully."
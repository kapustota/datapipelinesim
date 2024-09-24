#!/bin/bash

# Функция для обработки ошибок
error_exit() {
    echo "Error on line $1"
    exit 1
}

# Устанавливаем обработчик ошибок
trap 'error_exit $LINENO' ERR

# Параметры Lambda-функции
LAMBDA_NAME="lambda_loader_to_s3"
LAMBDA_RUNTIME="python3.8"
LAMBDA_ROLE="arn:aws:iam::000000000000:role/lambda-role"
LAMBDA_HANDLER="lambda_loader_to_s3.lambda_handler"
LAMBDA_PATH="/var/task/"
LAMBDA_FILE="lambda_loader_to_s3.py"
LAMBDA_ZIP="lambda_loader_to_s3.zip"
BUCKET_NAME="user-behavior-data"  # Имя вашего S3 бакета

cd $LAMBDA_PATH

# Проверяем наличие файла lambda_loader_to_s3.py
if [ ! -f $LAMBDA_FILE ]; then
    error_exit "File $LAMBDA_PATH not found."
fi

# Создаем zip-архив для lambda_loader_to_s3.py
zip -r $LAMBDA_ZIP . || error_exit "Failed to create zip for $LAMBDA_FILE."

# Создаем Lambda-функцию с переменной окружения BUCKET_NAME
awslocal lambda create-function \
    --function-name $LAMBDA_NAME \
    --runtime $LAMBDA_RUNTIME \
    --role $LAMBDA_ROLE \
    --handler $LAMBDA_HANDLER \
    --zip-file fileb://$LAMBDA_ZIP \
    --environment Variables="{BUCKET_NAME=$BUCKET_NAME}" || error_exit "Failed to create Lambda function $LAMBDA_NAME."

echo "Lambda function $LAMBDA_NAME created successfully."
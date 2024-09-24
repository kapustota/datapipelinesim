#!/bin/bash

# Функция для обработки ошибок
error_exit() {
    echo "Error on line $1"
    exit 1
}

# Устанавливаем обработчик ошибок
trap 'error_exit $LINENO' ERR

# Параметры Lambda-функции
LAMBDA_NAME="lambda_etl"
LAMBDA_RUNTIME="python3.8"
LAMBDA_ROLE="arn:aws:iam::000000000000:role/lambda-role"
LAMBDA_HANDLER="lambda_etl.lambda_handler"
LAMBDA_PATH="/var/task/etl/"
LAMBDA_FILE="lambda_etl.py"
LAMBDA_ZIP="lambda_etl.zip"

cd $LAMBDA_PATH

# Проверяем наличие файла lambda_etl.py
if [ ! -f $LAMBDA_FILE ]; then
    error_exit "File $LAMBDA_FILE not found."
fi

# Создаем zip-архив для Lambda-функции
zip -r $LAMBDA_ZIP . || error_exit "Failed to create zip for $LAMBDA_FILE."

# Создаем Lambda-функцию
awslocal lambda create-function \
    --function-name $LAMBDA_NAME \
    --runtime $LAMBDA_RUNTIME \
    --role $LAMBDA_ROLE \
    --handler $LAMBDA_HANDLER \
    --zip-file fileb://$LAMBDA_ZIP \
    --environment Variables="{POSTGRES_HOST=$POSTGRES_HOST,POSTGRES_PORT=$POSTGRES_PORT,POSTGRES_USER=$POSTGRES_USER,POSTGRES_PASSWORD=$POSTGRES_PASSWORD,POSTGRES_DB=$POSTGRES_DB}" || error_exit "Failed to create Lambda function $LAMBDA_NAME." 

echo "Lambda function $LAMBDA_NAME created successfully."
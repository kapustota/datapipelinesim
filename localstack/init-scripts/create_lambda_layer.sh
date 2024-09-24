#!/bin/bash

set -e

# Function to handle errors
error_handler() {
    echo "Error occurred in script at line: ${1}. Exiting."
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Define variables
LAYER_NAME="lambda_layer"
REQUIREMENTS_PATH="/var/task/etl/requirements.txt"
OUTPUT_DIR="lambda_layer/python/lib/python3.8/site-packages/"
ZIP_FILE="${LAYER_NAME}.zip"
LAMBDA_NAME="lambda_etl"

echo "Starting script to create Lambda Layer..."

# Create a directory for the dependencies
echo "Creating directory for dependencies at $OUTPUT_DIR..."
mkdir -p $OUTPUT_DIR

# Install dependencies into the directory
echo "Installing dependencies from $REQUIREMENTS_PATH to $OUTPUT_DIR..."
pip install -r $REQUIREMENTS_PATH -t $OUTPUT_DIR

# Проверка наличия установленных зависимостей
echo "Checking installed dependencies in $OUTPUT_DIR..."
ls -l $OUTPUT_DIR

# Create the zip file
echo "Creating zip file $ZIP_FILE..."
cd lambda_layer
zip -r ../$ZIP_FILE .
cd ..

# Проверка содержимого zip-архива
echo "Checking contents of zip file $ZIP_FILE..."
unzip -l $ZIP_FILE

# Publish the layer using awslocal
echo "Publishing the layer $LAYER_NAME to awslocal..."
LAYER_VERSION_ARN=$(awslocal lambda publish-layer-version \
    --layer-name $LAYER_NAME \
    --compatible-runtimes python3.8 \
    --zip-file fileb://$ZIP_FILE \
    --query 'LayerVersionArn' \
    --output text)

# Update the Lambda function to use the layer
echo "Updating Lambda function $LAMBDA_NAME to use the layer..."
awslocal lambda update-function-configuration \
    --function-name $LAMBDA_NAME \
    --layers $LAYER_VERSION_ARN

# Clean up
echo "Cleaning up..."
rm -rf $OUTPUT_DIR $ZIP_FILE

echo "Lambda Layer created, packaged as ${LAYER_NAME}.zip, and published to awslocal"
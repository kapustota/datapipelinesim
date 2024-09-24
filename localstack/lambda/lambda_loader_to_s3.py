import json
import boto3
import os
from datetime import datetime

s3_client = boto3.client('s3')
bucket_name = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    print("Lambda function has started")
    try:
        # Extract JSON data from the event
        print("Extracting JSON data from the event")
        json_data = event['body']
        
        # Generate a unique filename
        print("Generating a unique filename")
        timestamp = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
        file_name = f"data_{timestamp}.json"
        
        print(f"Uploading file to S3: {file_name}")
        s3_client.put_object(
            Bucket=bucket_name,
            Key=file_name,
            Body=json_data,
            ContentType='application/json'
        )
        
        print("Data stored successfully")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Data stored successfully'})
        }
    except Exception as e:
        print(f"Error storing data: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error storing data', 'error': str(e)})
        }

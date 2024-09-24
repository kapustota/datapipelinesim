import json
import boto3
import pg8000
import os

# Initialize S3 client
s3_client = boto3.client('s3')

# RDS settings
postgres_host = os.environ['POSTGRES_HOST']
postgres_port = os.environ['POSTGRES_PORT']
postgres_user = os.environ['POSTGRES_USER']
postgres_password = os.environ['POSTGRES_PASSWORD']
postgres_db = os.environ['POSTGRES_DB']

def fetch_data_from_s3(bucket_name, file_name):
    try:
        print(f"Fetching data from S3 bucket: {bucket_name}, file: {file_name}")
        response = s3_client.get_object(Bucket=bucket_name, Key=file_name)
        data = response['Body'].read().decode('utf-8')
        print("Data fetched successfully from S3")
        return json.loads(data)
    except Exception as e:
        print(f"Error fetching data from S3: {e}")
        raise

def load_data_to_postgres(data):
    try:
        print("Connecting to PostgreSQL database")
        conn = pg8000.connect(
            host=postgres_host,
            port=int(postgres_port),
            user=postgres_user,
            password=postgres_password,
            database=postgres_db
        )
        cursor = conn.cursor()
        print("Connected to PostgreSQL database")
        
        # Insert users
        for user in data['users']:
            cursor.execute(
            "INSERT INTO users (user_id, client_id, first_visit_date, last_visit_date, country, device_category, browser) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (user['user_id'], user['client_id'], user['first_visit_date'], user['last_visit_date'], user['country'], user['device_category'], user['browser'])
            )
        
        # Insert sessions
        for session in data['sessions']:
            cursor.execute(
            "INSERT INTO sessions (session_id, user_id, session_start_time, session_end_time, session_duration, pageviews, source, medium, campaign) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (session['session_id'], session['user_id'], session['session_start_time'], session['session_end_time'], session['session_duration'], session['pageviews'], session['source'], session['medium'], session['campaign'])
            )
        
        # Insert pageviews
        for pageview in data['pageviews']:
            cursor.execute(
            "INSERT INTO pageviews (pageview_id, session_id, page_path, page_title, timestamp, time_on_page, previous_page_path) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (pageview['pageview_id'], pageview['session_id'], pageview['page_path'], pageview['page_title'], pageview['timestamp'], pageview['time_on_page'], pageview['previous_page_path'])
            )
        
        # Insert events
        for event in data['events']:
            cursor.execute(
            "INSERT INTO events (event_id, session_id, event_category, event_action, event_label, event_value, timestamp) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (event['event_id'], event['session_id'], event['event_category'], event['event_action'], event['event_label'], event['event_value'], event['timestamp'])
            )
        
        # Insert goals
        for goal in data['goals']:
            cursor.execute(
            "INSERT INTO goals (goal_id, session_id, goal_name, goal_completion_time, goal_value) VALUES (%s, %s, %s, %s, %s)",
            (goal['goal_id'], goal['session_id'], goal['goal_name'], goal['goal_completion_time'], goal['goal_value'])
            )
        
        conn.commit()
        cursor.close()
        conn.close()
        print("Data loaded successfully into PostgreSQL")
    except Exception as e:
        print(f"Error loading data into PostgreSQL: {e}")
        raise

def lambda_handler(event, context):
    try:
        print("Lambda handler started")
        # Extract bucket name and file name from the event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        file_name = event['Records'][0]['s3']['object']['key']
        print(f"Bucket name: {bucket_name}, File name: {file_name}")
        
        # Fetch data from S3
        data = fetch_data_from_s3(bucket_name, file_name)
        
        # Load data into PostgreSQL
        load_data_to_postgres(data)
        
        print("Lambda handler completed successfully")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Data loaded successfully'})
        }
    except Exception as e:
        print(f"Error in lambda handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error loading data', 'error': str(e)})
        }
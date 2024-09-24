import random
import uuid
import os
import time
import requests
from faker import Faker
from datetime import datetime, timedelta

# Инициализация Faker для генерации случайных данных
fake = Faker()

def generate_user_data(n_users=10):
    users = []
    for _ in range(n_users):
        user_id = str(uuid.uuid4())
        users.append({
            "user_id": user_id,
            "client_id": str(uuid.uuid4()),
            "first_visit_date": fake.date_between(start_date="-2y", end_date="today").strftime("%Y-%m-%d"),
            "last_visit_date": fake.date_between(start_date="-1y", end_date="today").strftime("%Y-%m-%d"),
            "country": fake.country(),
            "device_category": random.choice(["desktop", "mobile", "tablet"]),
            "browser": fake.user_agent().split('/')[0]
        })
    return users

def generate_session_data(users, n_sessions_per_user=3):
    sessions = []
    for user in users:
        for _ in range(n_sessions_per_user):
            session_id = str(uuid.uuid4())
            session_start = fake.date_time_between(start_date="-1y", end_date="now")
            session_end = session_start + timedelta(minutes=random.randint(1, 60))
            sessions.append({
                "session_id": session_id,
                "user_id": user["user_id"],
                "session_start_time": session_start.strftime("%Y-%m-%dT%H:%M:%S"),
                "session_end_time": session_end.strftime("%Y-%m-%dT%H:%M:%S"),
                "session_duration": (session_end - session_start).seconds,
                "pageviews": random.randint(1, 10),
                "source": random.choice(["google", "facebook", "direct", "referral"]),
                "medium": random.choice(["organic", "cpc", "email", "referral"]),
                "campaign": random.choice([fake.company(), None])
            })
    return sessions

def generate_pageview_data(sessions, n_pageviews_per_session=5):
    pageviews = []
    for session in sessions:
        for _ in range(n_pageviews_per_session):
            pageview_id = str(uuid.uuid4())
            pageview_time = fake.date_time_between(start_date="-1y", end_date="now")
            pageviews.append({
                "pageview_id": pageview_id,
                "session_id": session["session_id"],
                "page_path": fake.uri_path(),
                "page_title": fake.sentence(),
                "timestamp": pageview_time.strftime("%Y-%m-%dT%H:%M:%S"),
                "time_on_page": random.randint(10, 300),
                "previous_page_path": fake.uri_path() if random.random() > 0.2 else None
            })
    return pageviews

def generate_event_data(sessions, n_events_per_session=3):
    events = []
    for session in sessions:
        for _ in range(n_events_per_session):
            event_id = str(uuid.uuid4())
            event_time = fake.date_time_between(start_date="-1y", end_date="now")
            events.append({
                "event_id": event_id,
                "session_id": session["session_id"],
                "event_category": random.choice(["click", "scroll", "interaction"]),
                "event_action": random.choice(["click_button", "form_submit", "play_video"]),
                "event_label": random.choice([None, "video_1", "button_3"]),
                "event_value": random.randint(1, 100),
                "timestamp": event_time.strftime("%Y-%m-%dT%H:%M:%S")
            })
    return events

def generate_goal_data(sessions, n_goals_per_session=1):
    goals = []
    for session in sessions:
        for _ in range(n_goals_per_session):
            goal_id = str(uuid.uuid4())
            goal_time = fake.date_time_between(start_date="-1y", end_date="now")
            goals.append({
                "goal_id": goal_id,
                "session_id": session["session_id"],
                "goal_name": random.choice(["Purchase", "Sign-up", "Download"]),
                "goal_completion_time": goal_time.strftime("%Y-%m-%dT%H:%M:%S"),
                "goal_value": random.uniform(1.0, 100.0)
            })
    return goals

def generate_analytics_data(n_users=10):
    # Генерация данных пользователей
    users = generate_user_data(n_users)
    
    # Генерация данных сессий для каждого пользователя
    sessions = generate_session_data(users)
    
    # Генерация данных просмотров страниц для каждой сессии
    pageviews = generate_pageview_data(sessions)
    
    # Генерация данных событий для каждой сессии
    events = generate_event_data(sessions)
    
    # Генерация данных целей для каждой сессии
    goals = generate_goal_data(sessions)
    
    return {
        "users": users,
        "sessions": sessions,
        "pageviews": pageviews,
        "events": events,
        "goals": goals
    }

def send_data_to_api(data):
    api_url = os.getenv("API_URL")
    if not api_url:
        raise ValueError("Error: API_URL environment variable is not set")
    
    response = requests.post(api_url, json=data)
    if response.status_code == 200:
        print("Data successfully sent to API")
    else:
        print(f"Error: Failed to send data to API. Status code: {response.status_code}, Response: {response.text}")

def wait_for_localstack(timeout=60):
    url = os.getenv("LOCALSTACK_URL")
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, verify=False)
            print(f"Response status code: {response.status_code}")
            print(f"Response content: {response.text}")
            if response.status_code == 200:
                print(f"Connected to LocalStack at {url}")
                return True
        except requests.ConnectionError:
            print(f"Waiting for LocalStack at {url}...")
            time.sleep(5)
    print(f"Error: Failed to connect to LocalStack at {url} within {timeout} seconds")
    return False

def load_env_vars(file_path):
    with open(file_path) as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ[key] = value

if __name__ == "__main__":
    if wait_for_localstack(90):
        time.sleep(80) # wait for LocalStack to fully initialize (костыль лол)
        try:
            load_env_vars('/shared/api_url.env')
        except Exception as e:
            print(f"Error: Failed to load environment variables: {e}")
            exit(1)
        print("LocalStack is ready. Running data generator...")
        while True:
            data = generate_analytics_data(1)
            send_data_to_api(data)
            time.sleep(20)
    else:
        print("Error: Exiting due to LocalStack connection failure.")

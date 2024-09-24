-- Подключение к созданной базе данных
\c web_analytics;

-- Создаем таблицу users (пользователи)
CREATE TABLE users (
    user_id VARCHAR(255) PRIMARY KEY,
    client_id VARCHAR(255) NOT NULL,
    first_visit_date DATE,
    last_visit_date DATE,
    country VARCHAR(100),
    device_category VARCHAR(50),
    browser VARCHAR(100)
);

-- Создаем таблицу sessions (сессии)
CREATE TABLE sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) REFERENCES users(user_id) ON DELETE CASCADE,
    session_start_time TIMESTAMP,
    session_end_time TIMESTAMP,
    session_duration INT,
    pageviews INT,
    source VARCHAR(100),
    medium VARCHAR(50),
    campaign VARCHAR(100)
);

-- Создаем таблицу pageviews (просмотры страниц)
CREATE TABLE pageviews (
    pageview_id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES sessions(session_id) ON DELETE CASCADE,
    page_path VARCHAR(255),
    page_title VARCHAR(255),
    timestamp TIMESTAMP,
    time_on_page INT,
    previous_page_path VARCHAR(255)
);

-- Создаем таблицу events (события)
CREATE TABLE events (
    event_id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES sessions(session_id) ON DELETE CASCADE,
    event_category VARCHAR(100),
    event_action VARCHAR(100),
    event_label VARCHAR(255),
    event_value INT,
    timestamp TIMESTAMP
);

-- Создаем таблицу goals (цели)
CREATE TABLE goals (
    goal_id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES sessions(session_id) ON DELETE CASCADE,
    goal_name VARCHAR(100),
    goal_completion_time TIMESTAMP,
    goal_value FLOAT
);

-- Индексы для ускорения поиска

-- Индекс для поиска по user_id в таблице sessions
CREATE INDEX idx_sessions_user_id ON sessions(user_id);

-- Индекс для поиска по session_id в таблице pageviews
CREATE INDEX idx_pageviews_session_id ON pageviews(session_id);

-- Индекс для поиска по session_id в таблице events
CREATE INDEX idx_events_session_id ON events(session_id);

-- Индекс для поиска по session_id в таблице goals
CREATE INDEX idx_goals_session_id ON goals(session_id);

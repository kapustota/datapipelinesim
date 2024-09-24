Docker, Python, Localstack

Data is being randomly generated at "data-generator" Docker container, sent to Localstack API Gateway, which triggers Lambda loader to s3. Then s3 triggers another Lambda, that pulling required dependencies from Lambda Layer and, therefore, exports .jsons from s3 and loads the data to local Postgres database. 

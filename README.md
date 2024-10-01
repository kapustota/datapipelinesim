Docker, Python, Localstack

Data is being randomly generated at "data-generator" Docker container, sent to Localstack API Gateway, which triggers Lambda loader to s3. Then s3 triggers another Lambda, that pulling required dependencies from Lambda Layer and, therefore, exports .jsons from s3 and loads the data to local Postgres database. 


How to build and run (Linux): 

1. Install [Docker Desktop](https://docs.docker.com/desktop/).


2. Give Docker necessary permissions:
```
sudo usermod -aG docker $USER
```

3. Go to the directory of the source code and run the containers:

```
docker-compose up &
```

4. To stop the containers running, use:

```
docker-compose down
```

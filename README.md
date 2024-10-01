Docker, Python, Localstack

Data is being randomly generated at "data-generator" Docker container, sent to Localstack API Gateway, which triggers Lambda loader to s3. Then s3 triggers another Lambda, that pulling required dependencies from Lambda Layer and, therefore, exports .jsons from s3 and loads the data to local Postgres database. 


How to build and run: 

1. Install Docker and Docker-compose and give it the necessary permissions:

'''
sudo apt update
sudo apt upgrade
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce
sudo usermod -aG docker $USER
'''

2. Install Docker-compose:

'''
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
'''

3. Go to the directory of the source code and run the containers:

'''
docker-compose up &
'''

4. To stop the containers running, use:

'''
docker-compose down
'''

# Project Name

This project provides scripts for setting up and updating a server environment using Docker, Nginx, Certbot, AWS CLI, and PM2.

## Prerequisites

- Ubuntu-based server
- Docker
- Nginx
- Certbot
- AWS CLI
- PM2
- AWS ECR repository with a Docker image

## Start

1. Clone this repository to your server.

2. Navigate to the project directory:
cd project-directory

3. Create a `.env` file and populate it with the required environment variables. You can use the provided `.env.example` as a template.

4. Create a `.env.docker` file and populate it with the environment variables specific to the Docker container. You can use the provided `.env.docker.example` as a template.

5. Make the start script executable:
chmod +x start.sh

6. Run the start script:
./start.sh

## Updating

1. Run the update script:
./update.sh

2. The update script will pull the latest Docker image, stop and delete the old PM2 process, and start a new PM2 process with the latest Docker image.

## Usage

- The server environment can be started, stopped, and managed using PM2:
pm2 start|stop|restart|delete|status process-name

- The Docker container logs can be viewed using PM2:
pm2 logs process-name

## License

This project is licensed under the [MIT License](LICENSE).
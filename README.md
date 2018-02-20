# Jupyter Workspace Setup
I created this project to help me re-produce my python juypter notebook working environment very quickly using docker.
## Features
* This docker setup is using CN mirrors for all kinds of sources (apt, npm, conda, pip, etc.) to speed up build time in CN. 
## Prerequisites
* Docker Compose 1.6.0+
* Docker Engine 1.10.0+

## Requirement
### Port (Default)
* 8888
* 8080

## Quick Start
### Change setting
modify the passwords in nb_secrets.env  to fit your environment

### Build and start containers 
```
docker-compose build
docker-compose up -d
```

# Jupyter Workspace Setup
I created this project to help me re-produce my python juypter notebook working environment very quickly using docker.
## Features
* This docker setup is using CN mirrors for all kinds of sources (apt, npm, conda, pip, etc.) to speed up build time in CN. 
## Prerequisites
* Docker Compose 1.6.0+
* Docker Engine 1.10.0+

## Requirement
### Port (Default)
* 3000
* 8888
* 8080

## Quick Start
### Change setting
modify the passwords, redirect URLs, etc. in nb_secrets.env and db_secrets.env to fit your environment

### Build and start containers 
```
docker-compose build
docker-compose up -d
```
After running the above, open a browser to `http://<your docker host IP>:8888/tree` to access the notebook server. Open the hello world notebook, run it, switch to dashboard mode to see it working. Then use the *File &rarr; Deploy As &rarr; Dashboard on Jupyter Dashboard Server*. After deploying, the notebook server will automatically redirect you to the dashboard server running on `http://<your docker host IP>:3000`. Login with `demo` as the username and password.
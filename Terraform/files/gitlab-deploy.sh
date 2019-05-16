#!/bin/bash
set -e

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu xenial stable"
sudo apt-get update

sudo apt-get install docker-ce docker-compose -y

sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab/

sudo bash -c 'printf \
"gitlab:\n\
  image: \"gitlab/gitlab-ce:latest\"\n\
  restart: always\n\
  hostname: \"gitlab.example.com\"\n\
  environment:\n\
    GITLAB_OMNIBUS_CONFIG: |\n\
      external_url \"http://%s/\"\n\
      gitlab_rails['initial_root_password'] = 'password'
  ports:\n\
    - \"80:80\"\n\
    - \"443:443\"\n\
    - \"2222:22\"\n\
  volumes:\n\
    - \"/srv/gitlab/config:/etc/gitlab\"\n\
    - \"/srv/gitlab/logs:/var/log/gitlab\"\n\
    - \"/srv/gitlab/data:/var/opt/gitlab\"\n" "$(curl ifconfig.me/ip)" > docker-compose.yml' 

sudo docker-compose up -d




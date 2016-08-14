#!/bin/bash

cd $(dirname $0)
if ! command -v docker-compose >/dev/null; then
    echo 'Seem you have not install docker-compose, yet!!!'
    echo 'Install make sure it is under the PATH'
    exit 1
fi

cat <<EOF > docker-compose.yml
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.gzts.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'https://gitlab.gzts.com'
      gitlab_rails['gitlab_shell_ssh_port'] = 10022
  ports:
    - '80:80'
    - '443:443'
    - '10022:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
EOF

mkdir -p /srv/gitlab/{config,logs/reconfigure,data}
docker-compose up -d

#!/bin/bash

sudo docker kill freq_build
sudo docker rm freq_build

dir=$(readlink -f $(dirname $0))

# Make it accessible to both the user and the container
chcon -R -t container_home_t  .

# FOR TESTING; forces complete docker rebuild
# sudo docker build --no-cache -t lojban/freq_build -f Dockerfile .
# sudo docker rmi lojban/freq_build
sudo docker build -t lojban/freq_build -f Dockerfile . || {
  echo "Docker build failed."
  exit 1
}
sudo /bin/docker run --name freq_build --log-driver syslog --log-opt tag=freq_build \
  -v $dir:/srv/freq -it lojban/freq_build \
  /tmp/docker_init.sh "$(id -u)" "$(id -g)" "$@"

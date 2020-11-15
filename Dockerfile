FROM debian:buster-slim

MAINTAINER Safayet Ahmed <sahmed62@<JHU domain name>>

# echo commands
# stop on error
# install build packages, build, remove packages
# RUN set -ex \

# install run-time packages
RUN set -ex \
        &&  apt update                  \
        &&  apt install -y              \
                linux-perf              \
                stress-ng               \
        &&  rm -rf /var/lib/apt/lists/* \
        &&  mkdir /home/perf-stress-ng

# add scripts
ADD --chown=0:0 image-scripts/stress-ng-wrap.sh.include /bin/stress-ng-wrap.sh.include
ADD --chown=0:0 image-scripts/indirection.sh /bin/indirection.sh
ADD --chown=0:0 image-scripts/entrypoint.sh /bin/entrypoint.sh

# set working directory
WORKDIR /home/perf-stress-ng

# set entrypoint
ENTRYPOINT ["/bin/entrypoint.sh"]


FROM ubuntu:20.04

MAINTAINER Safayet Ahmed <sahmed62@<JHU domain name>>

# echo commands
# stop on error
# install build packages, build, remove packages
# RUN set -ex \

# install run-time packages
RUN set -ex \
        &&  apt update                          \
        &&  apt install -y                      \
                bc                              \
                linux-tools-common              \
                linux-tools-lowlatency          \
                linux-cloud-tools-lowlatency    \
                linux-tools-$(uname -r)         \
                linux-cloud-tools-$(uname -r)   \
                stress-ng                       \
        &&  rm -rf /var/lib/apt/lists/*         \
        &&  mkdir /home/perf-stress-ng

# add scripts
ADD --chown=0:0 image-scripts/stress-ng-wrap.sh.include /bin/stress-ng-wrap.sh.include
ADD --chown=0:0 image-scripts/indirection.sh /bin/indirection.sh
ADD --chown=0:0 image-scripts/entrypoint.sh /bin/entrypoint.sh

# set working directory
WORKDIR /home/perf-stress-ng

# set entrypoint
ENTRYPOINT ["/bin/entrypoint.sh"]


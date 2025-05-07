#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************

ARG ECR_REGISTRY=ecr_registry_not_set

# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image

FROM ${ECR_REGISTRY}/uc3-mrt-admin-common
ARG COMMITDATE=''
ARG DOCKTAG=''

RUN dnf -y update && dnf clean all

# Add Admin Tool Code to the image
RUN ls /var/task
COPY . /var/task/

# Bundle dependencies
RUN bundle install 

# https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV COMMITDATE=$COMMITDATE
ENV DOCKTAG=$DOCKTAG
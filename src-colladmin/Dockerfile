#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************

FROM node as build
WORKDIR /tmp/assets

RUN npm install mustache --save
RUN find . -type f

# This image has been built from an image that matches the Lambda Ruby runtime
# MySql binary dependencies have been embedded into the image

FROM cdluc3/uc3-mrt-admin-common

# Build rest-client gem from source
RUN yum -y install gcc-c++

# Add Admin Tool Code to the image
COPY . /var/task/
COPY --from=build /tmp/assets/node_modules/mustache/mustache.min.js /var/task/web/mustache.min.js 

# Bundle dependencies
RUN bundle install 

# https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

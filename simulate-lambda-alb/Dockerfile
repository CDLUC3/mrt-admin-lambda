#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************

# This image is intended to simulate an ALB fronting a Lambda
# docker build -t ${ECR_REGISTRY}/simulate-lambda-alb .

FROM ruby:2.7

RUN apt-get update

RUN gem install bundler

COPY Gemfile Gemfile

RUN bundle install

COPY . .

# https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 8091

CMD ["ruby", "alb_simulate.rb"]
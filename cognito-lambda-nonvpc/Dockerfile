#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************

FROM public.ecr.aws/lambda/ruby:3.2

RUN yum -y update && yum -y upgrade

RUN yum -y install gcc make git

RUN gem update bundler 

# Start with a Gemfile containing only MySQL
COPY * ./

RUN bundle config set path 'vendor/bundle' && \
    bundle install 

# This structure assumes the following:
#   lambda_function.rb contains a module name LambdaFunctions which contains a class Handler
# That class conforms to the method signature expected for a Lambda.
CMD [ "lambda_function.LambdaFunctions::Handler.process" ]
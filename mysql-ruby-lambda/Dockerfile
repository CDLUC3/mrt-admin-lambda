#*********************************************************************
#   Copyright 2021 Regents of the University of California
#   All rights reserved
#*********************************************************************
# This image is based on an architecture that matches the Lambda Ruby runtime
# docker build -t ${ECR_REGISTRY}/mysql-ruby-lambda .

FROM public.ecr.aws/lambda/ruby:3

RUN yum -y update

# Install an os-specific MySQL installation.  
# gcc and make are required to build mysql.
# UC3 ruby code pulls a common gem from github for use in Lambda code.
RUN yum -y install mysql-devel gcc make git

RUN gem update bundler && \
    git clone https://github.com/cdluc3/uc3-ssm.git && \
    cd uc3-ssm && \
    gem build uc3-ssm.gemspec && \
    gem install uc3-ssm*.gem && \
    cd ..

# Start with a Gemfile containing only MySQL
COPY * ./

RUN bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
    bundle config --local silence_root_warning true && \
    bundle config set path 'vendor/bundle' && \
    bundle install && \
    gem install uc3-ssm/uc3-ssm*.gem --install-dir vendor/bundle/ruby/3.2.0

# This structure assumes the following:
#   lambda_function.rb contains a module name LambdaFunctions which contains a class Handler
# That class conforms to the method signature expected for a Lambda.
CMD [ "lambda_function.LambdaFunctions::Handler.process" ]
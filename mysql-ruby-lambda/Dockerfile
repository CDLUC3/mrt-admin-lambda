# This image is based on an architecture that matches the Lambda Ruby runtime
# docker build -t cdluc3/mysql-ruby-lambda .
FROM public.ecr.aws/lambda/ruby:2.7

# Install an os-specific MySQL installation.  The ruby code is insufficient to run
RUN yum -y install mysql-devel gcc make
RUN gem update bundler

# Start with a Gemfile containing only MySQL
COPY * ./

#RUN bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
#    bundle config --local silence_root_warning true && \
#    bundle config set path 'vendor/bundle' && \
#    bundle install 

# This image is based on an architecture that matches the Lambda Ruby runtime
FROM lambci/lambda:build-ruby2.7

# Install an os-specific MySQL installation.  The ruby code is insufficient to run
RUN yum -y install mysql-devel
RUN gem update bundler

# Start with a Gemfile containing only MySQL
COPY Gemfile ./

RUN bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
    bundle config --local silence_root_warning true && \
    bundle config set path 'vendor/bundle' && \
    bundle install && \
    # Copy the OS specific shared libraries into the working directory
    mkdir -p /var/task/lib && \
    cp -a /usr/lib64/mysql/*.so.* /var/task/lib/ && \
    # Zip the dependencies
    zip -r mysql-dependencies.zip .

# Sleep the docker container for 10 seconds.  This will allow the generated zip file to be copied out of the container.
CMD sleep 10

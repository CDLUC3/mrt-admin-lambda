# This image is based on an architecture that matches the Lambda Ruby runtime
FROM lambci/lambda:build-ruby2.7

# Install an os-specific MySQL installation.  The ruby code is insufficient to run
RUN yum -y install mysql-devel
RUN gem update bundler

# A special Gemfile has been created without uc3-ssm
# Note that only the dependencies are copied.
# A separate build will push source code changes into this zip file.
COPY Gemfile.docker ./Gemfile
COPY Gemfile.lock ./

# The uc3-ssm gem has been published as a GitHub package, but it cannot be installed without GitHub credentials
# Therefore, gem specific install is used
RUN gem install specific_install && \
    gem specific_install -l https://github.com/CDLUC3/uc3-ssm  && \
    # Build the MySql libraries for this architecture
    bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
    bundle config --local silence_root_warning true && \
    bundle config set path 'vendor/bundle' && \
    bundle install && \
    # Manually copy the gem and specification installed with gem specific install into the package
    cp -r /var/runtime/gems/uc3-ssm-0.1.1 vendor/bundle/ruby/2.7.0/gems/ && \
    cp -r /var/runtime/specifications/uc3-ssm* vendor/bundle/ruby/2.7.0/specifications/ && \
    # Copy the OS specific shared libraries into the working directory
    mkdir -p /var/task/lib && \
    cp -a /usr/lib64/mysql/*.so.* /var/task/lib/ && \
    # Zip the dependencies
    zip -r dependencies.zip .

# Sleep the docker container for 10 seconds.  This will allow the generated zip file to be copied out of the container.
CMD sleep 10

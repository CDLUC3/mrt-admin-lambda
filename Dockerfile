FROM lambci/lambda:build-ruby2.7
RUN yum -y install mysql-devel
RUN gem update bundler

#COPY Gemfile* src/* ./
COPY Gemfile* ./

RUN gem install specific_install && \
    gem specific_install -l https://github.com/CDLUC3/uc3-ssm -v && \
    mkdir -p vendor/bundle/ruby/2.7.0/gems/ && \
    cp -r /var/runtime/gems/uc3-ssm-* vendor/bundle/ruby/2.7.0/gems/ && \
    bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
    bundle config --local silence_root_warning true && \
    bundle install --path vendor/bundle && \
    mkdir -p /var/task/lib && \
    cp -a /usr/lib64/mysql/*.so.* /var/task/lib/ && \
    zip -r dependencies.zip .
    
CMD sleep 10

FROM lambci/lambda:build-ruby2.7
RUN yum -y install mysql-devel
RUN gem update bundler

#COPY Gemfile* src/* ./
COPY Gemfile* ./

RUN bundle config --local build.mysql2 --with-mysql2-config=/usr/lib64/mysql/mysql_config && \
    bundle config --local silence_root_warning true && \
    bundle install --path vendor/bundle --clean --standalone && \
    mkdir -p /var/task/lib && \
    cp -a /usr/lib64/mysql/*.so.* /var/task/lib/ && \
    rm -rf vendor/bundle/ruby/2.7.0/cache && \
    rm -rf vendor/bundle/ruby/2.7.0/extensions && \
    rm -rf vendor/bundle/ruby/2.7.0/build_info && \
    rm -rf vendor/bundle/ruby/2.7.0/specifications && \
    rm -rf vendor/bundle/ruby/2.7.0/bundler/gems/uc3-ssm-* && \
    zip -r dependencies.zip .

CMD sleep 10

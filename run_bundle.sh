#!/bin/bash
cd mysql-ruby-lambda
bundle install
bundle update
cd ../src-common
bundle install
bundle update
cd ../src-admintool
bundle install
bundle update
cd ../src-colladmin
rm -rf vendor/bundle/ruby/3*/bundler/gems/mrt-zk*
bundle install --redownload
bundle update
cd ../src-testdriver
bundle install
bundle update
cd ../cognito-lambda-nonvpc
bundle install
bundle update

#!/bin/bash
cd mysql-ruby-lambda
echo
pwd
echo '==========='
bundle update --bundler
bundle install
bundle update
bundle exec rubocop || exit
cd ../src-common
echo
pwd
echo '==========='
bundle update --bundler
bundle install
bundle update
bundle exec rubocop || exit
cd ../src-admintool
echo
pwd
echo '==========='
bundle update --bundler
bundle install
bundle update
bundle exec rubocop || exit
cd ../src-colladmin
echo
pwd
echo '==========='
rm -rf vendor/bundle/ruby/3*/bundler/gems/mrt-zk*
bundle update --bundler
bundle install
bundle update
bundle exec rubocop || exit
cd ../src-testdriver
echo
pwd
echo '==========='
bundle update --bundler
bundle install
bundle update
bundle exec rubocop || exit
cd ../simulate-lambda-alb
echo
pwd
echo '==========='
bundle install
bundle update
bundle exec rubocop || exit
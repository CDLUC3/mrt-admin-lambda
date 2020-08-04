#!/bin/bash

# Start with the bundle dependencies.  Code will be inserted into `deploy.zip`
cp mysql-deps/mysql-dependencies.zip deploy.zip

# Bundle addtional dependencies
bundle install

# Copy ruby code into zip
cd src
zip -r ../deploy.zip *
cd ../build
zip -r ../deploy.zip vendor/bundle/ruby/2.7.0/gems vendor/bundle/2.7.0/specifications
cd ..

# Display zip contents to the user
unzip -l deploy.zip

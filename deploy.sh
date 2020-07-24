#!/bin/bash

# If you have modified the Gemfile, you must run `makeDependencies.sh`

# Depends on https://github.com/CDLUC3/uc3-aws-cli scripts
EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Get the ARN for the lambda to publish
LAMBDA_ARN=`get_ssm_value_by_name admintool/lambda-arn`

# Get the URL for links to Merritt
MERRITT_PATH=`get_ssm_value_by_name admintool/merritt-path`

# Start with the bundle dependencies.  Code will be inserted into `deploy.zip`
cp dependencies.zip deploy.zip

# Copy ruby code into zip
cd src
zip -r ../deploy.zip *
cd ..

# Display zip contents to the user
unzip -l deploy.zip

# deploy lambda code
aws lambda update-function-code --function-name ${LAMBDA_ARN} --zip-file fileb://deploy.zip --region us-west-2

# Set environment and set timeout
aws lambda update-function-configuration --function-name ${LAMBDA_ARN} --region us-west-2 --timeout 60 --memory-size 128 --environment "Variables={SSM_ROOT_PATH=${SSM_ROOT_PATH},MERRITT_PATH=${MERRITT_PATH}}"

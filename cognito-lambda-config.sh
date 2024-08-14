#!/bin/bash

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

AWS_ACCOUNT_ID=`aws sts get-caller-identity| jq -r .Account` || die "AWS Account Not Found"
FUNCTNAME=uc3-mrt-cognitousers

# Get the ARN for the lambda to publish
LAMBDA_ARN=arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:uc3-mrt-cognitousers-img-prd

aws lambda update-function-configuration \
  --function-name ${LAMBDA_ARN} \
  --region us-west-2 \
  --output text \
  --timeout 180 \
  --memory-size 128 \
  --no-cli-pager 


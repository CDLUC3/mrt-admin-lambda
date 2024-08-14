#!/bin/bash

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

AWS_ACCOUNT_ID=`aws sts get-caller-identity| jq -r .Account` || die "AWS Account Not Found"
FUNCTNAME=uc3-mrt-cognitousers

# Get the ARN for the lambda to publish
LAMBDA_ARN=arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:uc3-mrt-cognitousers-img-prd

# Get the ECR image to publish
ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
UC3_ECR_REGISTRY=`get_ssm_value_by_name admintool/uc3-ecr-registry`
ECR_IMAGE_TAG=${UC3_ECR_REGISTRY}/${FUNCTNAME}:latest

# deploy lambda code
aws lambda update-function-code \
  --function-name ${LAMBDA_ARN} \
  --image-uri ${ECR_IMAGE_TAG} \
  --output text --region us-west-2 \
  --no-cli-pager \
  || die "Lambda Update failure"

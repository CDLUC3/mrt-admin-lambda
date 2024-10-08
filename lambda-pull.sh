#!/bin/bash

DEPLOY_ENV=${1:-dev}

EXIT_ON_DIE=true
source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

# Assume deploy runs from DEV
# Set ENV based on deploy env
SSM_DEPLOY_PATH=${SSM_ROOT_PATH//dev/${DEPLOY_ENV}}
AWS_ACCOUNT_ID=`aws sts get-caller-identity| jq -r .Account` || die "AWS Account Not Found"
UC3_ACCOUNT_ID=`get_ssm_value_by_name admintool/uc3account` || die "UC3 Account Not Found"
FUNCTNAME=uc3-mrt-admin-lambda

# Get the ARN for the lambda to publish
LAMBDA_ARN_BASE=arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:uc3-mrt-admintool-img
LAMBDA_ARN=${LAMBDA_ARN_BASE}-${DEPLOY_ENV}

# Get the ECR image to publish
ECR_REGISTRY=${UC3_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
ECR_IMAGE_TAG=${ECR_REGISTRY}/${FUNCTNAME}:${DEPLOY_ENV}

# login to ecr
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS \
    --password-stdin ${ECR_REGISTRY}/

# build a ruby lambda container with mysql
docker pull ${ECR_REGISTRY}/mysql-ruby-lambda \
  || die "Image pull failure for ${ECR_REGISTRY}/mysql-ruby-lambda"

# build common image for admintool and colladmin
docker pull ${ECR_REGISTRY}/uc3-mrt-admin-common \
  || die "Image pull failure for ${ECR_REGISTRY}/uc3-mrt-admin-common"

docker pull ${ECR_REGISTRY}/uc3-mrt-admin-lambda:prd \
  || die "Image pull failure for ${ECR_REGISTRY}/uc3-mrt-admin-lambda:prd"

docker pull ${ECR_REGISTRY}/uc3-mrt-colladmin-lambda:prd \
  || die "Image pull failure for ${ECR_REGISTRY}/uc3-mrt-colladmin-lambda:prd"

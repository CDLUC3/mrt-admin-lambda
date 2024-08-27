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
docker build --pull \
  -t ${ECR_REGISTRY}/mysql-ruby-lambda mysql-ruby-lambda \
  || die "Image build failure for ${ECR_REGISTRY}/mysql-ruby-lambda"

# aws ecr create-repository --repository-name mysql-ruby-lambda
docker push ${ECR_REGISTRY}/mysql-ruby-lambda \
  || die "Image push failure for mysql-ruby-lambda"

# build common image for admintool and colladmin
docker build --pull \
  --build-arg ECR_REGISTRY=${ECR_REGISTRY} \
  -t ${ECR_REGISTRY}/uc3-mrt-admin-common src-common \
  || die "Image build failure for ${ECR_REGISTRY}/uc3-mrt-admin-common"

# aws ecr create-repository --repository-name uc3-mrt-admin-common
docker push ${ECR_REGISTRY}/uc3-mrt-admin-common \
  || die "Image push failure for ${ECR_REGISTRY}/uc3-mrt-admin-common"

COMMITDATE=`date "+local: %Y-%m-%dT%H:%M:%S%z"`
# the build runs faster if the build tag does not change
COMMITDATE=devserver
DOCKTAG="local: ${DEPLOY_ENV}"

# build the admin tool
docker build --pull \
  --build-arg ECR_REGISTRY=${ECR_REGISTRY} \
  --build-arg COMMITDATE="${COMMITDATE}" \
  --build-arg DOCKTAG="${DOCKTAG}" \
  -t ${ECR_IMAGE_TAG} src-admintool \
  || die "Image build failure for ${ECR_IMAGE_TAG}"

# aws ecr create-repository --repository-name ${FUNCTNAME}
docker push ${ECR_IMAGE_TAG} || die "Image push failure"

# deploy lambda code
aws lambda update-function-code \
  --function-name ${LAMBDA_ARN} \
  --image-uri ${ECR_IMAGE_TAG} \
  --output text --region us-west-2 \
  --no-cli-pager \
  || die "Lambda Update failure"

date